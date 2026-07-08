import 'package:flutter_test/flutter_test.dart';
import 'package:neat/features/feature_gen/domain/usecases/generate_feature_usecase.dart';
import 'package:neat/features/generation/domain/services/templates/core_package_templates.dart';
import 'package:neat/features/generation/domain/services/templates/core_templates.dart';

/// Unit tests for the Shell Branch templates + the typed-shell extend transform.
/// The integration harness proves the generated shell compiles; these prove the
/// create/extend surgery produces the right structure cheaply.
void main() {
  group('scaffold', () {
    test('scaffoldWithNavBar emits a NavigationBar + first destination + anchor', () {
      final out = CoreTemplates.scaffoldWithNavBar(firstIcon: 'home', firstLabel: 'Home');
      expect(out, contains('class ScaffoldWithNavBar extends StatelessWidget'));
      expect(out, contains('StatefulNavigationShell navigationShell'));
      expect(out, contains('NavigationBar('));
      expect(out, contains("NavigationDestination(icon: Icon(Icons.home), label: 'Home')"));
      expect(out, contains('// neat:shell-destinations'));
      expect(out, contains('navigationShell.goBranch('));
      // A NavigationBar needs >= 2 destinations — guard so a single-branch shell
      // doesn't crash at startup (Flutter asserts destinations.length >= 2).
      expect(out, contains('destinations.length >= 2'));
    });

    test('shellDestination renders a single destination line', () {
      final line = CoreTemplates.shellDestination(icon: 'list', label: 'Orders');
      expect(line, contains("NavigationDestination(icon: Icon(Icons.list), label: 'Orders')"));
    });
  });

  group('plain go_router shell', () {
    test('shellRouteEntryPlain wraps the first branch in a StatefulShellRoute', () {
      final out = CoreTemplates.shellRouteEntryPlain(featureName: 'dashboard');
      expect(out, contains('StatefulShellRoute.indexedStack('));
      expect(out, contains('ScaffoldWithNavBar(navigationShell: navigationShell)'));
      expect(out, contains('StatefulShellBranch('));
      expect(out, contains('path: AppRoutePath.dashboard'));
      expect(out, contains('const DashboardPage()'));
      expect(out, contains('// neat:shell-branches'));
      // Proactive children anchor (§7 sub-routes): always present, split or
      // not, so the Workshop can later nest a sub-route under this branch.
      expect(out, contains('// neat:children:dashboard'));
    });

    test('shellBranchPlain renders a standalone branch block', () {
      final out = CoreTemplates.shellBranchPlain(featureName: 'orders');
      expect(out, contains('StatefulShellBranch('));
      expect(out, contains('path: AppRoutePath.orders'));
      expect(out, contains('const OrdersPage()'));
      expect(out, contains('// neat:children:orders'));
      expect(out, isNot(contains('StatefulShellRoute'))); // not the wrapper
    });

    test('shellRouteEntryPlain/shellBranchPlain use the registry when packageSplit', () {
      final entry = CoreTemplates.shellRouteEntryPlain(
        featureName: 'dashboard',
        featurePackageName: 'dashboard',
        corePackageName: 'core',
      );
      expect(entry, contains("builder: (context, state) => lookupShellPage('dashboard')(context, state)"));
      expect(entry, isNot(contains('const DashboardPage()')));

      final branch = CoreTemplates.shellBranchPlain(
        featureName: 'orders',
        featurePackageName: 'orders',
        corePackageName: 'core',
      );
      expect(branch, contains("builder: (context, state) => lookupShellPage('orders')(context, state)"));
      expect(branch, isNot(contains('const OrdersPage()')));
    });
  });

  group('go_router_builder typed shell', () {
    String firstShell() => CoreTemplates.appShellRouteBuilder(
          packageName: 'demo',
          featureName: 'dashboard',
        );

    test('appShellRouteBuilder creates a typed shell with the first branch', () {
      final out = firstShell();
      expect(out, contains('@TypedStatefulShellRoute<AppShellRouteData>('));
      expect(out, contains('TypedStatefulShellBranch<DashboardBranchData>('));
      expect(out, contains('TypedGoRoute<DashboardRoute>('));
      expect(out, contains('path: AppRoutePath.dashboard'));
      expect(out, contains('class AppShellRouteData extends StatefulShellRouteData'));
      expect(out, contains('class DashboardBranchData extends StatefulShellBranchData'));
      expect(out, contains(r'class DashboardRoute extends GoRouteData with $DashboardRoute'));
      expect(out, contains('ScaffoldWithNavBar(navigationShell: navigationShell)'));
      expect(out, contains('// neat:shell-branches'));
      expect(out, contains('// neat:shell-classes'));
      expect(out, contains('// neat:shell-imports'));
      // Proactive children anchor (§7 sub-routes): always present, split or
      // not, so the Workshop can later nest a sub-route under this branch.
      expect(out, contains('// neat:typed-children:dashboard'));
      // Non-split: direct import/construction, never the registry.
      expect(out, contains('const DashboardPage()'));
      expect(out, isNot(contains('shell_page_registry.dart')));
    });

    test('appShellRouteBuilder uses the registry when featurePackageName is set (packageSplit)', () {
      final out = CoreTemplates.appShellRouteBuilder(
        packageName: 'demo',
        featureName: 'dashboard',
        featurePackageName: 'dashboard',
        corePackageName: 'core',
      );
      expect(out, contains("import 'package:core/core/router/shell_page_registry.dart';"));
      expect(out, contains("lookupShellPage('dashboard')(context, state)"));
      expect(out, isNot(contains('features/dashboard/presentation/pages')));
      expect(out, isNot(contains('const DashboardPage()')));
    });

    test('shellBranchClassesBuilder uses the registry when packageSplit', () {
      final out = CoreTemplates.shellBranchClassesBuilder(
        featureName: 'orders',
        featurePackageName: 'orders',
        corePackageName: 'core',
      );
      expect(out, contains("lookupShellPage('orders')(context, state)"));
      expect(out, isNot(contains('const OrdersPage()')));
    });

    test('shellBranchClassesBuilder stays direct-import when not packageSplit', () {
      final out = CoreTemplates.shellBranchClassesBuilder(featureName: 'orders');
      expect(out, contains('const OrdersPage()'));
      expect(out, isNot(contains('lookupShellPage')));
    });

    test('extendTypedShell adds a second branch + classes, reusing the anchors', () {
      final extended = GenerateFeatureUsecase.extendTypedShell(
        shellSource: firstShell(),
        packageName: 'demo',
        featureName: 'orders',
      );

      // Both branches + both route classes present.
      expect(extended, contains('TypedStatefulShellBranch<DashboardBranchData>('));
      expect(extended, contains('TypedStatefulShellBranch<OrdersBranchData>('));
      expect(extended, contains(r'class DashboardRoute extends GoRouteData'));
      expect(extended, contains(r'class OrdersRoute extends GoRouteData with $OrdersRoute'));
      expect(extended, contains('const OrdersPage()'));
      // Page import added once.
      expect(extended, contains('features/orders/presentation/pages/orders_page.dart'));
      // Second branch also carries its own proactive children anchor.
      expect(extended, contains('// neat:typed-children:orders'));
      // Anchors are reused, not duplicated.
      expect('// neat:shell-branches'.allMatches(extended).length, 1);
      expect('// neat:shell-classes'.allMatches(extended).length, 1);
      expect('@TypedStatefulShellRoute'.allMatches(extended).length, 1);
    });

    test('extendTypedShell imports the registry (not the page) when packageSplit', () {
      final split = firstShell();
      final extended = GenerateFeatureUsecase.extendTypedShell(
        shellSource: CoreTemplates.appShellRouteBuilder(
          packageName: 'demo',
          featureName: 'dashboard',
          featurePackageName: 'dashboard',
          corePackageName: 'core',
        ),
        packageName: 'demo',
        featureName: 'orders',
        featurePackageName: 'orders',
        corePackageName: 'core',
      );
      expect(split, isNotEmpty); // sanity: non-split fixture still builds
      expect(extended, contains("lookupShellPage('orders')(context, state)"));
      expect(extended, isNot(contains('orders/presentation/pages/orders_page.dart')));
      // Registry import inserted once, not duplicated across branches.
      expect('shell_page_registry.dart'.allMatches(extended).length, 1);
    });
  });

  group('shell page registry', () {
    test('shellPageRegistry emits the Map + lookup helper + witness', () {
      final out = CoreTemplates.shellPageRegistry(
        packageName: 'core',
        featurePackageName: 'dashboard',
        featureName: 'dashboard',
      );
      expect(out, contains('final Map<String, ShellPageBuilder> shellPageBuilders = {'));
      expect(out, contains("'dashboard': (context, state) => const DashboardPage(),"));
      expect(out, contains('ShellPageBuilder lookupShellPage(String key)'));
      expect(out, contains('throw StateError('));
      expect(out, contains('// neat:shell-page-imports'));
      expect(out, contains('// neat:shell-page-builders'));
    });

    test('shellPageRegistry with no witness (Workshop self-heal path) has no witness import', () {
      final out = CoreTemplates.shellPageRegistry(packageName: 'core');
      expect(out, isNot(contains('presentation/pages')));
      expect(out, contains('final Map<String, ShellPageBuilder> shellPageBuilders = {'));
    });

    test(
      'CorePackageTemplates.pubspec declares go_router when useShell — the '
      "registry's ShellPageBuilder typedef needs GoRouterState (real bug: "
      'found via a real project, the dependency was missing so flutter '
      'analyze flagged depend_on_referenced_packages)',
      () {
        final withShell = CorePackageTemplates.pubspec(corePackageName: 'core', useShell: true);
        expect(withShell, contains('go_router: ^17.2.3'));

        final withoutShell = CorePackageTemplates.pubspec(corePackageName: 'core');
        expect(withoutShell, isNot(contains('go_router:')));
      },
    );
  });
}
