import 'dart:io';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:neat/features/architecture/domain/models/architecture_state.dart';
import 'package:neat/features/cicd/domain/models/cicd_state.dart';
import 'package:neat/features/cicd/domain/usecases/generate_yaml_usecase.dart';
import 'package:neat/features/dependencies/domain/models/pub_package.dart';
import 'package:neat/features/generation/domain/services/templates/config_templates.dart';
import 'package:neat/features/generation/domain/services/templates/core_templates.dart';
import 'package:neat/features/generation/domain/services/templates/dart/app_templates.dart';
import 'package:neat/features/generation/domain/services/templates/dart/core_dart_templates.dart';
import 'package:neat/features/generation/domain/services/templates/dart/data_templates.dart';
import 'package:neat/features/generation/domain/services/templates/dart/domain_templates.dart';
import 'package:neat/features/generation/domain/services/templates/dart/presentation_templates.dart';
import 'package:neat/features/generation/domain/services/templates/dart/state_templates.dart';
import 'package:neat/features/generation/domain/services/templates/local_storage_templates.dart';
import 'package:neat/features/identity/domain/models/identity_state.dart';
import 'package:neat/features/theme_engine/domain/models/theme_engine_state.dart';
import 'package:neat/features/theme_engine/domain/services/theme_templates.dart';

class LaunchGenerationUsecase {
  const LaunchGenerationUsecase();

