import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:neat/features/architecture/domain/models/env_config.dart';
import 'package:neat/features/generation/domain/models/field_spec.dart';

part 'architecture_state.freezed.dart';

/// Architecture choices made in the wizard.
///
/// Pure domain value object — no Flutter/Riverpod imports — so domain usecases
/// (tree preview, generation) can consume it without depending on presentation.
enum StructuralPattern { featureFirst, layerFirst }

/// How the data layer persists data.
///
/// Anything other than [remoteOnly] flips the project into a Dart **workspace**
/// with a dedicated `packages/<name>_local_storage` package (Drift).
/// - [offlineFirstRead]: local-first reads + cache fallback.
/// - [offlineFirstSync]: read + the Outbox write path (queued writes replayed
///   by a SyncService when connectivity returns).
enum StorageStrategy {
  remoteOnly,
  offlineFirstRead,
  offlineFirstSync;

  /// Triggers the workspace + Drift package.
  bool get isOfflineFirst => this != StorageStrategy.remoteOnly;

  /// Adds the Outbox table + SyncService + repository write path.
  bool get hasSync => this == StorageStrategy.offlineFirstSync;

  String get label => switch (this) {
        remoteOnly => 'Remote Only',
        offlineFirstRead => 'Offline-First',
        offlineFirstSync => 'Offline + Sync',
      };
}

/// The first feature's onboarding content.
enum FirstFeaturePreset {
  /// FakeStore Products: a full-CRUD worked example against a public API.
  /// Its API path is a hardcoded **absolute** URL, so it keeps working
  /// whatever the project's own API Base URL ends up being — it's NEAT's own
  /// reference feature, not something the user's real API config can pollute.
  example,

  /// Paste your own JSON response — infers the entity fields (Phase 1 flow).
  custom,

  /// No preset: just an id/name placeholder.
  minimal;
}

@freezed
abstract class ArchitectureState with _$ArchitectureState {
  const ArchitectureState._();

  const factory ArchitectureState({
    @Default(StructuralPattern.featureFirst) StructuralPattern pattern,
    @Default(true) bool includeMappers,

    /// Use @riverpod annotation syntax instead of manual NotifierProvider setup
    @Default(true) bool useRiverpodAnnotations,

    /// Use Cubit (simpler) instead of full Bloc with Events/States
    @Default(false) bool useCubit,
    @Default(true) bool mirrorTestStructure,

    /// Name of the first feature scaffolded under lib/features/ (snake_case).
    @Default('home') String firstFeatureName,

    /// The first feature's entity fields, inferred from a pasted Response JSON
    /// (or the default id/name placeholder). Drives the entity/model/mapper/Drift
    /// table/list tile of the generated feature.
    @Default(FieldSpec.idName) List<FieldSpec> firstFeatureFields,

    /// The raw JSON the user pasted to infer [firstFeatureFields] (kept so the
    /// UI can re-show / re-infer it). Empty → the default id/name placeholder.
    @Default('') String firstFeatureJson,

    /// Human-readable notes from the last inference (coerced id, dropped nested
    /// fields, null types…). Shown under the editor so the user can review/edit.
    @Default(<String>[]) List<String> firstFeatureFieldWarnings,

    /// Overrides the first feature's REST resource path (default:
    /// `/<firstFeatureName>s`). Either a relative path or an absolute URL — an
    /// absolute URL overrides the project's API Base URL entirely. Empty →
    /// the default pluralised path. REST clients only (dio/chopper/retrofit).
    @Default('') String firstFeatureApiPath,

    /// Onboarding choice for the first feature's content. Defaults to
    /// [FirstFeaturePreset.minimal] because that's what the *other* raw
    /// defaults above already are (id/name fields, no path override) — the
    /// live wizard flips its initial state to [FirstFeaturePreset.example]
    /// explicitly (see `ArchitectureNotifier.build()`), so this stays the
    /// neutral default for tests constructing `ArchitectureState()` directly.
    @Default(FirstFeaturePreset.minimal) FirstFeaturePreset firstFeaturePreset,

    /// Data persistence strategy. [StorageStrategy.offlineFirst] switches the
    /// generated project to a workspace with a Drift local-storage package.
    @Default(StorageStrategy.remoteOnly) StorageStrategy storageStrategy,

    /// When true (and go_router is in the stack), the app boots into a bottom
    /// [NavigationBar] shell: the first feature is the first tab, so the nav bar
    /// is the app's spine from launch. Requires go_router / go_router_builder.
    @Default(false) bool useNavigationShell,

    /// Material icon name for the first tab (only when [useNavigationShell]).
    @Default('home') String shellIcon,

    /// First tab label (blank → the feature name, capitalised).
    @Default('') String shellLabel,

    /// Opt-in: generate a Supabase **auth** feature (login/signup/forgot) + a
    /// go_router guard. Only effective with a Supabase backend + go_router_builder.
    @Default(false) bool generateAuth,

    /// Opt-in: make the first feature's list screen **live** via Supabase
    /// Realtime (`.stream()`). Only effective with a Supabase backend + riverpod
    /// annotations (the list becomes a StreamNotifier).
    @Default(false) bool generateRealtime,

    /// Opt-in: generate a Supabase **Storage** service (+ provider + a sample
    /// avatar upload widget). Only effective with a Supabase backend + riverpod.
    @Default(false) bool generateStorage,

    /// Path to an uploaded Firebase config JSON (the web app config or a
    /// FlutterFire export). When a Firebase backend is selected, NEAT generates
    /// `firebase_options.dart` from it. Blank → compile-safe placeholders.
    @Default('') String firebaseConfigPath,

    /// Opt-in: add Google + Apple OAuth sign-in to the auth feature (via
    /// `FirebaseAuth.signInWithProvider`). Only effective with a Firebase
    /// backend + auth enabled.
    @Default(false) bool generateOAuth,

    /// Opt-in: type-safe internationalisation with **slang** (en + fr base,
    /// `TranslationProvider` + `context.t`, a sample language switcher).
    @Default(false) bool generateI18n,

    /// Path to an uploaded **compact CSV** of translations (`key,en,fr,…`). When
    /// set (and [generateI18n] is on), the CSV becomes the single source of
    /// translations instead of the default en/fr JSON scaffold.
    @Default('') String i18nCsvPath,

    /// Opt-in: generate native **build flavors** (Android productFlavors, per-env
    /// entry points `main_<flavor>.dart`, `.vscode/launch.json`). Off by default
    /// so a plain `flutter run` works with zero config. Only effective with envied.
    @Default(false) bool generateFlavors,

    /// The build environments, renamable, each with an optional API base URL
    /// written into its `.env`. Starts as a **single** `prod` env (→ plain `.env`
    /// + `main.dart`, no flavors); the user adds more on demand. Drives envied +
    /// flavors. The production base is [baseEnvIndex] (not positional).
    @Default(<EnvConfig>[EnvConfig(name: 'prod')])
    List<EnvConfig> environments,

    /// Index into [environments] of the production **base** (no appId suffix; the
    /// logger quietens there; release builds target it). Chosen explicitly via
    /// the BASE chip — never positional, so adding an env never moves the base.
    @Default(0) int baseEnvIndex,
  }) = _ArchitectureState;

