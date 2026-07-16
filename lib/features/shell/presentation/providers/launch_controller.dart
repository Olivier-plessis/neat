import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:neat/features/architecture/domain/models/architecture_state.dart';
import 'package:neat/features/cicd/domain/models/cicd_state.dart';
import 'package:neat/features/dependencies/domain/models/pub_package.dart';
import 'package:neat/features/generation/domain/usecases/launch_generation_usecase.dart';
import 'package:neat/features/hub/presentation/providers/recent_projects_provider.dart';
import 'package:neat/features/identity/domain/models/identity_state.dart';
import 'package:neat/features/shell/presentation/providers/stepper_provider.dart';
import 'package:neat/features/theme_engine/domain/models/theme_engine_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'launch_controller.freezed.dart';
part 'launch_controller.g.dart';

/// Live state of a "Generate Project" run (Launch step).
@freezed
abstract class LaunchState with _$LaunchState {
  const factory LaunchState({
    @Default(false) bool hasFinished,
    @Default(<String>[]) List<String> logs,
    String? error,
  }) = _LaunchState;
}

/// Drives project generation from the Launch step: calls
/// LaunchGenerationUsecase, streams logs, and registers the freshly generated
/// project in the Hub's recent list — mirrors WorkshopController's own
/// usecase-orchestration pattern so the View never calls a usecase directly.
@Riverpod(keepAlive: true)
class LaunchController extends _$LaunchController {
  @override
  LaunchState build() => const LaunchState();

  Future<void> generate({
    required IdentityState identity,
    required List<PubPackage> packages,
    required ArchitectureState architecture,
    required CicdState cicd,
    required ThemeEngineState theme,
  }) async {
    // Shared with main_layout, which locks the Back button while this is true.
    ref.read(isGeneratingProvider.notifier).set(true);
    state = LaunchState(logs: ['neat@shell:~\$ generate --project ${identity.name}', '']);
    final collected = List<String>.from(state.logs);

    try {
      await const LaunchGenerationUsecase().execute(
        identity: identity,
        packages: packages,
        architecture: architecture,
        cicd: cicd,
        theme: theme,
        onLog: (line) {
          collected.add(line);
          state = state.copyWith(logs: List.unmodifiable(collected));
        },
      );
      state = state.copyWith(hasFinished: true);
      // Surface the freshly generated project in the Hub's recent list.
      await ref
          .read(recentProjectsProvider.notifier)
          .register(path: '${identity.projectPath}/${identity.name}', name: identity.name);
    } catch (e) {
      collected.add('[✗] Generation failed: $e');
      state = state.copyWith(error: e.toString(), logs: List.unmodifiable(collected));
    } finally {
      ref.read(isGeneratingProvider.notifier).set(false);
    }
  }

  /// Back to a clean slate — call when starting a fresh project (mirrors
  /// CurrentStep.startNewProject invalidating every other wizard provider).
  void reset() => state = const LaunchState();
}
