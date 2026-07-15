import 'dart:convert';
import 'dart:io';

import 'package:neat/core/contract/neat_contract.dart';
import 'package:neat/features/feature_gen/domain/models/loaded_project.dart';

/// Loads an existing NEAT project (Workshop mode): reads its Workspace Contract
/// (`.neat.json`) and lists its features from disk.
class ProjectLoader {
  const ProjectLoader();

  /// Loads the project at [projectPath]. Returns null when there's no
  /// `.neat.json` (not a NEAT-generated project) or it's malformed — the caller
  /// shows a clear "not a NEAT project" message rather than guessing the stack.
  Future<LoadedProject?> load(String projectPath) async {
    final contractFile = File('$projectPath/.neat.json');
    if (!contractFile.existsSync()) return null;

    final NeatContract contract;
    try {
      final decoded = jsonDecode(await contractFile.readAsString());
      if (decoded is! Map<String, dynamic>) return null;
      contract = NeatContract.fromJson(decoded);
    } catch (_) {
      return null;
    }

    return LoadedProject(
      path: projectPath,
      contract: contract,
      features: scanFeatures(projectPath, contract),
    );
  }

  /// Existing features = the directories under `lib/features/` (or, when
  /// `packageSplit` is on, the workspace packages under `packages/` — see
  /// ROADMAP.md §6a Step 2b). A feature package is named after the feature
  /// itself (no app-name prefix); only the UI and database packages keep the
  /// `<projectName>_ui` / `<projectName>_database` prefix (avoids reading as
  /// generic as "core"/"auth" when extracted on its own). The filesystem is
  /// the single source of truth (never a list stored in the contract), so it
  /// stays correct even when teammates add features by hand. `local_storage`
  /// stays excluded too — the database package's name before its rename —
  /// so projects generated before the rename still load correctly.
  List<String> scanFeatures(String projectPath, NeatContract contract) {
    if (contract.packageSplit) {
      final packagesDir = Directory('$projectPath/packages');
      if (!packagesDir.existsSync()) return const [];
      final uiPackageName = '${contract.projectName}_ui';
      final databasePackageName = '${contract.projectName}_database';
      const nonFeatureNames = ['core', 'local_storage', 'auth'];
      return packagesDir
          .listSync()
          .whereType<Directory>()
          .map((d) => d.uri.pathSegments.where((s) => s.isNotEmpty).last)
          .where(
            (name) =>
                name != uiPackageName &&
                name != databasePackageName &&
                !nonFeatureNames.contains(name),
          )
          .toList()
        ..sort();
    }
    final dir = Directory('$projectPath/lib/features');
    if (!dir.existsSync()) return const [];
    return dir
        .listSync()
        .whereType<Directory>()
        .map((d) => d.uri.pathSegments.where((s) => s.isNotEmpty).last)
        .where((name) => !name.startsWith('.'))
        .toList()
      ..sort();
  }
}
