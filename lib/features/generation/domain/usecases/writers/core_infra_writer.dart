import 'package:neat/features/architecture/domain/models/architecture_state.dart';
import 'package:neat/features/architecture/domain/models/env_config.dart';
import 'package:neat/features/generation/domain/services/templates/core_templates.dart';
import 'package:neat/features/generation/domain/services/templates/dart/core_dart_templates.dart';
import 'package:neat/features/generation/domain/usecases/writers/generation_io.dart';

/// Writes the app-level core building blocks: Result/Failure/UseCase,
/// AppRoutePath (+ the welcome placeholder), the network error handler,
/// utils/observability (extensions, AppLogger, error_handler,
/// provider_observer, logger_interceptor), and the plain (non-envied)
/// dio/chopper/supabase client providers — split out of
/// `LaunchGenerationUsecase`'s `_buildScaffold` (see ROADMAP.md for the
/// per-domain writer split).
///
/// Every file gated on `corePackageName == null` only exists to be imported
/// by app-level code — once packageSplit moves that code into the shared
/// core package (see `CorePackageWriter`), the app's own copy would just be
/// dead code (see ROADMAP.md §6a's "clean up the duplicated core/" note).
abstract final class CoreInfraWriter {
  static Future<void> write({
    required String lib,
    required ArchitectureState architecture,
    required String featureName,
    required String packageName,
    required String httpClient,
    required bool hasAuth,
    required bool hasRiverpod,
    required bool useAnnotations,
    required bool hasEnvied,
    required bool singleEnv,
    required List<EnvConfig> environments,
    required bool autoWireOnboarding,
    String? corePackageName,
  }) async {
    // ── core/result ───────────────────────────────────────────────────────
    if (corePackageName == null) {
      await writeFile(
        '$lib/core/result/result.dart',
        CoreDartTemplates.coreResultDart(packageName: packageName),
      );
      await writeFile(
        '$lib/core/usecases/use_case.dart',
        CoreDartTemplates.coreUsecaseDart(packageName: packageName),
      );
    }

    // ── core/constants ────────────────────────────────────────────────────
    if (corePackageName == null) {
      await writeFile(
        '$lib/core/constants/app_route_path.dart',
        CoreTemplates.appRoutePath(
          featureName: featureName,
          hasAuth: hasAuth,
          hasFirstFeature: architecture.generateFirstFeature,
          hasOnboarding: autoWireOnboarding,
        ),
      );
    }

    // No first feature → a placeholder welcome screen owns the root route
    // until one is added via the Workshop.
    if (!architecture.generateFirstFeature) {
      await writeFile(
        '$lib/core/pages/welcome_page.dart',
        CoreTemplates.welcomePage(
          packageName: packageName,
          appName: packageName,
        ),
      );
    }

    // ── core/error ────────────────────────────────────────────────────────
    if (corePackageName == null) {
      await writeFile('$lib/core/error/failure.dart', CoreTemplates.failure());

      // ── core/network/network_error_handler.dart ───────────────────────────
      // The only place exceptions are caught and mapped to a Failure —
      // UseCase.call() invokes it. Always generated (even with no http client).
      await writeFile(
        '$lib/core/network/network_error_handler.dart',
        CoreTemplates.networkErrorHandler(
          packageName: packageName,
          httpClient: httpClient,
          hasRiverpod: hasRiverpod,
        ),
      );
    }

    // ── core/utils + observers (observability) ──────────────────────────────
    if (corePackageName == null) {
      // ── core/utils ────────────────────────────────────────────────────────
      await writeFile(
        '$lib/core/utils/extensions.dart',
        CoreTemplates.extensions(),
      );

      await writeFile(
        '$lib/core/utils/app_logger.dart',
        CoreTemplates.appLogger(
          // Single-env has no production flavor to compare against → fall back
          // to the kReleaseMode logger (quietens logs in release builds).
          useEnvied: hasEnvied && !singleEnv,
          packageName: packageName,
          // Production = the explicit base environment (quietens logs there).
          prodFlavor: hasEnvied && environments.isNotEmpty
              ? architecture.baseEnv.flavor
              : 'prod',
        ),
      );
    }
    await writeFile(
      '$lib/core/error/error_handler.dart',
      CoreTemplates.errorHandler(
        packageName: packageName,
        corePackageName: corePackageName,
      ),
    );
    if (hasRiverpod) {
      await writeFile(
        '$lib/core/observers/provider_observer.dart',
        CoreTemplates.riverpodObserver(
          packageName: packageName,
          useAnnotations: useAnnotations,
          corePackageName: corePackageName,
        ),
      );
    }
    // HTTP logging interceptor — REST clients only (Supabase has its own).
    final isRestClient = httpClient == 'dio' || httpClient == 'chopper';
    if (isRestClient && corePackageName == null) {
      await writeFile(
        '$lib/core/observers/logger_interceptor.dart',
        CoreTemplates.loggerInterceptor(
          packageName: packageName,
          httpClient: httpClient,
        ),
      );
    }
    final isDioBased = httpClient == 'dio';
    if (isDioBased && hasRiverpod && corePackageName == null) {
      await writeFile(
        '$lib/core/network/dio_provider.dart',
        CoreTemplates.dioProvider(
          packageName: packageName,
          useAnnotations: useAnnotations,
          useEnvied: hasEnvied,
        ),
      );
    }
    // chopper_model_converter.dart is plain Dart (no Riverpod import at all)
    // and is imported directly by every chopper repository_impl.dart
    // (`unwrapChopperResponse`) regardless of state management — so unlike
    // chopper_client_provider.dart (a Riverpod provider, only ever consumed
    // by the Riverpod-only <feature>_repository_providers.dart DI graph),
    // it must not be gated on hasRiverpod. Bloc/Cubit stub-mode repositories
    // still need it to compile even though nothing wires a ChopperClient into
    // them yet.
    if (httpClient == 'chopper' && corePackageName == null) {
      await writeFile(
        '$lib/core/network/chopper_model_converter.dart',
        CoreTemplates.chopperModelConverter(
          packageName: packageName,
          featureName: architecture.generateFirstFeature ? featureName : null,
        ),
      );
    }
    if (httpClient == 'chopper' && hasRiverpod && corePackageName == null) {
      await writeFile(
        '$lib/core/network/chopper_client_provider.dart',
        CoreTemplates.chopperClientProvider(
          packageName: packageName,
          useAnnotations: useAnnotations,
          useEnvied: hasEnvied,
        ),
      );
    }
    if (httpClient == 'supabase' && hasRiverpod && corePackageName == null) {
      await writeFile(
        '$lib/core/network/supabase_provider.dart',
        CoreTemplates.supabaseProvider(
          packageName: packageName,
          useAnnotations: useAnnotations,
        ),
      );
    }
  }
}
