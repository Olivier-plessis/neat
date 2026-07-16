import 'dart:convert';
import 'dart:io';

import 'package:neat/core/contract/neat_contract.dart';
import 'package:neat/features/architecture/domain/models/architecture_state.dart';
import 'package:neat/features/architecture/domain/models/env_config.dart';
import 'package:neat/features/cicd/domain/models/cicd_state.dart';
import 'package:neat/features/dependencies/domain/models/pub_package.dart';
import 'package:neat/features/generation/domain/services/i18n_importer.dart';
import 'package:neat/features/generation/domain/services/templates/agents_md_template.dart';
import 'package:neat/features/generation/domain/services/templates/config_templates.dart';
import 'package:neat/features/generation/domain/services/templates/core_package_templates.dart';
import 'package:neat/features/generation/domain/services/templates/core_templates.dart';
import 'package:neat/features/generation/domain/usecases/writers/auth_writer.dart';
import 'package:neat/features/generation/domain/usecases/writers/backend_writer.dart';
import 'package:neat/features/generation/domain/usecases/writers/branding_writer.dart';
import 'package:neat/features/generation/domain/usecases/writers/cicd_writer.dart';
import 'package:neat/features/generation/domain/usecases/writers/core_infra_writer.dart';
import 'package:neat/features/generation/domain/usecases/writers/core_package_writer.dart';
import 'package:neat/features/generation/domain/usecases/writers/entry_point_writer.dart';
import 'package:neat/features/generation/domain/usecases/writers/env_writer.dart';
import 'package:neat/features/generation/domain/usecases/writers/feature_writer.dart';
import 'package:neat/features/generation/domain/usecases/writers/flavors_writer.dart';
import 'package:neat/features/generation/domain/usecases/writers/i18n_writer.dart';
import 'package:neat/features/generation/domain/usecases/writers/local_storage_package_writer.dart';
import 'package:neat/features/generation/domain/usecases/writers/onboarding_writer.dart';
import 'package:neat/features/generation/domain/usecases/writers/pubspec_writer.dart';
import 'package:neat/features/generation/domain/usecases/writers/router_writer.dart';
import 'package:neat/features/generation/domain/usecases/writers/theme_writer.dart';
import 'package:neat/features/identity/domain/models/identity_state.dart';
import 'package:neat/features/theme_engine/domain/models/theme_engine_state.dart';

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

    // Expand "desktop" into the three individual native platforms
    final platforms = identity.targetPlatforms.expand((p) {
      if (p == 'desktop') return ['macos', 'windows', 'linux'];
      return [p];
    }).toList();

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
      // identity.targetPlatforms.join(','),
      platforms.join(','),
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
    final hasGoRouterBuilder = packages.any(
      (p) => p.name == 'go_router_builder',
    );
    // go_router_builder requires go_router — treat it as selected even if the
    // user didn't explicitly add go_router as a standalone package.
    final hasGoRouter =
        packages.any((p) => p.name == 'go_router') || hasGoRouterBuilder;
    // Bottom-nav shell from launch: the first feature becomes the shell's
    // first branch (so it isn't also a plain top-level route). A shell needs
    // a first branch, so it's unavailable with no first feature. Hoisted
    // here (was computed later, right before _writeRouter's call) since
    // _writeCorePackage and the bootstrap() call site both need it too, and
    // both run earlier than _writeRouter.
    final useShell =
        architecture.useNavigationShell &&
        hasGoRouter &&
        architecture.generateFirstFeature;
    final hasFlexColorScheme = packages.any(
      (p) => p.name == 'flex_color_scheme',
    );
    final hasEnvied = packages.any((p) => p.name == 'envied');
    // Native build flavors are opt-in (off → plain `flutter run` works) and only
    // make sense with envied (per-flavor config). The environments (renamable,
    // default dev/staging/prod) drive both the envied classes and the flavors.
    final environments = architecture.environments;
    // Two orthogonal concepts:
    //  • Per-env *entry points* (`main_<env>.dart` + `.env.<env>` + launch.json):
    //    driven purely by having ≥2 environments — works on every platform
    //    (web/desktop included) since it's just Dart entry points + dart-define.
    //  • Native *flavors* (Android productFlavors / iOS schemes + `--flavor`):
    //    opt-in AND mobile-only (web/desktop have no flavor concept).
    // A single environment collapses both → one `main.dart` + one `.env`.
    final multiEnv = environments.length >= 2;
    final flavorsSupported = identity.targetPlatforms.any(
      (p) => p == 'android' || p == 'ios',
    );
    final hasEntryPoints = hasEnvied && multiEnv;
    final hasNativeFlavors =
        hasEntryPoints && architecture.generateFlavors && flavorsSupported;
    final hasFreezed = packages.any((p) => p.name == 'freezed');
    final hasJsonSerializable = packages.any(
      (p) => p.name == 'json_serializable',
    );
    final hasChopper = packages.any((p) => p.name == 'chopper');
    final hasDio = packages.any((p) => p.name == 'dio');
    // Supabase / Firebase are *backends* (SDKs) that play the same role as a
    // REST client: they back the feature's remote source. They take precedence.
    final hasSupabase = packages.any((p) => p.name == 'supabase_flutter');
    final hasFirebase = packages.any((p) => p.name == 'cloud_firestore');
    final hasHttpClient = hasChopper || hasDio || hasSupabase || hasFirebase;
    final httpClient = hasFirebase
        ? 'firebase'
        : hasSupabase
        ? 'supabase'
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
        identity.targetPlatforms.length == 1 &&
        identity.targetPlatforms.first == 'web';
    final useScreenUtil = !isWebOnly;
    // Web among targets → bootstrap uses usePathUrlStrategy().
    final isWeb = identity.targetPlatforms.contains('web');

    // The backend (Supabase or Firebase) drives the opt-in capabilities below.
    final hasBackend = httpClient == 'supabase' || httpClient == 'firebase';

    // Opt-in auth (login/signup/forgot + go_router guard). Requires the typed
    // router (a riverpod-provider GoRouter) to wire the guard.
    final hasAuth =
        architecture.generateAuth &&
        hasBackend &&
        hasGoRouterBuilder &&
        useAnnotations;

    // Opt-in Realtime: the first feature's list screen becomes live (a
    // StreamNotifier over `.stream()` / Firestore `.snapshots()`). Needs the
    // full DI graph (annotations).
    final hasRealtime =
        architecture.generateRealtime && hasBackend && useAnnotations;

    // Opt-in Storage: a StorageService (+ provider + sample avatar upload
    // widget). Needs riverpod for the provider + the backend client.
    final hasStorage =
        architecture.generateStorage && hasBackend && hasRiverpod;

    // Opt-in OAuth (Google + Apple) on the auth feature, via Firebase's
    // signInWithProvider. Requires the auth feature on a Firebase backend.
    final hasOAuth =
        architecture.generateOAuth && hasAuth && httpClient == 'firebase';

    // Opt-in i18n with slang (en + fr). Setup is universal; the sample page
    // consumption (`context.t` + LanguageSwitcher) is woven into riverpod pages.
    final hasI18n = architecture.generateI18n;

    // Opt-in onboarding (first-launch-only PageView skeleton + a persisted
    // "seen it" provider). Riverpod-annotations only for v1 — the provider
    // needs `@riverpod`. App-level always, no packageSplit placement (unlike
    // i18n) — see ROADMAP.md backlog for why.
    final hasOnboarding =
        architecture.generateOnboarding && hasRiverpod && useAnnotations;

    // Opt-in Sentry (CI/CD screen) — see AppTemplates.bootstrap's hasSentry
    // doc for how it wraps runApp instead of just adding an init line.
    final hasSentry = cicd.hasSentryDelivery;

    // Offline-first turns the project into a Dart workspace with a dedicated
    // database package (Drift). null when remote-only. Firestore ships its
    // own offline persistence, so a Firebase backend disables the Drift layer
    // (enabled in bootstrap via Settings(persistenceEnabled: true)) to avoid two
    // competing caches.
    final offlineFirst =
        architecture.storageStrategy.isOfflineFirst && !hasFirebase;
    // Named `<app>_database`, not the generic `local_storage` — the package
    // only ever contains Drift (a typed SQL database + DAOs), never
    // SharedPreferences/secure-storage/cache, so the generic name read as
    // misleading. Prefixed like uiPackage below (unlike core/auth/feature)
    // since "database" alone is ambiguous across projects in a monorepo.
    final localStoragePackage = offlineFirst ? '${packageName}_database' : null;
    // Sync strategy adds the Outbox table + SyncService + repository write path.
    final hasSync = architecture.storageStrategy.hasSync;

    // Opt-in: extract theme + tokens + components into a <app>_ui workspace
    // package — prefixed with the app name, same as the database package
    // above (every other split package below — core/auth/feature — doesn't;
    // see corePackageName/featurePackageName's comments).
    final uiPackage = theme.extractUiPackage ? '${packageName}_ui' : null;
    // Widgetbook becomes a workspace member when the UI package is on.
    final widgetbookIsMember = uiPackage != null && theme.generateWidgetbook;
    // Opt-in: Result/Failure/UseCase/dio-networking as a shared `core`
    // workspace package — a prerequisite for packageSplit. Cross-package
    // imports resolve fine either way in a Dart workspace (every member
    // shares one package_config.json — verified directly, not assumed), so
    // this isn't actually enforced by the analyzer; it's a deliberate
    // discipline (never import the app from a feature package) so a feature
    // package stays viable if it's ever pulled out of the workspace into its
    // own repo, which is the whole point of packageSplit. Re-derived from the
    // raw flag the same way hasAuth/hasRealtime/hasStorage are below, rather
    // than trusted as-is — the wizard disables its toggle outside this exact
    // combo, but the underlying flag can still drift (e.g. flipping storage
    // strategy after turning packageSplit on), so the generator re-validates
    // the combo before acting on it. dio/chopper/supabase/firebase, manual or
    // typed (go_router_builder) routing, remote-only/offline-first-read/
    // offline-first-sync, auth/realtime/storage all supported (see
    // ROADMAP.md §6a).
    final packageSplitSupported =
        architecture.packageSplit &&
        (httpClient == 'dio' ||
            httpClient == 'chopper' ||
            httpClient == 'supabase' ||
            httpClient == 'firebase') &&
        useAnnotations &&
        hasGoRouter;
    final corePackageName = packageSplitSupported ? 'core' : null;
    // The split first feature — only meaningful when there is one. Like
    // core/auth, a feature package is named after the feature itself, no
    // app-name prefix (only the extracted UI and database packages keep
    // one — see uiPackage/localStoragePackage above). The app name adds
    // nothing here; it's already implied by being in this workspace.
    final featurePackageName =
        packageSplitSupported && architecture.generateFirstFeature
        ? featureName
        : null;
    // Auth becomes its own workspace package too when split — same
    // package-root shape as any other split feature (screens included), just
    // depending on corePackageName for Result/Failure/UseCase instead of
    // duplicating them (unlike wesioo's standalone `authentication` package,
    // which has zero workspace deps — see ROADMAP.md §6a for why NEAT
    // deliberately diverges here).
    final authPackageName = packageSplitSupported && hasAuth ? 'auth' : null;
    // App path-deps + workspace members.
    final pathPackages = <String>[
      ?localStoragePackage,
      ?uiPackage,
      ?corePackageName,
      ?featurePackageName,
      ?authPackageName,
    ];
    final extraWorkspaceMembers = <String>[
      if (widgetbookIsMember) 'widgetbook',
    ];

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
      hasEntryPoints: hasEntryPoints,
      hasNativeFlavors: hasNativeFlavors,
      environments: environments,
      theme: theme,
      localStoragePackage: localStoragePackage,
      hasSync: hasSync,
      isWeb: isWeb,
      uiPackage: uiPackage,
      hasAuth: hasAuth,
      hasRealtime: hasRealtime,
      hasStorage: hasStorage,
      hasOAuth: hasOAuth,
      hasI18n: hasI18n,
      hasOnboarding: hasOnboarding,
      hasSentry: hasSentry,
      sentryDsn: cicd.sentryDsn,
      corePackageName: corePackageName,
      featurePackageName: featurePackageName,
      authPackageName: authPackageName,
    );
    onLog('[✓] Scaffold created.');

    // 2a. Shared core workspace package (Result/Failure/UseCase/dio networking)
    if (corePackageName != null) {
      onLog('[▶] Creating shared core workspace package...');
      // Mirrors _buildScaffold's own autoWireOnboarding — this method has its
      // own local scope (same reasoning as useShell just above), so it's
      // recomputed here from the same inputs rather than threaded through as
      // yet another argument.
      final autoWireOnboarding = hasOnboarding && hasGoRouterBuilder;
      await CorePackageWriter.write(
        projectDir,
        corePackageName,
        featureName: featureName,
        httpClient: httpClient,
        localStoragePackage: localStoragePackage,
        hasI18n: hasI18n,
        hasSync: hasSync,
        hasAuth: hasAuth,
        hasStorage: hasStorage,
        hasEnvied: hasEnvied,
        useShell: useShell,
        featurePackageName: featurePackageName,
        hasOnboarding: autoWireOnboarding,
        hasFirstFeature: architecture.generateFirstFeature,
      );
      onLog('[✓] packages/$corePackageName created.');
    }

    // 2b. Offline-first workspace package
    if (localStoragePackage != null) {
      onLog('[▶] Creating offline-first workspace package...');
      await LocalStoragePackageWriter.write(
        projectDir,
        localStoragePackage,
        featureName: featureName,
        hasSync: hasSync,
        fields: architecture.firstFeatureFields,
        includeFirstTable: architecture.generateFirstFeature,
        isWeb: isWeb,
      );
      onLog('[✓] packages/$localStoragePackage created.');
      if (isWeb) {
        // sqlite3.wasm + drift_worker.dart.js are prebuilt release binaries,
        // not generatable template text — see CoreTemplates.driftWebSetupDoc.
        await _write(
          '${projectDir.path}/docs/DRIFT_WEB_SETUP.md',
          CoreTemplates.driftWebSetupDoc(localStoragePackage: localStoragePackage),
        );
      }
    }

    // 2c. Per-env wiring — VS Code run configs + a doc (and, on mobile with the
    // flavors opt-in, native productFlavors). The Dart side is the
    // main_<env>.dart entry points. The base (no appId suffix) is chosen
    // explicitly (architecture.baseEnvIndex); we order it LAST so the existing
    // "base = last" contract inside _writeFlavors/_launchJson/_flavorsDoc holds.
    if (hasEntryPoints) {
      final baseFlavor = architecture.baseEnv.flavor;
      final names = [
        for (final e in environments)
          if (e.flavor != baseFlavor) e.flavor,
        baseFlavor,
      ];
      onLog('[▶] Wiring environments (${names.join(', ')})...');
      await FlavorsWriter.write(
        projectDir,
        FlavorsWriter.titleCase(packageName),
        names,
        nativeFlavors: hasNativeFlavors,
      );
      final what = hasNativeFlavors
          ? 'launch.json + Android productFlavors + docs/FLAVORS.md'
          : 'launch.json + docs/FLAVORS.md (entry points; no native flavors)';
      onLog('[✓] Environments wired ($what).');
    }

    // Branding: a logo was picked → generate app icons + splash.
    final hasLogo =
        theme.logoPath.isNotEmpty && File(theme.logoPath).existsSync();

    // 3. pubspec.yaml
    onLog('[▶] Configuring pubspec.yaml...');
    await PubspecWriter.write(
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
      addSlang: hasI18n,
      addOnboarding: hasOnboarding,
      addSentry: hasSentry,
    );
    onLog('[✓] Dependencies added to pubspec.yaml.');

    // 3b. Branding files: copy the logo + write the icon/splash configs.
    if (hasLogo) {
      onLog('[▶] Setting up branding (icons + splash)...');
      await BrandingWriter.write(projectDir, theme.logoPath, platforms);
    }

    // 4. CI/CD files (fastlane lanes are flavor-aware when envied is on).
    if (cicd.selectedTools.isNotEmpty) {
      onLog('[▶] Generating CI/CD configuration files...');
      await CicdWriter.write(projectDir, cicd, hasFlavors: hasNativeFlavors);
      onLog('[✓] CI/CD files written.');
    }

    // 5. flutter pub get — with automatic conflict recovery
    onLog("[▶] Running 'flutter pub get'...");
    await _pubGet(projectDir, flutter, onLog);

    // 6. build_runner — only if code-gen packages are present
    // (envied always needs it; we auto-injected the dev dep above).
    final hasBuildRunner =
        packages.any((p) => p.name == 'build_runner') || hasEnvied;
    if (hasBuildRunner) {
      onLog(
        "[▶] Running 'dart run build_runner build' (may fail on first run due to version resolution)...",
      );
      await _runBuildRunner(projectDir, onLog);
    }

    // In a workspace, build_runner runs per-package — the Drift package has its
    // own codegen (database.g.dart) that the root build does not produce.
    if (localStoragePackage != null) {
      onLog(
        '[▶] Running build_runner in packages/$localStoragePackage (Drift)...',
      );
      await _runBuildRunner(
        Directory('${projectDir.path}/packages/$localStoragePackage'),
        onLog,
      );
    }

    // Same for the shared core package — dioProvider's own @Riverpod codegen
    // (dio_provider.g.dart) isn't produced by the root build either.
    if (corePackageName != null) {
      onLog('[▶] Running build_runner in packages/$corePackageName...');
      await _runBuildRunner(
        Directory('${projectDir.path}/packages/$corePackageName'),
        onLog,
      );
    }

    // Same for the split feature package — its own entity/model/provider
    // codegen (freezed/.g.dart) isn't produced by the root build either.
    if (featurePackageName != null) {
      onLog('[▶] Running build_runner in packages/$featurePackageName...');
      await _runBuildRunner(
        Directory('${projectDir.path}/packages/$featurePackageName'),
        onLog,
      );
    }

    // Same for the auth package — its own riverpod codegen (auth_provider.g.dart,
    // auth_repository_providers.g.dart, auth_routes.g.dart) isn't produced by
    // the root build either.
    if (authPackageName != null) {
      onLog('[▶] Running build_runner in packages/$authPackageName...');
      await _runBuildRunner(
        Directory('${projectDir.path}/packages/$authPackageName'),
        onLog,
      );
    }

    // 6c. slang i18n codegen via the standalone CLI (not slang_build_runner —
    // that clashes with source_gen builders). Generates lib/i18n/strings.g.dart.
    // packageSplit: the whole i18n setup was written into the core package
    // instead (see _buildScaffold's i18n block) — run slang there instead.
    if (hasI18n) {
      final i18nCodegenDir = corePackageName != null
          ? Directory('${projectDir.path}/packages/$corePackageName')
          : projectDir;
      onLog("[▶] Running 'dart run slang' (i18n codegen)...");
      await const I18nImporter().runSlang(i18nCodegenDir, onLog);
    }

    // 6b. Branding tools — generate app icons + native splash from the logo.
    // Best-effort: a failure (e.g. missing native folders) never breaks the run.
    if (hasLogo) {
      onLog('[▶] Generating app icons + splash...');
      await BrandingWriter.runTools(projectDir, flutter, onLog);
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
      useCubit: useCubit,
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
      generateI18n: hasI18n,
      generateOnboarding: hasOnboarding,
      useNavigationShell: architecture.useNavigationShell && hasGoRouter,
      components: theme.components.map((c) => c.name).toList(),
      packageSplit: packageSplitSupported,
    );
    onLog('[▶] Writing .neat.json (Workspace Contract)...');
    await _writeContract(projectDir, contract);
    onLog('[✓] .neat.json written.');

    // 9. AGENTS.md — contract-aware AI rules (accurate to this exact stack).
    onLog('[▶] Writing AGENTS.md (AI agent guide)...');
    await _write(
      '${projectDir.path}/AGENTS.md',
      AgentsMdTemplate.generate(contract),
    );
    onLog('[✓] AGENTS.md written.');

    onLog('');
    onLog('[✓✓] Project successfully generated at ${projectDir.path}');
  }

  /// Writes the Workspace Contract to `<project>/.neat.json` (pretty-printed).
  Future<void> _writeContract(
    Directory projectDir,
    NeatContract contract,
  ) async {
    const encoder = JsonEncoder.withIndent('  ');
    await _write(
      '${projectDir.path}/.neat.json',
      '${encoder.convert(contract.toJson())}\n',
    );
  }

  Future<void> _dartFormat(
    Directory projectDir,
    void Function(String) onLog,
  ) async {
    try {
      final result = await Process.run('dart', [
        'format',
        '.',
      ], workingDirectory: projectDir.path);
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
    required bool hasEntryPoints,
    required bool hasNativeFlavors,
    required List<EnvConfig> environments,
    required ThemeEngineState theme,
    String? localStoragePackage,
    bool hasSync = false,
    bool isWeb = false,
    String? uiPackage,
    bool hasAuth = false,
    bool hasRealtime = false,
    bool hasStorage = false,
    bool hasOAuth = false,
    bool hasI18n = false,
    bool hasOnboarding = false,
    // See AppTemplates.bootstrap's hasSentry doc.
    bool hasSentry = false,
    String sentryDsn = '',
    String? corePackageName,
    String? featurePackageName,
    String? authPackageName,
  }) async {
    final lib = '${projectDir.path}/lib';
    // Bottom-nav shell from launch: the first feature becomes the shell's
    // first branch (so it isn't also a plain top-level route). A shell needs
    // a first branch, so it's unavailable with no first feature. Mirrors
    // execute()'s own copy (needed there too, for _writeCorePackage's
    // shell_page_registry.dart write) — this method has its own local scope,
    // so it's recomputed here from the same params rather than threaded
    // through as yet another argument.
    final useShell =
        architecture.useNavigationShell &&
        hasGoRouter &&
        architecture.generateFirstFeature;

    // A user-uploaded compact CSV replaces the default JSON scaffold. With a CSV
    // we don't know the translation keys, so the sample page consumption
    // (`context.t.<feature>.title` + switcher) is skipped — the rest of the
    // slang setup is still wired.
    final i18nFromCsv =
        hasI18n &&
        architecture.i18nCsvPath.isNotEmpty &&
        File(architecture.i18nCsvPath).existsSync();
    final hasI18nSample = hasI18n && !i18nFromCsv;

    // The redirect can only be auto-wired where the RouterNotifier-style
    // guard mechanism already exists (go_router_builder) — plain go_router
    // has no proven anchor-splicing precedent for this yet (see ROADMAP.md's
    // onboarding entry). Never mirrored into a packageSplit core package —
    // onboarding stays app-level, unlike Auth.
    final autoWireOnboarding = hasOnboarding && hasGoRouterBuilder;

    // ── main.dart + bootstrap ───────────────────────────────────────────────
    // A single environment → one `main.dart` loading the lone `Env`. With ≥2
    // environments, main.dart defaults to the FIRST and we also emit one entry
    // point per env (main_<env>.dart) — paired with `--flavor` only when native
    // flavors are on (mobile), otherwise just `-t lib/main_<env>.dart`.
    final singleEnv = hasEnvied && !hasEntryPoints;
    final defaultFlavor = hasEnvied && environments.isNotEmpty
        ? environments.first.flavor
        : 'dev';
    await EntryPointWriter.writeMainAndBootstrap(
      lib: lib,
      packages: packages,
      packageName: packageName,
      hasEnvied: hasEnvied,
      hasEntryPoints: hasEntryPoints,
      environments: environments,
      singleEnv: singleEnv,
      defaultFlavor: defaultFlavor,
      hasRiverpod: hasRiverpod,
      useAnnotations: useAnnotations,
      isWeb: isWeb,
      httpClient: httpClient,
      hasI18n: hasI18n,
      featurePackageName: featurePackageName,
      featureName: featureName,
      useShell: useShell,
      corePackageName: corePackageName,
      autoWireOnboarding: autoWireOnboarding,
      hasSentry: hasSentry,
    );

    // ── core/env (envied flavors) ───────────────────────────────────────────
    if (hasEnvied) {
      await EnvWriter.write(
        projectDir,
        lib,
        packageName,
        environments: environments,
        singleEnv: singleEnv,
        hasSupabase: httpClient == 'supabase',
        // No REST base URL for the SDK backends (Firebase config lives in
        // firebase_options.dart; Supabase keys are separate fields).
        hasApiBaseUrl: httpClient != 'supabase' && httpClient != 'firebase',
        hasSentry: hasSentry,
        sentryDsn: sentryDsn,
      );
    }

    // ── app.dart ──────────────────────────────────────────────────────────
    await EntryPointWriter.writeAppDart(
      lib: lib,
      packageName: packageName,
      hasGoRouter: hasGoRouter,
      hasRiverpod: hasRiverpod,
      useAnnotations: useAnnotations,
      hasBloc: hasBloc,
      useCubit: useCubit,
      useScreenUtil: useScreenUtil,
      hasGoRouterBuilder: hasGoRouterBuilder,
      uiPackage: uiPackage,
      hasI18n: hasI18n,
      corePackageName: corePackageName,
    );

    // ── core building blocks (result/constants/error/utils/observers/network) ──
    // packageSplit: everything gated on corePackageName == null only exists
    // to be imported by feature domain/data code, which now lives entirely
    // in split packages and imports from corePackageName instead — the app's
    // own copies would just be dead code (see ROADMAP.md §6a's "clean up the
    // duplicated core/" note).
    await CoreInfraWriter.write(
      lib: lib,
      architecture: architecture,
      featureName: featureName,
      packageName: packageName,
      httpClient: httpClient,
      hasAuth: hasAuth,
      hasRiverpod: hasRiverpod,
      useAnnotations: useAnnotations,
      hasEnvied: hasEnvied,
      singleEnv: singleEnv,
      environments: environments,
      autoWireOnboarding: autoWireOnboarding,
      corePackageName: corePackageName,
    );

    // ── backend + offline-first infrastructure ────────────────────────────────
    await BackendWriter.write(
      projectDir: projectDir,
      lib: lib,
      architecture: architecture,
      featureName: featureName,
      packageName: packageName,
      httpClient: httpClient,
      hasRiverpod: hasRiverpod,
      useAnnotations: useAnnotations,
      hasAuth: hasAuth,
      hasStorage: hasStorage,
      corePackageName: corePackageName,
      localStoragePackage: localStoragePackage,
      hasSync: hasSync,
    );

    // ── core/theme ────────────────────────────────────────────────────────
    final flexMatches = packages.where((p) => p.name == 'flex_color_scheme');
    await ThemeWriter.write(
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
      corePackageName: corePackageName,
    );

    // ── core/router ───────────────────────────────────────────────────────
    if (hasGoRouter) {
      await RouterWriter.write(
        lib: lib,
        packageName: packageName,
        featureName: featureName,
        hasGoRouterBuilder: hasGoRouterBuilder,
        useAnnotations: useAnnotations,
        useShell: useShell,
        shellIcon: architecture.shellIcon,
        shellLabel: architecture.effectiveShellLabel,
        hasAuth: hasAuth,
        hasFirstFeature: architecture.generateFirstFeature,
        featurePackageName: featurePackageName,
        corePackageName: corePackageName,
        hasOnboarding: autoWireOnboarding,
      );
    }

    // ── auth feature (opt-in, Supabase + go_router_builder) ──────────────────
    if (hasAuth) {
      await AuthWriter.write(
        projectDir: projectDir,
        lib: lib,
        packageName: packageName,
        featureName: featureName,
        backend: httpClient,
        oauth: hasOAuth,
        corePackageName: corePackageName,
        authPackageName: authPackageName,
        hasOnboarding: autoWireOnboarding,
        hasFirstFeature: architecture.generateFirstFeature,
      );
    }

    // ── i18n (slang, opt-in) ─────────────────────────────────────────────────
    if (hasI18n) {
      await I18nWriter.write(
        projectDir: projectDir,
        lib: lib,
        architecture: architecture,
        featureName: featureName,
        packageName: packageName,
        i18nFromCsv: i18nFromCsv,
        corePackageName: corePackageName,
      );
    }

    // ── onboarding (opt-in, Riverpod annotations only) ────────────────────
    if (hasOnboarding) {
      await OnboardingWriter.write(
        lib: lib,
        packageName: packageName,
        featureName: featureName,
        autoWireOnboarding: autoWireOnboarding,
        hasFirstFeature: architecture.generateFirstFeature,
        corePackageName: corePackageName,
      );
    }

    // ── components ────────────────────────────────────────────────────────
    if (!architecture.generateFirstFeature) {
      await _write('$lib/components/.gitkeep', '');
    }

    // ── feature ───────────────────────────────────────────────────────────
    // Off → the app ships with zero features; a placeholder welcome route
    // (written above) owns '/' instead. Add a real first feature later via
    // the Workshop, which owns all entity/JSON-paste editing.
    if (architecture.generateFirstFeature) {
      // packages/<packageName>_<featureName>/pubspec.yaml — depends on the
      // shared core package via a sibling path: dep (see ROADMAP.md §6a).
      if (featurePackageName != null && corePackageName != null) {
        await _write(
          '${projectDir.path}/packages/$featurePackageName/pubspec.yaml',
          CorePackageTemplates.featurePackagePubspec(
            featurePackageName: featurePackageName,
            corePackageName: corePackageName,
            httpClient: httpClient,
            hasGoRouterBuilder: hasGoRouterBuilder,
            localStoragePackage: localStoragePackage,
          ),
        );
      }
      await FeatureWriter.write(
        lib: featurePackageName != null
            ? '${projectDir.path}/packages/$featurePackageName/lib'
            : lib,
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
        packageSplit: featurePackageName != null,
        corePackageName: corePackageName,
        i18n: hasI18nSample,
      );

      // A feature isn't self-contained in its own folder — see
      // CoreTemplates.removeFirstFeatureDoc's doc for why a plain `rm -rf`
      // leaves dangling references, and exactly what to revert instead.
      await _write(
        '${projectDir.path}/docs/REMOVE_FIRST_FEATURE.md',
        CoreTemplates.removeFirstFeatureDoc(
          featureName: featureName,
          httpClient: httpClient,
          corePackageName: corePackageName,
          featurePackageName: featurePackageName,
          localStoragePackage: localStoragePackage,
          hasSync: hasSync,
          useShell: useShell,
        ),
      );
    }
  }

  // ── File writer ───────────────────────────────────────────────────────────

  Future<void> _write(String path, String content) async {
    final file = File(path);
    await file.create(recursive: true);
    await file.writeAsString(content);
  }

  // ── pub get ───────────────────────────────────────────────────────────────

  Future<void> _pubGet(
    Directory projectDir,
    String flutter,
    void Function(String) onLog,
  ) async {
    final result = await Process.run(flutter, [
      'pub',
      'get',
    ], workingDirectory: projectDir.path);

    if (result.exitCode != 0) {
      throw Exception(result.stderr.toString().trim());
    }

    onLog('[✓] Dependencies installed.');
  }

  // ── build_runner ──────────────────────────────────────────────────────────

  Future<void> _runBuildRunner(
    Directory projectDir,
    void Function(String) onLog,
  ) async {
    final result = await Process.run(
      'dart',
      ['run', 'build_runner', 'build', '--delete-conflicting-outputs'],
      workingDirectory: projectDir.path,
      environment: {
        ...Platform.environment,
        'PATH':
            '${Platform.environment['PATH']}:/usr/local/bin:/opt/homebrew/bin',
      },
    );

    if (result.stdout.toString().trim().isNotEmpty) {
      onLog(result.stdout.toString().trim());
    }

    if (result.exitCode != 0) {
      final stderr = result.stderr.toString().trim();
      if (stderr.isNotEmpty) onLog('[⚠] $stderr');
      onLog(
        '[⚠] build_runner failed — likely a version conflict (analyzer/dart_style).',
      );
      onLog('[ℹ] Run manually once pub resolution stabilises:');
      onLog('    dart run build_runner build --delete-conflicting-outputs');
      return;
    }

    onLog('[✓] Code generation complete.');
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
        'PATH':
            '${Platform.environment['PATH']}:/usr/local/bin:/opt/homebrew/bin',
      },
    );
    final resolved = which.stdout.toString().trim();
    if (resolved.isNotEmpty && File(resolved).existsSync()) return resolved;

    throw Exception(
      'Flutter SDK not found. Add it to PATH or install it at ~/flutter or ~/develop/flutter.',
    );
  }
}
