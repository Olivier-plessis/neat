import 'package:neat/features/generation/domain/services/templates/dart/_template_utils.dart';

class PresentationTemplates {
  PresentationTemplates._();

  // ── presentation/providers ────────────────────────────────────────────────

  static String featureProvider({
    required String featureName,
    required String packageName,
    required bool useAnnotations,
    required bool useCubit,
    bool dataList = false,
    bool realtime = false,
  }) {
    if (useCubit) return _cubitTemplate(featureName);
    if (useAnnotations) {
      if (dataList) {
        return realtime
            ? _riverpodListStreamNotifier(featureName, packageName)
            : _riverpodListNotifier(featureName, packageName);
      }
      return _riverpodAnnotationTemplate(featureName);
    }
    return _riverpodManualTemplate(featureName);
  }

  /// Realtime list: the notifier subscribes to the repository's live stream
  /// (Supabase `.stream()`), so the screen updates on every row change.
  static String _riverpodListStreamNotifier(String featureName, String packageName) {
    final p = pascal(featureName);
    return '''import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:$packageName/features/$featureName/domain/entities/${featureName}_entity.dart';
import '${featureName}_providers.dart';

part '${featureName}_provider.g.dart';

@riverpod
class ${p}Notifier extends _\$${p}Notifier {
  @override
  Stream<List<${p}Entity>> build() => ref.watch(${camel(featureName)}RepositoryProvider).watchAll();
}
''';
  }

  /// Notifier that loads the feature's items via its usecase. `build()` is async
  /// so the UI gets `AsyncValue<List<Entity>>` (loading → Skeletonizer).
  static String _riverpodListNotifier(String featureName, String packageName) {
    final p = pascal(featureName);
    return '''import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:$packageName/features/$featureName/domain/entities/${featureName}_entity.dart';
import '${featureName}_providers.dart';

part '${featureName}_provider.g.dart';

@riverpod
class ${p}Notifier extends _\$${p}Notifier {
  @override
  Future<List<${p}Entity>> build() async {
    final result = await ref.watch(get${p}UsecaseProvider).execute();
    return result.getOrThrow();
  }
}
''';
  }

  // ── presentation/providers/<f>_providers.dart (ready-to-use DI graph) ─────

