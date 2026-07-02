import 'package:neat/features/architecture/domain/models/architecture_state.dart';
import 'package:neat/features/architecture/domain/models/env_config.dart';
import 'package:neat/features/generation/domain/models/field_spec.dart';
import 'package:neat/features/generation/domain/services/json_entity_inferencer.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'architecture_provider.g.dart';

@Riverpod(keepAlive: true)
class ArchitectureNotifier extends _$ArchitectureNotifier {
  @override
  ArchitectureState build() =>
      const ArchitectureState().withFirstFeaturePreset(FirstFeaturePreset.example);

  void setPattern(StructuralPattern pattern) => state = state.copyWith(pattern: pattern);
  void toggleMappers(bool val) => state = state.copyWith(includeMappers: val);
  void toggleRiverpodAnnotations(bool val) => state = state.copyWith(useRiverpodAnnotations: val);
  void toggleCubit(bool val) => state = state.copyWith(useCubit: val);
  void toggleMirrorTest(bool val) => state = state.copyWith(mirrorTestStructure: val);
  void setFirstFeatureName(String val) =>
      state = state.copyWith(firstFeatureName: val.trim());
  void setFirstFeatureApiPath(String val) =>
      state = state.copyWith(firstFeatureApiPath: val.trim());

  // ── First-feature onboarding preset ─────────────────────────────────────────

  void setFirstFeaturePreset(FirstFeaturePreset preset) =>
      state = state.withFirstFeaturePreset(preset);

  // ── First-feature entity fields (JSON-driven) ───────────────────────────────

  /// Infers the entity fields from a pasted Response JSON and records the raw
  /// JSON + any inference warnings. Empty input restores the id/name default.
  /// Hand-editing fields this way means "Your entity", not a canned preset.
  void inferFieldsFromJson(String json) {
    if (json.trim().isEmpty) {
      resetFields();
      return;
    }
    final result = const JsonEntityInferencer().infer(json);
    state = state.copyWith(
      firstFeaturePreset: FirstFeaturePreset.custom,
      firstFeatureJson: json,
      firstFeatureFields: result.fields,
      firstFeatureFieldWarnings: result.warnings,
    );
  }

  /// Back to the default `id`/`name` placeholder (clears JSON + warnings).
  void resetFields() => state = state.copyWith(
        firstFeaturePreset: FirstFeaturePreset.minimal,
        firstFeatureJson: '',
        firstFeatureFields: FieldSpec.idName,
        firstFeatureFieldWarnings: const [],
      );

  /// Appends a blank editable String field (manual add).
  void addField() {
    final used = state.firstFeatureFields.map((f) => f.dartName).toSet();
    var name = 'field';
    for (var i = 1; used.contains(name); i++) {
      name = 'field$i';
    }
    state = state.copyWith(firstFeatureFields: [
      ...state.firstFeatureFields,
      FieldSpec(jsonKey: name, dartName: name),
    ]);
  }

  void setFieldName(int index, String name) =>
      _updateField(index, (f) => f.copyWith(dartName: name.trim()));

  /// Changes a field's Dart type (no-op on the id, which stays String).
  void setFieldType(int index, String type) =>
      _updateField(index, (f) => f.isId ? f : f.copyWith(dartType: type));

  void toggleFieldNullable(int index, bool nullable) =>
      _updateField(index, (f) => f.isId ? f : f.copyWith(nullable: nullable));

  /// Removes a field (keeps the id — it's required by the CRUD contract).
  void removeField(int index) {
    if (index < 0 || index >= state.firstFeatureFields.length) return;
    if (state.firstFeatureFields[index].isId) return;
    final next = [...state.firstFeatureFields]..removeAt(index);
    state = state.copyWith(firstFeatureFields: next);
  }

  void _updateField(int index, FieldSpec Function(FieldSpec) update) {
    if (index < 0 || index >= state.firstFeatureFields.length) return;
    final next = [...state.firstFeatureFields];
    next[index] = update(next[index]);
    state = state.copyWith(firstFeatureFields: next);
  }
  void setStorageStrategy(StorageStrategy strategy) =>
      state = state.copyWith(storageStrategy: strategy);
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