  Future<void> execute({
    required IdentityState identity,
    required List<PubPackage> packages,
    required ArchitectureState architecture,
    required CicdState cicd,
    required ThemeEngineState theme,
    required void Function(String) onLog,
  }) async {
    final projectDir = Directory('${identity.projectPath}/${identity.name}');
    final flutter = await _resolveFlutter();
    onLog('[▶] Using Flutter: $flutter');

    // 1. flutter create
    onLog("[▶] Running 'flutter create ${identity.name}'...");
    final createResult = await Process.run(flutter, [
      'create',
      '--project-name',
      identity.name,
      '-e',
      '--org',
      identity.organization,
      '--description',
      identity.description,
      '--platforms',
      identity.targetPlatforms.join(','),
      projectDir.path,
    ]);

    if (createResult.exitCode != 0) {
      throw Exception(createResult.stderr.toString().trim());
    }
    onLog('[✓] Flutter project created.');

    // 1b. .fvmrc — pin the Flutter SDK version for FVM users
    await _write(
      '${projectDir.path}/.fvmrc',
      ConfigTemplates.fvmrc(flutterVersion: identity.flutterVersion),
    );
    onLog('[✓] .fvmrc written (Flutter ${identity.flutterVersion}).');

    // Resolve feature flags from selected packages
    final hasRiverpod = packages.any((p) => p.name.contains('riverpod'));
    final hasBloc = packages.any((p) => p.name.contains('bloc'));
    final useCubit = architecture.useCubit && hasBloc;
    final useAnnotations = architecture.useRiverpodAnnotations && hasRiverpod;
    final hasGoRouterBuilder = packages.any((p) => p.name == 'go_router_builder');
    // go_router_builder requires go_router — treat it as selected even if the
    // user didn't explicitly add go_router as a standalone package.
    final hasGoRouter = packages.any((p) => p.name == 'go_router') || hasGoRouterBuilder;
    final hasFlexColorScheme = packages.any((p) => p.name == 'flex_color_scheme');
    final hasEnvied = packages.any((p) => p.name == 'envied');
    final hasFreezed = packages.any((p) => p.name == 'freezed');
    final hasJsonSerializable = packages.any((p) => p.name == 'json_serializable');
    final hasRetrofit = packages.any((p) => p.name == 'retrofit');
    final hasChopper = packages.any((p) => p.name == 'chopper');
    final hasDio = packages.any((p) => p.name == 'dio');
    final hasHttpClient = hasRetrofit || hasChopper || hasDio;
    final httpClient = hasRetrofit
        ? 'retrofit'
        : hasChopper
        ? 'chopper'
        : hasDio
        ? 'dio'
        : '';
    // The package name is the app name; the first feature is named separately
    // in the Architecture step (defaults to "home") — avoids features/<app_name>.
    final featureName = architecture.firstFeatureName;
    final packageName = identity.name;

    // flutter_screenutil is added by default, except for web-only projects
    // (responsive sizing there is handled differently).
    final isWebOnly =
        identity.targetPlatforms.length == 1 && identity.targetPlatforms.first == 'web';
    final useScreenUtil = !isWebOnly;
    // Web among targets → bootstrap uses usePathUrlStrategy().
    final isWeb = identity.targetPlatforms.contains('web');

    // Offline-first turns the project into a Dart workspace with a dedicated
    // local-storage package (Drift). null when remote-only.
    final offlineFirst = architecture.storageStrategy.isOfflineFirst;
    final localStoragePackage = offlineFirst ? '${packageName}_local_storage' : null;
    // Sync strategy adds the Outbox table + SyncService + repository write path.
    final hasSync = architecture.storageStrategy.hasSync;

    // 2. Scaffold Clean Architecture directories + files
    onLog('[▶] Scaffolding Clean Architecture...');
    await _buildScaffold(
      projectDir: projectDir,
      architecture: architecture,
      packages: packages,
      featureName: featureName,
      packageName: packageName,
      hasRiverpod: hasRiverpod,
      hasBloc: hasBloc,
      useCubit: useCubit,
      useAnnotations: useAnnotations,
      hasGoRouter: hasGoRouter,
      hasGoRouterBuilder: hasGoRouterBuilder,
      hasFlexColorScheme: hasFlexColorScheme,
      hasHttpClient: hasHttpClient,
      httpClient: httpClient,
      hasFreezed: hasFreezed,
      hasJsonSerializable: hasJsonSerializable,
      useScreenUtil: useScreenUtil,
      hasEnvied: hasEnvied,
      theme: theme,
      localStoragePackage: localStoragePackage,
      hasSync: hasSync,
      isWeb: isWeb,
    );
    onLog('[✓] Scaffold created.');

    // 2b. Offline-first workspace package
    if (localStoragePackage != null) {
      onLog('[▶] Creating offline-first workspace package...');
      await _writeLocalStoragePackage(
        projectDir,
        localStoragePackage,
        featureName: featureName,
        hasSync: hasSync,
      );
      onLog('[✓] packages/$localStoragePackage created.');
    }

    // 3. pubspec.yaml
    onLog('[▶] Configuring pubspec.yaml...');
    await _writePubspec(
      projectDir,
      packages,
      withWidgetbook: theme.generateWidgetbook,
      addScreenUtil: useScreenUtil,
      localStoragePackage: localStoragePackage,
    );
    onLog('[✓] Dependencies added to pubspec.yaml.');

    // 4. CI/CD files
    if (cicd.selectedTools.isNotEmpty) {
      onLog('[▶] Generating CI/CD configuration files...');
      await _writeCicdFiles(projectDir, cicd);
      onLog('[✓] CI/CD files written.');
    }

    // 5. flutter pub get — with automatic conflict recovery
    onLog("[▶] Running 'flutter pub get'...");
    await _pubGet(projectDir, flutter, onLog);

    // 6. build_runner — only if code-gen packages are present
    // (envied always needs it; we auto-injected the dev dep above).
    final hasBuildRunner = packages.any((p) => p.name == 'build_runner') || hasEnvied;
    if (hasBuildRunner) {
      onLog(
        "[▶] Running 'dart run build_runner build' (may fail on first run due to version resolution)...",
      );
      await _runBuildRunner(projectDir, onLog);
    }

    // In a workspace, build_runner runs per-package — the Drift package has its
    // own codegen (database.g.dart) that the root build does not produce.
    if (localStoragePackage != null) {
      onLog('[▶] Running build_runner in packages/$localStoragePackage (Drift)...');
      await _runBuildRunner(
        Directory('${projectDir.path}/packages/$localStoragePackage'),
        onLog,
      );
    }

    // 7. dart format — guarantees clean, consistent formatting on all output
    onLog('[▶] Formatting generated code...');
    await _dartFormat(projectDir, onLog);

    onLog('');
    onLog('[✓✓] Project successfully generated at ${projectDir.path}');
  }

  Future<void> _dartFormat(Directory projectDir, void Function(String) onLog) async {
    try {
      final result = await Process.run('dart', ['format', '.'], workingDirectory: projectDir.path);
      if (result.exitCode == 0) {
        onLog('[✓] Code formatted.');
      } else {
        onLog('[!] dart format skipped: ${result.stderr.toString().trim()}');
      }
    } catch (e) {
      onLog('[!] dart format skipped: $e');
    }
  }

  // ── Scaffold ──────────────────────────────────────────────────────────────

