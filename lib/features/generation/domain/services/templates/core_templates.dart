class CoreTemplates {
  CoreTemplates._();

  // ── core/constants/app_route_path.dart ────────────────────────────────────

  static String appRoutePath({required String featureName}) {
    final c = _camel(featureName);
    return '''class AppRoutePath {
  AppRoutePath._();

  /// First feature — app entry point.
  static const String $c = '/';
}
''';
  }

  // ── core/env/app_env.dart (envied — flavor contract + singleton) ─────────

  static String appEnv() => r'''/// The environment contract shared by every flavor.
abstract interface class AppEnvFields {
  abstract final String appName;
  abstract final String apiBaseUrl;
}

/// Global access to the active environment.
/// Call [AppEnv.setEnv] in main() before runApp().
abstract interface class AppEnv implements AppEnvFields {
  static AppEnv? _instance;

  static AppEnv get current =>
      _instance ?? (throw StateError('AppEnv not set — call AppEnv.setEnv() in main().'));

  static void setEnv(AppEnv env) => _instance = env;
}
''';

  // ── core/env/envs/<flavor>_env.dart (envied generated vars + AppEnv impl) ──

  /// [flavor] is one of: dev, staging, prod.
  static String flavorEnv({required String packageName, required String flavor}) {
    final p = _pascal(flavor); // Dev / Staging / Prod
    return '''import 'package:envied/envied.dart';
import 'package:$packageName/core/env/app_env.dart';

part '${flavor}_env.g.dart';

@Envied(path: '.env.$flavor', obfuscate: true)
abstract class ${p}EnvVars {
  @EnviedField(varName: 'APP_NAME')
  static final String appName = _${p}EnvVars.appName;

  @EnviedField(varName: 'API_BASE_URL')
  static final String apiBaseUrl = _${p}EnvVars.apiBaseUrl;
}

class ${p}Env implements AppEnv {
  @override
  final String appName = ${p}EnvVars.appName;

  @override
  final String apiBaseUrl = ${p}EnvVars.apiBaseUrl;
}
''';
  }

  /// Contents of a `.env.<flavor>` (or `.env.example`) file.
  static String envFile({required String appName}) => '''APP_NAME=$appName
API_BASE_URL=
''';

  // ── core/error/failure.dart ───────────────────────────────────────────────

  static String failure() => r'''sealed class Failure {
  const Failure(this.message);
  final String message;
}

final class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Network error. Please check your connection.']);
}

final class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Server error. Please try again later.']);
  final int? statusCode = null;
}

final class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Cache error. Please try again.']);
}

final class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'An unexpected error occurred.']);
}
''';

  // ── core/utils/extensions.dart ────────────────────────────────────────────

  static String extensions() => r'''extension StringX on String {
  bool get isNullOrEmpty => isEmpty;

  String get capitalize =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';

  String? get nullIfEmpty => isEmpty ? null : this;
}

extension IterableX<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;

  T? firstWhereOrNull(bool Function(T) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
''';

  // ── core/router/app_router.dart (basic GoRouter, no builder) ─────────────

  static String appRouter({required String packageName, required String featureName}) =>
      '''import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:$packageName/core/constants/app_route_path.dart';
import 'package:$packageName/features/$featureName/presentation/pages/${featureName}_page.dart';

final appRouter = GoRouter(
  initialLocation: AppRoutePath.${_camel(featureName)},
  debugLogDiagnostics: true,
  routes: [
    GoRoute(
      path: AppRoutePath.${_camel(featureName)},
      builder: (context, state) => const ${_pascal(featureName)}Page(),
    ),
  ],
);
''';

  // ── core/router/app_router.dart (go_router_builder + riverpod) ───────────

  static String appRouterBuilder({
    required String packageName,
    required String featureName,
    required bool useAnnotations,
  }) {
    final c = _camel(featureName);
    if (useAnnotations) {
      return '''import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:$packageName/core/constants/app_route_path.dart';
import 'routes.dart';

part 'app_router.g.dart';

@Riverpod(keepAlive: true)
RouterConfig<Object> appRouter(Ref ref) => GoRouter(
  initialLocation: AppRoutePath.$c,
  debugLogDiagnostics: true,
  routes: appRoutes,
);
''';
    }
    return '''import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:$packageName/core/constants/app_route_path.dart';
import 'routes.dart';

final appRouter = GoRouter(
  initialLocation: AppRoutePath.$c,
  debugLogDiagnostics: true,
  routes: appRoutes,
);
''';
  }

  // ── core/router/routes.dart (aggregator of per-feature routes) ───────────

  /// Aggregates each feature's generated `\$appRoutes`. New features add an
  /// aliased import + spread here.
  static String routesAggregator({required String packageName, required String featureName}) =>
      '''import 'package:go_router/go_router.dart';
import 'package:$packageName/features/$featureName/presentation/routes/${featureName}_routes.dart'
    as $featureName;

/// Aggregated app routes.
///
/// To add a feature: create its `<feature>_routes.dart` under the feature's
/// presentation/routes/ folder, then import it here with an alias and spread
/// its generated `\$appRoutes`.
final List<RouteBase> appRoutes = [
  ...$featureName.\$appRoutes,
];
''';

  // ── features/<f>/presentation/routes/<f>_routes.dart (typed routes) ──────

  static String featureRoutes({required String packageName, required String featureName}) =>
      '''import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:$packageName/core/constants/app_route_path.dart';
import 'package:$packageName/features/$featureName/presentation/pages/${featureName}_page.dart';

part '${featureName}_routes.g.dart';

@TypedGoRoute<${_pascal(featureName)}Route>(path: AppRoutePath.${_camel(featureName)})
class ${_pascal(featureName)}Route extends GoRouteData with \$${_pascal(featureName)}Route {
  const ${_pascal(featureName)}Route();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const ${_pascal(featureName)}Page();
}
''';

  // ── core/router/routes.dart (manual) ─────────────────────────────────────

  static String routesManual({required String packageName, required String featureName}) =>
      '''import 'package:go_router/go_router.dart';
import 'package:$packageName/features/$featureName/presentation/pages/${featureName}_page.dart';

final appRoutes = [
  GoRoute(
    path: '/',
    builder: (context, state) => const ${_pascal(featureName)}Page(),
  ),
];
''';

  static String _pascal(String s) => s.isEmpty
      ? s
      : s.split('_').map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1)).join();

  static String _camel(String s) {
    final p = _pascal(s);
    return p.isEmpty ? p : p[0].toLowerCase() + p.substring(1);
  }
}
