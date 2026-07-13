import 'package:neat/features/generation/domain/services/templates/core_templates.dart';
import 'package:neat/features/generation/domain/usecases/writers/generation_io.dart';

/// Writes `app_router.dart` + `routes.dart` (plain or typed go_router_builder
/// shape, the welcome-placeholder fallback with no first feature, and the
/// bottom-nav shell variant) — split out of `LaunchGenerationUsecase` (see
/// ROADMAP.md for the per-domain writer split).
abstract final class RouterWriter {
  static Future<void> write({
    required String lib,
    required String packageName,
    required String featureName,
    required bool hasGoRouterBuilder,
    required bool useAnnotations,
    bool useShell = false,
    String shellIcon = 'home',
    String shellLabel = '',
    bool hasAuth = false,
    bool hasFirstFeature = true,
    // Set when packageSplit is on: routesManual's feature-page import must
    // cross into the split feature package instead of lib/features/<name>/.
    String? featurePackageName,
    // Set when packageSplit is on: threaded to the shell templates so the
    // first branch's page (when useShell) reads core's shell page registry
    // instead of being imported directly (see CoreTemplates.shellPageRegistry).
    String? corePackageName,
    // Only true when the redirect can be auto-wired (go_router_builder — see
    // execute()'s autoWireOnboarding). Ignored when !hasGoRouterBuilder.
    bool hasOnboarding = false,
  }) async {
    final r = '$lib/core/router';

    // app_router.dart: initialLocation = AppRoutePath.<first> = '/' (or
    // AppRoutePath.welcome with no first feature). With auth a
    // RouterNotifier guard is wired (refreshListenable + redirect) — it also
    // covers onboarding when both are on.
    await writeFile(
      '$r/app_router.dart',
      hasGoRouterBuilder
          ? CoreTemplates.appRouterBuilder(
              packageName: packageName,
              featureName: featureName,
              useAnnotations: useAnnotations,
              hasAuth: hasAuth,
              hasFirstFeature: hasFirstFeature,
              hasOnboarding: hasOnboarding,
              corePackageName: corePackageName,
            )
          : CoreTemplates.appRouter(
              packageName: packageName,
              featureName: featureName,
              hasFirstFeature: hasFirstFeature,
              corePackageName: corePackageName,
            ),
    );

    // No first feature (never combined with a shell — see useShell's guard
    // in execute()): the welcome placeholder owns routes.dart instead.
    if (!hasFirstFeature) {
      if (hasGoRouterBuilder) {
        await writeFile(
          '$r/welcome_route.dart',
          CoreTemplates.welcomeRoute(
            packageName: packageName,
            corePackageName: corePackageName,
          ),
        );
        await writeFile(
          '$r/routes.dart',
          CoreTemplates.routesAggregatorWelcome(packageName: packageName),
        );
      } else {
        await writeFile(
          '$r/routes.dart',
          CoreTemplates.routesManualWelcome(
            packageName: packageName,
            corePackageName: corePackageName,
          ),
        );
      }
      return;
    }

    if (useShell) {
      // The bottom-nav scaffold + the shell route, with the first feature as
      // branch 0. routes.dart aggregates the shell instead of a flat route.
      // A UI widget, not routing config — its own core/navigation/ folder,
      // not nested inside core/router/.
      await writeFile(
        '$lib/core/navigation/scaffold_with_nav_bar.dart',
        CoreTemplates.scaffoldWithNavBar(
          firstIcon: shellIcon,
          firstLabel: shellLabel,
        ),
      );
      if (hasGoRouterBuilder) {
        await writeFile(
          '$r/app_shell_route.dart',
          CoreTemplates.appShellRouteBuilder(
            packageName: packageName,
            featureName: featureName,
            featurePackageName: featurePackageName,
            corePackageName: corePackageName,
          ),
        );
        await writeFile(
          '$r/routes.dart',
          CoreTemplates.routesAggregatorShell(packageName: packageName),
        );
      } else {
        await writeFile(
          '$r/routes.dart',
          CoreTemplates.routesManualShell(
            packageName: packageName,
            featureName: featureName,
            featurePackageName: featurePackageName,
            corePackageName: corePackageName,
          ),
        );
      }
      return;
    }

    await writeFile(
      '$r/routes.dart',
      hasGoRouterBuilder
          ? CoreTemplates.routesAggregator(
              packageName: packageName,
              featureName: featureName,
              featurePackageName: featurePackageName,
            )
          : CoreTemplates.routesManual(
              packageName: packageName,
              featureName: featureName,
              featurePackageName: featurePackageName,
              corePackageName: corePackageName,
            ),
    );
  }
}