  Future<void> _buildScaffold({
    required Directory projectDir,
    required ArchitectureState architecture,
    required List<PubPackage> packages,
    required String featureName,
    required String packageName,
    required bool hasRiverpod,
    required bool hasBloc,
    required bool useCubit,
    required bool useAnnotations,
    required bool hasGoRouter,
    required bool hasGoRouterBuilder,
    required bool hasFlexColorScheme,
    required bool hasHttpClient,
    required String httpClient,
    required bool hasFreezed,
    required bool hasJsonSerializable,
    required bool useScreenUtil,
    required bool hasEnvied,
    required ThemeEngineState theme,
    String? localStoragePackage,
    bool hasSync = false,
    bool isWeb = false,
  }) async {
    final lib = '${projectDir.path}/lib';

    // ── main.dart + bootstrap ───────────────────────────────────────────────
    await _write(
      '$lib/main.dart',
      AppTemplates.mainDart(packages, packageName: packageName, useEnvied: hasEnvied),
    );
    await _write(
      '$lib/core/bootstrap.dart',
      AppTemplates.bootstrap(
        packageName: packageName,
        hasRiverpod: hasRiverpod,
        useAnnotations: useAnnotations,
        useEnvied: hasEnvied,
        isWeb: isWeb,
      ),
    );

    // ── core/env (envied flavors) ───────────────────────────────────────────
    if (hasEnvied) {
      await _writeEnv(projectDir, lib, packageName);
    }

    // ── app.dart ──────────────────────────────────────────────────────────
    await _write(
      '$lib/app.dart',
      AppTemplates.appDart(
        name: featureName,
        hasGoRouter: hasGoRouter,
        hasRiverpod: hasRiverpod,
        useAnnotations: useAnnotations,
        hasBloc: hasBloc,
        useCubit: useCubit,
        useScreenUtil: useScreenUtil,
        // appRouterProvider only exists with go_router_builder + annotations.
        routerIsProvider: hasGoRouterBuilder && useAnnotations,
      ),
    );

    // ── core/result ───────────────────────────────────────────────────────
    await _write('$lib/core/result/result.dart', CoreDartTemplates.coreResultDart());
    await _write('$lib/core/usecases/use_case.dart', CoreDartTemplates.coreUsecaseDart());

    // ── core/constants ────────────────────────────────────────────────────
    await _write(
      '$lib/core/constants/app_route_path.dart',
      CoreTemplates.appRoutePath(featureName: featureName),
    );

    // ── core/error ────────────────────────────────────────────────────────
    await _write('$lib/core/error/failure.dart', CoreTemplates.failure());

    // ── core/utils ────────────────────────────────────────────────────────
    await _write('$lib/core/utils/extensions.dart', CoreTemplates.extensions());

    // ── core/utils + observers (observability) ──────────────────────────────
    await _write(
      '$lib/core/utils/app_logger.dart',
      CoreTemplates.appLogger(useEnvied: hasEnvied, packageName: packageName),
    );
    await _write(
      '$lib/core/error/error_handler.dart',
      CoreTemplates.errorHandler(packageName: packageName),
    );
    if (hasRiverpod) {
      await _write(
        '$lib/core/observers/provider_observer.dart',
        CoreTemplates.riverpodObserver(packageName: packageName, useAnnotations: useAnnotations),
      );
    }
    // HTTP logging interceptor + a client provider, adapted to the chosen client.
    if (hasHttpClient) {
      await _write(
        '$lib/core/observers/logger_interceptor.dart',
        CoreTemplates.loggerInterceptor(packageName: packageName, httpClient: httpClient),
      );
    }
    final isDioBased = httpClient == 'dio' || httpClient == 'retrofit';
    if (isDioBased && hasRiverpod) {
      await _write(
        '$lib/core/network/dio_provider.dart',
        CoreTemplates.dioProvider(
          packageName: packageName,
          useAnnotations: useAnnotations,
          useEnvied: hasEnvied,
        ),
      );
    }
    if (httpClient == 'chopper' && hasRiverpod) {
      await _write(
        '$lib/core/network/chopper_client_provider.dart',
        CoreTemplates.chopperClientProvider(
          packageName: packageName,
          useAnnotations: useAnnotations,
          useEnvied: hasEnvied,
        ),
      );
    }

    // ── core/network (offline-first) ────────────────────────────────────────
    if (localStoragePackage != null) {
      await _write('$lib/core/network/network_info.dart', CoreTemplates.networkInfo());
    }

    // ── core/sync (offline-first + sync / Outbox) ────────────────────────────
    if (localStoragePackage != null && hasSync) {
      await _write(
        '$lib/core/sync/sync_service.dart',
        CoreTemplates.syncService(
          packageName: packageName,
          localStoragePackage: localStoragePackage,
        ),
      );
    }

    // ── core/theme ────────────────────────────────────────────────────────
    await _writeTheme(
      lib: lib,
      packageName: packageName,
      hasRiverpod: hasRiverpod,
      useAnnotations: useAnnotations,
      hasBloc: hasBloc,
      useCubit: useCubit,
      hasFlexColorScheme: hasFlexColorScheme,
      useScreenUtil: useScreenUtil,
      theme: theme,
    );

    // ── core/router ───────────────────────────────────────────────────────
    if (hasGoRouter) {
      await _writeRouter(
        lib: lib,
        packageName: packageName,
        featureName: featureName,
        hasGoRouterBuilder: hasGoRouterBuilder,
        useAnnotations: useAnnotations,
      );
    }

    // ── components ────────────────────────────────────────────────────────
    await _write('$lib/components/.gitkeep', '');

    // ── feature ───────────────────────────────────────────────────────────
    await _writeFeature(
      lib: lib,
      featureName: featureName,
      packageName: packageName,
      architecture: architecture,
      hasRiverpod: hasRiverpod,
      hasBloc: hasBloc,
      useCubit: useCubit,
      useAnnotations: useAnnotations,
      hasGoRouter: hasGoRouter,
      hasGoRouterBuilder: hasGoRouterBuilder,
      hasHttpClient: hasHttpClient,
      httpClient: httpClient,
      hasFreezed: hasFreezed,
      hasJsonSerializable: hasJsonSerializable,
      localStoragePackage: localStoragePackage,
      hasSync: hasSync,
    );
  }

