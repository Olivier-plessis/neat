import 'package:flutter_test/flutter_test.dart';
import 'package:neat/features/generation/domain/services/templates/dart/auth_templates.dart';
import 'package:neat/features/generation/domain/services/templates/dart/onboarding_templates.dart';

void main() {
  group('OnboardingTemplates.onboardingSeenProvider', () {
    test('a keepAlive Riverpod provider persisting to shared_preferences, and a Listenable', () {
      final code = OnboardingTemplates.onboardingSeenProvider(packageName: 'demo_app');
      expect(code, contains("import 'package:shared_preferences/shared_preferences.dart';"));
      expect(code, contains('@Riverpod(keepAlive: true)'));
      expect(code, contains('class OnboardingSeen extends _\$OnboardingSeen implements Listenable'));
      expect(code, contains('bool build() => false;'));
      expect(code, contains('Future<void> load()'));
      expect(code, contains('Future<void> markSeen()'));
      expect(code, contains('void addListener(VoidCallback listener) => _listener = listener;'));
      expect(code, contains('void removeListener(VoidCallback listener) => _listener = null;'));
      expect(code, contains("part 'onboarding_seen_provider.g.dart';"));
    });
  });

  group('OnboardingTemplates.onboardingPage', () {
    test('a content-free PageView skeleton wired to the seen provider', () {
      final code = OnboardingTemplates.onboardingPage(packageName: 'demo_app');
      expect(
        code,
        contains("import 'package:demo_app/core/onboarding/onboarding_seen_provider.dart';"),
      );
      expect(code, contains("import 'package:flutter_hooks/flutter_hooks.dart';"));
      expect(code, contains('class OnboardingPage extends HookConsumerWidget'));
      expect(code, contains('usePageController()'));
      expect(code, contains('useState(0)'));
      expect(code, contains('PageView('));
      expect(code, contains("TextButton(onPressed: finish, child: const Text('Skip'))"));
      expect(code, contains('ref.read(onboardingSeenProvider.notifier).markSeen();'));
    });

    test('doc comment shows the redirect wiring, including the Auth conflict (manual case)', () {
      final code = OnboardingTemplates.onboardingPage(packageName: 'demo_app');
      expect(code, contains('redirect: (context, state) {'));
      expect(code, contains('AppRoutePath.onboarding'));
      expect(code, contains('RouterNotifier'));
      expect(code, contains('only accepts one `refreshListenable`'));
      expect(code, contains('ref.read(onboardingSeenProvider.notifier).load();'));
      expect(code, isNot(contains('already wired')));
    });

    test('autoWired: doc comment says NEAT already wired it, no manual example', () {
      final code = OnboardingTemplates.onboardingPage(packageName: 'demo_app', autoWired: true);
      expect(code, contains('NEAT already wired the routing gate'));
      expect(code, contains('app_router.dart'));
      expect(code, contains('router_notifier.dart'));
      expect(code, isNot(contains('Wire it yourself')));
      // The widget itself is identical either way — only the doc comment differs.
      expect(code, contains('class OnboardingPage extends HookConsumerWidget'));
    });
  });

  group('OnboardingTemplates.onboardingRoutesBuilder', () {
    test('a typed route pointing at OnboardingPage, navigating home via onDone', () {
      final code = OnboardingTemplates.onboardingRoutesBuilder(
        packageName: 'demo_app',
        homeRoute: 'AppRoutePath.product',
      );
      expect(code, contains('@TypedGoRoute<OnboardingRoute>(path: AppRoutePath.onboarding)'));
      expect(code, contains(r'class OnboardingRoute extends GoRouteData with $OnboardingRoute'));
      expect(code, contains("part 'onboarding_routes.g.dart';"));
      expect(code, contains('OnboardingPage(onDone: () => context.go(AppRoutePath.product))'));
    });

    test('packageSplit: AppRoutePath redirects to the core package, onboarding_page.dart stays app-level', () {
      final code = OnboardingTemplates.onboardingRoutesBuilder(
        packageName: 'demo_app',
        homeRoute: 'AppRoutePath.product',
        corePackageName: 'core',
      );
      expect(code, contains("import 'package:core/core/constants/app_route_path.dart';"));
      expect(code, contains("import 'package:demo_app/core/onboarding/onboarding_page.dart';"));
    });
  });

  group('AuthTemplates.routerNotifier — onboarding merge', () {
    test('no onboarding: only the auth redirect', () {
      final code = AuthTemplates.routerNotifier(
        packageName: 'demo_app',
        homeRoute: 'AppRoutePath.product',
      );
      expect(code, isNot(contains('onboarding')));
    });

    test('hasOnboarding: checked first, merged into the same guard (no second Listenable)', () {
      final code = AuthTemplates.routerNotifier(
        packageName: 'demo_app',
        homeRoute: 'AppRoutePath.product',
        hasOnboarding: true,
      );
      expect(code, contains('onboarding_seen_provider.dart'));
      expect(code, contains('ref.listen(onboardingSeenProvider,'));
      expect(code, contains('ref.read(onboardingSeenProvider)'));
      expect(code, contains('AppRoutePath.onboarding'));
      // Checked before the auth logic (shown before even asking to log in).
      final onboardingIdx = code.indexOf('onboardingSeen');
      final authIdx = code.indexOf('loggedIn');
      expect(onboardingIdx, greaterThan(0));
      expect(onboardingIdx, lessThan(authIdx));
      // Still exactly one Listenable — RouterNotifier itself.
      expect('implements Listenable'.allMatches(code).length, 1);
    });

    test(
      'hasOnboarding: the login redirect exempts the onboarding route itself '
      '(real bug, found via a real generated project: an unonboarded, '
      'unauthenticated user landing on /onboarding fell through both '
      'onboarding checks, then got bounced to /login by this one, which '
      'bounced straight back — an infinite /onboarding => /login => '
      '/onboarding loop)',
      () {
        final code = AuthTemplates.routerNotifier(
          packageName: 'demo_app',
          homeRoute: 'AppRoutePath.product',
          hasOnboarding: true,
        );
        expect(
          code,
          contains('if (!loggedIn && !onAuthRoute && !onOnboarding) return AppRoutePath.login;'),
        );
      },
    );

    test(
      'no onboarding: the login redirect does not reference onOnboarding — '
      'that variable is only ever declared when hasOnboarding is on, so '
      'including it here would be a compile error, not just a redundant check',
      () {
        final code = AuthTemplates.routerNotifier(
          packageName: 'demo_app',
          homeRoute: 'AppRoutePath.product',
        );
        expect(code, contains('if (!loggedIn && !onAuthRoute) return AppRoutePath.login;'));
        expect(code, isNot(contains('onOnboarding')));
      },
    );
  });
}
