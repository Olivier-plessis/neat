import 'package:neat/features/dependencies/domain/models/pub_package.dart';

class AppTemplates {
  AppTemplates._();

  // ── main.dart ─────────────────────────────────────────────────────────────

  static String mainDart(
    List<PubPackage> packages, {
    String packageName = '',
    bool useEnvied = false,
    String flavor = 'dev',
  }) {
    final imports = StringBuffer()..writeln("import 'core/bootstrap.dart';");
    if (useEnvied) imports.writeln("import 'core/env/envs/${flavor}_env.dart';");

    // The envied [flavor]Env carries the flavor's baked config. main_<flavor>.dart
    // entry points (one per flavor) pair with the native `--flavor` build.
    final envClass = '${flavor[0].toUpperCase()}${flavor.substring(1)}Env';
    final call = useEnvied ? 'bootstrap($envClass())' : 'bootstrap()';

    return '''${imports.toString()}
void main() => $call;
''';
  }

  // ── core/bootstrap.dart ─────────────────────────────────────────────────────

  /// Centralised start-up: bindings + error handling + provider scope, all
  /// inside a guarded zone that funnels uncaught errors to AppLogger.
  static String bootstrap({
    required String packageName,
    required bool hasRiverpod,
    required bool useAnnotations,
    required bool useEnvied,
    required bool isWeb,
    bool hasSupabase = false,
    bool hasFirebase = false,
    bool hasI18n = false,
  }) {
    final imports = StringBuffer()
      ..writeln("import 'dart:async';")
      ..writeln()
      ..writeln("import 'package:flutter/widgets.dart';");
    if (isWeb) {
      imports.writeln("import 'package:flutter_web_plugins/url_strategy.dart';");
    }
    if (hasSupabase) {
      imports.writeln("import 'package:supabase_flutter/supabase_flutter.dart';");
    }
    if (hasFirebase) {
      imports
        ..writeln("import 'package:cloud_firestore/cloud_firestore.dart';")
        ..writeln("import 'package:firebase_core/firebase_core.dart';");
    }
    if (hasRiverpod) {
      imports.writeln(useAnnotations
          ? "import 'package:hooks_riverpod/hooks_riverpod.dart';"
          : "import 'package:flutter_riverpod/flutter_riverpod.dart';");
    }
    imports.writeln("import 'package:$packageName/app.dart';");
    if (hasFirebase) {
      imports.writeln("import 'package:$packageName/firebase_options.dart';");
    }
    if (hasI18n) {
      imports
        ..writeln("import 'package:$packageName/core/i18n/locale_store.dart';")
        ..writeln("import 'package:$packageName/i18n/strings.g.dart';");
    }
    if (useEnvied) {
      imports.writeln("import 'package:$packageName/core/env/app_env.dart';");
    }
    imports.writeln("import 'package:$packageName/core/error/error_handler.dart';");
    imports.writeln("import 'package:$packageName/core/utils/app_logger.dart';");
    if (hasRiverpod) {
      imports.writeln("import 'package:$packageName/core/observers/provider_observer.dart';");
    }

    final sig =
        useEnvied ? 'Future<void> bootstrap(AppEnv env) async' : 'Future<void> bootstrap() async';
    final setEnv = useEnvied ? '  AppEnv.setEnv(env);\n' : '';
    final pathUrl = isWeb ? '\n      usePathUrlStrategy();' : '';
    final supaInit = hasSupabase
        ? (useEnvied
            ? '\n      await Supabase.initialize(\n'
                '        url: AppEnv.current.supabaseUrl,\n'
                '        publishableKey: AppEnv.current.supabasePublishableKey,\n'
                '      );'
            : "\n      await Supabase.initialize(url: '', publishableKey: ''); // TODO: set URL + publishable key")
        : '';
    final firebaseInit = hasFirebase
        ? '\n      await Firebase.initializeApp(\n'
            '        options: DefaultFirebaseOptions.currentPlatform,\n'
            '      );\n'
            '      // Firestore ships its own offline cache (no extra Drift layer needed).\n'
            '      FirebaseFirestore.instance.settings =\n'
            '          const Settings(persistenceEnabled: true);'
        : '';
    // Apply the persisted locale (falls back to the device locale) before runApp.
    final i18nInit = hasI18n ? '\n      await LocaleStore.init();' : '';
    final baseRoot = hasRiverpod
        ? 'ProviderScope(observers: [RiverpodObserver()], child: const App())'
        : 'const App()';
    // slang's TranslationProvider must sit above MaterialApp so context.t works.
    final root = hasI18n ? 'TranslationProvider(child: $baseRoot)' : baseRoot;

    final docComment = hasRiverpod
        ? '''/// Swap [ProviderScope] for an UncontrolledProviderScope if you need
/// bootstrap-time overrides (e.g. injecting config computed here).
'''
        : '';

    return '''${imports.toString()}
$docComment$sig {
$setEnv  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      registerErrorHandler();$pathUrl$i18nInit$firebaseInit$supaInit
      runApp($root);
    },
    (error, stack) => AppLogger.f('Uncaught exception', error: error, stackTrace: stack),
  );
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
    bool routerIsProvider = false,
    String? themePackage,
    bool hasI18n = false,
  }) {
    final imports = StringBuffer()..writeln("import 'package:flutter/material.dart';");
    if (hasI18n) {
      imports
        ..writeln("import 'package:flutter_localizations/flutter_localizations.dart';")
        ..writeln("import 'i18n/strings.g.dart';");
    }
    if (useScreenUtil) {
      imports.writeln("import 'package:flutter_screenutil/flutter_screenutil.dart';");
    }
    // AppTheme lives in the <app>_ui package when UI is extracted, else in the app.
    imports.writeln(themePackage != null
        ? "import 'package:$themePackage/$themePackage.dart';"
        : "import 'core/theme/app_theme.dart';");
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

    // slang locale wiring: drive MaterialApp from TranslationProvider so a
    // LocaleSettings.setLocale rebuild flows to the whole app.
    final localeArgs = hasI18n
        ? '''
      locale: TranslationProvider.of(context).flutterLocale,
      supportedLocales: AppLocaleUtils.supportedLocales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,'''
        : '';

    // The MaterialApp(.router) widget.
    final String materialApp;
    if (hasGoRouter) {
      // The router is only a Riverpod provider when go_router_builder + riverpod
      // annotations are both on; otherwise it's a top-level `appRouter` global.
      final router = routerIsProvider ? 'ref.watch(appRouterProvider)' : 'appRouter';
      materialApp = '''MaterialApp.router(
      title: '$name',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      $themeModeArg$localeArgs
      routerConfig: $router,
    )''';
    } else {
      materialApp = '''MaterialApp(
      title: '$name',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      $themeModeArg$localeArgs
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
