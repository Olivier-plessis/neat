import 'package:neat/features/generation/domain/models/field_spec.dart';
import 'package:neat/features/generation/domain/services/templates/dart/_template_utils.dart';
import 'package:neat/features/generation/domain/services/templates/dart/field_codegen.dart';

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
    bool includeCrudUi = false,
    List<FieldSpec> fields = FieldSpec.idName,
  }) {
    if (useCubit) return _cubitTemplate(featureName);
    if (useAnnotations) {
      if (dataList) {
        return realtime
            ? _riverpodListStreamNotifier(featureName, packageName)
            : _riverpodListNotifier(featureName, packageName, includeCrudUi, fields);
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
import 'package:$packageName/features/$featureName/data/repositories/${featureName}_repository_providers.dart';
import 'package:$packageName/features/$featureName/domain/entities/${featureName}_entity.dart';

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
  /// [includeCrudUi] adds local (optimistic) list mutators for create/delete —
  /// see [_crudSheets]'s doc for why they don't just `ref.invalidate` instead.
  static String _riverpodListNotifier(
    String featureName,
    String packageName, [
    bool includeCrudUi = false,
    List<FieldSpec> fields = FieldSpec.idName,
  ]) {
    final p = pascal(featureName);
    final idName = idField(fields).dartName;
    final mutators = includeCrudUi
        ? '''

  /// Optimistic insert — used instead of `ref.invalidate` because a refetch
  /// would just replay whatever the remote source *actually* has, which for
  /// a demo/fake backend (e.g. FakeStore) never reflects the write at all.
  void addItem(${p}Entity item) {
    final current = state.value ?? const [];
    state = AsyncData([...current, item]);
  }

  /// Optimistic removal — see [addItem].
  void removeItem(String id) {
    final current = state.value ?? const [];
    state = AsyncData(current.where((e) => e.$idName != id).toList());
  }'''
        : '';
    return '''import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:$packageName/features/$featureName/domain/entities/${featureName}_entity.dart';
import '${featureName}_usecase_providers.dart';

part '${featureName}_provider.g.dart';

@riverpod
class ${p}Notifier extends _\$${p}Notifier {
  @override
  Future<List<${p}Entity>> build() async {
    // The callable shorthand invokes UseCase.call(), which wraps execute() in
    // a Result (converting any thrown error to a Failure) — never call
    // execute() directly, it has no error handling of its own.
    final result = await ref.watch(get${p}UsecaseProvider)();
    return result.getOrThrow();
  }$mutators
}
''';
  }

  // ── presentation/providers/<f>_usecase_providers.dart (usecase-level DI) ──

  /// Wires the Get/Create/Update/Delete usecases as Riverpod providers, each
  /// built from the **abstract** repository provider exposed by
  /// `data/repositories/<feature>_repository_providers.dart` — the only file
  /// under `data/` this ever imports, and only for that abstract-typed
  /// provider. Presentation never references a concrete Data class (ApiSource,
  /// Model, RepositoryImpl) directly — matches the wesioo reference pattern.
  static String featureUsecaseProviders({
    required String featureName,
    required String packageName,
  }) {
    final p = pascal(featureName);
    final c = camel(featureName);
    return '''import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:$packageName/features/$featureName/data/repositories/${featureName}_repository_providers.dart';
import 'package:$packageName/features/$featureName/domain/usecases/get_${featureName}_usecase.dart';
import 'package:$packageName/features/$featureName/domain/usecases/${featureName}_crud_usecases.dart';

part '${featureName}_usecase_providers.g.dart';

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
    Delete${p}Usecase(ref.watch(${c}RepositoryProvider));
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
  /// [includeCrudUi] additionally wires a tap-for-detail sheet (with delete)
  /// and an "add" sheet (create) — off by default; only NEAT's own FakeStore
  /// example feature turns it on today (see field_spec.dart's `fakeStoreProduct`).
  static String _riverpodListPage(
    String featureName,
    String packageName, [
    bool i18n = false,
    List<FieldSpec> fields = FieldSpec.idName,
    bool includeCrudUi = false,
  ]) {
    final p = pascal(featureName);
    final c = camel(featureName);
    final i18nImports = i18n
        ? "import 'package:$packageName/core/i18n/language_switcher.dart';\n"
              "import 'package:$packageName/i18n/strings.g.dart';\n"
        : '';
    final titleWidget = i18n ? 'Text(context.t.$c.title)' : "const Text('$p')";
    final switcherAction = i18n ? 'const LanguageSwitcher(),\n          ' : '';

    // The tile's title is the inferred "display" field; the subtitle shows the id.
    final tf = titleField(fields);
    final titleExpr = tf.nullable ? "item.${tf.dartName} ?? ''" : 'item.${tf.dartName}';
    final idName = idField(fields).dartName;
    // Skeleton placeholder: a dummy entity per field. Not `const` — a DateTime
    // placeholder isn't a const expression.
    final placeholderArgs = fields.map((f) => '${f.dartName}: ${f.entityPlaceholder()}').join(', ');

    // This file lives in presentation/pages/ — the usecase providers live in
    // the sibling presentation/providers/, hence the `../providers/` prefix
    // (unlike ${featureName}_provider.dart's own bare-relative import, which
    // is a same-directory sibling of the usecase providers file).
    final crudImport = includeCrudUi
        ? "import '../providers/${featureName}_usecase_providers.dart';\n"
        : '';
    final addAction = includeCrudUi
        ? '''IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add',
            onPressed: () => showModalBottomSheet<void>(
              constraints: BoxConstraints(minWidth: double.infinity),
              context: context,
              isScrollControlled: true,
              builder: (_) => const _${p}CreateSheet(),
            ),
          ),
          '''
        : '';
    final onTapArg = includeCrudUi
        ? '''
            onTap: (item) => showModalBottomSheet<void>(
              constraints: BoxConstraints(minWidth: double.infinity),
              context: context,
              isScrollControlled: true,
              builder: (_) => _${p}DetailSheet(item: item),
            ),'''
        : '';
    final crudWidgets = includeCrudUi ? _crudSheets(featureName, packageName, fields) : '';

    return '''import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:$packageName/core/error/failure.dart';
import 'package:$packageName/core/theme/theme_mode_controller.dart';
${i18nImports}import 'package:$packageName/features/$featureName/domain/entities/${featureName}_entity.dart';
import 'package:$packageName/features/$featureName/presentation/providers/${featureName}_provider.dart';
$crudImport
class ${p}Page extends ConsumerWidget {
  const ${p}Page({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(${c}Provider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: $titleWidget,
        actions: [
          $addAction${switcherAction}IconButton(
            icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
            onPressed: () => ref.read(themeModeControllerProvider.notifier).toggle(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(${c}Provider),
        child: switch (state) {
          AsyncData(:final value) => _${p}List(items: value,$onTapArg),
          AsyncError(:final error) =>
            _${p}List.error(error is Failure ? error.message : error.toString()),
          _ => Skeletonizer(
              child: _${p}List(
                items: List.generate(
                  8,
                  (_) => ${p}Entity($placeholderArgs),
                ),
              ),
            ),
        },
      ),
    );
  }
}

class _${p}List extends StatelessWidget {
  const _${p}List({required this.items, this.onTap}) : error = null;
  const _${p}List.error(this.error) : items = const [], onTap = null;

  final List<${p}Entity> items;
  final String? error;
  final void Function(${p}Entity item)? onTap;

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
          title: Text($titleExpr),
          subtitle: Text('id: \${item.$idName}'),
          onTap: onTap == null ? null : () => onTap!(item),
        );
      },
    );
  }
}
$crudWidgets''';
  }

  /// The detail (+ delete) and create bottom sheets for [_riverpodListPage]'s
  /// [includeCrudUi] mode. Kept deliberately simple: the create form only
  /// covers scalar, non-id fields (String/int/double/bool) — nested
  /// object/list fields and DateTime fall back to [FieldSpec.entityPlaceholder],
  /// same as the list's Skeletonizer placeholder.
  static String _crudSheets(String featureName, String packageName, List<FieldSpec> fields) {
    final p = pascal(featureName);
    final c = camel(featureName);
    final idName = idField(fields).dartName;
    final detailRows = fields
        .map((f) => "Text('${f.dartName}: \${item.${f.dartName}}'),")
        .join('\n            ');

    final formFields = fields.where((f) => !f.isId && f.isScalar && f.dartType != 'DateTime');
    final ctrlDecls = formFields
        .where((f) => f.dartType != 'bool')
        .map((f) => '  final _${f.dartName}Ctrl = TextEditingController();')
        .join('\n');
    final boolDecls = formFields
        .where((f) => f.dartType == 'bool')
        .map((f) => '  bool _${f.dartName} = false;')
        .join('\n');
    final disposeLines = formFields
        .where((f) => f.dartType != 'bool')
        .map((f) => '    _${f.dartName}Ctrl.dispose();')
        .join('\n');
    final formWidgets = formFields
        .map(
          (f) => f.dartType == 'bool'
              ? '''CheckboxListTile(
            title: const Text('${f.dartName}'),
            value: _${f.dartName},
            onChanged: (v) => setState(() => _${f.dartName} = v ?? false),
          ),'''
              : '''TextField(
            controller: _${f.dartName}Ctrl,
            decoration: const InputDecoration(labelText: '${f.dartName}'),
          ),
          ''',
        )
        .join('\n          ');
    final ctorArgs = fields
        .map((f) {
          if (f.isId || !f.isScalar || f.dartType == 'DateTime') {
            return '${f.dartName}: ${f.entityPlaceholder()}';
          }
          return switch (f.dartType) {
            'int' => '${f.dartName}: int.tryParse(_${f.dartName}Ctrl.text) ?? 0',
            'double' => '${f.dartName}: double.tryParse(_${f.dartName}Ctrl.text) ?? 0.0',
            'bool' => '${f.dartName}: _${f.dartName}',
            _ => '${f.dartName}: _${f.dartName}Ctrl.text',
          };
        })
        .join(', ');

    return '''

class _${p}DetailSheet extends ConsumerWidget {
  const _${p}DetailSheet({required this.item});

  final ${p}Entity item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$p details', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          $detailRows
          const SizedBox(height: 16),
          FilledButton.icon(
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete'),
            onPressed: () async {
              final result = await ref.read(delete${p}UsecaseProvider)(item.$idName);
              result.fold(
                onSuccess: (_) {
                  // A local (optimistic) removal, not `ref.invalidate` — a
                  // refetch would just replay whatever the remote source
                  // *actually* has, which for a demo/fake backend (e.g.
                  // FakeStore) never reflects the delete at all.
                  ref.read(${c}Provider.notifier).removeItem(item.$idName);
                  if (context.mounted) Navigator.of(context).pop();
                },
                onFailure: (failure) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(failure.message)));
                  }
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _${p}CreateSheet extends ConsumerStatefulWidget {
  const _${p}CreateSheet();

  @override
  ConsumerState<_${p}CreateSheet> createState() => _${p}CreateSheetState();
}

class _${p}CreateSheetState extends ConsumerState<_${p}CreateSheet> {
$ctrlDecls
$boolDecls
  bool _saving = false;

  @override
  void dispose() {
$disposeLines
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    final entity = ${p}Entity($ctorArgs);
    final result = await ref.read(create${p}UsecaseProvider)(entity);
    if (!mounted) return;
    result.fold(
      onSuccess: (created) {
        // A local (optimistic) insert, not `ref.invalidate` — a refetch
        // would just replay whatever the remote source *actually* has,
        // which for a demo/fake backend (e.g. FakeStore) never reflects
        // the create at all.
        ref.read(${c}Provider.notifier).addItem(created);
        Navigator.of(context).pop();
      },
      onFailure: (failure) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failure.message)));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        spacing: 8,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add $p', style: Theme.of(context).textTheme.titleMedium),
          $formWidgets
          FilledButton(
            onPressed: _saving ? null : _submit,
            child: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
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
    bool i18n = false,
    List<FieldSpec> fields = FieldSpec.idName,
    bool includeCrudUi = false,
  }) {
    final p = pascal(featureName);

    if (hasRiverpod && useAnnotations && dataList) {
      return _riverpodListPage(featureName, packageName, i18n, fields, includeCrudUi);
    }

    if (hasRiverpod) {
      final c = camel(featureName);
      final i18nImports = i18n
          ? "import 'package:$packageName/core/i18n/language_switcher.dart';\n"
                "import 'package:$packageName/i18n/strings.g.dart';\n"
          : '';
      final titleWidget = i18n ? 'Text(context.t.$c.title)' : "const Text('$p')";
      final switcherAction = i18n ? 'const LanguageSwitcher(),\n          ' : '';
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
${i18nImports}import 'package:$packageName/features/$featureName/presentation/providers/${featureName}_provider.dart';

class ${p}Page extends ConsumerWidget {
  const ${p}Page({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(${c}Provider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: $titleWidget,
        actions: [
          ${switcherAction}IconButton(
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
