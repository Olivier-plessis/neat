import 'package:neat/features/architecture/domain/models/architecture_state.dart';
import 'package:neat/features/architecture/domain/models/env_config.dart';
import 'package:neat/features/generation/domain/models/field_spec.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'architecture_provider.g.dart';

@Riverpod(keepAlive: true)
class ArchitectureNotifier extends _$ArchitectureNotifier {
  @override
  ArchitectureState build() => const ArchitectureState(
        firstFeatureName: 'product',
        firstFeatureFields: FieldSpec.fakeStoreProduct,
        firstFeatureApiPath: 'https://fakestoreapi.com/products',
      );

  void setPattern(StructuralPattern pattern) => state = state.copyWith(pattern: pattern);
  void toggleMappers(bool val) => state = state.copyWith(includeMappers: val);
  void toggleRiverpodAnnotations(bool val) => state = state.copyWith(useRiverpodAnnotations: val);
  void toggleCubit(bool val) => state = state.copyWith(useCubit: val);
  void toggleMirrorTest(bool val) => state = state.copyWith(mirrorTestStructure: val);

  /// Off → the app ships with zero features (a placeholder welcome screen
  /// owns the root route instead). A shell needs a first branch, so turning
  /// this off also drops the navigation-shell opt-in.
  void setGenerateFirstFeature(bool val) => state = state.copyWith(
        generateFirstFeature: val,
        useNavigationShell: val ? state.useNavigationShell : false,
      );
  void setFirstFeatureName(String val) =>
      state = state.copyWith(firstFeatureName: val.trim());

  /// Only remote-only is wired for packageSplit today (see ROADMAP.md §6a) —
  /// leaving offline-first turns the toggle off in the UI (see
  /// architecture_screen.dart's canPackageSplit), but the underlying flag
  /// isn't reset here: the generator re-derives the effective combo itself
  /// (launch_generation_usecase.dart's packageSplitSupported), so a stale
  /// `true` while the toggle is hidden is harmless.
  void setStorageStrategy(StorageStrategy strategy) =>
      state = state.copyWith(storageStrategy: strategy);
  void togglePackageSplit(bool val) => state = state.copyWith(packageSplit: val);
  void toggleNavigationShell(bool val) => state = state.copyWith(useNavigationShell: val);
  void toggleGenerateAuth(bool val) => state = state.copyWith(generateAuth: val);
  void toggleGenerateRealtime(bool val) => state = state.copyWith(generateRealtime: val);
  void toggleGenerateStorage(bool val) => state = state.copyWith(generateStorage: val);
  void setFirebaseConfigPath(String path) =>
      state = state.copyWith(firebaseConfigPath: path.trim());
  void toggleGenerateOAuth(bool val) => state = state.copyWith(generateOAuth: val);
  void toggleGenerateI18n(bool val) => state = state.copyWith(generateI18n: val);
  void setI18nCsvPath(String path) => state = state.copyWith(i18nCsvPath: path.trim());
  void toggleGenerateFlavors(bool val) => state = state.copyWith(generateFlavors: val);

  void setEnvName(int index, String name) => _updateEnv(index, (e) => e.copyWith(name: name));
  void setEnvApiUrl(int index, String url) =>
      _updateEnv(index, (e) => e.copyWith(apiBaseUrl: url.trim()));
  void setEnvSupabaseUrl(int index, String url) =>
      _updateEnv(index, (e) => e.copyWith(supabaseUrl: url.trim()));
  void setEnvSupabaseKey(int index, String key) =>
      _updateEnv(index, (e) => e.copyWith(supabaseAnonKey: key.trim()));

  void _updateEnv(int index, EnvConfig Function(EnvConfig) update) {
    if (index < 0 || index >= state.environments.length) return;
    final next = [...state.environments];
    next[index] = update(next[index]);
    state = state.copyWith(environments: next);
  }

  /// Max number of environments offered in the wizard.
  static const maxEnvironments = 4;

  /// Appends a new environment (capped at [maxEnvironments]). The new one becomes
  /// the production base (last). A unique default name avoids flavor collisions.
  void addEnv() {
    if (state.environments.length >= maxEnvironments) return;
    final used = state.environments.map((e) => e.name).toSet();
    var name = 'env${state.environments.length + 1}';
    for (var i = state.environments.length + 1; used.contains(name); i++) {
      name = 'env$i';
    }
    state = state.copyWith(environments: [...state.environments, EnvConfig(name: name)]);
  }

  /// Removes the environment at [index]. Keeps at least one (a single env →
  /// no flavors, a plain `.env` + `main.dart`). The base index follows the
  /// surviving rows: shifts down if a row before it goes, and falls back to the
  /// new last row if the base itself is removed.
  void removeEnv(int index) {
    if (state.environments.length <= 1) return;
    if (index < 0 || index >= state.environments.length) return;
    final next = [...state.environments]..removeAt(index);
    var base = state.baseEnvIndex;
    if (index == base) {
      base = next.length - 1; // base removed → last surviving env becomes base
    } else if (index < base) {
      base -= 1; // a row before the base went → keep pointing at the same env
    }
    state = state.copyWith(
      environments: next,
      baseEnvIndex: base.clamp(0, next.length - 1),
    );
  }

  /// Marks [index] as the production base (no appId suffix; logger quietens
  /// there; release builds target it).
  void setBaseEnv(int index) {
    if (index < 0 || index >= state.environments.length) return;
    state = state.copyWith(baseEnvIndex: index);
  }
  void setShellIcon(String icon) => state = state.copyWith(shellIcon: icon);
  void setShellLabel(String label) => state = state.copyWith(shellLabel: label);
}