  /// Wires the full feature graph as Riverpod providers: API source (using the
  /// core dio/chopper provider, so the API_BASE_URL flows in), local source +
  /// Drift db + NetworkInfo when offline-first, the repository, and the CRUD
  /// usecases. Generated only with riverpod annotations + a remote source.
  static String featureDi({
    required String featureName,
    required String packageName,
    required String httpClient,
    required bool offlineFirst,
    bool hasSync = false,
    String? localStoragePackage,
  }) {
    final p = pascal(featureName);
    final c = camel(featureName);

    final imports = StringBuffer();
    if (hasSync) imports.writeln("import 'dart:convert';\n");
    imports.writeln("import 'package:riverpod_annotation/riverpod_annotation.dart';");
    if (offlineFirst) {
      // Shared app-wide singletons (Drift db + connectivity) live in core, not
      // per feature, so every feature reuses the same instances.
      imports.writeln(
          "import 'package:$packageName/core/providers/infrastructure_providers.dart';");
    }
    imports.writeln(switch (httpClient) {
      'chopper' => "import 'package:$packageName/core/network/chopper_client_provider.dart';",
      'supabase' => "import 'package:$packageName/core/network/supabase_provider.dart';",
      'firebase' => "import 'package:$packageName/core/network/firebase_provider.dart';",
      _ => "import 'package:$packageName/core/network/dio_provider.dart';",
    });
    if (hasSync) {
      imports.writeln("import 'package:$packageName/core/sync/sync_service.dart';");
    }
    imports
      ..writeln(
          "import 'package:$packageName/features/$featureName/data/repositories/${featureName}_repository_impl.dart';")
      ..writeln(
          "import 'package:$packageName/features/$featureName/data/sources/${featureName}_api_source.dart';");
    if (hasSync) {
      imports.writeln(
          "import 'package:$packageName/features/$featureName/data/models/${featureName}_model.dart';");
    }
    if (offlineFirst) {
      imports.writeln(
          "import 'package:$packageName/features/$featureName/data/sources/${featureName}_local_source.dart';");
    }
    imports
      ..writeln(
          "import 'package:$packageName/features/$featureName/domain/repositories/i_${featureName}_repository.dart';")
      ..writeln(
          "import 'package:$packageName/features/$featureName/domain/usecases/get_${featureName}_usecase.dart';")
      ..writeln(
          "import 'package:$packageName/features/$featureName/domain/usecases/${featureName}_crud_usecases.dart';");

    final apiConstruct = switch (httpClient) {
      'chopper' => '${p}ApiSource.create(ref.watch(chopperClientProvider))',
      'supabase' => '${p}ApiSource(ref.watch(supabaseClientProvider))',
      'firebase' => '${p}ApiSource(ref.watch(firestoreProvider))',
      _ => '${p}ApiSource(ref.watch(dioProvider))',
    };

    // appDatabaseProvider + networkInfoProvider come from the shared
    // core/providers/infrastructure_providers.dart (single instance app-wide).
    final offlineProviders = offlineFirst
        ? '''

@Riverpod(keepAlive: true)
${p}LocalSource ${c}LocalSource(Ref ref) => ${p}LocalSource(ref.watch(appDatabaseProvider));'''
        : '';

    final repoConstruct = offlineFirst
        ? '${p}RepositoryImpl(\n      ref.watch(${c}ApiSourceProvider),\n      ref.watch(${c}LocalSourceProvider),\n      ref.watch(networkInfoProvider),\n    )'
        : '${p}RepositoryImpl(ref.watch(${c}ApiSourceProvider))';

    // Chopper API calls return Response<T>; the result is ignored either way.
    final syncProvider = hasSync
        ? '''

/// Drains the offline write queue via the API source when back online.
/// Auto-starts on first read; cancels its subscription on dispose.
@Riverpod(keepAlive: true)
SyncService ${c}Sync(Ref ref) {
  final api = ref.watch(${c}ApiSourceProvider);
  final service = SyncService(
    ref.watch(appDatabaseProvider),
    ref.watch(networkInfoProvider),
    (entry) async {
      final data = entry.payload == null
          ? const <String, dynamic>{}
          : jsonDecode(entry.payload!) as Map<String, dynamic>;
      switch (entry.operation) {
        case 'create':
          await api.add(${p}Model.fromJson(data));
        case 'update':
          final model = ${p}Model.fromJson(data);
          await api.update(model.id, model);
        case 'delete':
          await api.delete(data['id'] as String);
      }
      return true;
    },
  )..start();
  ref.onDispose(service.dispose);
  return service;
}'''
        : '';

    return '''${imports.toString()}
part '${featureName}_providers.g.dart';

@Riverpod(keepAlive: true)
${p}ApiSource ${c}ApiSource(Ref ref) => $apiConstruct;$offlineProviders

@Riverpod(keepAlive: true)
I${p}Repository ${c}Repository(Ref ref) => $repoConstruct;

@Riverpod(keepAlive: true)
Get${p}Usecase get${p}Usecase(Ref ref) => Get${p}Usecase(ref.watch(${c}RepositoryProvider));

@Riverpod(keepAlive: true)
Create${p}Usecase create${p}Usecase(Ref ref) =>
    Create${p}Usecase(ref.watch(${c}RepositoryProvider));

@Riverpod(keepAlive: true)
Update${p}Usecase update${p}Usecase(Ref ref) =>
    Update${p}Usecase(ref.watch(${c}RepositoryProvider));

@Riverpod(keepAlive: true)
Delete${p}Usecase delete${p}Usecase(Ref ref) =>
    Delete${p}Usecase(ref.watch(${c}RepositoryProvider));$syncProvider
''';
  }

  static String _riverpodAnnotationTemplate(String featureName) {
    final p = pascal(featureName);
    return '''import 'package:riverpod_annotation/riverpod_annotation.dart';

part '${featureName}_provider.g.dart';

@riverpod
class ${p}Notifier extends _\$${p}Notifier {
  @override
  AsyncValue<void> build() => const AsyncData(null);
}
''';
  }

  static String _riverpodManualTemplate(String featureName) {
    final p = pascal(featureName);
    return '''import 'package:flutter_riverpod/flutter_riverpod.dart';

final ${camel(featureName)}Provider = StateNotifierProvider<${p}Notifier, AsyncValue<void>>(
  (ref) => ${p}Notifier(),
);

class ${p}Notifier extends StateNotifier<AsyncValue<void>> {
  ${p}Notifier() : super(const AsyncData(null));
}
''';
  }

  static String _cubitTemplate(String featureName) {
    final p = pascal(featureName);
    return '''import 'package:flutter_bloc/flutter_bloc.dart';

class ${p}Cubit extends Cubit<${p}State> {
  ${p}Cubit() : super(${p}Initial());
}

abstract class ${p}State {}
class ${p}Initial extends ${p}State {}
class ${p}Loading extends ${p}State {}
class ${p}Loaded extends ${p}State {}
class ${p}Error extends ${p}State {
  ${p}Error(this.message);
  final String message;
}
''';
  }

  // ── presentation/pages ────────────────────────────────────────────────────