  // ── Theme files ───────────────────────────────────────────────────────────

  Future<void> _writeTheme({
    required String lib,
    required String packageName,
    required bool hasRiverpod,
    required bool useAnnotations,
    required bool hasBloc,
    required bool useCubit,
    required bool hasFlexColorScheme,
    required bool useScreenUtil,
    required ThemeEngineState theme,
  }) async {
    final t = '$lib/core/theme';

    // constant/
    await _write('$t/constant/constant.dart', ThemeTemplates.constantBarrel());
    await _write(
      '$t/constant/app_color.dart',
      ThemeTemplates.appColor(
        seedHex: theme.seedColorHex,
        accentHex: theme.accentColorHex,
        errorHex: theme.destructiveColorHex,
      ),
    );
    await _write('$t/constant/app_gap.dart', ThemeTemplates.appGap());

    // typography/
    await _write(
      '$t/typography/typography.dart',
      ThemeTemplates.typographyBarrel(packageName: packageName, useScreenUtil: useScreenUtil),
    );
    await _write(
      '$t/typography/font_size.dart',
      ThemeTemplates.fontSize(theme.textStyles, useScreenUtil: useScreenUtil),
    );
    await _write('$t/typography/font_weight.dart', ThemeTemplates.fontWeight(theme.fontFamily));
    await _write('$t/typography/text_style.dart', ThemeTemplates.textStyle(theme.textStyles));

    // app_theme_extensions.dart
    await _write(
      '$t/app_theme_extensions.dart',
      ThemeTemplates.appThemeExtensions(packageName: packageName),
    );

    // app_theme.dart
    final useFlexColorScheme =
        hasFlexColorScheme || theme.approach == ThemeApproach.flexColorScheme;
    await _write(
      '$t/app_theme.dart',
      ThemeTemplates.appThemeForState(
        theme: theme,
        packageName: packageName,
        forceFlex: useFlexColorScheme,
        useScreenUtil: useScreenUtil,
      ),
    );

    // components/ (opt-in design-system components)
    for (final c in theme.components) {
      final content = switch (c) {
        AppComponent.button => ThemeTemplates.appButtonComponent(packageName: packageName),
        AppComponent.card => ThemeTemplates.appCardComponent(packageName: packageName),
        AppComponent.textField => ThemeTemplates.appTextFieldComponent(packageName: packageName),
      };
      await _write('$lib/components/${c.fileName}', content);
    }

    // widgetbook/main.dart (opt-in catalog, lives outside lib/)
    if (theme.generateWidgetbook) {
      final projectRoot = lib.substring(0, lib.length - '/lib'.length);
      await _write(
        '$projectRoot/widgetbook/main.dart',
        ThemeTemplates.widgetbookApp(packageName: packageName, components: theme.components),
      );
    }

    // theme mode controller
    if (hasRiverpod) {
      await _write(
        '$t/theme_mode_controller.dart',
        useAnnotations
            ? ThemeTemplates.themeModeControllerRiverpod(packageName: packageName)
            : ThemeTemplates.themeModeControllerRiverpodManual(),
      );
    }

    if (hasBloc || useCubit) {
      if (useCubit) {
        await _write('$t/brightness_theme/brightness_cubit.dart', ThemeTemplates.brightnessCubit());
        await _write(
          '$t/brightness_theme/brightness_state.dart',
          ThemeTemplates.brightnessCubitState(),
        );
      } else {
        await _write('$t/brightness_theme/brightness_bloc.dart', ThemeTemplates.brightnessBloc());
        await _write(
          '$t/brightness_theme/brightness_event.dart',
          ThemeTemplates.brightnessBlocEvent(),
        );
        await _write(
          '$t/brightness_theme/brightness_state.dart',
          ThemeTemplates.brightnessBlocState(),
        );
      }
    }
  }

