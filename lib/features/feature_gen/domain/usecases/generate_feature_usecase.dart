import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:neat/features/feature_gen/domain/models/feature_gen_options.dart';
import 'package:neat/features/feature_gen/domain/models/loaded_project.dart';
import 'package:neat/features/generation/domain/models/field_spec.dart';
import 'package:neat/features/generation/domain/services/feature_scaffolder.dart';
import 'package:neat/features/generation/domain/services/templates/core_package_templates.dart';
import 'package:neat/features/generation/domain/services/templates/core_templates.dart';
import 'package:neat/features/generation/domain/services/templates/local_storage_templates.dart';

/// Adds a new feature to an existing NEAT project, deriving every choice from
/// the project's Workspace Contract (`.neat.json`) so the new feature matches
/// the existing stack exactly. Non-destructive: it refuses to overwrite an
/// existing feature.
class GenerateFeatureUsecase {
  const GenerateFeatureUsecase();

  Future<void> execute({
    required LoadedProject project,
    required FeatureGenOptions options,
    required void Function(String) onLog,
  }) async {
    final featureName = options.name;
    final c = project.contract;
    final lib = '${project.path}/lib';
    final isFeatureFirst = c.architecture == 'feature_first';

    // Modular Monorepo (ROADMAP.md §6a): once a project is packageSplit, every
    // feature — including ones added later here — lives in its own workspace
    // package instead of a folder under lib/features/. Names follow the same
    // convention the wizard itself uses.
    final packageSplit = c.packageSplit;
    final corePackageName = packageSplit ? 'core' : null;
    final featurePackageName = packageSplit ? featureName : null;

    // Non-destructive guard.
    final featureDir = Directory(
      packageSplit
          ? '${project.path}/packages/$featurePackageName'
          : isFeatureFirst
              ? '$lib/features/$featureName'
              : '$lib/domain/$featureName',
    );
    if (featureDir.existsSync()) {
      throw Exception('Feature "$featureName" already exists — aborting (nothing overwritten).');
    }

    // Derive flags from the contract (the project stack) …
    final hasRiverpod = c.stateManagement == 'riverpod';
    final hasBloc = c.stateManagement == 'bloc';
    final useAnnotations = c.useRiverpodAnnotations && hasRiverpod;
    final hasGoRouterBuilder = c.navigation == 'go_router_builder';
    final hasGoRouter = c.navigation == 'go_router' || hasGoRouterBuilder;
    final projectHasHttp = c.httpClient != 'none';
    final localStoragePackage = c.storageStrategy != 'remoteOnly' ? 'local_storage' : null;
    final hasSync = c.storageStrategy == 'offlineFirstSync';

    // "Custom Endpoints" (ROADMAP.md §7 Phase 2): chopper-only, remote-only,
    // and — for this pass — not combined with packageSplit (the chopper
    // decoder registry crossing into core, `EndpointTemplates.endpointUsecase`
    // threading corePackageName, etc. aren't exercised together yet; same
    // "don't combine an unproven combo with another" discipline this
    // ROADMAP already applies elsewhere). Reject clearly instead of
    // generating something broken.
    if (options.useCustomEndpoints) {
      if (c.httpClient != 'chopper') {
        throw Exception(
          'Custom Endpoints requires chopper as the project\'s HTTP client '
          '(see ROADMAP.md §7 Phase 2) — this project uses "${c.httpClient}".',
        );
      }
      if (packageSplit) {
        throw Exception(
          'Custom Endpoints isn\'t supported yet for packageSplit projects '
          '(see ROADMAP.md §7 Phase 2). Add it as a normal (non-split) feature '
          'instead.',
        );
      }
    }

    // … then refine them with the per-feature Workshop choices. The feature can
    // only use stack capabilities the project actually has (you can't add a
    // remote source if the project has no HTTP client).
    final effHasHttp =
        options.useCustomEndpoints || (projectHasHttp && options.includeRemoteDataSource);
    final httpClient = options.useCustomEndpoints ? 'chopper' : (effHasHttp ? c.httpClient : '');
    // A local-only feature (no remote) always keeps its local source. Custom
    // endpoints are remote-only by design — never a local source.
    final writeLocal = !options.useCustomEndpoints && (options.includeLocalDataSource || !effHasHttp);
    // Drift-backed local source → the feature needs a typed table injected.
    final needsDriftTable = localStoragePackage != null && writeLocal;

    // A child route nests under an existing feature instead of getting its own
    // top-level route (supported for both go_router and go_router_builder).
    final asChild = hasGoRouter &&
        options.routing == FeatureRouting.child &&
        options.parentFeature.isNotEmpty;
    // A shell branch joins the app's StatefulShellRoute (bottom NavigationBar).
    final asShell = hasGoRouter && options.routing == FeatureRouting.shell;

    // packageSplit + child route (§6a Phase 3): plain go_router nests the
    // child's GoRoute inside the parent's *within the app's own shared
    // routes.dart* — the app already depends on every feature package for
    // their own top-level routes, so no new cross-feature dependency is
    // needed there, just the right import path (see _wireChildRoute below).
    // go_router_builder is the genuinely cross-feature case: the nested
    // TypedGoRoute lives inside the *parent package's own*
    // `<parent>_routes.dart`, so the parent needs a real `path:` dependency
    // onto the child package (see _wireChildRouteBuilder/
    // _addPathDependencyToPackage) — a one-way edge (child never depends back
    // on parent), so no cycle, unlike arbitrary two-way feature coupling.
    final parentPackageName = packageSplit ? options.parentFeature : null;

    // packages/<pkg>_<feature>/pubspec.yaml + wiring into the root workspace —
    // same shape as the wizard's own first split feature (see
    // CorePackageTemplates.featurePackagePubspec / LaunchGenerationUsecase).
    if (packageSplit) {
      final featurePubspec = File('${project.path}/packages/$featurePackageName/pubspec.yaml');
      await featurePubspec.create(recursive: true);
      await featurePubspec.writeAsString(
        CorePackageTemplates.featurePackagePubspec(
          featurePackageName: featurePackageName!,
          corePackageName: corePackageName!,
          httpClient: c.httpClient,
          hasGoRouterBuilder: hasGoRouterBuilder,
          localStoragePackage: localStoragePackage,
        ),
      );
      await _addWorkspaceMember(project.path, featurePackageName);
      // routes.dart (or the shell scaffold) imports the new package directly.
      await _addPathDependency(project.path, featurePackageName);
    }

    onLog('[▶] Generating feature "$featureName" (matching the project stack)...');
    await const FeatureScaffolder().writeFeature(
      lib: packageSplit ? '${project.path}/packages/$featurePackageName/lib' : lib,
      featureName: featureName,
      packageName: c.projectName,
      isFeatureFirst: isFeatureFirst,
      mirrorTestStructure: c.mirrorTestStructure,
      hasRiverpod: hasRiverpod,
      hasBloc: hasBloc,
      useCubit: c.useCubit && hasBloc,
      useAnnotations: useAnnotations,
      hasGoRouter: hasGoRouter,
      hasGoRouterBuilder: hasGoRouterBuilder,
      hasHttpClient: effHasHttp,
      httpClient: httpClient,
      hasFreezed: c.hasFreezed,
      hasJsonSerializable: c.hasJsonSerializable,
      localStoragePackage: localStoragePackage,
      hasSync: hasSync,
      includeLocalSource: options.includeLocalDataSource,
      includeUseCases: options.includeUseCase,
      isChildRoute: asChild,
      isShellBranch: asShell,
      fields: options.fields,
      apiPath: options.apiPath.isEmpty ? null : options.apiPath,
      packageSplit: packageSplit,
      corePackageName: corePackageName,
      useCustomEndpoints: options.useCustomEndpoints,
      endpoints: options.endpoints,
    );
    onLog('[✓] Feature files written.');

    // Wire the new feature's routes into the shared router (anchors).
    if (hasGoRouter) {
      // Self-heal: projects generated before the anchor system lack the
      // `// neat:` markers, so insertion would silently no-op. Add them first.
      await _ensureRoutingAnchors(project.path);
      if (asChild) {
        onLog('[▶] Wiring "$featureName" as a child of "${options.parentFeature}"...');
        if (hasGoRouterBuilder) {
          await _wireChildRouteBuilder(
            project.path,
            c.projectName,
            featureName,
            options.parentFeature,
            childPackageName: featurePackageName,
            parentPackageName: parentPackageName,
            corePackageName: corePackageName,
          );
        } else {
          await _wireChildRoute(
            project.path,
            c.projectName,
            featureName,
            options.parentFeature,
            childPackageName: featurePackageName,
            corePackageName: corePackageName,
          );
        }
      } else if (asShell) {
        onLog('[▶] Wiring "$featureName" as a shell branch...');
        await _wireShellBranch(
          project.path,
          c.projectName,
          featureName,
          icon: options.shellIcon,
          label: options.effectiveShellLabel,
          builder: hasGoRouterBuilder,
          onLog: onLog,
          featurePackageName: featurePackageName,
          corePackageName: corePackageName,
        );
      } else {
        onLog('[▶] Wiring routes...');
        await _wireRoutes(
          project.path,
          c.projectName,
          featureName,
          builder: hasGoRouterBuilder,
          featurePackageName: featurePackageName,
          corePackageName: corePackageName,
        );
      }
    }

    // Chopper's built-in JsonConverter can't call a custom Model's fromJson —
    // register this feature's Model in the shared decoder registry (only
    // relevant when the new feature actually generated a
    // <feature>_repository_providers.dart with a register<Feature>
    // ChopperDecoders() to call). That file is only written when
    // `useAnnotations && hasHttpClient && includeUseCases` — see
    // FeatureScaffolder.writeFeature's own gate — so this condition must
    // mirror it exactly. `effHasHttp` alone isn't enough: a real project
    // (Remote Data Source ON, Domain UseCase OFF) still skips the file, but
    // bootstrap.dart was wired to import/call a function that was never
    // generated, breaking the build. Custom-endpoints features never
    // generate that file either (no repository at all) — they register via
    // the separate per-endpoint block below instead.
    if (!options.useCustomEndpoints &&
        httpClient == 'chopper' &&
        useAnnotations &&
        effHasHttp &&
        options.includeUseCase) {
      if (packageSplit) {
        // The split feature already generated its own register<Feature>
        // ChopperDecoders() (see DataTemplates.featureRepositoryProviders) —
        // only bootstrap.dart's call-site wiring is left to do.
        await _registerChopperDecoderSplit(project.path, featurePackageName!, featureName);
      } else {
        await _registerChopperDecoder(project.path, c.projectName, featureName);
      }
    }

    // Custom Endpoints (ROADMAP.md §7 Phase 2): register each endpoint's
    // *response* Model (request models are never decoded, only sent) — never
    // packageSplit here (rejected above), so always the direct, non-split path.
    if (options.useCustomEndpoints) {
      for (final ep in options.endpoints) {
        if (ep.hasResponseBody) {
          await _registerChopperDecoderCustomEndpoint(
            project.path,
            c.projectName,
            featureName,
            ep.name,
          );
        }
      }
    }

    // Offline-first: inject the feature's typed table + DAO into the Drift
    // package (only when the feature actually keeps a Drift-backed local source).
    if (needsDriftTable) {
      onLog('[▶] Injecting Drift table for "$featureName"...');
      await _injectDriftTable(project.path, localStoragePackage, featureName, options.fields);
      // The feature DI references the shared infrastructure providers; create
      // them if this project predates that file (self-heal).
      if (useAnnotations) {
        await _ensureInfrastructureProviders(
          project.path,
          packageSplit ? corePackageName! : c.projectName,
          localStoragePackage,
          corePackageName: corePackageName,
        );
      }
    }

    // Regenerate code if the stack uses generators (riverpod / freezed / json)
    // — custom endpoints always need chopper_generator's `.chopper.dart` part
    // for the API source, regardless of state management.
    final dart = await _resolveDart();
    if (useAnnotations || c.hasFreezed || c.hasJsonSerializable || options.useCustomEndpoints) {
      onLog("[▶] Running 'dart run build_runner build' ($dart)...");
      await _runBuildRunner(dart, project.path, onLog);
    }
    // Drift codegen runs per-package, so build the local-storage package too.
    if (localStoragePackage != null) {
      onLog('[▶] Running build_runner in packages/$localStoragePackage...');
      await _runBuildRunner(dart, '${project.path}/packages/$localStoragePackage', onLog);
    }
    // packageSplit: the new feature package has its own build_runner pass too
    // (riverpod_generator/freezed/json_serializable/go_router_builder/chopper).
    if (packageSplit) {
      onLog('[▶] Running build_runner in packages/$featurePackageName...');
      await _runBuildRunner(dart, '${project.path}/packages/$featurePackageName', onLog);
    }
    // packageSplit + child route + go_router_builder: the *parent* package's
    // own <parent>_routes.dart was just edited too (a new nested
    // TypedGoRoute<ChildRoute> + ChildRoute class needing a generated
    // `$ChildRoute` mixin) — its build_runner pass has to re-run, or the
    // parent package won't compile.
    if (packageSplit && asChild && hasGoRouterBuilder) {
      onLog('[▶] Running build_runner in packages/$parentPackageName...');
      await _runBuildRunner(dart, '${project.path}/packages/$parentPackageName', onLog);
    }
    await _dartFormat(dart, project.path, onLog);
    onLog('[✓✓] Feature "$featureName" added.');
  }

