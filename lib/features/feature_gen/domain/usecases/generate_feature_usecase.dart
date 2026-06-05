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

    // Regenerate code if the stack uses generators (riverpod / freezed / json).
    if (useAnnotations || c.hasFreezed || c.hasJsonSerializable) {
      onLog("[▶] Running 'dart run build_runner build'...");
      await _runBuildRunner(project.path, onLog);
    }
    await _dartFormat(project.path, onLog);
    onLog('[✓✓] Feature "$featureName" added.');
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