  // ── Router files ──────────────────────────────────────────────────────────

  // ── envied environment system ───────────────────────────────────────────

  Future<void> _writeEnv(Directory projectDir, String lib, String packageName) async {
    const flavors = ['dev', 'staging', 'prod'];

    // Dart: contract + per-flavor envied classes.
    await _write('$lib/core/env/app_env.dart', CoreTemplates.appEnv());
    for (final flavor in flavors) {
      await _write(
        '$lib/core/env/envs/${flavor}_env.dart',
        CoreTemplates.flavorEnv(packageName: packageName, flavor: flavor),
      );
    }

    // .env files (must exist before build_runner so envied can read them).
    for (final flavor in flavors) {
      await _write('${projectDir.path}/.env.$flavor', CoreTemplates.envFile(appName: packageName));
    }
    await _write('${projectDir.path}/.env.example', CoreTemplates.envFile(appName: packageName));

    // Keep secrets out of git (but commit .env.example).
    await _appendGitignore(projectDir, '''

# Environment files (envied) — keep only .env.example
.env
.env.*
!.env.example
''');
  }

  Future<void> _appendGitignore(Directory projectDir, String content) async {
    final file = File('${projectDir.path}/.gitignore');
    if (file.existsSync()) {
      await file.writeAsString(content, mode: FileMode.append);
    } else {
      await file.writeAsString(content.trimLeft());
    }
  }

  Future<void> _writeRouter({
    required String lib,
    required String packageName,
    required String featureName,
    required bool hasGoRouterBuilder,
    required bool useAnnotations,
  }) async {
    final r = '$lib/core/router';

    if (hasGoRouterBuilder) {
      await _write(
        '$r/app_router.dart',
        CoreTemplates.appRouterBuilder(
          packageName: packageName,
          featureName: featureName,
          useAnnotations: useAnnotations,
        ),
      );
      await _write(
        '$r/routes.dart',
        CoreTemplates.routesAggregator(packageName: packageName, featureName: featureName),
      );
    } else {
      await _write(
        '$r/app_router.dart',
        CoreTemplates.appRouter(packageName: packageName, featureName: featureName),
      );
      await _write(
        '$r/routes.dart',
        CoreTemplates.routesManual(packageName: packageName, featureName: featureName),
      );
    }
  }

  // ── Feature files ─────────────────────────────────────────────────────────

