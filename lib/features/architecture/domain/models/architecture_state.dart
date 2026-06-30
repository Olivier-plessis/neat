import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:neat/features/architecture/domain/models/env_config.dart';

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

    /// The build environments (default dev/staging/prod), renamable, each with an
    /// optional API base URL written into its `.env.<flavor>`. The **last** one is
    /// the production base (no appId suffix). Drives envied + flavors.
    @Default(<EnvConfig>[
      EnvConfig(name: 'dev'),
      EnvConfig(name: 'staging'),
      EnvConfig(name: 'prod'),
    ])
    List<EnvConfig> environments,
  }) = _ArchitectureState;

  /// Validates the first feature name (Dart folder/identifier rules).
  String? validateFirstFeatureName() {
    if (firstFeatureName.isEmpty) return 'Feature name is required';
    if (!RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(firstFeatureName)) {
      return 'lowercase letters, digits & underscores; start with a letter';
    }
    return null;
  }

  /// The first tab's label (falls back to the feature name, capitalised).
  String get effectiveShellLabel {
    if (shellLabel.trim().isNotEmpty) return shellLabel.trim();
    if (firstFeatureName.isEmpty) return '';
    return firstFeatureName[0].toUpperCase() +
        firstFeatureName.substring(1).replaceAll('_', ' ');
  }
}
