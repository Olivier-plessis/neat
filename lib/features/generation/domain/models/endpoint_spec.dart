import 'package:neat/features/generation/domain/models/field_spec.dart';

/// A REST verb NEAT can generate a typed chopper method for.
enum HttpMethod { get, post, put, patch, delete }

/// One arbitrary REST endpoint in a "Custom Endpoints" Workshop feature (see
/// ROADMAP.md §7 Phase 2) — the endpoint-centric counterpart to the entity+CRUD
/// flow's single [FieldSpec] list. Each endpoint gets its own typed chopper
/// method, optional request/response Models, and its own UseCase.
///
/// Pure value object (no Flutter/codegen), mirroring [FieldSpec]'s own
/// hand-written style rather than freezed — this is a simple, flat shape with
/// no need for union types or deep nested `copyWith`.
class EndpointSpec {
  const EndpointSpec({
    required this.name,
    this.method = HttpMethod.get,
    this.path = '',
    this.requestFields = const [],
    this.requestJson = '',
    this.responseFields = const [],
    this.responseJson = '',
    this.requestWarnings = const [],
    this.responseWarnings = const [],
  });

  /// Dart identifier for the generated method/usecase, e.g. `login` ->
  /// `LoginUsecase` / `ApiSource.login()`.
  final String name;

  final HttpMethod method;

  /// Relative (appended to the project's API Base URL) or an absolute URL
  /// (overrides the host entirely) — same convention as
  /// `FeatureGenOptions.apiPath`.
  final String path;

  /// Request body fields (inferred from [requestJson], or empty — some
  /// endpoints, e.g. GET/DELETE, have no body at all).
  final List<FieldSpec> requestFields;

  /// The raw JSON pasted to infer [requestFields] (kept for the editor
  /// round-trip).
  final String requestJson;

  /// Response body fields (inferred from [responseJson], or empty — some
  /// endpoints return no meaningful body).
  final List<FieldSpec> responseFields;

  /// The raw JSON pasted to infer [responseFields] (kept for the editor
  /// round-trip).
  final String responseJson;

  final List<String> requestWarnings;
  final List<String> responseWarnings;

  bool get hasRequestBody => requestFields.isNotEmpty;
  bool get hasResponseBody => responseFields.isNotEmpty;

  EndpointSpec copyWith({
    String? name,
    HttpMethod? method,
    String? path,
    List<FieldSpec>? requestFields,
    String? requestJson,
    List<FieldSpec>? responseFields,
    String? responseJson,
    List<String>? requestWarnings,
    List<String>? responseWarnings,
  }) {
    return EndpointSpec(
      name: name ?? this.name,
      method: method ?? this.method,
      path: path ?? this.path,
      requestFields: requestFields ?? this.requestFields,
      requestJson: requestJson ?? this.requestJson,
      responseFields: responseFields ?? this.responseFields,
      responseJson: responseJson ?? this.responseJson,
      requestWarnings: requestWarnings ?? this.requestWarnings,
      responseWarnings: responseWarnings ?? this.responseWarnings,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is EndpointSpec &&
      other.name == name &&
      other.method == method &&
      other.path == path &&
      _listEq(other.requestFields, requestFields) &&
      other.requestJson == requestJson &&
      _listEq(other.responseFields, responseFields) &&
      other.responseJson == responseJson &&
      _strListEq(other.requestWarnings, requestWarnings) &&
      _strListEq(other.responseWarnings, responseWarnings);

  @override
  int get hashCode => Object.hash(
        name,
        method,
        path,
        Object.hashAll(requestFields),
        requestJson,
        Object.hashAll(responseFields),
        responseJson,
        Object.hashAll(requestWarnings),
        Object.hashAll(responseWarnings),
      );

  static bool _listEq(List<FieldSpec> a, List<FieldSpec> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static bool _strListEq(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  String toString() => 'EndpointSpec(${method.name} $path -> $name)';
}
