import 'package:neat/features/generation/domain/services/templates/dart/_template_utils.dart';

class PresentationTemplates {
  PresentationTemplates._();

  // ── presentation/providers ────────────────────────────────────────────────

  static String featureProvider({
    required String featureName,
    required bool useAnnotations,
    required bool useCubit,
  }) {
    if (useCubit) return _cubitTemplate(featureName);
    if (useAnnotations) return _riverpodAnnotationTemplate(featureName);
    return _riverpodManualTemplate(featureName);
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

  static String featurePage({
    required String featureName,
    required String packageName,
    required bool hasRiverpod,
    required bool useAnnotations,
    required bool hasBloc,
    required bool useCubit,
  }) {
    final p = pascal(featureName);

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
      return '''import 'package:go_router/go_router.dart';
import 'package:$packageName/features/$featureName/presentation/pages/${featureName}_page.dart';

class ${p}Route extends GoRouteData {
  const ${p}Route();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const ${p}Page();
}
''';
    }

    return '''import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:$packageName/features/$featureName/presentation/pages/${featureName}_page.dart';

final ${camel(featureName)}Route = GoRoute(
  path: '/',
  builder: (context, state) => const ${p}Page(),
);
''';
  }
}