  Future<void> _writeFeature({
    required String lib,
    required String featureName,
    required String packageName,
    required ArchitectureState architecture,
    required bool hasRiverpod,
    required bool hasBloc,
    required bool useCubit,
    required bool useAnnotations,
    required bool hasGoRouter,
    required bool hasGoRouterBuilder,
    required bool hasHttpClient,
    required String httpClient,
    required bool hasFreezed,
    required bool hasJsonSerializable,
    String? localStoragePackage,
    bool hasSync = false,
  }) async {
    final isFeatureFirst = architecture.pattern == StructuralPattern.featureFirst;
    final offlineFirst = localStoragePackage != null;

    String domainBase;
    String dataBase;
    String presentationBase;

    if (isFeatureFirst) {
      domainBase = '$lib/features/$featureName/domain';
      dataBase = '$lib/features/$featureName/data';
      presentationBase = '$lib/features/$featureName/presentation';
    } else {
      domainBase = '$lib/domain/$featureName';
      dataBase = '$lib/data/$featureName';
      presentationBase = '$lib/presentation/$featureName';
    }

    // domain/entities
    await _write(
      '$domainBase/entities/${featureName}_entity.dart',
      DomainTemplates.featureEntity(featureName: featureName, hasFreezed: hasFreezed),
    );

    // domain/repositories
    await _write(
      '$domainBase/repositories/i_${featureName}_repository.dart',
      DomainTemplates.featureIRepository(
        featureName: featureName,
        packageName: packageName,
        hasHttpClient: hasHttpClient,
      ),
    );

    // domain/usecases
    await _write(
      '$domainBase/usecases/get_${featureName}_usecase.dart',
      DomainTemplates.featureGetUsecase(featureName: featureName, packageName: packageName),
    );
    // CRUD write usecases require a remote source.
    if (hasHttpClient) {
      await _write(
        '$domainBase/usecases/${featureName}_crud_usecases.dart',
        DomainTemplates.featureCrudUsecases(featureName: featureName, packageName: packageName),
      );
    }

    // data/models
    await _write(
      '$dataBase/models/${featureName}_model.dart',
      DataTemplates.featureModel(
        featureName: featureName,
        packageName: packageName,
        hasFreezed: hasFreezed,
        hasJsonSerializable: hasJsonSerializable,
      ),
    );

    // data/repositories
    await _write(
      '$dataBase/repositories/${featureName}_repository_impl.dart',
      DataTemplates.featureRepositoryImpl(
        featureName: featureName,
        packageName: packageName,
        hasHttpClient: hasHttpClient,
        httpClient: httpClient,
        offlineFirst: offlineFirst,
        hasSync: hasSync,
      ),
    );

    // data/sources
    if (hasHttpClient) {
      await _write(
        '$dataBase/sources/${featureName}_api_source.dart',
        DataTemplates.featureApiSource(
          featureName: featureName,
          packageName: packageName,
          httpClient: httpClient,
        ),
      );
    }
    await _write(
      '$dataBase/sources/${featureName}_local_source.dart',
      DataTemplates.featureLocalSource(
        featureName: featureName,
        packageName: packageName,
        offlineFirst: offlineFirst,
        hasSync: hasSync,
        localStoragePackage: localStoragePackage,
      ),
    );

    // presentation/pages
    await _write(
      '$presentationBase/pages/${featureName}_page.dart',
      PresentationTemplates.featurePage(
        featureName: featureName,
        packageName: packageName,
        hasRiverpod: hasRiverpod,
        useAnnotations: useAnnotations,
        hasBloc: hasBloc,
        useCubit: useCubit,
      ),
    );

    // presentation/providers or bloc/cubit
    if (hasRiverpod) {
      await _write(
        '$presentationBase/providers/${featureName}_provider.dart',
        PresentationTemplates.featureProvider(
          featureName: featureName,
          useAnnotations: useAnnotations,
          useCubit: false,
        ),
      );
      // Ready-to-use DI graph: API source → repository → usecases, wired to the
      // core dio/chopper provider (so API_BASE_URL flows in). Needs annotations.
      if (useAnnotations && hasHttpClient) {
        await _write(
          '$presentationBase/providers/${featureName}_providers.dart',
          PresentationTemplates.featureDi(
            featureName: featureName,
            packageName: packageName,
            httpClient: httpClient,
            offlineFirst: offlineFirst,
            hasSync: hasSync,
            localStoragePackage: localStoragePackage,
          ),
        );
      }
    } else if (useCubit) {
      await _write(
        '$presentationBase/cubit/${featureName}_cubit.dart',
        StateTemplates.featureCubit(featureName: featureName),
      );
      await _write(
        '$presentationBase/cubit/${featureName}_state.dart',
        StateTemplates.featureCubitState(featureName: featureName),
      );
    } else if (hasBloc) {
      await _write(
        '$presentationBase/bloc/${featureName}_bloc.dart',
        StateTemplates.featureBloc(featureName: featureName),
      );
      await _write(
        '$presentationBase/bloc/${featureName}_event.dart',
        StateTemplates.featureBlocEvent(featureName: featureName),
      );
      await _write(
        '$presentationBase/bloc/${featureName}_state.dart',
        StateTemplates.featureBlocState(featureName: featureName),
      );
    }

    // presentation/routes
    if (hasGoRouterBuilder) {
      // Typed go_router_builder routes, aggregated in core/router/routes.dart.
      await _write(
        '$presentationBase/routes/${featureName}_routes.dart',
        CoreTemplates.featureRoutes(packageName: packageName, featureName: featureName),
      );
    } else if (hasGoRouter) {
      await _write(
        '$presentationBase/routes/${featureName}_route.dart',
        PresentationTemplates.featureRoute(
          featureName: featureName,
          packageName: packageName,
          useBuilder: false,
        ),
      );
    }

    // presentation/widgets
    await _write('$presentationBase/widgets/.gitkeep', '');

    // Mirror test structure
    if (architecture.mirrorTestStructure) {
      final testDomainBase = domainBase.replaceFirst('/lib/', '/test/');
      final testDataBase = dataBase.replaceFirst('/lib/', '/test/');
      final testPresentationBase = presentationBase.replaceFirst('/lib/', '/test/');
      await _write('$testDomainBase/.gitkeep', '');
      await _write('$testDataBase/.gitkeep', '');
      await _write('$testPresentationBase/.gitkeep', '');
    }
  }

