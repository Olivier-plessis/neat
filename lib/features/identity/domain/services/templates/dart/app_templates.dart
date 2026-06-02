import 'package:neat/features/dependencies/domain/models/pub_package.dart';

class AppTemplates {
  AppTemplates._();

  // ── main.dart ─────────────────────────────────────────────────────────────

  static String mainDart(List<PubPackage> packages) {
    final hasRiverpod = packages.any((p) => p.name.contains('riverpod'));

    final imports = StringBuffer();
    final wrapper = StringBuffer();

    imports.writeln("import 'package:flutter/material.dart';");
    if (hasRiverpod) imports.writeln("import 'package:hooks_riverpod/hooks_riverpod.dart';");
    imports.writeln("import 'app.dart';");

    wrapper.write(hasRiverpod ? 'ProviderScope(child: const App())' : 'const App()');

    return '''${imports.toString()}
void main() {
  runApp(${wrapper.toString()});
}
''';
  }

  // ── app.dart ──────────────────────────────────────────────────────────────

  static String appDart({
    required String name,
    required bool hasGoRouter,
    required bool hasRiverpod,
    required bool useAnnotations,
    required bool hasBloc,
    required bool useCubit,
  }) {
    final imports = StringBuffer();
    imports.writeln("import 'package:flutter/material.dart';");
    imports.writeln("import 'core/theme/app_theme.dart';");

    if (hasGoRouter) imports.writeln("import 'core/router/app_router.dart';");

    if (hasRiverpod && !useAnnotations) {
      imports.writeln("import 'package:flutter_riverpod/flutter_riverpod.dart';");
      imports.writeln("import 'core/theme/theme_mode_controller.dart';");
    } else if (hasRiverpod && useAnnotations) {
      imports.writeln("import 'package:hooks_riverpod/hooks_riverpod.dart';");
      imports.writeln("import 'core/theme/theme_mode_controller.dart';");
    }

    if (hasBloc || useCubit) {
      imports.writeln("import 'package:flutter_bloc/flutter_bloc.dart';");
      if (useCubit) {
        imports.writeln("import 'core/theme/brightness_theme/brightness_cubit.dart';");
      } else {
        imports.writeln("import 'core/theme/brightness_theme/brightness_bloc.dart';");
      }
    }

    final body = StringBuffer();

    if (hasGoRouter) {
      if (useAnnotations) {
        body.write('''class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeControllerProvider);
    return MaterialApp.router(
      title: '$name',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}''');
      } else if (hasRiverpod) {
        body.write('''class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeControllerProvider);
    return MaterialApp.router(
      title: '$name',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}''');
      } else if (useCubit) {
        body.write('''class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BrightnessCubit(),
      child: BlocBuilder<BrightnessCubit, BrightnessState>(
        builder: (context, state) => MaterialApp.router(
          title: '$name',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: context.read<BrightnessCubit>().themeMode,
          routerConfig: appRouter,
        ),
      ),
    );
  }
}''');
      } else if (hasBloc) {
        body.write('''class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BrightnessBloc(),
      child: BlocBuilder<BrightnessBloc, BrightnessState>(
        builder: (context, state) => MaterialApp.router(
          title: '$name',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: context.read<BrightnessBloc>().themeMode,
          routerConfig: appRouter,
        ),
      ),
    );
  }
}''');
      } else {
        body.write('''class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '$name',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: appRouter,
    );
  }
}''');
      }
    } else {
      body.write('''class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '$name',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('$name'),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: () {}, child: const Text('$name')),
                const SizedBox(height: 8),
                TextButton(onPressed: () {}, child: const Text('$name')),
                const SizedBox(height: 8),
                FilledButton(onPressed: () {}, child: const Text('$name')),
                const SizedBox(height: 8),
                OutlinedButton(onPressed: () {}, child: const Text('$name')),
                const SizedBox(height: 8),
                const TextField(decoration: InputDecoration(hintText: '$name')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}''');
    }

    return '${imports.toString()}\n${body.toString()}\n';
  }
}