  // ── Chopper decoder registration (inserts at // neat:chopper-decoders) ─────

  /// Registers [featureName]'s Model in the shared chopper decoder registry
  /// (see `CoreTemplates.chopperModelConverter`), so its `Response<XModel>` /
  /// `Response<List<XModel>>` calls decode correctly. No-op if the project has
  /// no chopper converter file (generated before this fix, or a non-chopper
  /// stack — the caller already guards on `httpClient == 'chopper'`).
  Future<void> _registerChopperDecoder(
    String projectPath,
    String packageName,
    String featureName,
  ) async {
    final file = File('$projectPath/lib/core/network/chopper_model_converter.dart');
    if (!file.existsSync()) return;
    final p = _pascal(featureName);
    var s = await file.readAsString();
    s = _insertBefore(s, '// neat:chopper-imports',
        "import 'package:$packageName/features/$featureName/data/models/${featureName}_model.dart';\n");
    s = _insertBefore(
        s, '// neat:chopper-decoders', '  ${p}Model: (json) => ${p}Model.fromJson(json),');
    await file.writeAsString(s);
  }

  /// Custom Endpoints variant (ROADMAP.md §7 Phase 2): registers one
  /// endpoint's *response* Model — same anchor mechanism as
  /// [_registerChopperDecoder], just named `${p}ResponseModel` (an endpoint's
  /// model file, not a feature-wide one) and one call per endpoint that
  /// actually has a response body, rather than once per feature.
  Future<void> _registerChopperDecoderCustomEndpoint(
    String projectPath,
    String packageName,
    String featureName,
    String endpointName,
  ) async {
    final file = File('$projectPath/lib/core/network/chopper_model_converter.dart');
    if (!file.existsSync()) return;
    final p = _pascal(endpointName);
    var s = await file.readAsString();
    s = _insertBefore(
      s,
      '// neat:chopper-imports',
      "import 'package:$packageName/features/$featureName/data/models/${endpointName}_model.dart';\n",
    );
    s = _insertBefore(s, '// neat:chopper-decoders',
        '  ${p}ResponseModel: (json) => ${p}ResponseModel.fromJson(json),');
    await file.writeAsString(s);
  }