  // ── File writer ───────────────────────────────────────────────────────────

  Future<void> _write(String path, String content) async {
    final file = File(path);
    await file.create(recursive: true);
    await file.writeAsString(content);
  }

  // ── pub get ───────────────────────────────────────────────────────────────

  Future<void> _pubGet(Directory projectDir, String flutter, void Function(String) onLog) async {
    final result = await Process.run(flutter, ['pub', 'get'], workingDirectory: projectDir.path);

    if (result.exitCode != 0) {
      throw Exception(result.stderr.toString().trim());
    }

    onLog('[✓] Dependencies installed.');
  }

  // ── build_runner ──────────────────────────────────────────────────────────

  Future<void> _runBuildRunner(Directory projectDir, void Function(String) onLog) async {
    final result = await Process.run(
      'dart',
      ['run', 'build_runner', 'build', '--delete-conflicting-outputs'],
      workingDirectory: projectDir.path,
      environment: {
        ...Platform.environment,
        'PATH': '${Platform.environment['PATH']}:/usr/local/bin:/opt/homebrew/bin',
      },
    );

    if (result.stdout.toString().trim().isNotEmpty) {
      onLog(result.stdout.toString().trim());
    }

    if (result.exitCode != 0) {
      final stderr = result.stderr.toString().trim();
      if (stderr.isNotEmpty) onLog('[⚠] $stderr');
      onLog('[⚠] build_runner failed — likely a version conflict (analyzer/dart_style).');
      onLog('[ℹ] Run manually once pub resolution stabilises:');
      onLog('    dart run build_runner build --delete-conflicting-outputs');
      return;
    }

    onLog('[✓] Code generation complete.');
  }

  // ── pubspec.yaml ──────────────────────────────────────────────────────────

  Future<void> _writePubspec(
    Directory projectDir,
    List<PubPackage> packages, {
    bool withWidgetbook = false,
    bool addScreenUtil = true,
    String? localStoragePackage,
  }) async {
    final pubspecFile = File('${projectDir.path}/pubspec.yaml');
    if (!pubspecFile.existsSync()) return;

    final original = await pubspecFile.readAsString();
    final content = buildPubspecContent(
      original,
      packages,
      withWidgetbook: withWidgetbook,
      addScreenUtil: addScreenUtil,
      localStoragePackage: localStoragePackage,
    );

    await pubspecFile.writeAsString(content);
  }

  // ── Offline-first workspace package ─────────────────────────────────────────

  /// Writes the minimal `packages/<name>_local_storage` workspace member.
  /// (Phase 1: compiles & is wired into the workspace; Drift lands in Phase 2.)
  Future<void> _writeLocalStoragePackage(
    Directory projectDir,
    String localStoragePackage, {
    required String featureName,
    bool hasSync = false,
  }) async {
    final root = '${projectDir.path}/packages/$localStoragePackage';
    await _write(
      '$root/pubspec.yaml',
      LocalStorageTemplates.packagePubspec(packageName: localStoragePackage),
    );
    await _write(
      '$root/lib/$localStoragePackage.dart',
      LocalStorageTemplates.publicApi(packageName: localStoragePackage),
    );
    await _write(
      '$root/lib/src/database.dart',
      LocalStorageTemplates.database(featureName: featureName, withOutbox: hasSync),
    );
  }

