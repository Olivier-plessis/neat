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

    /// chopper | dio | supabase | firebase | none
    required String httpClient,

    /// none | customM3 | flexColorScheme
    required String themeApproach,

    /// remoteOnly | offlineFirstRead | offlineFirstSync
    required String storageStrategy,
    @Default(1) int schemaVersion,
    @Default(true) bool useRiverpodAnnotations,

    /// Only meaningful when [stateManagement] is `bloc`: Cubit (no Events)
    /// instead of full Bloc. Read by the Workshop's feature generator so a
    /// feature added later matches the project's existing choice.
    @Default(false) bool useCubit,
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
    @Default(false) bool generateI18n,
    @Default(<String>[]) List<String> components,

    /// Modular Monorepo (see ROADMAP.md §6a): every feature lives in its own
    /// workspace package (`packages/<feature>/`) instead of a folder under
    /// `lib/features/`. Read by the Workshop's feature generator and project
    /// loader so a feature added later matches the project's existing
    /// structure. The shared core package is always named `core` — not
    /// stored separately, derived by convention (same convention the wizard
    /// itself uses).
    @Default(false) bool packageSplit,
  }) = _NeatContract;

  factory NeatContract.fromJson(Map<String, dynamic> json) => _$NeatContractFromJson(json);
}
