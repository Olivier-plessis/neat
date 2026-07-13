import 'package:neat/features/architecture/domain/models/env_config.dart';
import 'package:neat/features/dependencies/domain/models/pub_package.dart';
import 'package:neat/features/generation/domain/services/templates/dart/app_templates.dart';
import 'package:neat/features/generation/domain/usecases/writers/generation_io.dart';

/// Writes the app's boot sequence: `main.dart` (+ one `main_<env>.dart` per
/// environment when entry points are on), `bootstrap.dart`, and `app.dart` —
/// split out of `LaunchGenerationUsecase`'s `_buildScaffold` (see ROADMAP.md
/// for the per-domain writer split).
abstract final class EntryPointWriter {
  static Future<void> writeMainAndBootstrap({
    required String lib,
    required List<PubPackage> packages,
    required String packageName,
    required bool hasEnvied,
    required bool hasEntryPoints,
    required List<EnvConfig> environments,
    required bool singleEnv,
    required String defaultFlavor,
    required bool hasRiverpod,
    required bool useAnnotations,
    required bool isWeb,
    required String httpClient,
    required bool hasI18n,
    required String? featurePackageName,
    required String featureName,
    required bool useShell,
    required String? corePackageName,
    required bool autoWireOnboarding,
    bool hasSentry = false,
  }) async {
    await writeFile(
      '$lib/main.dart',
      AppTemplates.mainDart(
        packages,
        packageName: packageName,
        useEnvied: hasEnvied,
        flavor: defaultFlavor,
        singleEnv: singleEnv,
      ),
    );
    if (hasEntryPoints) {
      for (final env in environments) {
        await writeFile(
          '$lib/main_${env.flavor}.dart',
          AppTemplates.mainDart(
            packages,
            packageName: packageName,
            useEnvied: true,
            flavor: env.flavor,
          ),
        );
      }
    }
    await writeFile(
      '$lib/core/bootstrap.dart',
      AppTemplates.bootstrap(
        packageName: packageName,
        hasRiverpod: hasRiverpod,
        useAnnotations: useAnnotations,
        useEnvied: hasEnvied,
        isWeb: isWeb,
        hasSupabase: httpClient == 'supabase',
        hasFirebase: httpClient == 'firebase',
        hasI18n: hasI18n,
        chopperRegisterFeaturePackage: httpClient == 'chopper'
            ? featurePackageName
            : null,
        chopperRegisterFeatureName: httpClient == 'chopper'
            ? featureName
            : null,
        shellRegisterFeaturePackage: useShell && featurePackageName != null
            ? featurePackageName
            : null,
        shellRegisterFeatureName: useShell && featurePackageName != null
            ? featureName
            : null,
        corePackageName: corePackageName,
        bridgesApiBaseUrl:
            hasEnvied &&
            corePackageName != null &&
            (httpClient == 'dio' || httpClient == 'chopper'),
        hasOnboarding: autoWireOnboarding,
        hasSentry: hasSentry,
      ),
    );
  }

  static Future<void> writeAppDart({
    required String lib,
    required String packageName,
    required bool hasGoRouter,
    required bool hasRiverpod,
    required bool useAnnotations,
    required bool hasBloc,
    required bool useCubit,
    required bool useScreenUtil,
    required bool hasGoRouterBuilder,
    required String? uiPackage,
    required bool hasI18n,
    required String? corePackageName,
  }) async {
    await writeFile(
      '$lib/app.dart',
      AppTemplates.appDart(
        name: packageName,
        hasGoRouter: hasGoRouter,
        hasRiverpod: hasRiverpod,
        useAnnotations: useAnnotations,
        hasBloc: hasBloc,
        useCubit: useCubit,
        useScreenUtil: useScreenUtil,
        // appRouterProvider only exists with go_router_builder + annotations.
        routerIsProvider: hasGoRouterBuilder && useAnnotations,
        // When the theme lives in <app>_ui, app.dart imports it from there.
        themePackage: uiPackage,
        hasI18n: hasI18n,
        corePackageName: corePackageName,
      ),
    );
  }
}
