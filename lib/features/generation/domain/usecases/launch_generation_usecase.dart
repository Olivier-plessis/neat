import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:neat/core/contract/neat_contract.dart';
import 'package:neat/features/architecture/domain/models/architecture_state.dart';
import 'package:neat/features/architecture/domain/models/env_config.dart';
import 'package:neat/features/cicd/domain/models/cicd_state.dart';
import 'package:neat/features/cicd/domain/usecases/generate_yaml_usecase.dart';
import 'package:neat/features/dependencies/domain/models/pub_package.dart';
import 'package:neat/features/generation/domain/models/field_spec.dart';
import 'package:neat/features/generation/domain/services/feature_scaffolder.dart';
import 'package:neat/features/generation/domain/services/i18n_importer.dart';
import 'package:neat/features/generation/domain/services/templates/agents_md_template.dart';
import 'package:neat/features/generation/domain/services/templates/config_templates.dart';
import 'package:neat/features/generation/domain/services/templates/core_package_templates.dart';
import 'package:neat/features/generation/domain/services/templates/core_templates.dart';
import 'package:neat/features/generation/domain/services/templates/dart/app_templates.dart';
import 'package:neat/features/generation/domain/services/templates/dart/auth_templates.dart';
import 'package:neat/features/generation/domain/services/templates/dart/core_dart_templates.dart';
import 'package:neat/features/generation/domain/services/templates/dart/i18n_templates.dart';
import 'package:neat/features/generation/domain/services/templates/dart/onboarding_templates.dart';
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
    final hasGoRouterBuilder = packages.any((p) => p.name == 'go_router_builder');
    // go_router_builder requires go_router — treat it as selected even if the
    // user didn't explicitly add go_router as a standalone package.
    final hasGoRouter = packages.any((p) => p.name == 'go_router') || hasGoRouterBuilder;
    // Bottom-nav shell from launch: the first feature becomes the shell's
    // first branch (so it isn't also a plain top-level route). A shell needs
    // a first branch, so it's unavailable with no first feature. Hoisted
    // here (was computed later, right before _writeRouter's call) since
    // _writeCorePackage and the bootstrap() call site both need it too, and
    // both run earlier than _writeRouter.
    final useShell =
        architecture.useNavigationShell && hasGoRouter && architecture.generateFirstFeature;
    final hasFlexColorScheme = packages.any((p) => p.name == 'flex_color_scheme');
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
    final flavorsSupported = identity.targetPlatforms.any((p) => p == 'android' || p == 'ios');
    final hasEntryPoints = hasEnvied && multiEnv;
    final hasNativeFlavors = hasEntryPoints && architecture.generateFlavors && flavorsSupported;
    final hasFreezed = packages.any((p) => p.name == 'freezed');
    final hasJsonSerializable = packages.any((p) => p.name == 'json_serializable');
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
        identity.targetPlatforms.length == 1 && identity.targetPlatforms.first == 'web';
    final useScreenUtil = !isWebOnly;
    // Web among targets → bootstrap uses usePathUrlStrategy().
    final isWeb = identity.targetPlatforms.contains('web');

    // The backend (Supabase or Firebase) drives the opt-in capabilities below.
    final hasBackend = httpClient == 'supabase' || httpClient == 'firebase';

    // Opt-in auth (login/signup/forgot + go_router guard). Requires the typed
    // router (a riverpod-provider GoRouter) to wire the guard.
    final hasAuth = architecture.generateAuth && hasBackend && hasGoRouterBuilder && useAnnotations;

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

    // Opt-in i18n with slang (en + fr). Setup is universal; the sample page
    // consumption (`context.t` + LanguageSwitcher) is woven into riverpod pages.
    final hasI18n = architecture.generateI18n;

    // Opt-in onboarding (first-launch-only PageView skeleton + a persisted
    // "seen it" provider). Riverpod-annotations only for v1 — the provider
    // needs `@riverpod`. App-level always, no packageSplit placement (unlike
    // i18n) — see ROADMAP.md backlog for why.
    final hasOnboarding = architecture.generateOnboarding && hasRiverpod && useAnnotations;

    // Offline-first turns the project into a Dart workspace with a dedicated
    // local-storage package (Drift). null when remote-only. Firestore ships its
    // own offline persistence, so a Firebase backend disables the Drift layer
    // (enabled in bootstrap via Settings(persistenceEnabled: true)) to avoid two
    // competing caches.
    final offlineFirst = architecture.storageStrategy.isOfflineFirst && !hasFirebase;
    final localStoragePackage = offlineFirst ? 'local_storage' : null;
    // Sync strategy adds the Outbox table + SyncService + repository write path.
    final hasSync = architecture.storageStrategy.hasSync;

    // Opt-in: extract theme + tokens + components into a <app>_ui workspace
    // package — the one package that keeps the app-name prefix (every other
    // split package below — core/local_storage/auth/feature — doesn't; see
    // corePackageName/featurePackageName's comments).
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
    // core/local_storage/auth, a feature package is named after the feature
    // itself, no app-name prefix (only the extracted UI package keeps one —
    // see uiPackage above). The app name adds nothing here; it's already
    // implied by being in this workspace.
    final featurePackageName =
        packageSplitSupported && architecture.generateFirstFeature ? featureName : null;
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
      await _writeCorePackage(
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
      );
      onLog('[✓] packages/$corePackageName created.');
    }

    // 2b. Offline-first workspace package
    if (localStoragePackage != null) {
      onLog('[▶] Creating offline-first workspace package...');
      await _writeLocalStoragePackage(
        projectDir,
        localStoragePackage,
        featureName: featureName,
        hasSync: hasSync,
        fields: architecture.firstFeatureFields,
        includeFirstTable: architecture.generateFirstFeature,
      );
      onLog('[✓] packages/$localStoragePackage created.');
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
      await _writeFlavors(
        projectDir,
        _titleCase(packageName),
        names,
        nativeFlavors: hasNativeFlavors,
      );
      final what = hasNativeFlavors
          ? 'launch.json + Android productFlavors + docs/FLAVORS.md'
          : 'launch.json + docs/FLAVORS.md (entry points; no native flavors)';
      onLog('[✓] Environments wired ($what).');
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
      addSlang: hasI18n,
      addOnboarding: hasOnboarding,
    );
    onLog('[✓] Dependencies added to pubspec.yaml.');

    // 3b. Branding files: copy the logo + write the icon/splash configs.
    if (hasLogo) {
      onLog('[▶] Setting up branding (icons + splash)...');
      await _writeBranding(projectDir, theme.logoPath, platforms);
    }

    // 4. CI/CD files (fastlane lanes are flavor-aware when envied is on).
    if (cicd.selectedTools.isNotEmpty) {
      onLog('[▶] Generating CI/CD configuration files...');
      await _writeCicdFiles(projectDir, cicd, hasFlavors: hasNativeFlavors);
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
      await _runBuildRunner(Directory('${projectDir.path}/packages/$localStoragePackage'), onLog);
    }

    // Same for the shared core package — dioProvider's own @Riverpod codegen
    // (dio_provider.g.dart) isn't produced by the root build either.
    if (corePackageName != null) {
      onLog('[▶] Running build_runner in packages/$corePackageName...');
      await _runBuildRunner(Directory('${projectDir.path}/packages/$corePackageName'), onLog);
    }

    // Same for the split feature package — its own entity/model/provider
    // codegen (freezed/.g.dart) isn't produced by the root build either.
    if (featurePackageName != null) {
      onLog('[▶] Running build_runner in packages/$featurePackageName...');
      await _runBuildRunner(Directory('${projectDir.path}/packages/$featurePackageName'), onLog);
    }

    // Same for the auth package — its own riverpod codegen (auth_provider.g.dart,
    // auth_repository_providers.g.dart, auth_routes.g.dart) isn't produced by
    // the root build either.
    if (authPackageName != null) {
      onLog('[▶] Running build_runner in packages/$authPackageName...');
      await _runBuildRunner(Directory('${projectDir.path}/packages/$authPackageName'), onLog);
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
        architecture.useNavigationShell && hasGoRouter && architecture.generateFirstFeature;

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
    final defaultFlavor = hasEnvied && environments.isNotEmpty ? environments.first.flavor : 'dev';
    await _write(
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
        await _write(
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
        hasI18n: hasI18n,
        chopperRegisterFeaturePackage: httpClient == 'chopper' ? featurePackageName : null,
        chopperRegisterFeatureName: httpClient == 'chopper' ? featureName : null,
        shellRegisterFeaturePackage: useShell && featurePackageName != null ? featurePackageName : null,
        shellRegisterFeatureName: useShell && featurePackageName != null ? featureName : null,
        corePackageName: corePackageName,
        bridgesApiBaseUrl:
            hasEnvied && corePackageName != null && (httpClient == 'dio' || httpClient == 'chopper'),
        hasOnboarding: autoWireOnboarding,
      ),
    );

    // ── core/env (envied flavors) ───────────────────────────────────────────
    if (hasEnvied) {
      await _writeEnv(
        projectDir,
        lib,
        packageName,
        environments: environments,
        singleEnv: singleEnv,
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
        hasI18n: hasI18n,
        corePackageName: corePackageName,
      ),
    );

    // ── core/result ───────────────────────────────────────────────────────
    // packageSplit: these only exist to be imported by feature domain/data
    // code, which now lives entirely in split packages and imports them from
    // corePackageName instead — the app's own copies would just be dead code
    // (see ROADMAP.md §6a's "clean up the duplicated core/" note).
    if (corePackageName == null) {
      await _write(
        '$lib/core/result/result.dart',
        CoreDartTemplates.coreResultDart(packageName: packageName),
      );
      await _write(
        '$lib/core/usecases/use_case.dart',
        CoreDartTemplates.coreUsecaseDart(packageName: packageName),
      );
    }

    // ── core/constants ────────────────────────────────────────────────────
    await _write(
      '$lib/core/constants/app_route_path.dart',
      CoreTemplates.appRoutePath(
        featureName: featureName,
        hasAuth: hasAuth,
        hasFirstFeature: architecture.generateFirstFeature,
        hasOnboarding: autoWireOnboarding,
      ),
    );

    // No first feature → a placeholder welcome screen owns the root route
    // until one is added via the Workshop.
    if (!architecture.generateFirstFeature) {
      await _write(
        '$lib/core/pages/welcome_page.dart',
        CoreTemplates.welcomePage(packageName: packageName, appName: packageName),
      );
    }

    // ── core/error ────────────────────────────────────────────────────────
    // packageSplit: dead code in the app for the same reason as result.dart/
    // use_case.dart above — only feature repositories reference Failure/
    // NetworkErrorHandler, and they import from corePackageName instead.
    if (corePackageName == null) {
      await _write('$lib/core/error/failure.dart', CoreTemplates.failure());

      // ── core/network/network_error_handler.dart ───────────────────────────
      // The only place exceptions are caught and mapped to a Failure —
      // UseCase.call() invokes it. Always generated (even with no http client).
      await _write(
        '$lib/core/network/network_error_handler.dart',
        CoreTemplates.networkErrorHandler(
          packageName: packageName,
          httpClient: httpClient,
          hasRiverpod: hasRiverpod,
        ),
      );
    }

    // ── core/utils ────────────────────────────────────────────────────────
    await _write('$lib/core/utils/extensions.dart', CoreTemplates.extensions());

    // ── core/utils + observers (observability) ──────────────────────────────
    // packageSplit: AppLogger is stateless (no singleton-sharing correctness
    // issue, unlike theme_mode_controller), but the app no longer keeps its
    // own copy either — error_handler.dart/provider_observer.dart/
    // bootstrap.dart all redirect to corePackageName's copy instead, so
    // there's exactly one AppLogger for the whole workspace.
    if (corePackageName == null) {
      await _write(
        '$lib/core/utils/app_logger.dart',
        CoreTemplates.appLogger(
          // Single-env has no production flavor to compare against → fall back
          // to the kReleaseMode logger (quietens logs in release builds).
          useEnvied: hasEnvied && !singleEnv,
          packageName: packageName,
          // Production = the explicit base environment (quietens logs there).
          prodFlavor: hasEnvied && environments.isNotEmpty ? architecture.baseEnv.flavor : 'prod',
        ),
      );
    }
    await _write(
      '$lib/core/error/error_handler.dart',
      CoreTemplates.errorHandler(packageName: packageName, corePackageName: corePackageName),
    );
    if (hasRiverpod) {
      await _write(
        '$lib/core/observers/provider_observer.dart',
        CoreTemplates.riverpodObserver(
          packageName: packageName,
          useAnnotations: useAnnotations,
          corePackageName: corePackageName,
        ),
      );
    }
    // HTTP logging interceptor — REST clients only (Supabase has its own).
    // packageSplit: only ever imported by dio_provider.dart/
    // chopper_client_provider.dart below, both skipped in the app when split
    // (features import the core package's copies instead) — so this would be
    // dead code too.
    final isRestClient = httpClient == 'dio' || httpClient == 'chopper';
    if (isRestClient && corePackageName == null) {
      await _write(
        '$lib/core/observers/logger_interceptor.dart',
        CoreTemplates.loggerInterceptor(packageName: packageName, httpClient: httpClient),
      );
    }
    final isDioBased = httpClient == 'dio';
    // packageSplit: dead code — every feature's dio_provider.dart import
    // already redirects to corePackageName (see DataTemplates.
    // featureRepositoryProviders), and nothing in the app itself reads
    // dioProvider directly.
    if (isDioBased && hasRiverpod && corePackageName == null) {
      await _write(
        '$lib/core/network/dio_provider.dart',
        CoreTemplates.dioProvider(
          packageName: packageName,
          useAnnotations: useAnnotations,
          useEnvied: hasEnvied,
        ),
      );
    }
    // packageSplit + chopper: skipped entirely rather than written as an
    // inert witness-free copy — the split feature's registry entry lives in
    // (and is self-registered into) corePackageName instead (see
    // DataTemplates.featureRepositoryProviders/AppTemplates.bootstrap), so
    // the app never reads its own copy either way.
    //
    // chopper_model_converter.dart is plain Dart (no Riverpod import at all)
    // and is imported directly by every chopper repository_impl.dart
    // (`unwrapChopperResponse`) regardless of state management — so unlike
    // chopper_client_provider.dart (a Riverpod provider, only ever consumed
    // by the Riverpod-only <feature>_repository_providers.dart DI graph),
    // it must not be gated on hasRiverpod. Bloc/Cubit stub-mode repositories
    // still need it to compile even though nothing wires a ChopperClient into
    // them yet.
    if (httpClient == 'chopper' && corePackageName == null) {
      await _write(
        '$lib/core/network/chopper_model_converter.dart',
        CoreTemplates.chopperModelConverter(
          packageName: packageName,
          featureName: architecture.generateFirstFeature ? featureName : null,
        ),
      );
    }
    if (httpClient == 'chopper' && hasRiverpod && corePackageName == null) {
      await _write(
        '$lib/core/network/chopper_client_provider.dart',
        CoreTemplates.chopperClientProvider(
          packageName: packageName,
          useAnnotations: useAnnotations,
          useEnvied: hasEnvied,
        ),
      );
    }
    // packageSplit: dead code — every feature's supabase_provider.dart import
    // already redirects to corePackageName (see DataTemplates.
    // featureRepositoryProviders), and Auth (which stays app-level even when
    // split — see AuthTemplates) redirects there too.
    if (httpClient == 'supabase' && hasRiverpod && corePackageName == null) {
      await _write(
        '$lib/core/network/supabase_provider.dart',
        CoreTemplates.supabaseProvider(packageName: packageName, useAnnotations: useAnnotations),
      );
    }

    // ── core/network + firebase_options (Firebase backend) ───────────────────
    // packageSplit: same reasoning as supabase above for firebase_provider.dart
    // — firebase_options.dart/firestore config stay app-level regardless (not
    // Dart-importable, no boundary to cross).
    if (httpClient == 'firebase' && hasRiverpod && corePackageName == null) {
      await _write(
        '$lib/core/network/firebase_provider.dart',
        CoreTemplates.firebaseProvider(
          packageName: packageName,
          useAnnotations: useAnnotations,
          hasAuth: hasAuth,
          hasStorage: hasStorage,
        ),
      );
    }
    if (httpClient == 'firebase' && hasRiverpod) {
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
      await _write('${projectDir.path}/firestore.indexes.json', CoreTemplates.firestoreIndexes());
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
          corePackageName: corePackageName,
        ),
      );
      await _write(
        '$lib/core/storage/avatar_upload_field.dart',
        CoreTemplates.avatarUploadField(packageName: packageName),
      );
    }

    // ── core/network (offline-first) ────────────────────────────────────────
    // packageSplit: dead code — every feature's offline-first repository
    // already redirects to corePackageName's copies (see DataTemplates.
    // featureRepositoryImpl/featureRepositoryProviders), and the app itself
    // never reads NetworkInfo/appDatabaseProvider directly.
    if (localStoragePackage != null && corePackageName == null) {
      await _write('$lib/core/network/network_info.dart', CoreTemplates.networkInfo());
    }

    // ── core/providers (shared infrastructure singletons) ────────────────────
    // Drift db + connectivity, declared once for the whole app (not per feature).
    if (localStoragePackage != null && useAnnotations && corePackageName == null) {
      await _write(
        '$lib/core/providers/infrastructure_providers.dart',
        CoreTemplates.infrastructureProviders(
          packageName: packageName,
          localStoragePackage: localStoragePackage,
        ),
      );
    }

    // ── core/sync (offline-first + sync / Outbox) ────────────────────────────
    // packageSplit: dead code — every feature's SyncService provider already
    // redirects to corePackageName's copy (see
    // DataTemplates.featureRepositoryProviders), and the app itself never
    // reads SyncService directly.
    if (localStoragePackage != null && hasSync && corePackageName == null) {
      await _write(
        '$lib/core/sync/sync_service.dart',
        CoreTemplates.syncService(
          packageName: packageName,
          localStoragePackage: localStoragePackage,
        ),
      );
    }

    // ── docs/OFFLINE.md (usage guide) ────────────────────────────────────────
    // Uses the first feature as a worked example — skipped when there isn't
    // one yet (the guide is still useful once a real feature is added via
    // the Workshop, at which point OFFLINE.md can be revisited manually).
    if (localStoragePackage != null && architecture.generateFirstFeature) {
      await _write(
        '${projectDir.path}/docs/OFFLINE.md',
        CoreTemplates.offlineDoc(
          packageName: packageName,
          featureName: featureName,
          localStoragePackage: localStoragePackage,
          hasSync: hasSync,
          fields: architecture.firstFeatureFields,
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
      corePackageName: corePackageName,
    );

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
        hasFirstFeature: architecture.generateFirstFeature,
        featurePackageName: featurePackageName,
        corePackageName: corePackageName,
        hasOnboarding: autoWireOnboarding,
      );
    }

    // ── auth feature (opt-in, Supabase + go_router_builder) ──────────────────
    if (hasAuth) {
      await _writeAuth(
        projectDir: projectDir,
        lib: lib,
        packageName: packageName,
        featureName: featureName,
        backend: httpClient,
        oauth: hasOAuth,
        corePackageName: corePackageName,
        authPackageName: authPackageName,
        hasOnboarding: autoWireOnboarding,
      );
    }

    // ── i18n (slang, opt-in) ─────────────────────────────────────────────────
    // packageSplit: single-sourced in the core package, same reasoning as
    // theme_mode_controller.dart — a split feature's page reads `context.t`/
    // `LanguageSwitcher` from there (see PresentationTemplates), so the app
    // must not keep its own separate copy (that would be a feature→app
    // import if the feature read the app's copy instead — the exact cycle
    // packageSplit exists to avoid).
    if (hasI18n) {
      final i18nRoot = corePackageName != null ? '${projectDir.path}/packages/$corePackageName' : projectDir.path;
      final i18nLib = corePackageName != null ? '$i18nRoot/lib' : lib;
      final i18nPackageName = corePackageName ?? packageName;
      if (i18nFromCsv) {
        // The user uploaded a compact CSV → it is the single source of truth.
        final csv = File(architecture.i18nCsvPath).readAsStringSync();
        final base = I18nImporter.parseLocales(csv).firstOrNull ?? 'en';
        await _write('$i18nRoot/slang.yaml', I18nImporter.slangCsvConfig(base));
        await _write('$i18nLib/i18n/strings.i18n.csv', csv);
      } else {
        // English preferred as the base locale when picked (matches NEAT's
        // long-standing default); otherwise fall back to whatever is selected
        // (at least one is always guaranteed — see ArchitectureNotifier.
        // toggleI18nLocale).
        final locales = architecture.i18nLocales;
        final baseLocale = locales.contains('en') ? 'en' : locales.first;
        await _write(
          '$i18nRoot/slang.yaml',
          I18nTemplates.slangConfig(baseLocale: baseLocale),
        );
        // Non-namespace mode → files are named `<locale>.i18n.json`.
        if (locales.contains('en')) {
          await _write('$i18nLib/i18n/en.i18n.json', I18nTemplates.baseTranslations(featureName));
        }
        if (locales.contains('fr')) {
          await _write('$i18nLib/i18n/fr.i18n.json', I18nTemplates.frTranslations(featureName));
        }
      }
      await _write(
        '$i18nLib/core/i18n/locale_store.dart',
        I18nTemplates.localeStore(packageName: i18nPackageName),
      );
      await _write(
        '$i18nLib/core/i18n/language_switcher.dart',
        I18nTemplates.languageSwitcher(packageName: i18nPackageName),
      );
    }

    // ── onboarding (opt-in, Riverpod annotations only) ────────────────────
    // Always app-level (unlike i18n) — it has no cross-feature dependency to
    // solve, so no packageSplit placement question. The redirect is
    // auto-wired only when autoWireOnboarding (go_router_builder) — see
    // OnboardingTemplates' doc comment for the plain-go_router fallback.
    if (hasOnboarding) {
      await _write(
        '$lib/core/onboarding/onboarding_seen_provider.dart',
        OnboardingTemplates.onboardingSeenProvider(packageName: packageName),
      );
      await _write(
        '$lib/core/onboarding/onboarding_page.dart',
        OnboardingTemplates.onboardingPage(
          packageName: packageName,
          autoWired: autoWireOnboarding,
        ),
      );
      if (autoWireOnboarding) {
        final onboardingHomeRoute = 'AppRoutePath.${_camelCase(featureName)}';
        await _write(
          '$lib/core/onboarding/onboarding_routes.dart',
          OnboardingTemplates.onboardingRoutesBuilder(
            packageName: packageName,
            homeRoute: onboardingHomeRoute,
          ),
        );

        // Aggregate the onboarding route into the shared route table (typed
        // go_router_builder only — see autoWireOnboarding).
        final onboardingRoutesImport =
            "import 'package:$packageName/core/onboarding/onboarding_routes.dart' as onboarding;";
        final routesFile = File('$lib/core/router/routes.dart');
        if (routesFile.existsSync()) {
          var s = await routesFile.readAsString();
          s = _insertBeforeAnchor(s, '// neat:route-imports', onboardingRoutesImport);
          s = _insertBeforeAnchor(s, '// neat:route-entries', r'  ...onboarding.$appRoutes,');
          await routesFile.writeAsString(s);
        }
      }
    }

    // ── components ────────────────────────────────────────────────────────
    await _write('$lib/components/.gitkeep', '');

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
      await _writeFeature(
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
    }
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
    // Set when packageSplit is on: theme_mode_controller.dart is written into
    // the shared core package instead (see _writeCorePackage) — the app must
    // not keep its own separate copy, or the app shell and a split feature
    // page's toggle would watch two different provider instances.
    String? corePackageName,
  }) async {
    // When extracted, theme + tokens + components live in packages/<ui>/lib;
    // their imports target <ui> instead of the app. State (theme mode / bloc)
    // always stays in the app.
    final themePkg = uiPackage ?? packageName;
    final themeLib = uiPackage != null ? '${projectDir.path}/packages/$uiPackage/lib' : lib;
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
      final widgetbookApp = ThemeTemplates.widgetbookApp(
        packageName: themePkg,
        components: theme.components,
      );
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

    // theme mode controller — single-sourced from the core package when
    // packageSplit is on (see this function's corePackageName doc).
    if (hasRiverpod && corePackageName == null) {
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
          '$appT/brightness_theme/brightness_cubit.dart',
          ThemeTemplates.brightnessCubit(),
        );
        await _write(
          '$appT/brightness_theme/brightness_state.dart',
          ThemeTemplates.brightnessCubitState(),
        );
      } else {
        await _write(
          '$appT/brightness_theme/brightness_bloc.dart',
          ThemeTemplates.brightnessBloc(),
        );
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
  sdk: ^3.12.0
  flutter: ">=1.17.0"

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
    await _write(
      '$root/lib/widgets/asset_images.dart',
      ThemeTemplates.assetWidgets(packageName: uiPackage),
    );
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
  String _widgetbookPubspec(String packageName, String uiPackage) =>
      '''name: ${packageName}_widgetbook
description: "Interactive component catalog — generated by NEAT."
version: 0.1.0
publish_to: 'none'

environment:
  sdk: ^3.12.0
  flutter: ">=1.17.0"

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
    required List<EnvConfig> environments,
    bool singleEnv = false,
    bool hasSupabase = false,
    bool hasApiBaseUrl = true,
  }) async {
    // Dart: contract shared by every env.
    await _write(
      '$lib/core/env/app_env.dart',
      CoreTemplates.appEnv(hasApiBaseUrl: hasApiBaseUrl, hasSupabase: hasSupabase),
    );

    if (singleEnv) {
      // One env → a single `Env`/`EnvVars` reading a plain `.env` (no flavor
      // suffix, no per-env classes, no entry points).
      final env = environments.first;
      await _write(
        '$lib/core/env/envs/env.dart',
        CoreTemplates.flavorEnv(
          packageName: packageName,
          flavor: env.flavor,
          single: true,
          hasApiBaseUrl: hasApiBaseUrl,
          hasSupabase: hasSupabase,
        ),
      );
      await _write(
        '${projectDir.path}/.env',
        CoreTemplates.envFile(
          appName: packageName,
          hasApiBaseUrl: hasApiBaseUrl,
          hasSupabase: hasSupabase,
          apiBaseUrl: env.apiBaseUrl,
          supabaseUrl: env.supabaseUrl,
          supabaseKey: env.supabaseAnonKey,
        ),
      );
    } else {
      // ≥2 envs: per-env envied classes + `.env.<flavor>` files (must exist
      // before build_runner so envied can read them). The user-provided API URL
      // (if any) is pre-filled per environment.
      for (final env in environments) {
        await _write(
          '$lib/core/env/envs/${env.flavor}_env.dart',
          CoreTemplates.flavorEnv(
            packageName: packageName,
            flavor: env.flavor,
            hasApiBaseUrl: hasApiBaseUrl,
            hasSupabase: hasSupabase,
          ),
        );
      }
      for (final env in environments) {
        await _write(
          '${projectDir.path}/.env.${env.flavor}',
          CoreTemplates.envFile(
            appName: packageName,
            hasApiBaseUrl: hasApiBaseUrl,
            hasSupabase: hasSupabase,
            apiBaseUrl: env.apiBaseUrl,
            supabaseUrl: env.supabaseUrl,
            supabaseKey: env.supabaseAnonKey,
          ),
        );
      }
    }
    await _write(
      '${projectDir.path}/.env.example',
      CoreTemplates.envFile(
        appName: packageName,
        hasApiBaseUrl: hasApiBaseUrl,
        hasSupabase: hasSupabase,
      ),
    );

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

  /// [authPackageName] set when packageSplit is on: Auth (screens included)
  /// becomes its own workspace package (`packages/auth/`, package-root
  /// layout like any other split feature) instead of `lib/features/auth/`,
  /// depending on [corePackageName] for Result/Failure/UseCase rather than
  /// duplicating them the way wesioo's standalone `authentication` package
  /// does (see ROADMAP.md §6a).
  Future<void> _writeAuth({
    required Directory projectDir,
    required String lib,
    required String packageName,
    required String featureName,
    String backend = 'supabase',
    bool oauth = false,
    String? corePackageName,
    String? authPackageName,
    bool hasOnboarding = false,
  }) async {
    final a = authPackageName != null
        ? '${projectDir.path}/packages/$authPackageName/lib'
        : '$lib/features/auth';
    if (authPackageName != null) {
      await _write(
        '${projectDir.path}/packages/$authPackageName/pubspec.yaml',
        CorePackageTemplates.featurePackagePubspec(
          featurePackageName: authPackageName,
          corePackageName: corePackageName!,
          httpClient: backend,
          hasGoRouterBuilder: true, // generateAuth already requires it
        ),
      );
    }
    await _write(
      '$a/domain/repositories/i_auth_repository.dart',
      AuthTemplates.iAuthRepository(
        packageName: packageName,
        oauth: oauth,
        corePackageName: corePackageName,
      ),
    );
    await _write(
      '$a/data/repositories/auth_repository_impl.dart',
      AuthTemplates.authRepositoryImpl(
        packageName: packageName,
        backend: backend,
        oauth: oauth,
        corePackageName: corePackageName,
        authPackageName: authPackageName,
      ),
    );
    await _write(
      '$a/presentation/providers/auth_provider.dart',
      AuthTemplates.authProvider(
        packageName: packageName,
        backend: backend,
        corePackageName: corePackageName,
      ),
    );
    await _write(
      '$a/data/repositories/auth_repository_providers.dart',
      AuthTemplates.authRepositoryProviders(
        packageName: packageName,
        backend: backend,
        corePackageName: corePackageName,
        authPackageName: authPackageName,
      ),
    );
    await _write(
      '$a/presentation/screens/login_screen.dart',
      AuthTemplates.loginScreen(
        packageName: packageName,
        oauth: oauth,
        corePackageName: corePackageName,
        authPackageName: authPackageName,
      ),
    );
    await _write(
      '$a/presentation/screens/signup_screen.dart',
      AuthTemplates.signupScreen(
        packageName: packageName,
        corePackageName: corePackageName,
        authPackageName: authPackageName,
      ),
    );
    await _write(
      '$a/presentation/screens/forgot_password_screen.dart',
      AuthTemplates.forgotPasswordScreen(
        packageName: packageName,
        corePackageName: corePackageName,
        authPackageName: authPackageName,
      ),
    );
    await _write(
      '$a/presentation/routes/auth_routes.dart',
      AuthTemplates.authRoutesBuilder(
        packageName: packageName,
        corePackageName: corePackageName,
        authPackageName: authPackageName,
      ),
    );

    // The go_router guard. Logged-in users on an auth route go to the first
    // feature's route ('/'). router_notifier.dart always stays app-level.
    final homeRoute = 'AppRoutePath.${_camelCase(featureName)}';
    await _write(
      '$lib/core/router/router_notifier.dart',
      AuthTemplates.routerNotifier(
        packageName: packageName,
        homeRoute: homeRoute,
        backend: backend,
        authPackageName: authPackageName,
        hasOnboarding: hasOnboarding,
      ),
    );

    // Aggregate the auth routes into the shared route table (at the anchors).
    final authRoutesImport = authPackageName != null
        ? "import 'package:$authPackageName/presentation/routes/auth_routes.dart' as auth;"
        : "import 'package:$packageName/features/auth/presentation/routes/auth_routes.dart' as auth;";
    final routes = File('$lib/core/router/routes.dart');
    if (routes.existsSync()) {
      var s = await routes.readAsString();
      s = _insertBeforeAnchor(s, '// neat:route-imports', authRoutesImport);
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
    await _write(
      '$r/app_router.dart',
      hasGoRouterBuilder
          ? CoreTemplates.appRouterBuilder(
              packageName: packageName,
              featureName: featureName,
              useAnnotations: useAnnotations,
              hasAuth: hasAuth,
              hasFirstFeature: hasFirstFeature,
              hasOnboarding: hasOnboarding,
            )
          : CoreTemplates.appRouter(
              packageName: packageName,
              featureName: featureName,
              hasFirstFeature: hasFirstFeature,
            ),
    );

    // No first feature (never combined with a shell — see useShell's guard
    // in execute()): the welcome placeholder owns routes.dart instead.
    if (!hasFirstFeature) {
      if (hasGoRouterBuilder) {
        await _write('$r/welcome_route.dart', CoreTemplates.welcomeRoute(packageName: packageName));
        await _write(
          '$r/routes.dart',
          CoreTemplates.routesAggregatorWelcome(packageName: packageName),
        );
      } else {
        await _write('$r/routes.dart', CoreTemplates.routesManualWelcome(packageName: packageName));
      }
      return;
    }

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
          CoreTemplates.appShellRouteBuilder(
            packageName: packageName,
            featureName: featureName,
            featurePackageName: featurePackageName,
            corePackageName: corePackageName,
          ),
        );
        await _write(
          '$r/routes.dart',
          CoreTemplates.routesAggregatorShell(packageName: packageName),
        );
      } else {
        await _write(
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

    await _write(
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
            ),
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
    bool i18n = false,
    bool packageSplit = false,
    String? corePackageName,
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
      i18n: i18n,
      fields: architecture.firstFeatureFields,
      apiPath: architecture.firstFeatureApiPath.isEmpty ? null : architecture.firstFeatureApiPath,
      // The simple detail/create sheets are scoped to NEAT's own worked
      // example for now (see FeatureScaffolder.writeFeature's includeCrudUi
      // doc) — not a general Workshop/wizard capability yet. `generateFirstFeature`
      // alone isn't enough to identify it: plenty of tests/flows still set an
      // arbitrary first feature (e.g. Firebase/Supabase realtime's "todo")
      // with the plain `_riverpodListNotifier`, which has no addItem/removeItem
      // — only the wizard's Example toggle ever produces this exact apiPath.
      includeCrudUi: architecture.firstFeatureApiPath == 'https://fakestoreapi.com/products',
      packageSplit: packageSplit,
      corePackageName: corePackageName,
      // The wizard's first feature only ever becomes a shell branch, never a
      // child of one (that combination only exists via the Workshop) — so
      // needsShellRegistration is exactly isShellBranch here.
      needsShellRegistration: isShellBranch,
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
  Future<void> _writeBranding(Directory projectDir, String logoPath, List<String> platforms) async {
    final src = File(logoPath);
    if (!src.existsSync()) return;
    final dest = File('${projectDir.path}/assets/branding/logo.png');
    await dest.create(recursive: true);
    await dest.writeAsBytes(await src.readAsBytes());
    await _write(
      '${projectDir.path}/flutter_launcher_icons.yaml',
      CoreTemplates.launcherIconsConfig(platforms: platforms),
    );
    await _write(
      '${projectDir.path}/flutter_native_splash.yaml',
      CoreTemplates.nativeSplashConfig(platforms: platforms),
    );
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
        onLog(
          result.exitCode == 0
              ? '[✓] ${args.last} done.'
              : '[!] ${args.last}: ${result.stderr.toString().trim().split('\n').take(1).join()}',
        );
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
    bool addSlang = false,
    bool addOnboarding = false,
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
      addSlang: addSlang,
      addOnboarding: addOnboarding,
    );

    await pubspecFile.writeAsString(content);
  }

  // ── Shared core workspace package ───────────────────────────────────────────

  /// Writes the `packages/<name>_core` workspace member: every file is
  /// generated by **reusing the existing app-level templates**
  /// (`CoreTemplates`/`CoreDartTemplates`), just pointed at [corePackageName]
  /// instead of the app's own package name — same content, different home.
  /// [httpClient] drives NetworkErrorHandler + which client provider ships
  /// (dio for dio, chopper's client + its witness-free decoder
  /// registry for chopper). When [hasEnvied] is on too, the dio/chopper
  /// client's `baseUrl` can't read `AppEnv` directly (this package sits
  /// below the app, which owns it) — it reads a settable `ApiConfig.baseUrl`
  /// instead, bridged from `bootstrap()` (see `CoreTemplates.apiConfig`/
  /// `dioProvider`/`chopperClientProvider`'s `sharedConfig` param). Real bug,
  /// found via a real packageSplit + envied + chopper project: without this,
  /// every split feature's remote call silently hits an empty baseUrl
  /// (`Invalid argument(s): No host specified in URI ...`).
  Future<void> _writeCorePackage(
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
  }) async {
    final root = '${projectDir.path}/packages/$corePackageName';
    await _write(
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
    await _write('$root/lib/core/error/failure.dart', CoreTemplates.failure());
    await _write(
      '$root/lib/core/result/result.dart',
      CoreDartTemplates.coreResultDart(packageName: corePackageName),
    );
    await _write(
      '$root/lib/core/usecases/use_case.dart',
      CoreDartTemplates.coreUsecaseDart(packageName: corePackageName),
    );
    await _write(
      '$root/lib/core/network/network_error_handler.dart',
      CoreTemplates.networkErrorHandler(packageName: corePackageName, httpClient: httpClient),
    );
    final isDioBased = httpClient == 'dio';
    // Bridges AppEnv.apiBaseUrl into this package when both apply — see this
    // method's doc comment.
    if (hasEnvied && (isDioBased || httpClient == 'chopper')) {
      await _write('$root/lib/core/network/api_config.dart', CoreTemplates.apiConfig());
    }
    // Shell page registry (see this method's doc comment) — seeded with the
    // first branch (the wizard's own first feature) as a witness.
    if (useShell) {
      await _write(
        '$root/lib/core/router/shell_page_registry.dart',
        CoreTemplates.shellPageRegistry(
          packageName: corePackageName,
          featurePackageName: featurePackageName,
          featureName: featureName,
        ),
      );
    }
    if (isDioBased) {
      await _write(
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
      await _write(
        '$root/lib/core/network/chopper_model_converter.dart',
        CoreTemplates.chopperModelConverter(packageName: corePackageName),
      );
      await _write(
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
      await _write(
        '$root/lib/core/network/supabase_provider.dart',
        CoreTemplates.supabaseProvider(packageName: corePackageName, useAnnotations: true),
      );
    }
    if (httpClient == 'firebase') {
      await _write(
        '$root/lib/core/network/firebase_provider.dart',
        CoreTemplates.firebaseProvider(
          packageName: corePackageName,
          useAnnotations: true,
          hasAuth: hasAuth,
          hasStorage: hasStorage,
        ),
      );
    }
    await _write(
      '$root/lib/core/observers/logger_interceptor.dart',
      CoreTemplates.loggerInterceptor(packageName: corePackageName, httpClient: httpClient),
    );
    await _write(
      '$root/lib/core/utils/app_logger.dart',
      CoreTemplates.appLogger(useEnvied: false, packageName: corePackageName),
    );
    await _write(
      '$root/lib/core/utils/future_extensions.dart',
      CorePackageTemplates.futureExtensions(),
    );
    await _write(
      '$root/lib/core/constants/app_route_path.dart',
      // hasAuth: the split Auth package's screens/routes import AppRoutePath
      // from here, so the login/signup/forgotPassword constants must be
      // mirrored here too — missing this made every auth route constant
      // undefined in the auth package (found via a failing integration test).
      // hasOnboarding: same shape of bug, found the same way — see the param
      // doc above.
      CoreTemplates.appRoutePath(
        featureName: featureName,
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
    await _write(
      '$root/lib/core/theme/theme_mode_controller.dart',
      ThemeTemplates.themeModeControllerRiverpod(packageName: corePackageName),
    );
    if (localStoragePackage != null) {
      await _write('$root/lib/core/network/network_info.dart', CoreTemplates.networkInfo());
      await _write(
        '$root/lib/core/providers/infrastructure_providers.dart',
        CoreTemplates.infrastructureProviders(
          packageName: corePackageName,
          localStoragePackage: localStoragePackage,
        ),
      );
      if (hasSync) {
        await _write(
          '$root/lib/core/sync/sync_service.dart',
          CoreTemplates.syncService(
            packageName: corePackageName,
            localStoragePackage: localStoragePackage,
          ),
        );
      }
    }
  }

  // ── Offline-first workspace package ─────────────────────────────────────────

  /// Writes the minimal `packages/<name>_local_storage` workspace member.
  /// (Phase 1: compiles & is wired into the workspace; Drift lands in Phase 2.)
  Future<void> _writeLocalStoragePackage(
    Directory projectDir,
    String localStoragePackage, {
    required String featureName,
    bool hasSync = false,
    List<FieldSpec> fields = FieldSpec.idName,
    bool includeFirstTable = true,
  }) async {
    final root = '${projectDir.path}/packages/$localStoragePackage';
    await _write(
      '$root/pubspec.yaml',
      LocalStorageTemplates.packagePubspec(packageName: localStoragePackage),
    );
    await _write('$root/build.yaml', LocalStorageTemplates.buildYaml());
    await _write(
      '$root/lib/$localStoragePackage.dart',
      LocalStorageTemplates.publicApi(packageName: localStoragePackage),
    );
    await _write(
      '$root/lib/src/database.dart',
      LocalStorageTemplates.database(
        featureName: featureName,
        withOutbox: hasSync,
        fields: fields,
        includeFirstTable: includeFirstTable,
      ),
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
    bool addSlang = false,
    bool addOnboarding = false,
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

    // Generated Cubit/Bloc code always imports package:flutter_bloc — inject
    // it when the user picked a bloc-family package that isn't flutter_bloc
    // itself (e.g. the plain, Flutter-less `bloc` package from a pub.dev
    // search) so the project still compiles.
    final hasBlocFamily = uniquePackages.any((p) => p.name.contains('bloc'));
    final hasFlutterBlocExplicit = uniquePackages.any((p) => p.name == 'flutter_bloc');
    if (hasBlocFamily && !hasFlutterBlocExplicit) {
      deps.write('  flutter_bloc: ^9.1.1\n');
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
    // slang i18n: runtime (slang + slang_flutter + flutter_localizations) +
    // shared_preferences for locale persistence. Codegen runs via the slang CLI
    // (`dart run slang`), not slang_build_runner — see _runSlang.
    if (addSlang) {
      if (!uniquePackages.any((p) => p.name == 'slang')) {
        deps.write('  slang: ^4.16.0\n');
      }
      if (!uniquePackages.any((p) => p.name == 'slang_flutter')) {
        deps.write('  slang_flutter: ^4.16.0\n');
      }
      if (!uniquePackages.any((p) => p.name == 'flutter_localizations')) {
        deps.write('  flutter_localizations:\n    sdk: flutter\n');
      }
      // Persist the chosen locale across restarts (LocaleStore).
      if (!uniquePackages.any((p) => p.name == 'shared_preferences')) {
        deps.write('  shared_preferences: ^2.3.3\n');
      }
    }
    // Onboarding: shared_preferences for the "seen it" flag — same package
    // LocaleStore uses for locale persistence, so guard against addSlang
    // already having added it (avoid a duplicate line).
    if (addOnboarding &&
        !addSlang &&
        !uniquePackages.any((p) => p.name == 'shared_preferences')) {
      deps.write('  shared_preferences: ^2.3.3\n');
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
    // Path deps on local workspace packages (e.g. <app>_ui, local_storage).
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
    final members = [...pathPackages.map((p) => 'packages/$p'), ...extraWorkspaceMembers];
    if (members.isNotEmpty) {
      final block = members.map((m) => '  - $m').join('\n');
      content = '${content.trimRight()}\n\nworkspace:\n$block\n';
    }

    // drift_dev 2.34.0's query analyzer calls a `DartPlaceholder.when()` method
    // that sqlparser removed in 0.44.6 (a breaking change published under a
    // compatible `^0.44.0` constraint, so pub picks it up without a conflict —
    // the build just fails at codegen time). Override stays workspace-wide
    // here (a pub workspace resolves one version of everything) until
    // drift_dev bumps its own sqlparser constraint past the break.
    if (addConnectivity) {
      content = '${content.trimRight()}\n\n'
          'dependency_overrides:\n'
          '  sqlparser: ">=0.44.0 <0.44.6"\n';
    }

    return content;
  }

  // ── CI/CD files ───────────────────────────────────────────────────────────

  // ── Build flavors (dev/staging/prod) ────────────────────────────────────────

  static String _titleCase(String snake) => snake
      .split('_')
      .where((w) => w.isNotEmpty)
      .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');

  Future<void> _writeFlavors(
    Directory projectDir,
    String appName,
    List<String> flavors, {
    required bool nativeFlavors,
  }) async {
    // VS Code run/debug configs, one per env (--flavor only with native flavors).
    await _write(
      '${projectDir.path}/.vscode/launch.json',
      _launchJson(flavors, nativeFlavors: nativeFlavors),
    );
    // How-to (covers the iOS Xcode-scheme step we can't script reliably).
    await _write(
      '${projectDir.path}/docs/FLAVORS.md',
      _flavorsDoc(appName, flavors, nativeFlavors: nativeFlavors),
    );
    // Android productFlavors only make sense for native (mobile) flavors.
    if (nativeFlavors) {
      await _patchAndroidFlavors(projectDir, appName, flavors);
    }
  }

  static String _pascalFlavor(String flavor) => _titleCase(flavor).replaceAll(' ', '');

  /// Inserts Gradle `productFlavors` (one per environment) before `buildTypes {`
  /// and points the manifest label at the per-flavor `@string/app_name`. The
  /// **last** flavor is the production base (no appId suffix). No-op if the
  /// flutter-created Gradle/Manifest layout isn't recognised.
  Future<void> _patchAndroidFlavors(
    Directory projectDir,
    String appName,
    List<String> flavors,
  ) async {
    final gradle = File('${projectDir.path}/android/app/build.gradle.kts');
    if (gradle.existsSync()) {
      var src = await gradle.readAsString();
      if (!src.contains('productFlavors') && src.contains('buildTypes {')) {
        final base = flavors.last;
        final flavorsBlock = StringBuffer();
        for (final f in flavors) {
          final isBase = f == base;
          final label = isBase ? appName : '$appName ${_titleCase(f)}';
          flavorsBlock.writeln('        create("$f") {');
          flavorsBlock.writeln('            dimension = "env"');
          if (!isBase) {
            flavorsBlock.writeln('            applicationIdSuffix = ".$f"');
            flavorsBlock.writeln('            versionNameSuffix = "-$f"');
          }
          flavorsBlock.writeln('            resValue("string", "app_name", "$label")');
          flavorsBlock.writeln('        }');
        }
        // AGP 8+ disables resValues by default; the per-flavor app_name needs it.
        final block =
            '''    buildFeatures {
        resValues = true
    }
    flavorDimensions += "env"
    productFlavors {
${flavorsBlock.toString().trimRight()}
    }

''';
        src = src.replaceFirst('    buildTypes {', '$block    buildTypes {');
        await gradle.writeAsString(src);
      }
    }

    // Point the launcher label at the flavor-provided string resource.
    final manifest = File('${projectDir.path}/android/app/src/main/AndroidManifest.xml');
    if (manifest.existsSync()) {
      var src = await manifest.readAsString();
      src = src.replaceAll(RegExp(r'android:label="[^"]*"'), 'android:label="@string/app_name"');
      await manifest.writeAsString(src);
    }
  }

  String _launchJson(List<String> flavors, {required bool nativeFlavors}) {
    String args(String f) => nativeFlavors ? ',\n      "args": ["--flavor", "$f"]' : '';
    final configs = <String>[
      for (final f in flavors)
        '''    {
      "name": "${_titleCase(f)} (debug)",
      "request": "launch",
      "type": "dart",
      "program": "lib/main_$f.dart"${args(f)}
    }''',
      // Release config for the production (last) env.
      '''    {
      "name": "${_titleCase(flavors.last)} (release)",
      "request": "launch",
      "type": "dart",
      "flutterMode": "release",
      "program": "lib/main_${flavors.last}.dart"${args(flavors.last)}
    }''',
    ];
    return '''{
  "version": "0.2.0",
  "configurations": [
${configs.join(',\n')}
  ]
}
''';
  }

  String _flavorsDoc(String appName, List<String> flavors, {required bool nativeFlavors}) {
    final base = flavors.last;
    final envFiles = flavors.map((f) => '`.env.$f`').join(' / ');
    final envClasses = flavors.map((f) => '${_pascalFlavor(f)}Env').join(' / ');
    final first = flavors.first;

    // Without native flavors (web/desktop targets, or the opt-in left off), the
    // environments are pure Dart entry points: same app id, selected via `-t`.
    if (!nativeFlavors) {
      final rows = flavors
          .map((f) {
            final tag = f == base ? '`$f` *(production base)*' : '`$f`';
            return '| $tag | `lib/main_$f.dart` | `.env.$f` → ${_pascalFlavor(f)}Env |';
          })
          .join('\n');
      return '''# Environments (${flavors.join(' / ')})

This project wires ${flavors.length} environments as **Dart entry points** (no native
build flavors — your targets don't support them, or the opt-in is off). They share a
single app id and are selected by the entry point you run. The **last** env (`$base`)
is the production base.

| Environment | Entry point | Config |
| --- | --- | --- |
$rows

## Run / build

```sh
flutter run -t lib/main_$first.dart
flutter build web --release -t lib/main_$base.dart
```

VS Code: pick an environment from the Run and Debug panel (`.vscode/launch.json`).

## Config (envied)

Each env's secrets live in $envFiles, baked into the generated $envClasses classes
at `build_runner` time and selected by the entry point
(`bootstrap(${_pascalFlavor(first)}Env())`, …). The API base URL you entered is
pre-filled in each `.env.<env>`.

> Enable **native build flavors** (Infrastructure step) on an Android/iOS target to
> get separate app ids + names that install side-by-side.
''';
    }

    final rows = flavors
        .map((f) {
          final isBase = f == base;
          final suffix = isBase ? '—' : '`.$f`';
          final label = isBase ? appName : '$appName ${_titleCase(f)}';
          return '| $f | `lib/main_$f.dart` | $suffix | $label |';
        })
        .join('\n');
    return '''# Build flavors (${flavors.join(' / ')})

This project ships ${flavors.length} flavors. Each pairs a **native flavor** (separate
app id + name, so they install side-by-side) with a **Dart entry point** that loads
the matching envied config. The **last** flavor (`$base`) is the production base.

| Flavor | Entry point | App id suffix | App name |
| --- | --- | --- | --- |
$rows

## Run / build

```sh
flutter run   --flavor $first -t lib/main_$first.dart
flutter build appbundle --release --flavor $base -t lib/main_$base.dart
```

VS Code: pick a flavor from the Run and Debug panel (`.vscode/launch.json`).

## Config (envied)

Each flavor's secrets live in $envFiles, baked into the generated
$envClasses classes at `build_runner` time and selected by the entry point
(`bootstrap(${_pascalFlavor(first)}Env())`, …). The API base URL you entered is
pre-filled in each `.env.<flavor>`.

## Android — done

`android/app/build.gradle.kts` defines `productFlavors`; the launcher name comes
from the per-flavor `@string/app_name`. Nothing else to do.

## iOS — one manual step

Flutter's `--flavor` needs a matching **Xcode scheme** + build configurations, which
can't be generated reliably. In Xcode: duplicate the `Runner` scheme per flavor and
add `Debug-<flavor>` / `Release-<flavor>` build configs (set
`PRODUCT_BUNDLE_IDENTIFIER` + `PRODUCT_NAME` per flavor via an `.xcconfig`). See
https://docs.flutter.dev/deployment/flavors.
''';
  }

  Future<void> _writeCicdFiles(
    Directory projectDir,
    CicdState cicd, {
    bool hasFlavors = false,
  }) async {
    final generated = const GenerateYamlUsecase().execute(cicd, hasFlavors: hasFlavors);

    for (final file in generated) {
      final f = File('${projectDir.path}/${file.filename}');
      await f.create(recursive: true);
      await f.writeAsString(file.content);
    }

    // Keep fastlane secrets + signing material out of git.
    if (cicd.isSelected(CiTool.fastlane)) {
      await _appendGitignore(projectDir, '''

# fastlane secrets + Android signing (keep only the .example files)
**/fastlane/.env
android/key.properties
**/*.jks
**/*.keystore
''');
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
