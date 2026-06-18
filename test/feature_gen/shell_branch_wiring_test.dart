import 'package:flutter_test/flutter_test.dart';
import 'package:neat/features/feature_gen/domain/usecases/generate_feature_usecase.dart';
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
    });

    test('shellBranchPlain renders a standalone branch block', () {
      final out = CoreTemplates.shellBranchPlain(featureName: 'orders');
      expect(out, contains('StatefulShellBranch('));
      expect(out, contains('path: AppRoutePath.orders'));
      expect(out, contains('const OrdersPage()'));
      expect(out, isNot(contains('StatefulShellRoute'))); // not the wrapper
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
      expect(out, contains('TypedGoRoute<DashboardRoute>(path: AppRoutePath.dashboard)'));
      expect(out, contains('class AppShellRouteData extends StatefulShellRouteData'));
      expect(out, contains('class DashboardBranchData extends StatefulShellBranchData'));
      expect(out, contains(r'class DashboardRoute extends GoRouteData with $DashboardRoute'));
      expect(out, contains('ScaffoldWithNavBar(navigationShell: navigationShell)'));
      expect(out, contains('// neat:shell-branches'));
      expect(out, contains('// neat:shell-classes'));
      expect(out, contains('// neat:shell-imports'));
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
      // Anchors are reused, not duplicated.
      expect('// neat:shell-branches'.allMatches(extended).length, 1);
      expect('// neat:shell-classes'.allMatches(extended).length, 1);
      expect('@TypedStatefulShellRoute'.allMatches(extended).length, 1);
    });
  });
}
