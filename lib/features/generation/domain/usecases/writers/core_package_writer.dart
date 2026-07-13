import 'dart:io';

import 'package:neat/features/generation/domain/services/templates/core_package_templates.dart';
import 'package:neat/features/generation/domain/services/templates/core_templates.dart';
import 'package:neat/features/generation/domain/services/templates/dart/core_dart_templates.dart';
import 'package:neat/features/generation/domain/usecases/writers/generation_io.dart';
import 'package:neat/features/theme_engine/domain/services/theme_templates.dart';

/// Writes the shared `core` workspace package (Result/Failure/UseCase +
/// dio/chopper/supabase/firebase networking + AppRoutePath + theme mode
/// controller — the packageSplit prerequisite) — split out of
/// `LaunchGenerationUsecase` (see ROADMAP.md §6a for the per-domain writer
/// split and the packageSplit design itself).
abstract final class CorePackageWriter {
  static Future<void> write(
    Directory projectDir,
    String corePackageName, {
    required String featureName,
    required String httpClient,
    // Set when offline-first is on: NetworkInfo + the shared
    // appDatabaseProvider/networkInfoProvider (infrastructure_providers.dart)
    // move here too — every offline-first repository across every feature
    // package needs to share the *same* Drift db + connectivity instances,
    // and core is the only place that sits below all of them.
    String? localStoragePackage,
    bool hasI18n = false,
    // Set when offline-first *sync* (Outbox) is on: sync_service.dart moves
    // here too, for the same reason as network_info.dart/
    // infrastructure_providers.dart above — every feature package's
    // SyncService provider (see DataTemplates.featureRepositoryProviders)
    // needs to import the same copy, and a feature package can't import the
    // app's.
    bool hasSync = false,
    // Supabase/Firebase client-init providers move here too, for the same
    // reason as dio/chopper above — Auth (which stays app-level even when
    // split, see AuthTemplates) and every feature's ApiSource both need the
    // same client instance. hasAuth/hasStorage drive which extra Firebase
    // singletons firebase_provider.dart exposes (mirrors the app-level call).
    bool hasAuth = false,
    bool hasStorage = false,
    bool hasEnvied = false,
    // Set when the project boots into a navigation shell (see ROADMAP.md
    // §6a): the core package also gets the shell page registry
    // (shellPageBuilders), seeded with the first branch as a witness
    // (mirrors chopperModelConverter's own witness — see
    // CoreTemplates.shellPageRegistry's doc). [featurePackageName] is the
    // first branch's own split package, used for the witness import.
    bool useShell = false,
    String? featurePackageName,
    // Same rationale as hasAuth just below: a split feature package (added
    // later via the Workshop) may want AppRoutePath.onboarding — e.g. a
    // "Replay onboarding" settings action — and can only reach it through
    // this mirrored copy, never the app's own.
    bool hasOnboarding = false,
    // Same rationale as hasAuth/hasOnboarding above: a Workshop-added feature
    // package reads AppRoutePath from here too, so it must mirror whichever
    // entry (first-feature vs welcome placeholder) the app itself resolved to.
    bool hasFirstFeature = true,
  }) async {
    final root = '${projectDir.path}/packages/$corePackageName';
    await writeFile(
      '$root/pubspec.yaml',
      CorePackageTemplates.pubspec(
        corePackageName: corePackageName,
        httpClient: httpClient,
        localStoragePackage: localStoragePackage,
        hasI18n: hasI18n,
        hasAuth: hasAuth,
        hasStorage: hasStorage,
        useShell: useShell,
      ),
    );
    await writeFile(
      '$root/lib/core/error/failure.dart',
      CoreTemplates.failure(),
    );
    await writeFile(
      '$root/lib/core/result/result.dart',
      CoreDartTemplates.coreResultDart(packageName: corePackageName),
    );
    await writeFile(
      '$root/lib/core/usecases/use_case.dart',
      CoreDartTemplates.coreUsecaseDart(packageName: corePackageName),
    );
    await writeFile(
      '$root/lib/core/network/network_error_handler.dart',
      CoreTemplates.networkErrorHandler(
        packageName: corePackageName,
        httpClient: httpClient,
      ),
    );
    final isDioBased = httpClient == 'dio';
    // Bridges AppEnv.apiBaseUrl into this package when both apply — see this
    // method's doc comment.
    if (hasEnvied && (isDioBased || httpClient == 'chopper')) {
      await writeFile(
        '$root/lib/core/network/api_config.dart',
        CoreTemplates.apiConfig(),
      );
    }
    // Shell page registry (see this method's doc comment) — seeded with the
    // first branch (the wizard's own first feature) as a witness.
    if (useShell) {
      await writeFile(
        '$root/lib/core/router/shell_page_registry.dart',
        CoreTemplates.shellPageRegistry(
          packageName: corePackageName,
          featurePackageName: featurePackageName,
          featureName: featureName,
        ),
      );
    }
    if (isDioBased) {
      await writeFile(
        '$root/lib/core/network/dio_provider.dart',
        CoreTemplates.dioProvider(
          packageName: corePackageName,
          useAnnotations: true,
          useEnvied: hasEnvied,
          sharedConfig: true,
        ),
      );
    }
    if (httpClient == 'chopper') {
      // No witness: unlike the non-split registry (anchor-inserted at
      // generation/Workshop time), split feature packages register their own
      // decoder at runtime instead (see DataTemplates.featureRepositoryProviders'
      // registersChopperDecoder) — core can't import their Models without
      // recreating the very cycle packageSplit exists to avoid.
      await writeFile(
        '$root/lib/core/network/chopper_model_converter.dart',
        CoreTemplates.chopperModelConverter(packageName: corePackageName),
      );
      await writeFile(
        '$root/lib/core/network/chopper_client_provider.dart',
        CoreTemplates.chopperClientProvider(
          packageName: corePackageName,
          useAnnotations: true,
          useEnvied: hasEnvied,
          sharedConfig: true,
        ),
      );
    }
    if (httpClient == 'supabase') {
      await writeFile(
        '$root/lib/core/network/supabase_provider.dart',
        CoreTemplates.supabaseProvider(
          packageName: corePackageName,
          useAnnotations: true,
        ),
      );
    }
    if (httpClient == 'firebase') {
      await writeFile(
        '$root/lib/core/network/firebase_provider.dart',
        CoreTemplates.firebaseProvider(
          packageName: corePackageName,
          useAnnotations: true,
          hasAuth: hasAuth,
          hasStorage: hasStorage,
        ),
      );
    }
    await writeFile(
      '$root/lib/core/observers/logger_interceptor.dart',
      CoreTemplates.loggerInterceptor(
        packageName: corePackageName,
        httpClient: httpClient,
      ),
    );
    await writeFile(
      '$root/lib/core/utils/app_logger.dart',
      CoreTemplates.appLogger(useEnvied: false, packageName: corePackageName),
    );
    await writeFile(
      '$root/lib/core/utils/future_extensions.dart',
      CorePackageTemplates.futureExtensions(),
    );
    await writeFile(
      '$root/lib/core/utils/extensions.dart',
      CoreTemplates.extensions(),
    );
    await writeFile(
      '$root/lib/core/constants/app_route_path.dart',
      // hasAuth: the split Auth package's screens/routes import AppRoutePath
      // from here, so the login/signup/forgotPassword constants must be
      // mirrored here too — missing this made every auth route constant
      // undefined in the auth package (found via a failing integration test).
      // hasOnboarding: same shape of bug, found the same way — see the param
      // doc above.
      CoreTemplates.appRoutePath(
        featureName: featureName,
        hasFirstFeature: hasFirstFeature,
        hasAuth: hasAuth,
        hasOnboarding: hasOnboarding,
      ),
    );
    // theme_mode_controller is a single app-wide *stateful* provider (unlike
    // the other core files above, which are stateless types/singletons) —
    // both the app shell's MaterialApp and a split feature page's dark-mode
    // toggle read/write it, so it must be single-sourced here rather than
    // duplicated, or the two would watch different provider instances and
    // drift out of sync. Phase 1 always has Riverpod annotations.
    await writeFile(
      '$root/lib/core/theme/theme_mode_controller.dart',
      ThemeTemplates.themeModeControllerRiverpod(packageName: corePackageName),
    );
    if (localStoragePackage != null) {
      await writeFile(
        '$root/lib/core/network/network_info.dart',
        CoreTemplates.networkInfo(),
      );
      await writeFile(
        '$root/lib/core/providers/infrastructure_providers.dart',
        CoreTemplates.infrastructureProviders(
          packageName: corePackageName,
          localStoragePackage: localStoragePackage,
        ),
      );
      if (hasSync) {
        await writeFile(
          '$root/lib/core/sync/sync_service.dart',
          CoreTemplates.syncService(
            packageName: corePackageName,
            localStoragePackage: localStoragePackage,
          ),
        );
      }
    }
  }
}
