import 'package:flutter_test/flutter_test.dart';
import 'package:neat/features/dependencies/domain/models/pub_package.dart';
import 'package:neat/features/generation/domain/services/templates/core_templates.dart';
import 'package:neat/features/generation/domain/services/templates/dart/app_templates.dart';

/// Detects template placeholders that were never substituted. A leftover like
/// `{feature}` or `{app_name}` means a generation bug.
final _unsubstitutedPlaceholder = RegExp(r'\{(feature|app_name|package|name)\}');

void main() {
  // A multi-word, snake_case feature name is the stress case: identifiers must
  // become camelCase (`userProfile`) and types PascalCase (`UserProfile`),
  // never `user_profileProvider` or `features/<app_name>`.
  const feature = 'user_profile';
  const pkgName = 'my_app';

  void expectNoPlaceholders(String code) {
    expect(
      _unsubstitutedPlaceholder.hasMatch(code),
      isFalse,
      reason: 'Unsubstituted placeholder in:\n$code',
    );
  }

  group('CoreTemplates.appRoutePath', () {
    final out = CoreTemplates.appRoutePath(featureName: feature);

    test('declares a camelCase constant, never snake_case', () {
      expect(out, contains('static const String userProfile'));
      expect(out, isNot(contains('user_profile')));
    });

    test('no leftover placeholders', () => expectNoPlaceholders(out));
  });

  group('CoreTemplates.appRouterBuilder (riverpod annotations)', () {
    final out = CoreTemplates.appRouterBuilder(
      packageName: pkgName,
      featureName: feature,
      useAnnotations: true,
    );

    test('imports the route-path constants and uses camelCase entry', () {
      expect(out, contains('app_route_path.dart'));
      expect(out, contains('AppRoutePath.userProfile'));
    });

    test('emits the generated part directive', () {
      expect(out, contains("part 'app_router.g.dart';"));
    });

    test('aggregates routes via routes.dart', () {
      expect(out, contains("import 'routes.dart';"));
      expect(out, contains('routes: appRoutes'));
    });
  });

  group('CoreTemplates.featureRoutes (typed go_router)', () {
    final out = CoreTemplates.featureRoutes(packageName: pkgName, featureName: feature);

    test('uses PascalCase route class + camelCase path', () {
      expect(out, contains('@TypedGoRoute<UserProfileRoute>(path: AppRoutePath.userProfile)'));
      expect(out, contains(r'class UserProfileRoute extends GoRouteData with $UserProfileRoute'));
    });

    test('imports the feature page and emits a part directive', () {
      expect(out, contains('features/user_profile/presentation/pages/user_profile_page.dart'));
      expect(out, contains("part 'user_profile_routes.g.dart';"));
    });
  });

  group('CoreTemplates.routesAggregator', () {
    final out = CoreTemplates.routesAggregator(packageName: pkgName, featureName: feature);

    test('spreads the feature\'s generated \$appRoutes', () {
      expect(out, contains(r'...user_profile.$appRoutes'));
      expect(out, contains('final List<RouteBase> appRoutes'));
    });
  });

  group('CoreTemplates envied env files', () {
    test('appEnv defines the contract + singleton accessor', () {
      final out = CoreTemplates.appEnv();
      expect(out, contains('abstract interface class AppEnvFields'));
      expect(out, contains('static void setEnv(AppEnv env)'));
      expect(out, contains('static AppEnv get current'));
    });

    test('flavorEnv wires @Envied to the matching .env file (PascalCase impl)', () {
      final dev = CoreTemplates.flavorEnv(packageName: pkgName, flavor: 'dev');
      expect(dev, contains("@Envied(path: '.env.dev', obfuscate: true)"));
      expect(dev, contains('abstract class DevEnvVars'));
      expect(dev, contains('class DevEnv implements AppEnv'));
      expect(dev, contains("part 'dev_env.g.dart';"));
    });

    test('envFile carries the app name', () {
      final out = CoreTemplates.envFile(appName: 'My App');
      expect(out, contains('APP_NAME=My App'));
      expect(out, contains('API_BASE_URL='));
    });
  });

  group('AppTemplates.mainDart', () {
    final riverpod = [
      const PubPackage(name: 'hooks_riverpod', version: '3.3.1', description: ''),
    ];

    test('without envied: main calls bootstrap()', () {
      final out = AppTemplates.mainDart(riverpod, packageName: pkgName);
      expect(out, contains('void main() => bootstrap();'));
      expect(out, contains("import 'core/bootstrap.dart';"));
    });

    test('with envied: main calls bootstrap(DevEnv())', () {
      final out = AppTemplates.mainDart(riverpod, packageName: pkgName, useEnvied: true);
      expect(out, contains('void main() => bootstrap(DevEnv());'));
      expect(out, contains('core/env/envs/dev_env.dart'));
    });
  });

  group('AppTemplates.bootstrap', () {
    test('guards the zone and wires the RiverpodObserver (riverpod)', () {
      final out = AppTemplates.bootstrap(
        packageName: pkgName,
        hasRiverpod: true,
        useAnnotations: true,
        useEnvied: false,
        isWeb: false,
      );
      expect(out, contains('Future<void> bootstrap() async'));
      expect(out, contains('runZonedGuarded'));
      expect(out, contains('registerErrorHandler();'));
      expect(out, contains('WidgetsFlutterBinding.ensureInitialized();'));
      expect(out, contains('ProviderScope(observers: [RiverpodObserver()], child: const App())'));
      expect(out, contains("AppLogger.f('Uncaught exception'"));
      expect(out, isNot(contains('usePathUrlStrategy')));
    });

    test('with envied: takes an AppEnv and sets it', () {
      final out = AppTemplates.bootstrap(
        packageName: pkgName,
        hasRiverpod: true,
        useAnnotations: true,
        useEnvied: true,
        isWeb: false,
      );
      expect(out, contains('Future<void> bootstrap(AppEnv env) async'));
      expect(out, contains('AppEnv.setEnv(env);'));
    });

    test('web target adds usePathUrlStrategy', () {
      final out = AppTemplates.bootstrap(
        packageName: pkgName,
        hasRiverpod: true,
        useAnnotations: true,
        useEnvied: false,
        isWeb: true,
      );
      expect(out, contains('usePathUrlStrategy();'));
      expect(out, contains('flutter_web_plugins/url_strategy.dart'));
    });

    test('without riverpod: runs the bare App in the guarded zone', () {
      final out = AppTemplates.bootstrap(
        packageName: pkgName,
        hasRiverpod: false,
        useAnnotations: false,
        useEnvied: false,
        isWeb: false,
      );
      expect(out, contains('runApp(const App())'));
      expect(out, isNot(contains('ProviderScope')));
    });
  });

  group('AppTemplates.appDart responsive wrapping', () {
    test('with screenutil: wraps MaterialApp in ScreenUtilInit', () {
      final out = AppTemplates.appDart(
        name: pkgName,
        hasGoRouter: false,
        hasRiverpod: true,
        useAnnotations: true,
        hasBloc: false,
        useCubit: false,
        useScreenUtil: true,
      );
      expect(out, contains('ScreenUtilInit('));
      expect(out, contains('designSize: const Size(375, 812)'));
      expect(out, contains('flutter_screenutil/flutter_screenutil.dart'));
    });

    test('without screenutil: no ScreenUtilInit, no import', () {
      final out = AppTemplates.appDart(
        name: pkgName,
        hasGoRouter: false,
        hasRiverpod: true,
        useAnnotations: true,
        hasBloc: false,
        useCubit: false,
        // useScreenUtil defaults to false — this is the non-responsive path.
      );
      expect(out, isNot(contains('ScreenUtilInit')));
      expect(out, isNot(contains('flutter_screenutil')));
    });

    test('go_router + provider router watches appRouterProvider', () {
      final out = AppTemplates.appDart(
        name: pkgName,
        hasGoRouter: true,
        hasRiverpod: true,
        useAnnotations: true,
        hasBloc: false,
        useCubit: false,
        routerIsProvider: true,
      );
      expect(out, contains('MaterialApp.router('));
      expect(out, contains('routerConfig: ref.watch(appRouterProvider)'));
    });

    test('go_router without a provider router uses the global appRouter', () {
      // go_router selected but NOT go_router_builder → router is a top-level
      // `appRouter`, never the (non-existent) appRouterProvider.
      final out = AppTemplates.appDart(
        name: pkgName,
        hasGoRouter: true,
        hasRiverpod: true,
        useAnnotations: true,
        hasBloc: false,
        useCubit: false,
        // routerIsProvider defaults to false.
      );
      expect(out, contains('MaterialApp.router('));
      expect(out, contains('routerConfig: appRouter'));
      expect(out, isNot(contains('appRouterProvider')));
    });
  });
}
