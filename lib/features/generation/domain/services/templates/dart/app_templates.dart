import 'package:neat/features/dependencies/domain/models/pub_package.dart';

class AppTemplates {
  AppTemplates._();

  // ── main.dart ─────────────────────────────────────────────────────────────

  static String mainDart(
    List<PubPackage> packages, {
    String packageName = '',
    bool useEnvied = false,
  }) {
    final hasRiverpod = packages.any((p) => p.name.contains('riverpod'));

    final imports = StringBuffer();
    final wrapper = StringBuffer();

    imports.writeln("import 'package:flutter/material.dart';");
    if (hasRiverpod) imports.writeln("import 'package:hooks_riverpod/hooks_riverpod.dart';");
    if (useEnvied) {
      imports
        ..writeln("import 'package:$packageName/core/env/app_env.dart';")
        ..writeln("import 'package:$packageName/core/env/envs/dev_env.dart';");
    }
    imports.writeln("import 'app.dart';");

    wrapper.write(hasRiverpod ? 'ProviderScope(child: const App())' : 'const App()');

    // Default to the dev flavor; swap DevEnv() for StagingEnv()/ProdEnv() as needed.
    final setEnv = useEnvied ? '  AppEnv.setEnv(DevEnv());\n' : '';

    return '''${imports.toString()}
void main() {
$setEnv  runApp(${wrapper.toString()});
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
    bool useScreenUtil = false,
  }) {
    final imports = StringBuffer()..writeln("import 'package:flutter/material.dart';");
    if (useScreenUtil) {
      imports.writeln("import 'package:flutter_screenutil/flutter_screenutil.dart';");
    }
    imports.writeln("import 'core/theme/app_theme.dart';");
    if (hasGoRouter) imports.writeln("import 'core/router/app_router.dart';");
    if (hasRiverpod) {
      imports
        ..writeln(useAnnotations
            ? "import 'package:hooks_riverpod/hooks_riverpod.dart';"
            : "import 'package:flutter_riverpod/flutter_riverpod.dart';")
        ..writeln("import 'core/theme/theme_mode_controller.dart';");
    }
    if (hasBloc || useCubit) {
      imports.writeln("import 'package:flutter_bloc/flutter_bloc.dart';");
      imports.writeln(useCubit
          ? "import 'core/theme/brightness_theme/brightness_cubit.dart';"
          : "import 'core/theme/brightness_theme/brightness_bloc.dart';");
    }

    // themeMode argument (depends on state management).
    final themeModeArg = hasRiverpod
        ? 'themeMode: ref.watch(themeModeControllerProvider),'
        : useCubit
            ? 'themeMode: context.watch<BrightnessCubit>().themeMode,'
            : hasBloc
                ? 'themeMode: context.watch<BrightnessBloc>().themeMode,'
                : '';

    // The MaterialApp(.router) widget.
    final String materialApp;
    if (hasGoRouter) {
      final router = useAnnotations ? 'ref.watch(appRouterProvider)' : 'appRouter';
      materialApp = '''MaterialApp.router(
      title: '$name',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      $themeModeArg
      routerConfig: $router,
    )''';
    } else {
      materialApp = '''MaterialApp(
      title: '$name',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      $themeModeArg
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
    )''';
    }

    // Wrap in ScreenUtilInit when responsive sizing is enabled.
    final root = useScreenUtil
        ? '''ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) => $materialApp,
    )'''
        : materialApp;

    // Compose the App widget class.
    final body = StringBuffer();
    if (hasRiverpod) {
      body.write('''class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return $root;
  }
}''');
    } else if (hasBloc || useCubit) {
      final provider = useCubit ? 'BrightnessCubit' : 'BrightnessBloc';
      body.write('''class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => $provider(),
      child: Builder(
        builder: (context) => $root,
      ),
    );
  }
}''');
    } else {
      body.write('''class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return $root;
  }
}''');
    }

    return '${imports.toString()}\n${body.toString()}\n';
  }
}
