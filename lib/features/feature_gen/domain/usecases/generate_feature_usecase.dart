import 'dart:io';

import 'package:neat/features/feature_gen/domain/models/loaded_project.dart';
import 'package:neat/features/generation/domain/services/feature_scaffolder.dart';

/// Adds a new feature to an existing NEAT project, deriving every choice from
/// the project's Workspace Contract (`.neat.json`) so the new feature matches
/// the existing stack exactly. Non-destructive: it refuses to overwrite an
/// existing feature.
class GenerateFeatureUsecase {
  const GenerateFeatureUsecase();

  Future<void> execute({
    required LoadedProject project,
    required String featureName,
    required void Function(String) onLog,
  }) async {
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

    // Derive flags from the contract.
    final hasRiverpod = c.stateManagement == 'riverpod';
    final hasBloc = c.stateManagement == 'bloc';
    final useAnnotations = c.useRiverpodAnnotations && hasRiverpod;
    final hasGoRouterBuilder = c.navigation == 'go_router_builder';
    final hasGoRouter = c.navigation == 'go_router' || hasGoRouterBuilder;
    final hasHttpClient = c.httpClient != 'none';
    final httpClient = hasHttpClient ? c.httpClient : '';
    final localStoragePackage =
        c.storageStrategy != 'remoteOnly' ? '${c.projectName}_local_storage' : null;
    final hasSync = c.storageStrategy == 'offlineFirstSync';

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
      hasHttpClient: hasHttpClient,
      httpClient: httpClient,
      hasFreezed: c.hasFreezed,
      hasJsonSerializable: c.hasJsonSerializable,
      localStoragePackage: localStoragePackage,
      hasSync: hasSync,
    );
    onLog('[✓] Feature files written.');

    // Wire the new feature's routes into the shared router (anchors).
    if (hasGoRouter) {
      onLog('[▶] Wiring routes...');
      await _wireRoutes(
        project.path,
        c.projectName,
        featureName,
        builder: hasGoRouterBuilder,
      );
    }

    // Regenerate code if the stack uses generators (riverpod / freezed / json).
    if (useAnnotations || c.hasFreezed || c.hasJsonSerializable) {
      onLog("[▶] Running 'dart run build_runner build'...");
      await _runBuildRunner(project.path, onLog);
    }
    await _dartFormat(project.path, onLog);
    onLog('[✓✓] Feature "$featureName" added.');
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

  /// Inserts [line] (plus a newline) immediately before the line containing
  /// [anchor]. No-op if the anchor is absent.
  String _insertBefore(String content, String anchor, String line) {
    final idx = content.indexOf(anchor);
    if (idx < 0) return content;
    final lineStart = content.lastIndexOf('\n', idx) + 1;
    return '${content.substring(0, lineStart)}$line\n${content.substring(lineStart)}';
  }

  static String _pascal(String s) => s
      .split('_')
      .map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1))
      .join();

  static String _camel(String s) {
    final p = _pascal(s);
    return p.isEmpty ? p : p[0].toLowerCase() + p.substring(1);
  }

  Future<void> _runBuildRunner(String dir, void Function(String) onLog) async {
    final result = await Process.run(
      'dart',
      ['run', 'build_runner', 'build', '--delete-conflicting-outputs'],
      workingDirectory: dir,
      environment: {
        ...Platform.environment,
        'PATH': '${Platform.environment['PATH']}:/usr/local/bin:/opt/homebrew/bin',
      },
    );
    onLog(result.exitCode == 0
        ? '[✓] Code generated.'
        : '[!] build_runner: ${result.stderr.toString().trim()}');
  }

  Future<void> _dartFormat(String dir, void Function(String) onLog) async {
    try {
      final result = await Process.run('dart', ['format', '.'], workingDirectory: dir);
      onLog(result.exitCode == 0 ? '[✓] Code formatted.' : '[!] dart format skipped.');
    } catch (e) {
      onLog('[!] dart format skipped: $e');
    }
  }
}
