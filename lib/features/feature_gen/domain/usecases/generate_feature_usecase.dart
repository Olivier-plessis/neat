import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:neat/features/feature_gen/domain/models/feature_gen_options.dart';
import 'package:neat/features/feature_gen/domain/models/loaded_project.dart';
import 'package:neat/features/generation/domain/services/feature_scaffolder.dart';
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

    // Non-destructive guard.
    final featureDir = Directory(
      isFeatureFirst ? '$lib/features/$featureName' : '$lib/domain/$featureName',
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
    final localStoragePackage =
        c.storageStrategy != 'remoteOnly' ? '${c.projectName}_local_storage' : null;
    final hasSync = c.storageStrategy == 'offlineFirstSync';

    // … then refine them with the per-feature Workshop choices. The feature can
    // only use stack capabilities the project actually has (you can't add a
    // remote source if the project has no HTTP client).
    final effHasHttp = projectHasHttp && options.includeRemoteDataSource;
    final httpClient = effHasHttp ? c.httpClient : '';
    // A local-only feature (no remote) always keeps its local source.
    final writeLocal = options.includeLocalDataSource || !effHasHttp;
    // Drift-backed local source → the feature needs a typed table injected.
    final needsDriftTable = localStoragePackage != null && writeLocal;

    // A child route nests under an existing feature instead of getting its own
    // top-level route (supported for both go_router and go_router_builder).
    final asChild = hasGoRouter &&
        options.routing == FeatureRouting.child &&
        options.parentFeature.isNotEmpty;
    // A shell branch joins the app's StatefulShellRoute (bottom NavigationBar).
    final asShell = hasGoRouter && options.routing == FeatureRouting.shell;

    onLog('[▶] Generating feature "$featureName" (matching the project stack)...');
    await const FeatureScaffolder().writeFeature(
      lib: lib,
      featureName: featureName,
      packageName: c.projectName,
      isFeatureFirst: isFeatureFirst,
      mirrorTestStructure: c.mirrorTestStructure,
      hasRiverpod: hasRiverpod,
      hasBloc: hasBloc,
      useCubit: false, // BLoC/Cubit is gated; riverpod is the validated path.
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
              project.path, c.projectName, featureName, options.parentFeature);
        } else {
          await _wireChildRoute(project.path, c.projectName, featureName, options.parentFeature);
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
        );
      } else {
        onLog('[▶] Wiring routes...');
        await _wireRoutes(project.path, c.projectName, featureName, builder: hasGoRouterBuilder);
      }
    }

    // Offline-first: inject the feature's typed table + DAO into the Drift
    // package (only when the feature actually keeps a Drift-backed local source).
    if (needsDriftTable) {
      onLog('[▶] Injecting Drift table for "$featureName"...');
      await _injectDriftTable(project.path, localStoragePackage, featureName);
      // The feature DI references the shared infrastructure providers; create
      // them if this project predates that file (self-heal).
      if (useAnnotations) {
        await _ensureInfrastructureProviders(project.path, c.projectName, localStoragePackage);
      }
    }

    // Regenerate code if the stack uses generators (riverpod / freezed / json).
    final dart = await _resolveDart();
    if (useAnnotations || c.hasFreezed || c.hasJsonSerializable) {
      onLog("[▶] Running 'dart run build_runner build' ($dart)...");
      await _runBuildRunner(dart, project.path, onLog);
    }
    // Drift codegen runs per-package, so build the local-storage package too.
    if (localStoragePackage != null) {
      onLog('[▶] Running build_runner in packages/$localStoragePackage...');
      await _runBuildRunner(dart, '${project.path}/packages/$localStoragePackage', onLog);
    }
    await _dartFormat(dart, project.path, onLog);
    onLog('[✓✓] Feature "$featureName" added.');
  }

  // ── Drift table injection (inserts at the // neat: anchors) ────────────────

  Future<void> _injectDriftTable(
    String projectPath,
    String localStoragePackage,
    String featureName,
  ) async {
    final db = File('$projectPath/packages/$localStoragePackage/lib/src/database.dart');
    if (!db.existsSync()) return;
    final p = _pascal(featureName);
    var s = await db.readAsString();
    s = _insertBefore(s, '// neat:tables', '${LocalStorageTemplates.featureTable(featureName)}\n');
    s = _insertBefore(s, '// neat:table-names', '    ${p}Rows,');
    s = _insertBefore(s, '// neat:daos', '${LocalStorageTemplates.featureDao(featureName)}\n');
    await db.writeAsString(s);
  }

  // ── Route wiring (inserts at the // neat: anchors) ─────────────────────────

  Future<void> _wireRoutes(
    String projectPath,
    String packageName,
    String featureName, {
    required bool builder,
  }) async {
    final camel = _camel(featureName);
    final pascal = _pascal(featureName);

    // 1. AppRoutePath constant.
    final routePath = File('$projectPath/lib/core/constants/app_route_path.dart');
    if (routePath.existsSync()) {
      final s = _insertBefore(
        await routePath.readAsString(),
        '// neat:routes',
        "  static const String $camel = '/$featureName';",
      );
      await routePath.writeAsString(s);
    }

    // 2. routes.dart (single wiring point for both routing modes).
    final routes = File('$projectPath/lib/core/router/routes.dart');
    if (!routes.existsSync()) return;
    var s = await routes.readAsString();
    if (builder) {
      s = _insertBefore(
        s,
        '// neat:route-imports',
        "import 'package:$packageName/features/$featureName/presentation/routes/"
            "${featureName}_routes.dart' as $featureName;",
      );
      s = _insertBefore(s, '// neat:route-entries', '  ...$featureName.\$appRoutes,');
    } else {
      s = _insertBefore(
        s,
        '// neat:route-imports',
        "import 'package:$packageName/features/$featureName/presentation/pages/"
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
  Future<void> _wireChildRoute(
    String projectPath,
    String packageName,
    String featureName,
    String parentFeature,
  ) async {
    final camel = _camel(featureName);

    // 1. AppRoutePath: the full navigable path '/parent/child'.
    final routePath = File('$projectPath/lib/core/constants/app_route_path.dart');
    if (routePath.existsSync()) {
      final s = _insertBefore(
        await routePath.readAsString(),
        '// neat:routes',
        "  static const String $camel = '/$parentFeature/$featureName';",
      );
      await routePath.writeAsString(s);
    }

    // 2. routes.dart: nest the child under the parent (pure transformation).
    final routes = File('$projectPath/lib/core/router/routes.dart');
    if (!routes.existsSync()) return;
    final s = wireChildIntoRoutes(
      routesSource: await routes.readAsString(),
      packageName: packageName,
      featureName: featureName,
      parentFeature: parentFeature,
    );
    await routes.writeAsString(s);
  }

  /// go_router_builder variant: nests the child inside the parent's typed route
  /// tree. The child becomes a `TypedGoRoute<ChildRoute>` in the parent's
  /// `@TypedGoRoute(routes: [...])` and its `ChildRoute` class is appended to the
  /// parent's routes file (the builder then generates the `\$ChildRoute` mixin).
  Future<void> _wireChildRouteBuilder(
    String projectPath,
    String packageName,
    String featureName,
    String parentFeature,
  ) async {
    final camel = _camel(featureName);

    // 1. AppRoutePath: the full navigable path '/parent/child'.
    final routePath = File('$projectPath/lib/core/constants/app_route_path.dart');
    if (routePath.existsSync()) {
      final s = _insertBefore(
        await routePath.readAsString(),
        '// neat:routes',
        "  static const String $camel = '/$parentFeature/$featureName';",
      );
      await routePath.writeAsString(s);
    }

    // 2. parent's typed routes file: inject the nested typed route + child class.
    final parentRoutes = File(
      '$projectPath/lib/features/$parentFeature/presentation/routes/${parentFeature}_routes.dart',
    );
    if (!parentRoutes.existsSync()) return;
    final s = wireChildIntoTypedRoutes(
      parentRoutesSource: await parentRoutes.readAsString(),
      packageName: packageName,
      childFeature: featureName,
      parentFeature: parentFeature,
    );
    await parentRoutes.writeAsString(s);
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
  }) {
    final childPascal = _pascal(childFeature);
    final parentPascal = _pascal(parentFeature);
    final parentCamel = _camel(parentFeature);
    var s = parentRoutesSource;

    // 1. Import the child page (just before the part directive).
    final childImport =
        "import 'package:$packageName/features/$childFeature/presentation/pages/"
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
  }) async {
    final camel = _camel(featureName);

    // 1. AppRoutePath: absolute top-level path for the branch.
    final routePath = File('$projectPath/lib/core/constants/app_route_path.dart');
    if (routePath.existsSync()) {
      final s = _insertBefore(
        await routePath.readAsString(),
        '// neat:routes',
        "  static const String $camel = '/$featureName';",
      );
      await routePath.writeAsString(s);
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
      await _wireShellBranchBuilder(projectPath, packageName, featureName, firstBranch: firstBranch);
    } else {
      await _wireShellBranchPlain(projectPath, packageName, featureName, firstBranch: firstBranch);
    }
  }

  Future<void> _wireShellBranchPlain(
    String projectPath,
    String packageName,
    String featureName, {
    required bool firstBranch,
  }) async {
    final routes = File('$projectPath/lib/core/router/routes.dart');
    if (!routes.existsSync()) return;
    var s = await routes.readAsString();
    s = _insertBefore(
      s,
      '// neat:route-imports',
      "import 'package:$packageName/features/$featureName/presentation/pages/"
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
  }) async {
    final shellFile = File('$projectPath/lib/core/router/app_shell_route.dart');
    if (firstBranch) {
      await shellFile.create(recursive: true);
      await shellFile.writeAsString(
        CoreTemplates.appShellRouteBuilder(packageName: packageName, featureName: featureName),
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
  }) {
    var s = shellSource;
    s = _insertBefore(
      s,
      '// neat:shell-imports',
      "import 'package:$packageName/features/$featureName/presentation/pages/"
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
  }) {
    final pascal = _pascal(featureName);
    final parentCamel = _camel(parentFeature);
    var s = routesSource;

    s = _insertBefore(
      s,
      '// neat:route-imports',
      "import 'package:$packageName/features/$featureName/presentation/pages/"
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

  // ── Anchor self-healing (forward-compat for pre-anchor projects) ───────────

  /// Creates `core/providers/infrastructure_providers.dart` (shared Drift db +
  /// connectivity singletons) when missing. New projects already ship it; this
  /// self-heals projects generated before it existed, since the feature DI now
  /// imports it.
  Future<void> _ensureInfrastructureProviders(
    String projectPath,
    String packageName,
    String localStoragePackage,
  ) async {
    final file = File('$projectPath/lib/core/providers/infrastructure_providers.dart');
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
