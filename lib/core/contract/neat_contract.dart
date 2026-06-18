import 'package:freezed_annotation/freezed_annotation.dart';

part 'neat_contract.freezed.dart';
part 'neat_contract.g.dart';

/// The "Workspace Contract" — NEAT's fingerprint written to `.neat.json` at the
/// project root when a project is generated.
///
/// It captures the project's **stack** (not its features — those are derived
/// by scanning `lib/features/`) so that feature generation stays consistent
/// across sessions and across developers. Because it lives in the repo and is
/// committed to Git, every teammate's NEAT reads the same contract — no
/// reliance on any per-machine local storage.
@freezed
abstract class NeatContract with _$NeatContract {
  const factory NeatContract({
    required String projectName,

    /// feature_first | layer_first
    required String architecture,

    /// riverpod | bloc | none
    required String stateManagement,

    /// go_router_builder | go_router | none
    required String navigation,

    /// chopper | dio | retrofit | none
    required String httpClient,

    /// none | customM3 | flexColorScheme
    required String themeApproach,

    /// remoteOnly | offlineFirstRead | offlineFirstSync
    required String storageStrategy,
    @Default(1) int schemaVersion,
    @Default(true) bool useRiverpodAnnotations,
    @Default(false) bool extractUiPackage,
    @Default(false) bool useScreenUtil,
    @Default(false) bool hasEnvied,
    @Default(false) bool hasFreezed,
    @Default(false) bool hasJsonSerializable,
    @Default(true) bool includeMappers,
    @Default(true) bool mirrorTestStructure,
    @Default(false) bool generateWidgetbook,
    @Default(false) bool useNavigationShell,
    @Default(false) bool generateAuth,
    @Default(false) bool generateRealtime,
    @Default(false) bool generateStorage,
    @Default(false) bool generateOAuth,
    @Default(<String>[]) List<String> components,
  }) = _NeatContract;

  factory NeatContract.fromJson(Map<String, dynamic> json) => _$NeatContractFromJson(json);
}
