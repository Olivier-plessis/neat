class CoreTemplates {
  CoreTemplates._();

  // ── core/constants/app_route_path.dart ────────────────────────────────────

  static String appRoutePath() => r'''class AppRoutePath {
  AppRoutePath._();

  static const String home = '/';
  static const String splash = '/splash';
}
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
  initialLocation: AppRoutePath.home,
  debugLogDiagnostics: true,
  routes: [
    GoRoute(
      path: AppRoutePath.home,
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
    if (useAnnotations) {
      return '''import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'routes.dart';

part 'app_router.g.dart';

@Riverpod(keepAlive: true)
RouterConfig<Object> appRouter(Ref ref) => GoRouter(
  initialLocation: '/',
  debugLogDiagnostics: true,
  routes: \$appRoutes,
);
''';
    }
    return '''import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'routes.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  debugLogDiagnostics: true,
  routes: \$appRoutes,
);
''';
  }

  // ── core/router/routes.dart (go_router_builder TypedGoRoute) ─────────────

  static String routesBuilder({required String packageName, required String featureName}) =>
      '''import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:$packageName/features/$featureName/presentation/pages/${featureName}_page.dart';

part 'routes.g.dart';

@TypedGoRoute<${_pascal(featureName)}Route>(path: '/')
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
}