  /// packageSplit variant: the split feature already generates its own
  /// `register<Feature>ChopperDecoders()` (see
  /// `DataTemplates.featureRepositoryProviders` — triggered automatically
  /// whenever `packageSplit`+chopper is passed to `FeatureScaffolder`). Core
  /// can't import the feature's Model back to populate its registry itself
  /// (the exact cycle packageSplit exists to avoid), so instead this wires
  /// `bootstrap.dart`'s `// neat:chopper-register-imports`/`-calls` anchors to
  /// import and call that function before anything hits the shared
  /// ChopperClient — mirrors the wizard's own first-feature wiring
  /// (`AppTemplates.bootstrap`). No-op if the project predates these anchors.
  Future<void> _registerChopperDecoderSplit(
    String projectPath,
    String featurePackageName,
    String featureName,
  ) async {
    final file = File('$projectPath/lib/core/bootstrap.dart');
    if (!file.existsSync()) return;
    final p = _pascal(featureName);
    var s = await file.readAsString();
    s = _insertBefore(
      s,
      '// neat:chopper-register-imports',
      "import 'package:$featurePackageName/data/repositories/${featureName}_repository_providers.dart';",
    );
    s = _insertBefore(
      s,
      '// neat:chopper-register-calls',
      '      register${p}ChopperDecoders();',
    );
    await file.writeAsString(s);
  }

  // ── Drift table injection (inserts at the // neat: anchors) ────────────────

