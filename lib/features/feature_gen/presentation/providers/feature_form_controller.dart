import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:neat/core/contract/neat_contract.dart';
import 'package:neat/features/feature_gen/domain/models/feature_gen_options.dart';
import 'package:neat/features/generation/domain/models/crud_endpoint_overrides.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'feature_form_controller.freezed.dart';
part 'feature_form_controller.g.dart';

/// The Workshop's in-progress "add feature" form: the options being built up
/// across the 3 steps, plus which step is currently showing.
@freezed
abstract class FeatureFormState with _$FeatureFormState {
  const factory FeatureFormState({
    @Default(FeatureGenOptions()) FeatureGenOptions opts,
    @Default(0) int step,
  }) = _FeatureFormState;
}

/// Scoped per [NeatContract] (family) and auto-disposed (default, no
/// keepAlive) — the Workshop can only be reached with a project already
/// loaded and closing it always routes back through the Hub first (see
/// hub_screen.dart's `_open`), so nothing ever watches this provider across
/// two different "add feature" sessions. Reopening any project therefore
/// always starts from a fresh form, matching the old useState-per-mount
/// behavior without any manual reset call.
@riverpod
class FeatureFormController extends _$FeatureFormController {
  @override
  FeatureFormState build(NeatContract contract) => FeatureFormState(
    opts: FeatureGenOptions(
      includeRemoteDataSource: contract.httpClient != 'none',
      includeLocalDataSource: contract.storageStrategy != 'remoteOnly',
    ),
  );

  /// Replaces the whole options object — the single write path every step
  /// widget already calls via its own `onChanged: ValueChanged<FeatureGenOptions>`.
  void update(FeatureGenOptions opts) => state = state.copyWith(opts: opts);

  void setStep(int step) => state = state.copyWith(step: step);

  void setName(String name) => update(state.opts.copyWith(name: name));

  void setShellLabel(String label) => update(state.opts.copyWith(shellLabel: label));

  /// Direct event-handler equivalent of what used to be a reactive "sync
  /// endpoint paths to apiPath" effect on ArchitectureLayersStep: called
  /// straight from the API Path TextField's own controller listener, not a
  /// widget watching for the value to differ after the fact — so there's no
  /// build-phase state-mutation hazard to route around with
  /// addPostFrameCallback (see ROADMAP / prior fix for the crash this used
  /// to cause).
  void setApiPath(String apiPath) {
    final opts = state.opts.copyWith(apiPath: apiPath);
    update(
      opts.customizeEndpoints
          ? opts.copyWith(
              endpointOverrides: apiPath.isNotEmpty
                  ? CrudEndpointOverrides.defaultsFor(apiPath)
                  : const CrudEndpointOverrides(),
            )
          : opts,
    );
  }
}
