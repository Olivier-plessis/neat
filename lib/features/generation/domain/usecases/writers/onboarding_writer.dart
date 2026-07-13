import 'dart:io';

import 'package:neat/features/generation/domain/services/templates/dart/onboarding_templates.dart';
import 'package:neat/features/generation/domain/usecases/writers/generation_io.dart';

/// Writes the opt-in first-launch onboarding flow (seen-provider + page +,
/// when auto-wireable, its typed route merged into the shared route table)
/// — split out of `LaunchGenerationUsecase`'s `_buildScaffold` (see
/// ROADMAP.md for the per-domain writer split).
///
/// Always app-level (unlike i18n) — it has no cross-feature dependency to
/// solve, so no packageSplit placement question. The redirect is
/// auto-wired only when [autoWireOnboarding] (go_router_builder) — see
/// `OnboardingTemplates`' doc comment for the plain-go_router fallback.
abstract final class OnboardingWriter {
  static Future<void> write({
    required String lib,
    required String packageName,
    required String featureName,
    required bool autoWireOnboarding,
    required bool hasFirstFeature,
    String? corePackageName,
  }) async {
    await writeFile(
      '$lib/core/onboarding/onboarding_seen_provider.dart',
      OnboardingTemplates.onboardingSeenProvider(packageName: packageName),
    );
    await writeFile(
      '$lib/core/onboarding/onboarding_page.dart',
      OnboardingTemplates.onboardingPage(
        packageName: packageName,
        autoWired: autoWireOnboarding,
      ),
    );
    if (autoWireOnboarding) {
      final onboardingHomeRoute = homeRouteExpr(
        featureName: featureName,
        hasFirstFeature: hasFirstFeature,
      );
      await writeFile(
        '$lib/core/onboarding/onboarding_routes.dart',
        OnboardingTemplates.onboardingRoutesBuilder(
          packageName: packageName,
          homeRoute: onboardingHomeRoute,
          corePackageName: corePackageName,
        ),
      );

      // Aggregate the onboarding route into the shared route table (typed
      // go_router_builder only — see autoWireOnboarding).
      final onboardingRoutesImport =
          "import 'package:$packageName/core/onboarding/onboarding_routes.dart' as onboarding;";
      final routesFile = File('$lib/core/router/routes.dart');
      if (routesFile.existsSync()) {
        var s = await routesFile.readAsString();
        s = insertBeforeAnchor(
          s,
          '// neat:route-imports',
          onboardingRoutesImport,
        );
        s = insertBeforeAnchor(
          s,
          '// neat:route-entries',
          r'  ...onboarding.$appRoutes,',
        );
        await routesFile.writeAsString(s);
      }
    }
  }
}