  Future<void> _injectDriftTable(
    String projectPath,
    String localStoragePackage,
    String featureName,
    List<FieldSpec> fields,
  ) async {
    final db = File('$projectPath/packages/$localStoragePackage/lib/src/database.dart');
    if (!db.existsSync()) return;
    final p = _pascal(featureName);
    var s = await db.readAsString();
    s = _insertBefore(
        s, '// neat:tables', '${LocalStorageTemplates.featureTable(featureName, fields: fields)}\n');
    s = _insertBefore(s, '// neat:table-names', '    ${p}Rows,');
    s = _insertBefore(s, '// neat:daos', '${LocalStorageTemplates.featureDao(featureName)}\n');

    // Bump the schema version + add a migration step so a device that
    // already has the app installed picks up the new table — Drift only
    // runs onCreate on a brand-new db file, never onUpgrade, unless the
    // version actually changes (see LocalStorageTemplates.database's doc).
    // Self-heals projects generated before this mechanism existed.
    s = _ensureMigrationStrategy(s);
    final newVersion = _currentSchemaVersion(s) + 1;
    s = _setSchemaVersion(s, newVersion);
    s = _insertBefore(
      s,
      '// neat:migrations',
      '          if (from < $newVersion) await m.createTable(${_camel(featureName)}Rows);',
    );
    await db.writeAsString(s);
  }

  /// Reads `int get schemaVersion => N;`. Defaults to 1 if the getter can't
  /// be found (shouldn't happen — every generated database.dart has one).
  @visibleForTesting
  static int currentSchemaVersion(String source) => _currentSchemaVersion(source);
  static int _currentSchemaVersion(String source) {
    final m = RegExp(r'int get schemaVersion => (\d+);').firstMatch(source);
    return m != null ? int.parse(m.group(1)!) : 1;
  }

  static String _setSchemaVersion(String source, int version) =>
      source.replaceFirst(RegExp(r'int get schemaVersion => \d+;'), 'int get schemaVersion => $version;');

  /// Adds the `MigrationStrategy get migration` getter (with the
  /// `// neat:migrations` anchor inside `onUpgrade`) right after the
  /// `schemaVersion` getter, when missing. Idempotent — no-op if a project
  /// already has it (every project generated after this fix does).
  @visibleForTesting
  static String ensureMigrationStrategy(String source) => _ensureMigrationStrategy(source);
  static String _ensureMigrationStrategy(String source) {
    if (source.contains('MigrationStrategy get migration')) return source;
    const anchor = 'int get schemaVersion => ';
    final idx = source.indexOf(anchor);
    if (idx < 0) return source; // can't self-heal without the getter to anchor on
    final lineEnd = source.indexOf('\n', idx);
    if (lineEnd < 0) return source;
    const migrationBlock = '''

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          // neat:migrations
        },
      );
''';
    return source.substring(0, lineEnd + 1) + migrationBlock + source.substring(lineEnd + 1);
  }

  // ── Route wiring (inserts at the // neat: anchors) ─────────────────────────

  Future<void> _wireRoutes(
    String projectPath,
    String packageName,
    String featureName, {
    required bool builder,
    // packageSplit: crosses into the split feature package instead of
    // features/<name>/, and mirrors the AppRoutePath constant into the core
    // package's own copy (split features import AppRoutePath from there, not
    // from the app — see ROADMAP.md §6a).
    String? featurePackageName,
    String? corePackageName,
  }) async {
    final camel = _camel(featureName);
    final pascal = _pascal(featureName);

    // 1. AppRoutePath constant — the app's own copy, always.
    await _addRouteConstant(
      '$projectPath/lib/core/constants/app_route_path.dart',
      camel,
      '/$featureName',
    );
    if (corePackageName != null) {
      await _addRouteConstant(
        '$projectPath/packages/$corePackageName/lib/core/constants/app_route_path.dart',
        camel,
        '/$featureName',
      );
    }

    // 2. routes.dart (single wiring point for both routing modes).
    final routes = File('$projectPath/lib/core/router/routes.dart');
    if (!routes.existsSync()) return;
    var s = await routes.readAsString();
    final pkg = featurePackageName ?? packageName;
    final pathPrefix = featurePackageName != null ? '' : 'features/$featureName/';
    if (builder) {
      s = _insertBefore(
        s,
        '// neat:route-imports',
        "import 'package:$pkg/${pathPrefix}presentation/routes/"
            "${featureName}_routes.dart' as $featureName;",
      );
      s = _insertBefore(s, '// neat:route-entries', '  ...$featureName.\$appRoutes,');
    } else {
      s = _insertBefore(
        s,
        '// neat:route-imports',
        "import 'package:$pkg/${pathPrefix}presentation/pages/"
            "${featureName}_page.dart';",
      );
      s = _insertBefore(
        s,
        '// neat:route-entries',
        '  GoRoute(\n'
            '    path: AppRoutePath.$camel,\n'
            '    builder: (context, state) => const ${pascal}Page(),\n'
            '  ),',
      );
    }
    await routes.writeAsString(s);
  }

  // ── Child route wiring (nests the feature under a parent's GoRoute) ────────

  /// Wires [featureName] as a child of [parentFeature] in plain go_router:
  /// `GoRoute(path: '/parent', routes: [GoRoute(path: 'child', …)])`, navigated
  /// as `/parent/child`. Ensures the parent carries a `// neat:children:<parent>`
  /// anchor (adding a `routes: [...]` clause if it has none yet) so subsequent
  /// children stack cleanly.
  ///
  /// packageSplit (§6a Phase 3): the nesting happens inside the **app's own**
  /// `routes.dart` — the app already depends on every feature package for
  /// their top-level routes, so [childPackageName] only changes the child
  /// page's import path, never adds a dependency. [corePackageName] redirects
  /// the `AppRoutePath` constant the same way every other split-feature
  /// wiring point already does.
  Future<void> _wireChildRoute(
    String projectPath,
    String packageName,
    String featureName,
    String parentFeature, {
    String? childPackageName,
    String? corePackageName,
  }) async {
    final camel = _camel(featureName);

    // 1. AppRoutePath: the full navigable path '/parent/child'.
    await _addRouteConstant(
      '$projectPath/lib/core/constants/app_route_path.dart',
      camel,
      '/$parentFeature/$featureName',
    );
    if (corePackageName != null) {
      await _addRouteConstant(
        '$projectPath/packages/$corePackageName/lib/core/constants/app_route_path.dart',
        camel,
        '/$parentFeature/$featureName',
      );
    }

    // 2. routes.dart: nest the child under the parent (pure transformation).
    final routes = File('$projectPath/lib/core/router/routes.dart');
    if (!routes.existsSync()) return;
    final s = wireChildIntoRoutes(
      routesSource: await routes.readAsString(),
      packageName: packageName,
      featureName: featureName,
      parentFeature: parentFeature,
      childPackageName: childPackageName,
    );
    await routes.writeAsString(s);
  }