  /// A real list screen: renders the feature's items, shows a Skeletonizer
  /// placeholder while loading, pull-to-refresh, and empty/error states.
  static String _riverpodListPage(String featureName, String packageName) {
    final p = pascal(featureName);
    final c = camel(featureName);
    return '''import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:$packageName/core/theme/theme_mode_controller.dart';
import 'package:$packageName/features/$featureName/domain/entities/${featureName}_entity.dart';
import 'package:$packageName/features/$featureName/presentation/providers/${featureName}_provider.dart';

class ${p}Page extends ConsumerWidget {
  const ${p}Page({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(${c}Provider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('$p'),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
            onPressed: () => ref.read(themeModeControllerProvider.notifier).toggle(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(${c}Provider),
        child: switch (state) {
          AsyncData(:final value) => _${p}List(items: value),
          AsyncError(:final error) => _${p}List.error(error.toString()),
          _ => Skeletonizer(
              child: _${p}List(
                items: List.generate(
                  8,
                  (_) => const ${p}Entity(id: '000000', name: 'Placeholder item name'),
                ),
              ),
            ),
        },
      ),
    );
  }
}

class _${p}List extends StatelessWidget {
  const _${p}List({required this.items}) : error = null;
  const _${p}List.error(this.error) : items = const [];

  final List<${p}Entity> items;
  final String? error;

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return ListView(
        children: [Padding(padding: const EdgeInsets.all(24), child: Text(error!))],
      );
    }
    if (items.isEmpty) {
      return ListView(
        children: const [Padding(padding: EdgeInsets.all(24), child: Text('No items yet.'))],
      );
    }
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = items[index];
        return ListTile(
          leading: const CircleAvatar(child: Icon(Icons.label_outline)),
          title: Text(item.name),
          subtitle: Text('id: \${item.id}'),
        );
      },
    );
  }
}
''';
  }

  static String featurePage({
    required String featureName,
    required String packageName,
    required bool hasRiverpod,
    required bool useAnnotations,
    required bool hasBloc,
    required bool useCubit,
    bool dataList = false,
  }) {
    final p = pascal(featureName);

    if (hasRiverpod && useAnnotations && dataList) {
      return _riverpodListPage(featureName, packageName);
    }

    if (hasRiverpod) {
      final body = useAnnotations
          ? '''switch (state) {
        AsyncData() => const Center(child: Text('$p')),
        AsyncError(:final error) => Center(child: Text(error.toString())),
        _ => const Center(child: CircularProgressIndicator()),
      }'''
          : '''state.when(
        data: (_) => const Center(child: Text('$p')),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
      )''';

      return '''import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:$packageName/core/theme/theme_mode_controller.dart';
import 'package:$packageName/features/$featureName/presentation/providers/${featureName}_provider.dart';

class ${p}Page extends ConsumerWidget {
  const ${p}Page({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(${camel(featureName)}Provider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('$p'),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
            onPressed: () => ref.read(themeModeControllerProvider.notifier).toggle(),
          ),
        ],
      ),
      body: $body,
    );
  }
}
''';
    }

    if (useCubit) {
      return '''import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:$packageName/core/theme/brightness_theme/brightness_cubit.dart';
import 'package:$packageName/features/$featureName/presentation/cubit/${featureName}_cubit.dart';

class ${p}Page extends StatelessWidget {
  const ${p}Page({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BlocProvider(
      create: (_) => ${p}Cubit(),
      child: BlocBuilder<${p}Cubit, ${p}State>(
        builder: (context, state) => Scaffold(
          appBar: AppBar(
            title: const Text('$p'),
            actions: [
              IconButton(
                icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
                onPressed: () => context.read<BrightnessCubit>().toggle(),
              ),
            ],
          ),
          body: const Center(child: Text('$p')),
        ),
      ),
    );
  }
}
''';
    }

    if (hasBloc) {
      return '''import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:$packageName/core/theme/brightness_theme/brightness_bloc.dart';
import 'package:$packageName/features/$featureName/presentation/bloc/${featureName}_bloc.dart';

class ${p}Page extends StatelessWidget {
  const ${p}Page({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BlocProvider(
      create: (_) => ${p}Bloc(),
      child: BlocBuilder<${p}Bloc, ${p}State>(
        builder: (context, state) => Scaffold(
          appBar: AppBar(
            title: const Text('$p'),
            actions: [
              IconButton(
                icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
                onPressed: () => context.read<BrightnessBloc>().add(const BrightnessToggled()),
              ),
            ],
          ),
          body: const Center(child: Text('$p')),
        ),
      ),
    );
  }
}
''';
    }

    return '''import 'package:flutter/material.dart';

class ${p}Page extends StatelessWidget {
  const ${p}Page({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('$p')),
      body: const Center(child: Text('$p')),
    );
  }
}
''';
  }

  // ── presentation/routes ───────────────────────────────────────────────────

  static String featureRoute({
    required String featureName,
    required String packageName,
    required bool useBuilder,
  }) {
    final p = pascal(featureName);

    if (useBuilder) {
      return '''import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:$packageName/features/$featureName/presentation/pages/${featureName}_page.dart';

class ${p}Route extends GoRouteData {
  const ${p}Route();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const ${p}Page();
}
''';
    }

    return '''import 'package:go_router/go_router.dart';
import 'package:$packageName/features/$featureName/presentation/pages/${featureName}_page.dart';

final ${camel(featureName)}Route = GoRoute(
  path: '/',
  builder: (context, state) => const ${p}Page(),
);
''';
  }
}
