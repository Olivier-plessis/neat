import 'package:neat/features/architecture/domain/models/architecture_state.dart';
import 'package:neat/features/generation/domain/services/feature_scaffolder.dart';

/// Thin adapter over [FeatureScaffolder] for the wizard's first feature —
/// split out of `LaunchGenerationUsecase` (see ROADMAP.md for the per-domain
/// writer split).
abstract final class FeatureWriter {
  static Future<void> write({
    required String lib,
    required String featureName,
    required String packageName,
    required ArchitectureState architecture,
    required bool hasRiverpod,
    required bool hasBloc,
    required bool useCubit,
    required bool useAnnotations,
    required bool hasGoRouter,
    required bool hasGoRouterBuilder,
    required bool hasHttpClient,
    required String httpClient,
    required bool hasFreezed,
    required bool hasJsonSerializable,
    String? localStoragePackage,
    bool hasSync = false,
    bool isShellBranch = false,
    bool realtime = false,
    bool i18n = false,
    bool packageSplit = false,
    String? corePackageName,
  }) async {
    await const FeatureScaffolder().writeFeature(
      lib: lib,
      featureName: featureName,
      packageName: packageName,
      isFeatureFirst: architecture.pattern == StructuralPattern.featureFirst,
      mirrorTestStructure: architecture.mirrorTestStructure,
      hasRiverpod: hasRiverpod,
      hasBloc: hasBloc,
      useCubit: useCubit,
      useAnnotations: useAnnotations,
      hasGoRouter: hasGoRouter,
      hasGoRouterBuilder: hasGoRouterBuilder,
      hasHttpClient: hasHttpClient,
      httpClient: httpClient,
      hasFreezed: hasFreezed,
      hasJsonSerializable: hasJsonSerializable,
      localStoragePackage: localStoragePackage,
      hasSync: hasSync,
      isShellBranch: isShellBranch,
      realtime: realtime,
      i18n: i18n,
      fields: architecture.firstFeatureFields,
      apiPath: architecture.firstFeatureApiPath.isEmpty
          ? null
          : architecture.firstFeatureApiPath,
      // The simple detail/create sheets are scoped to NEAT's own worked
      // example for now (see FeatureScaffolder.writeFeature's includeCrudUi
      // doc) — not a general Workshop/wizard capability yet. `generateFirstFeature`
      // alone isn't enough to identify it: plenty of tests/flows still set an
      // arbitrary first feature (e.g. Firebase/Supabase realtime's "todo")
      // with the plain `_riverpodListNotifier`, which has no addItem/removeItem
      // — only the wizard's Example toggle ever produces this exact apiPath.
      includeCrudUi:
          architecture.firstFeatureApiPath ==
          'https://fakestoreapi.com/products',
      packageSplit: packageSplit,
      corePackageName: corePackageName,
      // The wizard's first feature only ever becomes a shell branch, never a
      // child of one (that combination only exists via the Workshop) — so
      // needsShellRegistration is exactly isShellBranch here.
      needsShellRegistration: isShellBranch,
    );
  }
}