  /// go_router_builder variant: nests the child inside the parent's typed route
  /// tree. The child becomes a `TypedGoRoute<ChildRoute>` in the parent's
  /// `@TypedGoRoute(routes: [...])` and its `ChildRoute` class is appended to the
  /// parent's routes file (the builder then generates the `\$ChildRoute` mixin).
  ///
  /// packageSplit (§6a Phase 3): unlike the plain go_router variant above, the
  /// nesting happens inside the **parent package's own** `<parent>_routes.dart`
  /// — a genuine cross-feature-package import, so [parentPackageName] (when
  /// set) also gets a `path:` dependency added onto [childPackageName] (a
  /// one-way edge: the child never depends back on the parent, so this can't
  /// introduce a cycle).
  Future<void> _wireChildRouteBuilder(
    String projectPath,
    String packageName,
    String featureName,
    String parentFeature, {
    String? childPackageName,
    String? parentPackageName,
    String? corePackageName,
  }) async {
    final camel = _camel(featureName);

    // 1. AppRoutePath: the full navigable path '/parent/child'.
    await _addRouteConstant(
      '$projectPath/lib/core/constants/app_route_path.dart',
      camel,
      '/$parentFeature/$featureName',
    );
    if (corePackageName != null) {
      await _addRouteConstant(
        '$projectPath/packages/$corePackageName/lib/core/constants/app_route_path.dart',
        camel,
        '/$parentFeature/$featureName',
      );
    }

    // 2. parent's typed routes file: inject the nested typed route + child class.
    final parentRoutesPath = parentPackageName != null
        ? '$projectPath/packages/$parentPackageName/lib/presentation/routes/${parentFeature}_routes.dart'
        : '$projectPath/lib/features/$parentFeature/presentation/routes/${parentFeature}_routes.dart';
    final parentRoutes = File(parentRoutesPath);
    if (!parentRoutes.existsSync()) return;
    final s = wireChildIntoTypedRoutes(
      parentRoutesSource: await parentRoutes.readAsString(),
      packageName: packageName,
      childFeature: featureName,
      parentFeature: parentFeature,
      childPackageName: childPackageName,
    );
    await parentRoutes.writeAsString(s);

    // 3. The parent package now imports the child package directly — declare
    // the dependency, or `dart pub get` never resolves it.
    if (parentPackageName != null && childPackageName != null) {
      await _addPathDependencyToPackage(projectPath, parentPackageName, childPackageName);
    }
  }

  /// Pure transformation of a parent's `<parent>_routes.dart` (go_router_builder):
  /// imports the child page, ensures the parent's `@TypedGoRoute` carries a
  /// `routes: [ // neat:typed-children:<parent> ]` list, inserts the child's
  /// `TypedGoRoute<ChildRoute>` there, and appends the `ChildRoute` class.
  @visibleForTesting
  static String wireChildIntoTypedRoutes({
    required String parentRoutesSource,
    required String packageName,
    required String childFeature,
    required String parentFeature,
    // packageSplit: the child's own package — the parent package needs a
    // real path: dependency on it (see _wireChildRouteBuilder), since this
    // import crosses a genuine feature-package boundary, unlike the plain
    // go_router variant (nested inside the app's own shared routes.dart).
    String? childPackageName,
  }) {
    final childPascal = _pascal(childFeature);
    final parentPascal = _pascal(parentFeature);
    final parentCamel = _camel(parentFeature);
    var s = parentRoutesSource;

    // 1. Import the child page (just before the part directive).
    final childPkg = childPackageName ?? packageName;
    final childPathPrefix = childPackageName != null ? '' : 'features/$childFeature/';
    final childImport =
        "import 'package:$childPkg/${childPathPrefix}presentation/pages/"
        "${childFeature}_page.dart';";
    if (!s.contains(childImport)) {
      s = _insertBefore(s, "part '", childImport);
    }

    // 2. Ensure the parent annotation owns a routes:[] list with the anchor.
    final anchor = '// neat:typed-children:$parentFeature';
    if (!s.contains(anchor)) {
      final flat = '@TypedGoRoute<${parentPascal}Route>(path: AppRoutePath.$parentCamel)';
      final nested = '@TypedGoRoute<${parentPascal}Route>(\n'
          '  path: AppRoutePath.$parentCamel,\n'
          '  routes: [\n'
          '    $anchor\n'
          '  ],\n'
          ')';
      s = s.replaceFirst(flat, nested);
    }

    // 3. Insert the nested typed route (relative path) at the anchor.
    s = _insertBefore(s, anchor, "    TypedGoRoute<${childPascal}Route>(path: '$childFeature'),");

    // 4. Append the child route class (the builder generates its mixin).
    if (!s.contains('class ${childPascal}Route extends GoRouteData')) {
      s = '$s\n'
          'class ${childPascal}Route extends GoRouteData with \$${childPascal}Route {\n'
          '  const ${childPascal}Route();\n\n'
          '  @override\n'
          '  Widget build(BuildContext context, GoRouterState state) =>\n'
          '      const ${childPascal}Page();\n'
          '}\n';
    }
    return s;
  }

  // ── Shell branch wiring (create-or-extend the app's StatefulShellRoute) ────

