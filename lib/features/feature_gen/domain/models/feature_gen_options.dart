import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:neat/features/generation/domain/models/crud_endpoint_overrides.dart';
import 'package:neat/features/generation/domain/models/endpoint_spec.dart';
import 'package:neat/features/generation/domain/models/field_spec.dart';

part 'feature_gen_options.freezed.dart';

/// Per-feature generation choices made in the Workshop. These refine (but never
/// contradict) the project stack read from `.neat.json`.
enum FeatureRouting { root, child, shell }

@freezed
abstract class FeatureGenOptions with _$FeatureGenOptions {
  const factory FeatureGenOptions({
    @Default('') String name,
    @Default(FeatureRouting.root) FeatureRouting routing,
    @Default('') String parentFeature, // only when routing == child

    /// Opt-in, only when routing == child: instead of a separate
    /// feature/package, the new feature's files nest inside the parent's own
    /// package/folder (`data`/`domain`/`presentation`, each gaining a
    /// `<name>/` subfolder), like a settings sub-page — no new pubspec,
    /// workspace member, or path: dependency. Mirrors maxit-front-flutter's
    /// `page/<sub-feature>/` pattern.
    @Default(false) bool mergeIntoParent,
    @Default('home') String shellIcon, // Material icon name, only when shell
    @Default('') String shellLabel, // NavigationBar label, only when shell
    @Default(true) bool includeRemoteDataSource,
    @Default(true) bool includeLocalDataSource,
    @Default(true) bool includeUseCase,
    @Default(true) bool includeMapper,

    /// Entity fields (inferred from a pasted Response JSON, or the id/name
    /// default). Drives the entity/model/mapper/Drift table of the new feature.
    @Default(FieldSpec.idName) List<FieldSpec> fields,

    /// The raw JSON pasted to infer [fields] (kept for the editor round-trip).
    @Default('') String json,

    /// Notes from the last inference (shown under the editor).
    @Default(<String>[]) List<String> fieldWarnings,

    /// Overrides the REST resource path (default: `/<name>s`). Either a
    /// relative path or an absolute URL — an absolute URL overrides the
    /// project's API Base URL entirely. Empty → the default pluralised path.
    /// REST clients only (dio/chopper).
    @Default('') String apiPath,

    /// "Custom Endpoints" mode (see ROADMAP.md §7 Phase 2): the feature is N
    /// arbitrary REST calls instead of one entity + fixed CRUD. Mutually
    /// exclusive with [fields]/[json]/[apiPath]/the data-source toggles above
    /// — the Workshop UI shows one section or the other, never both.
    /// Chopper-only, remote-only (no local storage/offline-first/realtime).
    @Default(false) bool useCustomEndpoints,

    /// The endpoints when [useCustomEndpoints] is on.
    @Default(<EndpointSpec>[]) List<EndpointSpec> endpoints,

    /// Opt-in (Entity + CRUD only, chopper — Architecture Layers step):
    /// customize each of the 5 fixed CRUD operations' own HTTP method + path,
    /// instead of deriving all 5 from [apiPath]'s single base path. Off by
    /// default — most REST APIs follow the plain convention [apiPath] alone
    /// already covers.
    @Default(false) bool customizeEndpoints,

    /// The per-operation overrides when [customizeEndpoints] is on.
    @Default(CrudEndpointOverrides()) CrudEndpointOverrides endpointOverrides,
  }) = _FeatureGenOptions;

  const FeatureGenOptions._();

  /// The branch label shown in the NavigationBar (falls back to the feature
  /// name, capitalised, when left blank).
  String get effectiveShellLabel {
    if (shellLabel.trim().isNotEmpty) return shellLabel.trim();
    if (name.isEmpty) return '';
    return name[0].toUpperCase() + name.substring(1).replaceAll('_', ' ');
  }

  String? validateName() {
    if (name.isEmpty) return 'Feature name is required';
    if (!RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(name)) {
      return 'lowercase letters, digits & underscores; start with a letter';
    }
    return null;
  }

  bool get hasAnyDataSource => includeRemoteDataSource || includeLocalDataSource;
}
