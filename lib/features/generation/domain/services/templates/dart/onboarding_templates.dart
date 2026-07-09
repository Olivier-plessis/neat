/// Templates for the opt-in **onboarding** flow: a first-launch-only intro
/// (a content-free `PageView` skeleton) + a persisted "seen it" provider.
///
/// The redirect gate is auto-wired when it's go_router_builder (typed) — see
/// `AuthTemplates.routerNotifier`'s `hasOnboarding` param (merged into the
/// existing guard) and `CoreTemplates.appRouterBuilder`'s `hasOnboarding`
/// param (a standalone guard when there's no Auth). Plain go_router has no
/// proven anchor-splicing precedent to build on (see ROADMAP.md's onboarding
/// entry) — it stays generated-but-unwired, same as before.
class OnboardingTemplates {
  OnboardingTemplates._();

  // ── core/onboarding/onboarding_seen_provider.dart ─────────────────────────

  /// The persisted "has onboarding been seen" flag. A Riverpod provider (not
  /// a static class like `LocaleStore`) implementing [Listenable] — same
  /// shape as `AuthTemplates.routerNotifier`'s `RouterNotifier` — so it can
  /// be used directly as a go_router `refreshListenable` when there's no Auth
  /// guard to merge into (see [onboardingPage]'s doc comment).
  static String onboardingSeenProvider({required String packageName}) =>
      '''import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'onboarding_seen_provider.g.dart';

/// Whether onboarding has been completed (or skipped) — persisted so it only
/// shows once. See `OnboardingPage`'s doc comment (package:$packageName/core/
/// onboarding/onboarding_page.dart) for how the redirect gate is wired.
@Riverpod(keepAlive: true)
class OnboardingSeen extends _\$OnboardingSeen implements Listenable {
  static const _prefsKey = 'onboarding_seen';

  VoidCallback? _listener;

  @override
  bool build() => false;

  /// Call once at start-up (before runApp), same convention as
  /// `LocaleStore.init()` — loads the persisted flag so [state] reflects
  /// reality before the first route/redirect decision is made.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_prefsKey) ?? false;
    _listener?.call();
  }

  /// Call from the onboarding flow's last page (Skip or Get Started).
  Future<void> markSeen() async {
    state = true;
    _listener?.call();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, true);
  }

  @override
  void addListener(VoidCallback listener) => _listener = listener;

  @override
  void removeListener(VoidCallback listener) => _listener = null;
}
''';

  // ── core/onboarding/onboarding_page.dart ──────────────────────────────────

  /// A content-free, 3-slide `PageView` skeleton. Slide copy is a placeholder
  /// — replace `_slides` with your own. [autoWired] must match whatever
  /// `launch_generation_usecase.dart` actually did (`autoWireOnboarding` —
  /// true only for go_router_builder) — it only changes this doc comment, so
  /// a mismatch wouldn't break anything, just mislead whoever reads it.
  static String onboardingPage({required String packageName, bool autoWired = false}) {
    final wiringDoc = autoWired
        ? '''/// NEAT already wired the routing gate — see `core/router/app_router.dart`
/// (or `core/router/router_notifier.dart` if this project also has Auth,
/// which merges the check into that same guard rather than attaching a
/// second `refreshListenable` — go_router only accepts one). The persisted
/// flag is also loaded before the first redirect decision, in `bootstrap()`.
/// You don't need to touch routing — just replace the slide content.'''
        : '''/// NEAT does **not** wire this into your router — onboarding can interact
/// with a navigation shell, an auth guard, or packageSplit in ways only you
/// can resolve for your app. Wire it yourself, e.g. in your GoRouter's
/// `redirect:`:
///
/// ```dart
/// redirect: (context, state) {
///   final seen = ref.read(onboardingSeenProvider);
///   final onOnboarding = state.matchedLocation == AppRoutePath.onboarding;
///   if (!seen && !onOnboarding) return AppRoutePath.onboarding;
///   if (seen && onOnboarding) return AppRoutePath.home;
///   return null;
/// },
/// ```
///
/// go_router only accepts one `refreshListenable`. If you're also using
/// Auth's `RouterNotifier`, don't attach a second one for onboarding — fold
/// the check above into `RouterNotifier.redirect()` instead. Either way, call
/// `await ref.read(onboardingSeenProvider.notifier).load();` once at
/// start-up (in `bootstrap()`, before `runApp` — same spot as
/// `LocaleStore.init()`) so [state] is accurate before the first redirect.''';
    return '''import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:$packageName/core/onboarding/onboarding_seen_provider.dart';

/// A short first-launch intro (a few slides), shown once then skipped on
/// every subsequent launch. Content is a placeholder — customize [_slides].
///
$wiringDoc
///
/// A [HookConsumerWidget] — `usePageController`/`useState` replace a
/// StatefulWidget's controller + dispose() + setState() boilerplate.
/// `flutter_hooks` is already a guaranteed dependency here (part of the
/// Riverpod-annotations package preset this feature is gated on).
class OnboardingPage extends HookConsumerWidget {
  const OnboardingPage({required this.onDone, super.key});

  /// Called after the last slide (Skip or Get Started) — typically
  /// `context.go(AppRoutePath.home)`.
  final VoidCallback onDone;

  static const _slides = [
    (title: 'Welcome', body: 'Tell users what your app does in one line.'),
    (title: 'Key feature', body: 'Highlight what makes your app worth using.'),
    (title: 'Get started', body: 'One last nudge before they dive in.'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = usePageController();
    final page = useState(0);

    void finish() {
      ref.read(onboardingSeenProvider.notifier).markSeen();
      onDone();
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(onPressed: finish, child: const Text('Skip')),
            ),
            Expanded(
              child: PageView(
                controller: controller,
                onPageChanged: (i) => page.value = i,
                children: [
                  for (final slide in _slides)
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(slide.title, style: Theme.of(context).textTheme.headlineMedium),
                          const SizedBox(height: 16),
                          Text(slide.body, textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _slides.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == page.value
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    if (page.value == _slides.length - 1) {
                      finish();
                    } else {
                      controller.nextPage(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                      );
                    }
                  },
                  child: Text(page.value == _slides.length - 1 ? 'Get started' : 'Next'),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
''';
  }

  // ── core/onboarding/onboarding_routes.dart (go_router_builder only) ──────

  /// The typed route for [OnboardingPage] — only generated when the redirect
  /// can be auto-wired (go_router_builder; see launch_generation_usecase.dart's
  /// `autoWireOnboarding`). Mirrors `AuthTemplates.authRoutesBuilder`'s shape.
  static String onboardingRoutesBuilder({
    required String packageName,
    required String homeRoute,
  }) =>
      '''import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:$packageName/core/constants/app_route_path.dart';
import 'package:$packageName/core/onboarding/onboarding_page.dart';

part 'onboarding_routes.g.dart';

@TypedGoRoute<OnboardingRoute>(path: AppRoutePath.onboarding)
class OnboardingRoute extends GoRouteData with \$OnboardingRoute {
  const OnboardingRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      OnboardingPage(onDone: () => context.go($homeRoute));
}
''';
}