  /// Adds [featureName] as a branch of the app's bottom-navigation shell.
  /// The first shell branch *creates* the shell (scaffold + StatefulShellRoute);
  /// later branches *extend* it (a branch + a NavigationDestination) via anchors.
  Future<void> _wireShellBranch(
    String projectPath,
    String packageName,
    String featureName, {
    required String icon,
    required String label,
    required bool builder,
    required void Function(String) onLog,
    String? featurePackageName,
    String? corePackageName,
  }) async {
    final camel = _camel(featureName);

    // 1. AppRoutePath: absolute top-level path for the branch.
    await _addRouteConstant(
      '$projectPath/lib/core/constants/app_route_path.dart',
      camel,
      '/$featureName',
    );
    if (corePackageName != null) {
      await _addRouteConstant(
        '$projectPath/packages/$corePackageName/lib/core/constants/app_route_path.dart',
        camel,
        '/$featureName',
      );
    }

    // 2. Shared scaffold: create on the first branch, else add a destination.
    final scaffold = File('$projectPath/lib/core/router/scaffold_with_nav_bar.dart');
    final firstBranch = !scaffold.existsSync();
    if (firstBranch) {
      onLog('[▶] Creating the navigation shell (first branch)...');
      await scaffold.create(recursive: true);
      await scaffold.writeAsString(
        CoreTemplates.scaffoldWithNavBar(firstIcon: icon, firstLabel: label),
      );
    } else {
      final s = _insertBefore(
        await scaffold.readAsString(),
        '// neat:shell-destinations',
        CoreTemplates.shellDestination(icon: icon, label: label),
      );
      await scaffold.writeAsString(s);
    }

    // 3. Route tree wiring (plain vs typed).
    if (builder) {
      await _wireShellBranchBuilder(
        projectPath,
        packageName,
        featureName,
        firstBranch: firstBranch,
        featurePackageName: featurePackageName,
      );
    } else {
      await _wireShellBranchPlain(
        projectPath,
        packageName,
        featureName,
        firstBranch: firstBranch,
        featurePackageName: featurePackageName,
      );
    }
  }

  Future<void> _wireShellBranchPlain(
    String projectPath,
    String packageName,
    String featureName, {
    required bool firstBranch,
    String? featurePackageName,
  }) async {
    final routes = File('$projectPath/lib/core/router/routes.dart');
    if (!routes.existsSync()) return;
    var s = await routes.readAsString();
    final pkg = featurePackageName ?? packageName;
    final pathPrefix = featurePackageName != null ? '' : 'features/$featureName/';
    s = _insertBefore(
      s,
      '// neat:route-imports',
      "import 'package:$pkg/${pathPrefix}presentation/pages/"
          "${featureName}_page.dart';",
    );
    if (firstBranch) {
      s = _insertBefore(
        s,
        '// neat:route-imports',
        "import 'package:$packageName/core/router/scaffold_with_nav_bar.dart';",
      );
      s = _insertBefore(
        s,
        '// neat:route-entries',
        CoreTemplates.shellRouteEntryPlain(featureName: featureName),
      );
    } else {
      s = _insertBefore(
        s,
        '// neat:shell-branches',
        CoreTemplates.shellBranchPlain(featureName: featureName),
      );
    }
    await routes.writeAsString(s);
  }

  Future<void> _wireShellBranchBuilder(
    String projectPath,
    String packageName,
    String featureName, {
    required bool firstBranch,
    String? featurePackageName,
  }) async {
    final shellFile = File('$projectPath/lib/core/router/app_shell_route.dart');
    if (firstBranch) {
      await shellFile.create(recursive: true);
      await shellFile.writeAsString(
        CoreTemplates.appShellRouteBuilder(
          packageName: packageName,
          featureName: featureName,
          featurePackageName: featurePackageName,
        ),
      );
      // Aggregate the shell's generated routes into routes.dart.
      final routes = File('$projectPath/lib/core/router/routes.dart');
      if (routes.existsSync()) {
        var s = await routes.readAsString();
        s = _insertBefore(
          s,
          '// neat:route-imports',
          "import 'package:$packageName/core/router/app_shell_route.dart' as app_shell;",
        );
        s = _insertBefore(s, '// neat:route-entries', r'  ...app_shell.$appRoutes,');
        await routes.writeAsString(s);
      }
    } else {
      if (!shellFile.existsSync()) return;
      await shellFile.writeAsString(
        extendTypedShell(
          shellSource: await shellFile.readAsString(),
          packageName: packageName,
          featureName: featureName,
          featurePackageName: featurePackageName,
        ),
      );
    }
  }

  /// Pure transformation that extends an existing typed shell file with a new
  /// branch: imports the page, inserts a `TypedStatefulShellBranch` at the
  /// branches anchor and the branch's `BranchData`/`Route` classes at the classes
  /// anchor. Extracted for unit testing without filesystem access.
  @visibleForTesting
  static String extendTypedShell({
    required String shellSource,
    required String packageName,
    required String featureName,
    String? featurePackageName,
  }) {
    var s = shellSource;
    final pkg = featurePackageName ?? packageName;
    final pathPrefix = featurePackageName != null ? '' : 'features/$featureName/';
    s = _insertBefore(
      s,
      '// neat:shell-imports',
      "import 'package:$pkg/${pathPrefix}presentation/pages/"
          "${featureName}_page.dart';",
    );
    s = _insertBefore(
      s,
      '// neat:shell-branches',
      CoreTemplates.shellBranchBuilder(featureName: featureName),
    );
    return _insertBefore(
      s,
      '// neat:shell-classes',
      CoreTemplates.shellBranchClassesBuilder(featureName: featureName),
    );
  }

