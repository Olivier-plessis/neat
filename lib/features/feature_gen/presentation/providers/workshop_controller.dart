import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:neat/features/feature_gen/domain/models/feature_gen_options.dart';
import 'package:neat/features/feature_gen/domain/models/loaded_project.dart';
import 'package:neat/features/feature_gen/domain/services/project_loader.dart';
import 'package:neat/features/feature_gen/domain/usecases/generate_feature_usecase.dart';
import 'package:neat/features/generation/domain/services/i18n_importer.dart';
import 'package:neat/features/hub/presentation/providers/recent_projects_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'workshop_controller.freezed.dart';
part 'workshop_controller.g.dart';

/// Workshop session: the opened NEAT project + the live state of a feature
/// generation run.
@freezed
abstract class WorkshopState with _$WorkshopState {
  const factory WorkshopState({
    LoadedProject? project,
    @Default(false) bool isGenerating,
    @Default(<String>[]) List<String> logs,
    String? error,
  }) = _WorkshopState;
}

/// Drives Workshop mode: open an existing NEAT project (via its `.neat.json`)
/// and generate features into it. The folder picker lives in the UI; this
/// controller takes a resolved path so it stays testable.
@Riverpod(keepAlive: true)
class WorkshopController extends _$WorkshopController {
  @override
  WorkshopState build() => const WorkshopState();

  /// Opens the project at [path]. Sets [WorkshopState.error] when it isn't a
  /// NEAT project (no readable `.neat.json`).
  Future<void> openProject(String path) async {
    final project = await const ProjectLoader().load(path);
    if (project == null) {
      state = const WorkshopState(error: 'Not a NEAT project — no readable .neat.json found.');
      return;
    }
    state = WorkshopState(project: project);
    // Surface it in the Hub's recent list.
    await ref
        .read(recentProjectsProvider.notifier)
        .register(path: project.path, name: project.contract.projectName);
  }

  /// Closes the current project (back to the Hub).
  void close() => state = const WorkshopState();

  /// Imports a compact CSV of translations into the open project: places it as
  /// the slang source, regenerates `strings.g.dart`, streaming logs. Only
  /// meaningful when the project was generated with i18n (`generateI18n`).
  Future<void> importTranslations(String csvPath) async {
    final project = state.project;
    if (project == null || state.isGenerating) return;
    final file = File(csvPath);
    if (!file.existsSync()) {
      state = state.copyWith(error: 'CSV introuvable : $csvPath');
      return;
    }

    state = state.copyWith(isGenerating: true, logs: const [], error: null);
    final collected = <String>[];
    try {
      final locales = await const I18nImporter().importCsv(
        projectPath: project.path,
        csvContent: await file.readAsString(),
        onLog: (line) {
          collected.add(line);
          state = state.copyWith(logs: List.unmodifiable(collected));
        },
      );
      collected.add('[✓] Traductions importées (${locales.join(', ')}).');
      state = state.copyWith(isGenerating: false, logs: List.unmodifiable(collected));
    } catch (e) {
      state = state.copyWith(isGenerating: false, error: e.toString());
    }
  }

  /// Generates a feature into the open project from the Workshop [options],
  /// streaming logs, then refreshes the feature list from disk.
  Future<void> generateFeature(FeatureGenOptions options) async {
    final project = state.project;
    if (project == null || state.isGenerating) return;

    state = state.copyWith(isGenerating: true, logs: const [], error: null);
    final collected = <String>[];
    try {
      await const GenerateFeatureUsecase().execute(
        project: project,
        options: options,
        onLog: (line) {
          collected.add(line);
          state = state.copyWith(logs: List.unmodifiable(collected));
        },
      );
      final refreshed = await const ProjectLoader().load(project.path);
      state = state.copyWith(project: refreshed ?? project, isGenerating: false);
    } catch (e) {
      state = state.copyWith(isGenerating: false, error: e.toString());
    }
  }
}