  /// Pure pubspec assembly: takes the `flutter create` pubspec [original] and
  /// returns it with all selected + auto-injected dependencies merged in.
  ///
  /// Extracted from [_writePubspec] so it can be unit-tested without touching
  /// the filesystem — guards against malformed-YAML regressions.
  @visibleForTesting
  static String buildPubspecContent(
    String original,
    List<PubPackage> packages, {
    bool withWidgetbook = false,
    bool addScreenUtil = true,
    String? localStoragePackage,
  }) {
    final deps = StringBuffer();
    final devDeps = StringBuffer();

    // Deduplicate by name — keepAlive state can accumulate duplicates across
    // multiple generation runs if the user applies a preset on a non-empty list.
    final seen = <String>{};
    final uniquePackages = packages.where((p) => seen.add(p.name)).toList();

    final hasGoRouterBuilder = uniquePackages.any((p) => p.name == 'go_router_builder');
    final hasGoRouterExplicit = uniquePackages.any((p) => p.name == 'go_router');

    for (final pkg in uniquePackages) {
      final line = '  ${pkg.name}: ^${pkg.version}\n';
      if (pkg.isDev) {
        devDeps.write(line);
      } else {
        deps.write(line);
      }
    }

    // go_router_builder is a dev dep but requires go_router as a runtime dep.
    // Auto-inject it when missing so the generated code compiles out of the box.
    if (hasGoRouterBuilder && !hasGoRouterExplicit) {
      deps.write('  go_router: ^17.2.3\n');
    }

    // The generated typography uses google_fonts to apply the chosen font
    // family at runtime — inject it unless the user already added it.
    if (!uniquePackages.any((p) => p.name == 'google_fonts')) {
      deps.write('  google_fonts: ^8.1.0\n');
    }

    // AppLogger (observability) is always generated — inject the logger package.
    if (!uniquePackages.any((p) => p.name == 'logger')) {
      deps.write('  logger: ^2.7.0\n');
    }

    // Responsive sizing — added by default, skipped for web-only projects.
    if (addScreenUtil && !uniquePackages.any((p) => p.name == 'flutter_screenutil')) {
      deps.write('  flutter_screenutil: ^5.9.3\n');
    }

    // Widgetbook catalog (dev-only) when opted in.
    if (withWidgetbook && !uniquePackages.any((p) => p.name == 'widgetbook')) {
      devDeps.write('  widgetbook: ^3.7.0\n');
    }

    // envied needs its generator (+ build_runner) to produce the .g.dart files.
    if (uniquePackages.any((p) => p.name == 'envied')) {
      if (!uniquePackages.any((p) => p.name == 'envied_generator')) {
        devDeps.write('  envied_generator: ^1.1.1\n');
      }
      if (!uniquePackages.any((p) => p.name == 'build_runner')) {
        devDeps.write('  build_runner: ^2.4.13\n');
      }
    }

    // Offline-first → the app path-depends on the workspace local-storage
    // package and needs connectivity_plus for the NetworkInfo brick.
    if (localStoragePackage != null) {
      if (!uniquePackages.any((p) => p.name == 'connectivity_plus')) {
        deps.write('  connectivity_plus: ^7.1.1\n');
      }
      deps.write('  $localStoragePackage:\n    path: packages/$localStoragePackage\n');
    }

    var content = original;

    if (deps.isNotEmpty) {
      content = content.replaceFirst(
        'dependencies:\n  flutter:\n    sdk: flutter',
        'dependencies:\n  flutter:\n    sdk: flutter\n$deps',
      );
    }
    if (devDeps.isNotEmpty) {
      content = content.replaceFirst(
        'dev_dependencies:\n  flutter_test:\n    sdk: flutter',
        'dev_dependencies:\n  flutter_test:\n    sdk: flutter\n$devDeps',
      );
    }

    // Declare the Dart workspace at the root (app = workspace root). Members
    // live under packages/ and each carries `resolution: workspace`.
    if (localStoragePackage != null) {
      content = '${content.trimRight()}\n\nworkspace:\n  - packages/$localStoragePackage\n';
    }

    return content;
  }

  // ── CI/CD files ───────────────────────────────────────────────────────────

  Future<void> _writeCicdFiles(Directory projectDir, CicdState cicd) async {
    final generated = const GenerateYamlUsecase().execute(cicd);

    for (final file in generated) {
      final f = File('${projectDir.path}/${file.filename}');
      await f.create(recursive: true);
      await f.writeAsString(file.content);
    }
  }

  // ── Flutter binary resolution ─────────────────────────────────────────────

  Future<String> _resolveFlutter() async {
    final candidates = [
      '/usr/local/bin/flutter',
      '/opt/homebrew/bin/flutter',
      '${Platform.environment['HOME']}/develop/flutter/bin/flutter',
      '${Platform.environment['HOME']}/flutter/bin/flutter',
      '${Platform.environment['HOME']}/fvm/default/bin/flutter',
      '${Platform.environment['HOME']}/.pub-cache/bin/flutter',
    ];

    for (final path in candidates) {
      if (File(path).existsSync()) return path;
    }

    final which = await Process.run(
      'which',
      ['flutter'],
      environment: {
        ...Platform.environment,
        'PATH': '${Platform.environment['PATH']}:/usr/local/bin:/opt/homebrew/bin',
      },
    );
    final resolved = which.stdout.toString().trim();
    if (resolved.isNotEmpty && File(resolved).existsSync()) return resolved;

    throw Exception(
      'Flutter SDK not found. Add it to PATH or install it at ~/flutter or ~/develop/flutter.',
    );
  }
}
