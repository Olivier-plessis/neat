import 'package:flutter_test/flutter_test.dart';
import 'package:neat/features/feature_gen/domain/usecases/generate_feature_usecase.dart';
import 'package:neat/features/generation/domain/services/templates/core_templates.dart';

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

  test(
    'packageSplit (§6a Phase 3): child import points at its own package, not '
    'features/<name>/ — the app already depends on every feature package for '
    'their own top-level routes, so no new dependency is needed here',
    () {
      final out = GenerateFeatureUsecase.wireChildIntoRoutes(
        routesSource: routesWithParent(),
        packageName: 'demo',
        featureName: 'settings',
        parentFeature: 'dashboard',
        childPackageName: 'demo_settings',
      );
      expect(out, contains("import 'package:demo_settings/presentation/pages/settings_page.dart';"));
      expect(out, isNot(contains('features/settings/')));
      expect(out, contains("path: 'settings',"));
    },
  );

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

  test(
    'packageSplit (§6a Phase 3): typed child import points at its own '
    'package — this one IS a genuine cross-feature-package import (the '
    'parent package\'s own routes file), so the caller must also add a '
    'path: dependency (see _wireChildRouteBuilder / '
    '_addPathDependencyToPackage, not exercised by this pure transformation)',
    () {
      final out = GenerateFeatureUsecase.wireChildIntoTypedRoutes(
        parentRoutesSource: typedParentRoutes(),
        packageName: 'demo',
        childFeature: 'settings',
        parentFeature: 'dashboards',
        childPackageName: 'demo_settings',
      );
      expect(out, contains("import 'package:demo_settings/presentation/pages/settings_page.dart';"));
      expect(out, isNot(contains('features/settings/')));
      expect(out, contains("TypedGoRoute<SettingsRoute>(path: 'settings')"));
    },
  );

  // ── Nested under a shell branch (real bug found via a real project:
  // parentFeature can be a shell branch, whose route lives inside
  // app_shell_route.dart/routes.dart, not a standalone <parent>_routes.dart —
  // the flat top-level mechanisms above silently no-op (typed) or corrupt
  // the file at the wrong location (plain) for this case) ────────────────────

  // A fresh, 2-branch typed shell (built via the real production templates,
  // not hand-typed, so it's guaranteed to match actual generated shape) —
  // both branches already carry the proactive `// neat:typed-children:<f>`
  // anchor from the moment they're created.
  String newShellSource() {
    final first = CoreTemplates.appShellRouteBuilder(packageName: 'demo', featureName: 'product');
    return GenerateFeatureUsecase.extendTypedShell(
      shellSource: first,
      packageName: 'demo',
      featureName: 'users',
    );
  }

  // The exact legacy shape (no anchor at all) a project generated before
  // this fix has — verified against a real project's app_shell_route.dart.
  String legacyShellSource() => '''import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:demo/core/constants/app_route_path.dart';
import 'package:demo/core/router/scaffold_with_nav_bar.dart';
import 'package:demo/features/product/presentation/pages/product_page.dart';
import 'package:demo/features/users/presentation/pages/users_page.dart';
// neat:shell-imports

part 'app_shell_route.g.dart';

@TypedStatefulShellRoute<AppShellRouteData>(
  branches: [
    TypedStatefulShellBranch<ProductBranchData>(
      routes: [TypedGoRoute<ProductRoute>(path: AppRoutePath.product)],
    ),
    TypedStatefulShellBranch<UsersBranchData>(
      routes: [TypedGoRoute<UsersRoute>(path: AppRoutePath.users)],
    ),
    // neat:shell-branches
  ],
)
class AppShellRouteData extends StatefulShellRouteData {
  const AppShellRouteData();

  @override
  Widget builder(
    BuildContext context,
    GoRouterState state,
    StatefulNavigationShell navigationShell,
  ) =>
      ScaffoldWithNavBar(navigationShell: navigationShell);
}

class ProductBranchData extends StatefulShellBranchData {
  const ProductBranchData();
}

class ProductRoute extends GoRouteData with \$ProductRoute {
  const ProductRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const ProductPage();
}

class UsersBranchData extends StatefulShellBranchData {
  const UsersBranchData();
}

class UsersRoute extends GoRouteData with \$UsersRoute {
  const UsersRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const UsersPage();
}
// neat:shell-classes
''';

  test('typed: nests a child under a shell branch (proactive anchor)', () {
    final out = GenerateFeatureUsecase.wireChildIntoTypedShell(
      shellSource: newShellSource(),
      packageName: 'demo',
      parentFeature: 'product',
      childFeature: 'reviews',
    );
    expect(out, contains("TypedGoRoute<ReviewsRoute>(path: 'reviews')"));
    expect(out, contains(r'class ReviewsRoute extends GoRouteData with $ReviewsRoute'));
    expect(out, contains('const ReviewsPage()'));
    expect(out, contains('features/reviews/presentation/pages/reviews_page.dart'));
    // Nested at product's own anchor — before it, not users'.
    final anchorIdx = out.indexOf('// neat:typed-children:product');
    final childIdx = out.indexOf("TypedGoRoute<ReviewsRoute>(path: 'reviews')");
    expect(childIdx, lessThan(anchorIdx));
    // users' branch is untouched (it has its own anchor too, proactively —
    // that's unrelated to this child, not a sign it was touched).
    expect(out, contains('TypedGoRoute<UsersRoute>('));
    expect('// neat:typed-children:'.allMatches(out).length, 2);
  });

  test(
    'typed: self-heals a legacy flat shell branch (no anchor) before nesting a '
    'child — the other, unrelated branch stays untouched (narrow fix, no forced '
    'full-shell retrofit)',
    () {
      final out = GenerateFeatureUsecase.wireChildIntoTypedShell(
        shellSource: legacyShellSource(),
        packageName: 'demo',
        parentFeature: 'product',
        childFeature: 'reviews',
      );
      // Retrofit: product's flat route became anchored.
      expect(out, contains('// neat:typed-children:product'));
      expect(out, contains("TypedGoRoute<ReviewsRoute>(path: 'reviews')"));
      expect(out, contains(r'class ReviewsRoute extends GoRouteData with $ReviewsRoute'));
      // users (the other branch) stays exactly flat.
      expect(out, contains('TypedGoRoute<UsersRoute>(path: AppRoutePath.users)'));
      expect(out, isNot(contains('// neat:typed-children:users')));
    },
  );

  test('typed: packageSplit child under a shell branch uses the registry, not a direct import', () {
    final out = GenerateFeatureUsecase.wireChildIntoTypedShell(
      shellSource: newShellSource(),
      packageName: 'demo',
      parentFeature: 'product',
      childFeature: 'reviews',
      childPackageName: 'reviews',
      corePackageName: 'core',
    );
    expect(out, contains("lookupShellPage('reviews')(context, state)"));
    expect(out, isNot(contains('reviews/presentation/pages/reviews_page.dart')));
    expect(out, contains("import 'package:core/core/router/shell_page_registry.dart';"));
  });

  // A fresh, 2-branch plain go_router shell (built via the real production
  // templates), mirroring _wireShellBranchPlain's own insertion for the
  // second branch.
  String newPlainRoutesSource() {
    var s = CoreTemplates.routesManualShell(packageName: 'demo', featureName: 'product');
    s = s.replaceFirst(
      '// neat:route-imports',
      "import 'package:demo/features/users/presentation/pages/users_page.dart';\n"
          '// neat:route-imports',
    );
    s = s.replaceFirst(
      '// neat:shell-branches',
      '${CoreTemplates.shellBranchPlain(featureName: 'users')}\n      // neat:shell-branches',
    );
    return s;
  }

  // The exact legacy shape (no anchor, no nested routes:[] at all) a project
  // generated before this fix has. This is also the corruption-regression
  // fixture: with the OLD `_addChildrenAnchorToParent`'s `\n  ),` proximity
  // match, searching from `AppRoutePath.product,` would skip straight past
  // this GoRoute's own (deeply-nested) close and land on the outer
  // `StatefulShellRoute.indexedStack(...)`'s 2-space-indented close instead
  // — after BOTH branches. The balanced-paren scan must land inside
  // product's own branch, before users'.
  String legacyPlainRoutesSource() => '''import 'package:go_router/go_router.dart';
import 'package:demo/core/constants/app_route_path.dart';
import 'package:demo/core/router/scaffold_with_nav_bar.dart';
import 'package:demo/features/product/presentation/pages/product_page.dart';
import 'package:demo/features/users/presentation/pages/users_page.dart';
// neat:route-imports

final List<RouteBase> appRoutes = [
  StatefulShellRoute.indexedStack(
    builder: (context, state, navigationShell) =>
        ScaffoldWithNavBar(navigationShell: navigationShell),
    branches: [
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: AppRoutePath.product,
            builder: (context, state) => const ProductPage(),
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: AppRoutePath.users,
            builder: (context, state) => const UsersPage(),
          ),
        ],
      ),
      // neat:shell-branches
    ],
  ),
  // neat:route-entries
];
''';

  test('plain: nests a child under a shell branch (proactive anchor)', () {
    final out = GenerateFeatureUsecase.wireChildIntoPlainShell(
      routesSource: newPlainRoutesSource(),
      packageName: 'demo',
      parentFeature: 'product',
      childFeature: 'reviews',
    );
    expect(out, contains("path: 'reviews',"));
    expect(out, contains('const ReviewsPage()'));
    expect(out, contains('features/reviews/presentation/pages/reviews_page.dart'));
    final anchorIdx = out.indexOf('// neat:children:product');
    final childIdx = out.indexOf("path: 'reviews',");
    expect(childIdx, lessThan(anchorIdx));
    // users' branch is untouched (it has its own anchor too, proactively —
    // that's unrelated to this child, not a sign it was touched).
    expect('// neat:children:'.allMatches(out).length, 2);
  });

  test(
    'plain: self-heals a legacy shell branch, nesting the child inside the right '
    "branch — regression: the old proximity match would've corrupted the file "
    "by landing on the shell's outer closing paren instead",
    () {
      final out = GenerateFeatureUsecase.wireChildIntoPlainShell(
        routesSource: legacyPlainRoutesSource(),
        packageName: 'demo',
        parentFeature: 'product',
        childFeature: 'reviews',
      );
      expect(out, contains('// neat:children:product'));
      expect(out, contains("path: 'reviews',"));
      // The child sits inside product's own branch — after product's own
      // path, before users' branch entirely.
      final productIdx = out.indexOf('path: AppRoutePath.product,');
      final childIdx = out.indexOf("path: 'reviews',");
      final usersIdx = out.indexOf('path: AppRoutePath.users,');
      expect(productIdx, lessThan(childIdx));
      expect(childIdx, lessThan(usersIdx));
      // users' own branch stays untouched — no forced retrofit.
      expect(out, isNot(contains('// neat:children:users')));
    },
  );

  test('plain: packageSplit child under a shell branch uses the registry, not a direct import', () {
    final out = GenerateFeatureUsecase.wireChildIntoPlainShell(
      routesSource: newPlainRoutesSource(),
      packageName: 'demo',
      parentFeature: 'product',
      childFeature: 'reviews',
      childPackageName: 'reviews',
      corePackageName: 'core',
    );
    expect(out, contains("lookupShellPage('reviews')(context, state)"));
    expect(out, isNot(contains('reviews/presentation/pages/reviews_page.dart')));
    expect(out, contains("import 'package:core/core/router/shell_page_registry.dart';"));
  });
}
