import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:neat/core/contract/neat_contract.dart';
import 'package:neat/features/architecture/domain/models/architecture_state.dart';
import 'package:neat/features/cicd/domain/models/cicd_state.dart';
import 'package:neat/features/cicd/domain/usecases/generate_yaml_usecase.dart';
import 'package:neat/features/dependencies/domain/models/pub_package.dart';
import 'package:neat/features/generation/domain/services/feature_scaffolder.dart';
import 'package:neat/features/generation/domain/services/templates/agents_md_template.dart';
import 'package:neat/features/generation/domain/services/templates/config_templates.dart';
import 'package:neat/features/generation/domain/services/templates/core_templates.dart';
import 'package:neat/features/generation/domain/services/templates/dart/app_templates.dart';
import 'package:neat/features/generation/domain/services/templates/dart/auth_templates.dart';
import 'package:neat/features/generation/domain/services/templates/dart/core_dart_templates.dart';
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
    // Supabase / Firebase are *backends* (SDKs) that play the same role as a
    // REST client: they back the feature's remote source. They take precedence.
    final hasSupabase = packages.any((p) => p.name == 'supabase_flutter');
    final hasFirebase = packages.any((p) => p.name == 'cloud_firestore');
    final hasHttpClient =
        hasRetrofit || hasChopper || hasDio || hasSupabase || hasFirebase;
    final httpClient = hasFirebase
        ? 'firebase'
        : hasSupabase
        ? 'supabase'
        : hasRetrofit
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

    // The backend (Supabase or Firebase) drives the opt-in capabilities below.
    final hasBackend = httpClient == 'supabase' || httpClient == 'firebase';

    // Opt-in auth (login/signup/forgot + go_router guard). Requires the typed
    // router (a riverpod-provider GoRouter) to wire the guard.
    final hasAuth = architecture.generateAuth &&
        hasBackend &&
        hasGoRouterBuilder &&
        useAnnotations;

    // Opt-in Realtime: the first feature's list screen becomes live (a
    // StreamNotifier over `.stream()` / Firestore `.snapshots()`). Needs the
    // full DI graph (annotations).
    final hasRealtime = architecture.generateRealtime && hasBackend && useAnnotations;

    // Opt-in Storage: a StorageService (+ provider + sample avatar upload
    // widget). Needs riverpod for the provider + the backend client.
    final hasStorage = architecture.generateStorage && hasBackend && hasRiverpod;

    // Opt-in OAuth (Google + Apple) on the auth feature, via Firebase's
    // signInWithProvider. Requires the auth feature on a Firebase backend.
    final hasOAuth = architecture.generateOAuth && hasAuth && httpClient == 'firebase';

    // Offline-first turns the project into a Dart workspace with a dedicated
    // local-storage package (Drift). null when remote-only. Firestore ships its
    // own offline persistence, so a Firebase backend disables the Drift layer
    // (enabled in bootstrap via Settings(persistenceEnabled: true)) to avoid two
    // competing caches.
    final offlineFirst = architecture.storageStrategy.isOfflineFirst && !hasFirebase;
    final localStoragePackage = offlineFirst ? '${packageName}_local_storage' : null;
    // Sync strategy adds the Outbox table + SyncService + repository write path.
    final hasSync = architecture.storageStrategy.hasSync;

    // Opt-in: extract theme + tokens + components into a <app>_ui workspace package.
    final uiPackage = theme.extractUiPackage ? '${packageName}_ui' : null;
    // Widgetbook becomes a workspace member when the UI package is on.
    final widgetbookIsMember = uiPackage != null && theme.generateWidgetbook;
    // App path-deps + workspace members.
    final pathPackages = <String>[
      ?localStoragePackage,
      ?uiPackage,
    ];
    final extraWorkspaceMembers = <String>[if (widgetbookIsMember) 'widgetbook'];

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
      uiPackage: uiPackage,
      hasAuth: hasAuth,
      hasRealtime: hasRealtime,
      hasStorage: hasStorage,
      hasOAuth: hasOAuth,
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

    // Branding: a logo was picked → generate app icons + splash.
    final hasLogo = theme.logoPath.isNotEmpty && File(theme.logoPath).existsSync();

    // 3. pubspec.yaml
    onLog('[▶] Configuring pubspec.yaml...');
    await _writePubspec(
      projectDir,
      packages,
      // When widgetbook is its own workspace member, it owns the dep — don't
      // also inject it into the app.
      withWidgetbook: theme.generateWidgetbook && !widgetbookIsMember,
      addScreenUtil: useScreenUtil,
      pathPackages: pathPackages,
      extraWorkspaceMembers: extraWorkspaceMembers,
      addConnectivity: offlineFirst,
      // The first feature gets a real list screen (Skeletonizer) when it has the
      // DI graph: annotations + a remote source.
      addSkeletonizer: useAnnotations && hasHttpClient,
      addBranding: hasLogo,
      addImagePicker: hasStorage,
      addFirebaseCore: httpClient == 'firebase',
      addFirebaseAuth: hasAuth && httpClient == 'firebase',
      addFirebaseStorage: hasStorage && httpClient == 'firebase',
    );
    onLog('[✓] Dependencies added to pubspec.yaml.');

    // 3b. Branding files: copy the logo + write the icon/splash configs.
    if (hasLogo) {
      onLog('[▶] Setting up branding (icons + splash)...');
      await _writeBranding(projectDir, theme.logoPath);
    }

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

    // 6b. Branding tools — generate app icons + native splash from the logo.
    // Best-effort: a failure (e.g. missing native folders) never breaks the run.
    if (hasLogo) {
      onLog('[▶] Generating app icons + splash...');
      await _runBrandingTools(projectDir, flutter, onLog);
    }

    // 7. dart format — guarantees clean, consistent formatting on all output
    onLog('[▶] Formatting generated code...');
    await _dartFormat(projectDir, onLog);

    // 8. .neat.json — the Workspace Contract (stack fingerprint) for feature gen.
    final contract = NeatContract(
      projectName: packageName,
      architecture: architecture.pattern == StructuralPattern.featureFirst
          ? 'feature_first'
          : 'layer_first',
      stateManagement: hasRiverpod
          ? 'riverpod'
          : hasBloc
          ? 'bloc'
          : 'none',
      useRiverpodAnnotations: useAnnotations,
      navigation: hasGoRouterBuilder
          ? 'go_router_builder'
          : hasGoRouter
          ? 'go_router'
          : 'none',
      httpClient: hasHttpClient ? httpClient : 'none',
      themeApproach: theme.approach.name,
      storageStrategy: architecture.storageStrategy.name,
      extractUiPackage: theme.extractUiPackage,
      useScreenUtil: useScreenUtil,
      hasEnvied: hasEnvied,
      hasFreezed: hasFreezed,
      hasJsonSerializable: hasJsonSerializable,
      includeMappers: architecture.includeMappers,
      mirrorTestStructure: architecture.mirrorTestStructure,
      generateWidgetbook: theme.generateWidgetbook,
      generateAuth: hasAuth,
      generateRealtime: hasRealtime,
      generateStorage: hasStorage,
      generateOAuth: hasOAuth,
      useNavigationShell: architecture.useNavigationShell && hasGoRouter,
      components: theme.components.map((c) => c.name).toList(),
    );
    onLog('[▶] Writing .neat.json (Workspace Contract)...');
    await _writeContract(projectDir, contract);
    onLog('[✓] .neat.json written.');

    // 9. AGENTS.md — contract-aware AI rules (accurate to this exact stack).
    onLog('[▶] Writing AGENTS.md (AI agent guide)...');
    await _write('${projectDir.path}/AGENTS.md', AgentsMdTemplate.generate(contract));
    onLog('[✓] AGENTS.md written.');

    onLog('');
    onLog('[✓✓] Project successfully generated at ${projectDir.path}');
  }

  /// Writes the Workspace Contract to `<project>/.neat.json` (pretty-printed).
  Future<void> _writeContract(Directory projectDir, NeatContract contract) async {
    const encoder = JsonEncoder.withIndent('  ');
    await _write('${projectDir.path}/.neat.json', '${encoder.convert(contract.toJson())}\n');
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
    String? uiPackage,
    bool hasAuth = false,
    bool hasRealtime = false,
    bool hasStorage = false,
    bool hasOAuth = false,
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
        hasSupabase: httpClient == 'supabase',
        hasFirebase: httpClient == 'firebase',
      ),
    );

    // ── core/env (envied flavors) ───────────────────────────────────────────
    if (hasEnvied) {
      await _writeEnv(
        projectDir,
        lib,
        packageName,
        hasSupabase: httpClient == 'supabase',
        // No REST base URL for the SDK backends (Firebase config lives in
        // firebase_options.dart; Supabase keys are separate fields).
        hasApiBaseUrl: httpClient != 'supabase' && httpClient != 'firebase',
      );
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
        // When the theme lives in <app>_ui, app.dart imports it from there.
        themePackage: uiPackage,
      ),
    );

    // ── core/result ───────────────────────────────────────────────────────
    await _write('$lib/core/result/result.dart', CoreDartTemplates.coreResultDart());
    await _write('$lib/core/usecases/use_case.dart', CoreDartTemplates.coreUsecaseDart());

    // ── core/constants ────────────────────────────────────────────────────
    await _write(
      '$lib/core/constants/app_route_path.dart',
      CoreTemplates.appRoutePath(featureName: featureName, hasAuth: hasAuth),
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
    // HTTP logging interceptor — REST clients only (Supabase has its own).
    final isRestClient =
        httpClient == 'dio' || httpClient == 'chopper' || httpClient == 'retrofit';
    if (isRestClient) {
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
    if (httpClient == 'supabase' && hasRiverpod) {
      await _write(
        '$lib/core/network/supabase_provider.dart',
        CoreTemplates.supabaseProvider(packageName: packageName, useAnnotations: useAnnotations),
      );
    }

    // ── core/network + firebase_options (Firebase backend) ───────────────────
    if (httpClient == 'firebase' && hasRiverpod) {
      await _write(
        '$lib/core/network/firebase_provider.dart',
        CoreTemplates.firebaseProvider(
          packageName: packageName,
          useAnnotations: useAnnotations,
          hasAuth: hasAuth,
          hasStorage: hasStorage,
        ),
      );
      // firebase_options.dart from the uploaded config JSON (stub values if
      // none was provided — the project still compiles).
      final config = _readFirebaseConfig(architecture.firebaseConfigPath);
      await _write('$lib/firebase_options.dart', CoreTemplates.firebaseOptions(config));
      // A short guide to swap in real per-platform values.
      await _write('${projectDir.path}/docs/FIREBASE.md', CoreTemplates.firebaseDoc(packageName));
      // Firestore Security Rules scaffold + Firebase CLI wiring.
      await _write(
        '${projectDir.path}/firestore.rules',
        CoreTemplates.firestoreRules(featureName: featureName, hasAuth: hasAuth),
      );
      await _write(
          '${projectDir.path}/firestore.indexes.json', CoreTemplates.firestoreIndexes());
      await _write('${projectDir.path}/firebase.json', CoreTemplates.firebaseJson());
    }

    // ── core/storage (Storage, opt-in) ───────────────────────────────────────
    if (hasStorage) {
      await _write(
        '$lib/core/storage/storage_service.dart',
        CoreTemplates.storageService(
          packageName: packageName,
          useAnnotations: useAnnotations,
          backend: httpClient,
        ),
      );
      await _write(
        '$lib/core/storage/avatar_upload_field.dart',
        CoreTemplates.avatarUploadField(packageName: packageName),
      );
    }

    // ── core/network (offline-first) ────────────────────────────────────────
    if (localStoragePackage != null) {
      await _write('$lib/core/network/network_info.dart', CoreTemplates.networkInfo());
    }

    // ── core/providers (shared infrastructure singletons) ────────────────────
    // Drift db + connectivity, declared once for the whole app (not per feature).
    if (localStoragePackage != null && useAnnotations) {
      await _write(
        '$lib/core/providers/infrastructure_providers.dart',
        CoreTemplates.infrastructureProviders(
          packageName: packageName,
          localStoragePackage: localStoragePackage,
        ),
      );
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

    // ── docs/OFFLINE.md (usage guide) ────────────────────────────────────────
    if (localStoragePackage != null) {
      await _write(
        '${projectDir.path}/docs/OFFLINE.md',
        CoreTemplates.offlineDoc(
          packageName: packageName,
          featureName: featureName,
          localStoragePackage: localStoragePackage,
          hasSync: hasSync,
        ),
      );
    }

    // ── core/theme ────────────────────────────────────────────────────────
    final flexMatches = packages.where((p) => p.name == 'flex_color_scheme');
    await _writeTheme(
      projectDir: projectDir,
      lib: lib,
      packageName: packageName,
      hasRiverpod: hasRiverpod,
      useAnnotations: useAnnotations,
      hasBloc: hasBloc,
      useCubit: useCubit,
      hasFlexColorScheme: hasFlexColorScheme,
      useScreenUtil: useScreenUtil,
      theme: theme,
      uiPackage: uiPackage,
      flexVersion: flexMatches.isEmpty ? null : flexMatches.first.version,
    );

    // Bottom-nav shell from launch: the first feature becomes the shell's
    // first branch (so it isn't also a plain top-level route).
    final useShell = architecture.useNavigationShell && hasGoRouter;

    // ── core/router ───────────────────────────────────────────────────────
    if (hasGoRouter) {
      await _writeRouter(
        lib: lib,
        packageName: packageName,
        featureName: featureName,
        hasGoRouterBuilder: hasGoRouterBuilder,
        useAnnotations: useAnnotations,
        useShell: useShell,
        shellIcon: architecture.shellIcon,
        shellLabel: architecture.effectiveShellLabel,
        hasAuth: hasAuth,
      );
    }

    // ── auth feature (opt-in, Supabase + go_router_builder) ──────────────────
    if (hasAuth) {
      await _writeAuth(
        lib: lib,
        packageName: packageName,
        featureName: featureName,
        backend: httpClient,
        oauth: hasOAuth,
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
      isShellBranch: useShell,
      realtime: hasRealtime,
    );
  }

  // ── Theme files ───────────────────────────────────────────────────────────

  Future<void> _writeTheme({
    required Directory projectDir,
    required String lib,
    required String packageName,
    required bool hasRiverpod,
    required bool useAnnotations,
    required bool hasBloc,
    required bool useCubit,
    required bool hasFlexColorScheme,
    required bool useScreenUtil,
    required ThemeEngineState theme,
    String? uiPackage,
    String? flexVersion,
  }) async {
    // When extracted, theme + tokens + components live in packages/<ui>/lib;
    // their imports target <ui> instead of the app. State (theme mode / bloc)
    // always stays in the app.
    final themePkg = uiPackage ?? packageName;
    final themeLib =
        uiPackage != null ? '${projectDir.path}/packages/$uiPackage/lib' : lib;
    final t = '$themeLib/core/theme';

    final useFlexColorScheme =
        hasFlexColorScheme || theme.approach == ThemeApproach.flexColorScheme;

    // constant/
    await _write(
      '$t/constant/constant.dart',
      ThemeTemplates.constantBarrel(useScreenUtil: useScreenUtil),
    );
    await _write(
      '$t/constant/app_color.dart',
      ThemeTemplates.appColor(
        seedHex: theme.seedColorHex,
        accentHex: theme.accentColorHex,
        errorHex: theme.destructiveColorHex,
      ),
    );
    await _write('$t/constant/app_gap.dart', ThemeTemplates.appGap(useScreenUtil: useScreenUtil));

    // typography/
    await _write(
      '$t/typography/typography.dart',
      ThemeTemplates.typographyBarrel(packageName: themePkg, useScreenUtil: useScreenUtil),
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
      ThemeTemplates.appThemeExtensions(packageName: themePkg),
    );

    // app_theme.dart
    await _write(
      '$t/app_theme.dart',
      ThemeTemplates.appThemeForState(
        theme: theme,
        packageName: themePkg,
        forceFlex: useFlexColorScheme,
        useScreenUtil: useScreenUtil,
      ),
    );

    // components/ (opt-in design-system components)
    for (final c in theme.components) {
      final content = switch (c) {
        AppComponent.button => ThemeTemplates.appButtonComponent(packageName: themePkg),
        AppComponent.card => ThemeTemplates.appCardComponent(packageName: themePkg),
        AppComponent.textField => ThemeTemplates.appTextFieldComponent(packageName: themePkg),
      };
      await _write('$themeLib/components/${c.fileName}', content);
    }

    // <app>_ui package scaffolding (pubspec + public barrel).
    if (uiPackage != null) {
      await _writeUiPackage(
        projectDir,
        uiPackage,
        components: theme.components,
        useScreenUtil: useScreenUtil,
        flexVersion: useFlexColorScheme ? flexVersion : null,
        logoPath: theme.logoPath,
      );
    }

    // Widgetbook catalog.
    if (theme.generateWidgetbook) {
      final widgetbookApp =
          ThemeTemplates.widgetbookApp(packageName: themePkg, components: theme.components);
      if (uiPackage != null) {
        // A proper workspace member that depends on <app>_ui.
        await _write('${projectDir.path}/widgetbook/lib/main.dart', widgetbookApp);
        await _write(
          '${projectDir.path}/widgetbook/pubspec.yaml',
          _widgetbookPubspec(packageName, uiPackage),
        );
      } else {
        await _write('${projectDir.path}/widgetbook/main.dart', widgetbookApp);
      }
    }

    // State (theme mode / brightness) ALWAYS stays in the app, never in <ui>.
    final appT = '$lib/core/theme';

    // theme mode controller
    if (hasRiverpod) {
      await _write(
        '$appT/theme_mode_controller.dart',
        useAnnotations
            ? ThemeTemplates.themeModeControllerRiverpod(packageName: packageName)
            : ThemeTemplates.themeModeControllerRiverpodManual(),
      );
    }

    if (hasBloc || useCubit) {
      if (useCubit) {
        await _write(
            '$appT/brightness_theme/brightness_cubit.dart', ThemeTemplates.brightnessCubit());
        await _write(
          '$appT/brightness_theme/brightness_state.dart',
          ThemeTemplates.brightnessCubitState(),
        );
      } else {
        await _write(
            '$appT/brightness_theme/brightness_bloc.dart', ThemeTemplates.brightnessBloc());
        await _write(
          '$appT/brightness_theme/brightness_event.dart',
          ThemeTemplates.brightnessBlocEvent(),
        );
        await _write(
          '$appT/brightness_theme/brightness_state.dart',
          ThemeTemplates.brightnessBlocState(),
        );
      }
    }
  }

  // ── <app>_ui workspace package (theme + tokens + components) ────────────────

  Future<void> _writeUiPackage(
    Directory projectDir,
    String uiPackage, {
    required Set<AppComponent> components,
    required bool useScreenUtil,
    String? flexVersion,
    String logoPath = '',
  }) async {
    final root = '${projectDir.path}/packages/$uiPackage';

    final deps = StringBuffer()
      ..writeln('  flutter:')
      ..writeln('    sdk: flutter')
      ..writeln('  google_fonts: ^8.1.0')
      ..writeln('  flutter_svg: ^2.0.16');
    if (useScreenUtil) deps.writeln('  flutter_screenutil: ^5.9.3');
    if (flexVersion != null) deps.writeln('  flex_color_scheme: ^$flexVersion');

    await _write('$root/pubspec.yaml', '''name: $uiPackage
description: "Design system (theme, tokens, components) — generated by NEAT."
version: 0.1.0
publish_to: 'none'

environment:
  sdk: ^3.6.0

resolution: workspace

dependencies:
${deps.toString().trimRight()}

dev_dependencies:
  flutter_lints: ^6.0.0
  spider: ^4.2.3

flutter:
  # Branding assets shipped inside the package, rendered via SvgPictureCustom /
  # ImagePictureCustom (loaded with package: '$uiPackage').
  assets:
    - assets/
''');

    // Shared SVG/image widgets + an assets folder for branding.
    await _write('$root/lib/widgets/asset_images.dart',
        ThemeTemplates.assetWidgets(packageName: uiPackage));
    await _write('$root/assets/.gitkeep', '');

    // A displayable copy of the logo + typed asset paths (spider-compatible).
    final hasLogo = logoPath.isNotEmpty && File(logoPath).existsSync();
    if (hasLogo) {
      final dest = File('$root/assets/branding/logo.png');
      await dest.create(recursive: true);
      await dest.writeAsBytes(await File(logoPath).readAsBytes());
    }
    await _write('$root/spider.yaml', ThemeTemplates.spiderConfig());
    await _write('$root/lib/gen/assets.dart', ThemeTemplates.assetsClass(hasLogo: hasLogo));

    // Public barrel.
    final exports = StringBuffer()
      ..writeln("export 'core/theme/app_theme.dart';")
      ..writeln("export 'core/theme/constant/constant.dart';")
      ..writeln("export 'core/theme/typography/typography.dart';")
      ..writeln("export 'widgets/asset_images.dart';")
      ..writeln("export 'gen/assets.dart';");
    for (final c in components) {
      exports.writeln("export 'components/${c.fileName}';");
    }
    await _write('$root/lib/$uiPackage.dart', '''/// Public API of the $uiPackage design system.
library;

${exports.toString().trimRight()}
''');
  }

  /// pubspec for the standalone Widgetbook workspace member (depends on `<ui>`).
  /// Named `<app>_widgetbook` — it can't be called `widgetbook` since it depends
  /// on the `widgetbook` package.
  String _widgetbookPubspec(String packageName, String uiPackage) => '''name: ${packageName}_widgetbook
description: "Interactive component catalog — generated by NEAT."
version: 0.1.0
publish_to: 'none'

environment:
  sdk: ^3.6.0

resolution: workspace

dependencies:
  flutter:
    sdk: flutter
  widgetbook: ^3.7.0
  $uiPackage:
    path: ../packages/$uiPackage

dev_dependencies:
  flutter_lints: ^6.0.0
''';

  // ── Router files ──────────────────────────────────────────────────────────

  // ── envied environment system ───────────────────────────────────────────

  Future<void> _writeEnv(
    Directory projectDir,
    String lib,
    String packageName, {
    bool hasSupabase = false,
    bool hasApiBaseUrl = true,
  }) async {
    const flavors = ['dev', 'staging', 'prod'];

    // Dart: contract + per-flavor envied classes.
    await _write('$lib/core/env/app_env.dart',
        CoreTemplates.appEnv(hasApiBaseUrl: hasApiBaseUrl, hasSupabase: hasSupabase));
    for (final flavor in flavors) {
      await _write(
        '$lib/core/env/envs/${flavor}_env.dart',
        CoreTemplates.flavorEnv(
          packageName: packageName,
          flavor: flavor,
          hasApiBaseUrl: hasApiBaseUrl,
          hasSupabase: hasSupabase,
        ),
      );
    }

    // .env files (must exist before build_runner so envied can read them).
    for (final flavor in flavors) {
      await _write('${projectDir.path}/.env.$flavor',
          CoreTemplates.envFile(appName: packageName, hasApiBaseUrl: hasApiBaseUrl, hasSupabase: hasSupabase));
    }
    await _write('${projectDir.path}/.env.example',
        CoreTemplates.envFile(appName: packageName, hasApiBaseUrl: hasApiBaseUrl, hasSupabase: hasSupabase));

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

  // ── auth feature (opt-in: Supabase + go_router_builder + riverpod) ──────────

  Future<void> _writeAuth({
    required String lib,
    required String packageName,
    required String featureName,
    String backend = 'supabase',
    bool oauth = false,
  }) async {
    final a = '$lib/features/auth';
    await _write('$a/domain/repositories/i_auth_repository.dart',
        AuthTemplates.iAuthRepository(packageName: packageName, oauth: oauth));
    await _write('$a/data/repositories/auth_repository_impl.dart',
        AuthTemplates.authRepositoryImpl(packageName: packageName, backend: backend, oauth: oauth));
    await _write('$a/presentation/providers/auth_provider.dart',
        AuthTemplates.authProvider(packageName: packageName, backend: backend));
    await _write('$a/presentation/providers/auth_providers.dart',
        AuthTemplates.authDi(packageName: packageName, backend: backend));
    await _write('$a/presentation/screens/login_screen.dart',
        AuthTemplates.loginScreen(packageName: packageName, oauth: oauth));
    await _write(
        '$a/presentation/screens/signup_screen.dart', AuthTemplates.signupScreen(packageName: packageName));
    await _write('$a/presentation/screens/forgot_password_screen.dart',
        AuthTemplates.forgotPasswordScreen(packageName: packageName));
    await _write(
        '$a/presentation/routes/auth_routes.dart', AuthTemplates.authRoutesBuilder(packageName: packageName));

    // The go_router guard. Logged-in users on an auth route go to the first
    // feature's route ('/').
    final homeRoute = 'AppRoutePath.${_camelCase(featureName)}';
    await _write('$lib/core/router/router_notifier.dart',
        AuthTemplates.routerNotifier(packageName: packageName, homeRoute: homeRoute, backend: backend));

    // Aggregate the auth routes into the shared route table (at the anchors).
    final routes = File('$lib/core/router/routes.dart');
    if (routes.existsSync()) {
      var s = await routes.readAsString();
      s = _insertBeforeAnchor(s, '// neat:route-imports',
          "import 'package:$packageName/features/auth/presentation/routes/auth_routes.dart' as auth;");
      s = _insertBeforeAnchor(s, '// neat:route-entries', r'  ...auth.$appRoutes,');
      await routes.writeAsString(s);
    }
  }

  /// Inserts [line] before the line containing [anchor]. No-op if absent.
  String _insertBeforeAnchor(String content, String anchor, String line) {
    final idx = content.indexOf(anchor);
    if (idx < 0) return content;
    final lineStart = content.lastIndexOf('\n', idx) + 1;
    return '${content.substring(0, lineStart)}$line\n${content.substring(lineStart)}';
  }

  /// Parses the uploaded Firebase config JSON into a flat map of option keys.
  /// Accepts either the web app config (`{apiKey, projectId, …}`) or a nested
  /// shape that wraps it under common keys. Falls back to placeholder values
  /// (so the project still compiles) when no/invalid file is provided.
  static Map<String, dynamic> _readFirebaseConfig(String path) {
    const fallback = <String, dynamic>{
      'apiKey': 'TODO_API_KEY',
      'appId': 'TODO_APP_ID',
      'messagingSenderId': 'TODO_SENDER_ID',
      'projectId': 'TODO_PROJECT_ID',
    };
    if (path.isEmpty) return fallback;
    final file = File(path);
    if (!file.existsSync()) return fallback;
    try {
      final decoded = jsonDecode(file.readAsStringSync());
      if (decoded is! Map<String, dynamic>) return fallback;
      // Unwrap common nesting (e.g. {"firebase": {...}} or {"web": {...}}).
      Map<String, dynamic> cfg = decoded;
      for (final key in const ['firebaseConfig', 'firebase', 'web', 'result']) {
        final inner = cfg[key];
        if (inner is Map<String, dynamic> && inner.containsKey('apiKey')) {
          cfg = inner;
          break;
        }
      }
      // Keep only string-valued config keys; merge over the fallback so any
      // missing required field still has a compile-safe placeholder.
      final cleaned = <String, dynamic>{...fallback};
      for (final entry in cfg.entries) {
        if (entry.value is String && (entry.value as String).isNotEmpty) {
          cleaned[entry.key] = entry.value;
        }
      }
      return cleaned;
    } catch (_) {
      return fallback;
    }
  }

  static String _camelCase(String s) {
    final parts = s.split('_');
    final pascal = parts.map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1)).join();
    return pascal.isEmpty ? pascal : pascal[0].toLowerCase() + pascal.substring(1);
  }

  Future<void> _writeRouter({
    required String lib,
    required String packageName,
    required String featureName,
    required bool hasGoRouterBuilder,
    required bool useAnnotations,
    bool useShell = false,
    String shellIcon = 'home',
    String shellLabel = '',
    bool hasAuth = false,
  }) async {
    final r = '$lib/core/router';

    // app_router.dart: initialLocation = AppRoutePath.<first> = '/'. With auth a
    // RouterNotifier guard is wired (refreshListenable + redirect).
    await _write(
      '$r/app_router.dart',
      hasGoRouterBuilder
          ? CoreTemplates.appRouterBuilder(
              packageName: packageName,
              featureName: featureName,
              useAnnotations: useAnnotations,
              hasAuth: hasAuth,
            )
          : CoreTemplates.appRouter(packageName: packageName, featureName: featureName),
    );

    if (useShell) {
      // The bottom-nav scaffold + the shell route, with the first feature as
      // branch 0. routes.dart aggregates the shell instead of a flat route.
      await _write(
        '$r/scaffold_with_nav_bar.dart',
        CoreTemplates.scaffoldWithNavBar(firstIcon: shellIcon, firstLabel: shellLabel),
      );
      if (hasGoRouterBuilder) {
        await _write(
          '$r/app_shell_route.dart',
          CoreTemplates.appShellRouteBuilder(packageName: packageName, featureName: featureName),
        );
        await _write('$r/routes.dart', CoreTemplates.routesAggregatorShell(packageName: packageName));
      } else {
        await _write(
          '$r/routes.dart',
          CoreTemplates.routesManualShell(packageName: packageName, featureName: featureName),
        );
      }
      return;
    }

    await _write(
      '$r/routes.dart',
      hasGoRouterBuilder
          ? CoreTemplates.routesAggregator(packageName: packageName, featureName: featureName)
          : CoreTemplates.routesManual(packageName: packageName, featureName: featureName),
    );
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
    bool isShellBranch = false,
    bool realtime = false,
  }) async {
    await const FeatureScaffolder().writeFeature(
      lib: lib,
      featureName: featureName,
      packageName: packageName,
      isFeatureFirst: architecture.pattern == StructuralPattern.featureFirst,
      mirrorTestStructure: architecture.mirrorTestStructure,
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
      isShellBranch: isShellBranch,
      realtime: realtime,
    );
  }

  // ── File writer ───────────────────────────────────────────────────────────

  Future<void> _write(String path, String content) async {
    final file = File(path);
    await file.create(recursive: true);
    await file.writeAsString(content);
  }

  // ── branding (logo → icons + splash) ───────────────────────────────────────

  /// Copies the picked logo into `assets/branding/logo.png` and writes the
  /// flutter_launcher_icons / flutter_native_splash configs.
  Future<void> _writeBranding(Directory projectDir, String logoPath) async {
    final src = File(logoPath);
    if (!src.existsSync()) return;
    final dest = File('${projectDir.path}/assets/branding/logo.png');
    await dest.create(recursive: true);
    await dest.writeAsBytes(await src.readAsBytes());
    await _write('${projectDir.path}/flutter_launcher_icons.yaml', CoreTemplates.launcherIconsConfig());
    await _write('${projectDir.path}/flutter_native_splash.yaml', CoreTemplates.nativeSplashConfig());
  }

  /// Runs flutter_launcher_icons + flutter_native_splash. Best-effort: failures
  /// (e.g. a platform folder absent) are logged but never abort generation.
  Future<void> _runBrandingTools(
    Directory projectDir,
    String flutter,
    void Function(String) onLog,
  ) async {
    final dart = '${File(flutter).parent.path}/dart';
    const tasks = [
      ['run', 'flutter_launcher_icons'],
      ['run', 'flutter_native_splash:create'],
    ];
    for (final args in tasks) {
      try {
        final result = await Process.run(
          dart,
          args,
          workingDirectory: projectDir.path,
          environment: {
            ...Platform.environment,
            'PATH': '${Platform.environment['PATH']}:/usr/local/bin:/opt/homebrew/bin',
          },
        ).timeout(const Duration(minutes: 3));
        onLog(result.exitCode == 0
            ? '[✓] ${args.last} done.'
            : '[!] ${args.last}: ${result.stderr.toString().trim().split('\n').take(1).join()}');
      } catch (e) {
        onLog('[!] ${args.last} skipped: $e');
      }
    }
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
    List<String> pathPackages = const [],
    List<String> extraWorkspaceMembers = const [],
    bool addConnectivity = false,
    bool addSkeletonizer = false,
    bool addBranding = false,
    bool addImagePicker = false,
    bool addFirebaseCore = false,
    bool addFirebaseAuth = false,
    bool addFirebaseStorage = false,
  }) async {
    final pubspecFile = File('${projectDir.path}/pubspec.yaml');
    if (!pubspecFile.existsSync()) return;

    final original = await pubspecFile.readAsString();
    final content = buildPubspecContent(
      original,
      packages,
      withWidgetbook: withWidgetbook,
      addScreenUtil: addScreenUtil,
      pathPackages: pathPackages,
      extraWorkspaceMembers: extraWorkspaceMembers,
      addConnectivity: addConnectivity,
      addSkeletonizer: addSkeletonizer,
      addBranding: addBranding,
      addImagePicker: addImagePicker,
      addFirebaseCore: addFirebaseCore,
      addFirebaseAuth: addFirebaseAuth,
      addFirebaseStorage: addFirebaseStorage,
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
    List<String> pathPackages = const [],
    List<String> extraWorkspaceMembers = const [],
    bool addConnectivity = false,
    bool addSkeletonizer = false,
    bool addBranding = false,
    bool addImagePicker = false,
    bool addFirebaseCore = false,
    bool addFirebaseAuth = false,
    bool addFirebaseStorage = false,
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

    // connectivity_plus for the offline NetworkInfo brick.
    if (addConnectivity && !uniquePackages.any((p) => p.name == 'connectivity_plus')) {
      deps.write('  connectivity_plus: ^7.1.1\n');
    }
    // skeletonizer for the generated list screen's loading placeholders.
    if (addSkeletonizer && !uniquePackages.any((p) => p.name == 'skeletonizer')) {
      deps.write('  skeletonizer: ^2.1.3\n');
    }
    // image_picker for the Storage sample avatar upload widget.
    if (addImagePicker && !uniquePackages.any((p) => p.name == 'image_picker')) {
      deps.write('  image_picker: ^1.1.2\n');
    }
    // Firebase: cloud_firestore is the user-selected marker; firebase_core is
    // required by it, and auth/storage are pulled in with their opt-ins.
    if (addFirebaseCore && !uniquePackages.any((p) => p.name == 'firebase_core')) {
      deps.write('  firebase_core: ^3.8.1\n');
    }
    if (addFirebaseAuth && !uniquePackages.any((p) => p.name == 'firebase_auth')) {
      deps.write('  firebase_auth: ^5.3.4\n');
    }
    if (addFirebaseStorage && !uniquePackages.any((p) => p.name == 'firebase_storage')) {
      deps.write('  firebase_storage: ^12.4.0\n');
    }
    // Branding tooling: app icons + splash from the uploaded logo.
    if (addBranding) {
      if (!uniquePackages.any((p) => p.name == 'flutter_launcher_icons')) {
        devDeps.write('  flutter_launcher_icons: ^0.14.4\n');
      }
      if (!uniquePackages.any((p) => p.name == 'flutter_native_splash')) {
        devDeps.write('  flutter_native_splash: ^2.4.6\n');
      }
    }
    // Path deps on local workspace packages (e.g. <app>_ui, <app>_local_storage).
    for (final pkg in pathPackages) {
      deps.write('  $pkg:\n    path: packages/$pkg\n');
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
    // live under packages/ (or widgetbook/) and each carries `resolution: workspace`.
    final members = [
      ...pathPackages.map((p) => 'packages/$p'),
      ...extraWorkspaceMembers,
    ];
    if (members.isNotEmpty) {
      final block = members.map((m) => '  - $m').join('\n');
      content = '${content.trimRight()}\n\nworkspace:\n$block\n';
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