  /// Pure transformation of `routes.dart`: imports the child page, ensures the
  /// parent's `// neat:children:<parent>` anchor exists (adding a `routes: [...]`
  /// clause to the parent's flat GoRoute if needed), then inserts the child as a
  /// relative-path GoRoute at that anchor. Extracted so it is unit-testable
  /// without touching the filesystem.
  @visibleForTesting
  static String wireChildIntoRoutes({
    required String routesSource,
    required String packageName,
    required String featureName,
    required String parentFeature,
    // packageSplit: the child's own package — the app already depends on it
    // (every feature gets a top-level path: dependency), so this only
    // changes the import path, same as _wireRoutes' non-child case.
    String? childPackageName,
  }) {
    final pascal = _pascal(featureName);
    final parentCamel = _camel(parentFeature);
    var s = routesSource;

    final pkg = childPackageName ?? packageName;
    final pathPrefix = childPackageName != null ? '' : 'features/$featureName/';
    s = _insertBefore(
      s,
      '// neat:route-imports',
      "import 'package:$pkg/${pathPrefix}presentation/pages/"
          "${featureName}_page.dart';",
    );

    final childAnchor = '// neat:children:$parentFeature';
    if (!s.contains(childAnchor)) {
      s = _addChildrenAnchorToParent(s, parentCamel, parentFeature);
    }
    return _insertBefore(
      s,
      childAnchor,
      '  GoRoute(\n'
          "    path: '$featureName',\n"
          '    builder: (context, state) => const ${pascal}Page(),\n'
          '  ),',
    );
  }

  /// Rewrites the parent's flat `GoRoute(path: AppRoutePath.<parent>, …)` to add
  /// a `routes: [ // neat:children:<parent> ]` clause. No-op if the parent route
  /// can't be located (the caller's child insertion then safely no-ops).
  static String _addChildrenAnchorToParent(String s, String parentCamel, String parentFeature) {
    final marker = 'AppRoutePath.$parentCamel,';
    final mIdx = s.indexOf(marker);
    if (mIdx < 0) return s;
    // The parent GoRoute closes at the next 2-space-indented '),'.
    final closeIdx = s.indexOf('\n  ),', mIdx);
    if (closeIdx < 0) return s;
    const insertion = '\n    routes: [\n      // neat:children:PARENT\n    ],';
    return s.substring(0, closeIdx) +
        insertion.replaceFirst('PARENT', parentFeature) +
        s.substring(closeIdx);
  }

  /// Inserts [line] (plus a newline) immediately before the line containing
  /// [anchor]. No-op if the anchor is absent.
  static String _insertBefore(String content, String anchor, String line) {
    final idx = content.indexOf(anchor);
    if (idx < 0) return content;
    final lineStart = content.lastIndexOf('\n', idx) + 1;
    return '${content.substring(0, lineStart)}$line\n${content.substring(lineStart)}';
  }

  /// Adds a `static const String $camel = '$routeValue';` to an
  /// `AppRoutePath`-shaped file at [path] (app's own copy, or the core
  /// package's mirrored copy — see `_wireRoutes`'s doc). No-op if the file is
  /// absent.
  Future<void> _addRouteConstant(String path, String camel, String routeValue) async {
    final file = File(path);
    if (!file.existsSync()) return;
    final s = _insertBefore(
      await file.readAsString(),
      '// neat:routes',
      "  static const String $camel = '$routeValue';",
    );
    await file.writeAsString(s);
  }

  // ── Root pubspec.yaml editing (packageSplit: wiring a new feature package) ─

  /// Adds `packages/$memberDir` to the root pubspec's `workspace:` list.
  /// Idempotent — a project with `packageSplit` on always already has a
  /// `workspace:` block (the shared core package is always a member), so this
  /// only ever appends a line to the existing list.
  Future<void> _addWorkspaceMember(String projectPath, String memberDir) async {
    final pubspec = File('$projectPath/pubspec.yaml');
    var s = await pubspec.readAsString();
    final line = '  - packages/$memberDir';
    if (s.contains(line)) return;
    s = s.contains('\nworkspace:\n')
        ? s.replaceFirst('\nworkspace:\n', '\nworkspace:\n$line\n')
        : '${s.trimRight()}\n\nworkspace:\n$line\n';
    await pubspec.writeAsString(s);
  }

  /// Adds a sibling `path:` dependency on `packages/$dependencyName` to the
  /// root pubspec — needed because the app's own `routes.dart` (or shell
  /// scaffold) imports the new feature package directly. Idempotent.
  Future<void> _addPathDependency(String projectPath, String dependencyName) async {
    final pubspec = File('$projectPath/pubspec.yaml');
    var s = await pubspec.readAsString();
    if (s.contains('  $dependencyName:\n    path: packages/$dependencyName')) return;
    s = s.replaceFirst(
      'dependencies:\n  flutter:\n    sdk: flutter',
      'dependencies:\n  flutter:\n    sdk: flutter\n  $dependencyName:\n    path: packages/$dependencyName\n',
    );
    await pubspec.writeAsString(s);
  }

  /// Adds a sibling `path:` dependency from another workspace **feature**
  /// package (not the root) onto [dependencyName] — the packageSplit child-
  /// route case (§6a Phase 3): [packageDir]'s own `<parent>_routes.dart` now
  /// imports the child feature package's page directly, a genuine one-way
  /// cross-feature-package dependency (the child never depends back). No-op
  /// if [packageDir]'s pubspec doesn't exist (e.g. an unknown parent — same
  /// safe-no-op behavior as the routes-file transformation itself). Idempotent.
  Future<void> _addPathDependencyToPackage(
    String projectPath,
    String packageDir,
    String dependencyName,
  ) async {
    final pubspec = File('$projectPath/packages/$packageDir/pubspec.yaml');
    if (!pubspec.existsSync()) return;
    var s = await pubspec.readAsString();
    if (s.contains('  $dependencyName:\n    path: ../$dependencyName')) return;
    s = s.replaceFirst(
      'dependencies:\n  flutter:\n    sdk: flutter',
      'dependencies:\n  flutter:\n    sdk: flutter\n  $dependencyName:\n    path: ../$dependencyName\n',
    );
    await pubspec.writeAsString(s);
  }

  // ── Anchor self-healing (forward-compat for pre-anchor projects) ───────────