  /// Validates the first feature name (Dart folder/identifier rules).
  String? validateFirstFeatureName() {
    if (firstFeatureName.isEmpty) return 'Feature name is required';
    if (!RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(firstFeatureName)) {
      return 'lowercase letters, digits & underscores; start with a letter';
    }
    return null;
  }

  /// The production base environment (index clamped to a valid range).
  EnvConfig get baseEnv => environments[baseEnvIndex.clamp(0, environments.length - 1)];

  /// Applies [preset]'s concrete name/fields/path — the single source of
  /// truth for what each onboarding choice actually means, shared by the
  /// wizard's initial state and its preset-switch callback. `custom` only
  /// records the marker: switching to "Your entity" shouldn't wipe JSON the
  /// user already pasted.
  ArchitectureState withFirstFeaturePreset(FirstFeaturePreset preset) {
    return switch (preset) {
      FirstFeaturePreset.example => copyWith(
          firstFeaturePreset: preset,
          firstFeatureName: 'product',
          firstFeatureFields: FieldSpec.fakeStoreProduct,
          firstFeatureJson: '',
          firstFeatureFieldWarnings: const [],
          firstFeatureApiPath: 'https://fakestoreapi.com/products',
        ),
      FirstFeaturePreset.minimal => copyWith(
          firstFeaturePreset: preset,
          firstFeatureFields: FieldSpec.idName,
          firstFeatureJson: '',
          firstFeatureFieldWarnings: const [],
          firstFeatureApiPath: '',
        ),
      FirstFeaturePreset.custom => copyWith(firstFeaturePreset: preset),
    };
  }

  /// The first tab's label (falls back to the feature name, capitalised).
  String get effectiveShellLabel {
    if (shellLabel.trim().isNotEmpty) return shellLabel.trim();
    if (firstFeatureName.isEmpty) return '';
    return firstFeatureName[0].toUpperCase() +
        firstFeatureName.substring(1).replaceAll('_', ' ');
  }
}
