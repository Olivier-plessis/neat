import 'package:flutter_test/flutter_test.dart';
import 'package:neat/features/feature_gen/domain/usecases/generate_feature_usecase.dart';

/// Unit tests for the pure `routes.dart` child-nesting transformation. The
/// integration harness proves the result compiles; these prove the surgery
/// produces the right nested structure cheaply.
void main() {
  // A `routes.dart` exactly as NEAT generates it (plain go_router) with one
  // existing root feature ("dashboard").
  String routesWithParent() => '''import 'package:go_router/go_router.dart';
import 'package:demo/core/constants/app_route_path.dart';
import 'package:demo/features/dashboard/presentation/pages/dashboard_page.dart';
// neat:route-imports

/// App routes. NEAT inserts new features at the anchors below.
final List<RouteBase> appRoutes = [
  GoRoute(
    path: AppRoutePath.dashboard,
    builder: (context, state) => const DashboardPage(),
  ),
  // neat:route-entries
];
''';

  test('nests a child under a flat parent, adding a routes:[] clause', () {
    final out = GenerateFeatureUsecase.wireChildIntoRoutes(
      routesSource: routesWithParent(),
      packageName: 'demo',
      featureName: 'settings',
      parentFeature: 'dashboard',
    );

    // Parent now owns a routes: [...] list with the children anchor.
    expect(out, contains('routes: ['));
    expect(out, contains('// neat:children:dashboard'));
    // Child is a relative-path GoRoute (no leading slash).
    expect(out, contains("path: 'settings',"));
    expect(out, contains('const SettingsPage()'));
    // Child page import was added.
    expect(out, contains('features/settings/presentation/pages/settings_page.dart'));
    // The child sits inside the parent's routes list, before the anchor.
    final childIdx = out.indexOf("path: 'settings',");
    final anchorIdx = out.indexOf('// neat:children:dashboard');
    expect(childIdx, lessThan(anchorIdx));
  });

  test('a second child reuses the existing children anchor (no duplicate routes:[])', () {
    final first = GenerateFeatureUsecase.wireChildIntoRoutes(
      routesSource: routesWithParent(),
      packageName: 'demo',
      featureName: 'settings',
      parentFeature: 'dashboard',
    );
    final second = GenerateFeatureUsecase.wireChildIntoRoutes(
      routesSource: first,
      packageName: 'demo',
      featureName: 'profile',
      parentFeature: 'dashboard',
    );

    // Only one routes: [ clause and one children anchor for the parent.
    expect('routes: ['.allMatches(second).length, 1);
    expect('// neat:children:dashboard'.allMatches(second).length, 1);
    // Both children are present.
    expect(second, contains("path: 'settings',"));
    expect(second, contains("path: 'profile',"));
  });

  test('unknown parent leaves the routes list untouched (safe no-op nesting)', () {
    final out = GenerateFeatureUsecase.wireChildIntoRoutes(
      routesSource: routesWithParent(),
      packageName: 'demo',
      featureName: 'settings',
      parentFeature: 'nonexistent',
    );
    // No children anchor could be created → no nesting happened.
    expect(out, isNot(contains('routes: [')));
    expect(out, isNot(contains("path: 'settings',")));
  });

  // ── go_router_builder (typed routes) ────────────────────────────────────────

  // A parent's `<parent>_routes.dart` exactly as NEAT generates it (builder).
  String typedParentRoutes() => '''import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:demo/core/constants/app_route_path.dart';
import 'package:demo/features/dashboards/presentation/pages/dashboards_page.dart';

part 'dashboards_routes.g.dart';

@TypedGoRoute<DashboardsRoute>(path: AppRoutePath.dashboards)
class DashboardsRoute extends GoRouteData with \$DashboardsRoute {
  const DashboardsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const DashboardsPage();
}
''';

  test('typed: nests a child TypedGoRoute + appends its route class', () {
    final out = GenerateFeatureUsecase.wireChildIntoTypedRoutes(
      parentRoutesSource: typedParentRoutes(),
      packageName: 'demo',
      childFeature: 'settings',
      parentFeature: 'dashboards',
    );

    // Parent annotation gained a routes:[] list with the anchor.
    expect(out, contains('routes: ['));
    expect(out, contains('// neat:typed-children:dashboards'));
    // Child is a relative-path nested TypedGoRoute.
    expect(out, contains("TypedGoRoute<SettingsRoute>(path: 'settings')"));
    // Child route class appended (builder will generate its mixin).
    expect(out, contains(r'class SettingsRoute extends GoRouteData with $SettingsRoute'));
    expect(out, contains('const SettingsPage()'));
    // Child page import added.
    expect(out, contains('features/settings/presentation/pages/settings_page.dart'));
    // The original flat annotation form is gone.
    expect(out, isNot(contains('@TypedGoRoute<DashboardsRoute>(path: AppRoutePath.dashboards)')));
  });

  test('typed: a second child reuses the anchor (one routes:[], two TypedGoRoutes)', () {
    final first = GenerateFeatureUsecase.wireChildIntoTypedRoutes(
      parentRoutesSource: typedParentRoutes(),
      packageName: 'demo',
      childFeature: 'settings',
      parentFeature: 'dashboards',
    );
    final second = GenerateFeatureUsecase.wireChildIntoTypedRoutes(
      parentRoutesSource: first,
      packageName: 'demo',
      childFeature: 'profile',
      parentFeature: 'dashboards',
    );

    expect('routes: ['.allMatches(second).length, 1);
    expect('// neat:typed-children:dashboards'.allMatches(second).length, 1);
    expect(second, contains("TypedGoRoute<SettingsRoute>(path: 'settings')"));
    expect(second, contains("TypedGoRoute<ProfileRoute>(path: 'profile')"));
    expect(second, contains(r'class SettingsRoute extends GoRouteData'));
    expect(second, contains(r'class ProfileRoute extends GoRouteData'));
  });
}