  /// Creates `core/providers/infrastructure_providers.dart` (shared Drift db +
  /// connectivity singletons) when missing. New projects already ship it; this
  /// self-heals projects generated before it existed, since the feature DI now
  /// imports it. packageSplit: lives in the core package instead of the app
  /// (see ROADMAP.md §6a) — [packageName] is already `corePackageName` in that
  /// case (see the call site), and [corePackageName] picks the right root dir.
  Future<void> _ensureInfrastructureProviders(
    String projectPath,
    String packageName,
    String localStoragePackage, {
    String? corePackageName,
  }) async {
    final root = corePackageName != null ? '$projectPath/packages/$corePackageName' : projectPath;
    final file = File('$root/lib/core/providers/infrastructure_providers.dart');
    if (file.existsSync()) return;
    await file.create(recursive: true);
    await file.writeAsString(
      CoreTemplates.infrastructureProviders(
        packageName: packageName,
        localStoragePackage: localStoragePackage,
      ),
    );
  }

  /// Ensures `app_route_path.dart` and `routes.dart` carry the `// neat:` anchors
  /// feature-gen inserts at. Projects generated before the anchor system lack
  /// them, which would make every insertion a silent no-op.
  Future<void> _ensureRoutingAnchors(String projectPath) async {
    final routePath = File('$projectPath/lib/core/constants/app_route_path.dart');
    if (routePath.existsSync()) {
      await routePath.writeAsString(healRoutePathAnchor(await routePath.readAsString()));
    }
    final routes = File('$projectPath/lib/core/router/routes.dart');
    if (routes.existsSync()) {
      await routes.writeAsString(healRoutesAnchors(await routes.readAsString()));
    }
  }

  /// Adds the `// neat:routes` anchor inside `AppRoutePath` (before the closing
  /// brace) when missing. Idempotent.
  @visibleForTesting
  static String healRoutePathAnchor(String content) {
    if (content.contains('// neat:routes')) return content;
    final lastBrace = content.lastIndexOf('}');
    if (lastBrace < 0) return content;
    return '${content.substring(0, lastBrace)}  // neat:routes\n${content.substring(lastBrace)}';
  }

  /// Adds the `// neat:route-imports` (after the last import) and
  /// `// neat:route-entries` (inside the `appRoutes` list) anchors when missing.
  /// Works for both plain and builder aggregators. Idempotent.
  @visibleForTesting
  static String healRoutesAnchors(String content) {
    var s = content;
    if (!s.contains('// neat:route-imports')) {
      final imports = RegExp(r'^import .*;$', multiLine: true).allMatches(s).toList();
      if (imports.isNotEmpty) {
        final end = imports.last.end;
        s = '${s.substring(0, end)}\n// neat:route-imports${s.substring(end)}';
      }
    }
    if (!s.contains('// neat:route-entries')) {
      final re = RegExp(r'final List<RouteBase> appRoutes = \[(.*?)\];', dotAll: true);
      s = s.replaceFirstMapped(re, (m) {
        var body = m.group(1)!.trim();
        if (body.isNotEmpty && !body.endsWith(',')) body = '$body,';
        final inner = body.isEmpty ? '  // neat:route-entries' : '  $body\n  // neat:route-entries';
        return 'final List<RouteBase> appRoutes = [\n$inner\n];';
      });
    }
    return s;
  }

  static String _pascal(String s) => s
      .split('_')
      .map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1))
      .join();

  static String _camel(String s) {
    final p = _pascal(s);
    return p.isEmpty ? p : p[0].toLowerCase() + p.substring(1);
  }

  Future<void> _runBuildRunner(String dart, String dir, void Function(String) onLog) async {
    try {
      final result = await Process.run(
        dart,
        ['run', 'build_runner', 'build', '--delete-conflicting-outputs'],
        workingDirectory: dir,
        environment: {
          ...Platform.environment,
          'PATH': '${Platform.environment['PATH']}:/usr/local/bin:/opt/homebrew/bin',
        },
      );
      onLog(result.exitCode == 0
          ? '[✓] Code generated.'
          : '[!] build_runner failed:\n${result.stderr.toString().trim()}');
    } catch (e) {
      onLog('[!] build_runner could not be launched ($dart): $e');
    }
  }

  Future<void> _dartFormat(String dart, String dir, void Function(String) onLog) async {
    try {
      final result = await Process.run(dart, ['format', '.'], workingDirectory: dir);
      onLog(result.exitCode == 0 ? '[✓] Code formatted.' : '[!] dart format skipped.');
    } catch (e) {
      onLog('[!] dart format skipped: $e');
    }
  }

  /// Resolves the `dart` executable robustly. The NEAT GUI app often launches
  /// with a minimal PATH that omits the Flutter SDK (e.g. `~/develop/flutter/bin`),
  /// so relying on `dart` being on PATH silently fails. Mirrors the wizard's
  /// Flutter resolution: known install locations first, then `which`, then PATH.
  Future<String> _resolveDart() async {
    final home = Platform.environment['HOME'];
    final candidates = <String>[
      '/usr/local/bin/dart',
      '/opt/homebrew/bin/dart',
      if (home != null) ...[
        '$home/develop/flutter/bin/dart',
        '$home/development/flutter/bin/dart',
        '$home/flutter/bin/dart',
        '$home/fvm/default/bin/dart',
        '$home/.pub-cache/bin/dart',
      ],
      '/opt/flutter/bin/dart',
    ];
    for (final path in candidates) {
      if (File(path).existsSync()) return path;
    }
    try {
      final which = await Process.run('which', ['dart'], environment: {
        ...Platform.environment,
        'PATH': '${Platform.environment['PATH']}:/usr/local/bin:/opt/homebrew/bin',
      });
      final resolved = which.stdout.toString().trim();
      if (resolved.isNotEmpty && File(resolved).existsSync()) return resolved;
    } catch (_) {/* fall through */}
    return 'dart'; // last resort: hope it's on PATH
  }
}
