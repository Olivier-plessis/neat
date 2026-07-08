import 'package:neat/features/generation/domain/models/endpoint_spec.dart';
import 'package:neat/features/generation/domain/models/field_spec.dart';
import 'package:neat/features/generation/domain/services/templates/dart/_template_utils.dart';
import 'package:neat/features/generation/domain/services/templates/dart/field_codegen.dart';

/// Templates for "Custom Endpoints" features (ROADMAP.md §7 Phase 2) — the
/// endpoint-centric counterpart to DataTemplates/DomainTemplates' entity+CRUD
/// templates. Each [EndpointSpec] gets its own request/response Models (when
/// it has a body), one typed chopper method, and one UseCase — no entity, no
/// repository interface, no local source (see FeatureScaffolder's
/// useCustomEndpoints branch). Chopper-only: unlike the CRUD path, this never
/// generates a dio/supabase/firebase variant (see ROADMAP.md §7 scope notes).
class EndpointTemplates {
  EndpointTemplates._();

  // ── data/models/<endpoint>_model.dart ─────────────────────────────────────

  /// One file per endpoint: its request Model (if any), its response Model
  /// (if any), plus any nested sub-models either one needs. Empty string when
  /// the endpoint has neither (a bodyless call, e.g. `DELETE /logout`) — the
  /// caller skips writing the file entirely in that case.
  static String endpointModelFile({
    required EndpointSpec endpoint,
    required bool hasFreezed,
    required bool hasJsonSerializable,
  }) {
    final p = pascal(endpoint.name);
    // Collected together (not per-field-list) so a nested object name shared
    // between the request and response bodies (e.g. both carry a "Rating")
    // still dedupes into a single generated sub-class, not two.
    final objects = collectObjectSpecs([...endpoint.requestFields, ...endpoint.responseFields]);

    if (hasFreezed) {
      final blocks = <String>[
        if (endpoint.hasRequestBody)
          _freezedModel('${p}Request', endpoint.requestFields, hasJsonSerializable),
        if (endpoint.hasResponseBody)
          _freezedModel('${p}Response', endpoint.responseFields, hasJsonSerializable),
        for (final o in objects) _freezedModel(o.objectName, o.children, hasJsonSerializable),
      ];
      if (blocks.isEmpty) return '';
      final partJson = hasJsonSerializable ? "\npart '${endpoint.name}_model.g.dart';" : '';
      return '''import 'package:freezed_annotation/freezed_annotation.dart';

part '${endpoint.name}_model.freezed.dart';$partJson

${blocks.join('\n\n')}
''';
    }

    final blocks = <String>[
      if (endpoint.hasRequestBody) _plainModel('${p}Request', endpoint.requestFields),
      if (endpoint.hasResponseBody) _plainModel('${p}Response', endpoint.responseFields),
      for (final o in objects) _plainModel(o.objectName, o.children),
    ];
    if (blocks.isEmpty) return '';
    return '${blocks.join('\n\n')}\n';
  }

  /// One freezed model class with fromJson (when [hasJson]) — no
  /// fromEntity/toEntity mappers, unlike `DataTemplates._modelFreezed`: a
  /// request/response DTO has no domain Entity counterpart to map to/from.
  static String _freezedModel(String base, List<FieldSpec> fields, bool hasJson) {
    final params = fields.map((f) {
      final ann = hasJson && f.needsJsonKey ? '    ${f.jsonKeyAnnotation}\n' : '';
      return '$ann    ${f.nullable ? '' : 'required '}${f.modelType} ${f.dartName},';
    }).join('\n');
    final fromJson = hasJson
        ? '\n  factory ${base}Model.fromJson(Map<String, dynamic> json) =>\n      _\$${base}ModelFromJson(json);\n'
        : '';
    return '''@freezed
abstract class ${base}Model with _\$${base}Model {
  const factory ${base}Model({
$params
  }) = _${base}Model;
$fromJson}''';
  }

  /// One plain (no codegen) model class with hand-written JSON — no
  /// fromEntity/toEntity mappers (see [_freezedModel]'s doc for why).
  static String _plainModel(String base, List<FieldSpec> fields) {
    final ctorParams = fields
        .map((f) => f.nullable ? '    this.${f.dartName},' : '    required this.${f.dartName},')
        .join('\n');
    final decls = fields.map((f) => '  final ${f.modelType} ${f.dartName};').join('\n');
    final fromJsonArgs = fields.map((f) => '    ${f.dartName}: ${f.fromJsonExpr()},').join('\n');
    final toJsonEntries = fields.map((f) => "    '${f.jsonKey}': ${f.toJsonValue()},").join('\n');
    return '''class ${base}Model {
  const ${base}Model({
$ctorParams
  });

$decls

  factory ${base}Model.fromJson(Map<String, dynamic> json) => ${base}Model(
$fromJsonArgs
  );

  Map<String, dynamic> toJson() => {
$toJsonEntries
  };
}''';
  }

  // ── data/sources/<feature>_api_source.dart (chopper method fragment) ──────

  /// One typed chopper method for [endpoint]. Unlike the CRUD API source
  /// (one shared `@ChopperApi(baseUrl: ...)` — every method relative to it),
  /// custom endpoints have no common resource path, so each method carries
  /// its **own full path** and the class-level `baseUrl` stays empty (see
  /// `DataTemplates.featureApiSource`'s `useCustomEndpoints` branch).
  static String apiSourceMethod(EndpointSpec endpoint) {
    final verb = endpoint.method.name.toUpperCase();
    final p = pascal(endpoint.name);
    final responseType = endpoint.hasResponseBody ? '${p}ResponseModel' : 'dynamic';
    final params = endpoint.hasRequestBody ? '@Body() ${p}RequestModel body' : '';
    return '''  @$verb(path: '${endpoint.path}')
  Future<Response<$responseType>> ${endpoint.name}($params);''';
  }

  // ── domain/usecases/<endpoint>_usecase.dart ───────────────────────────────

  /// One UseCase per endpoint — calls the feature's `ApiSource` directly (no
  /// repository interface to mediate: there's no entity to abstract over,
  /// see FeatureScaffolder's useCustomEndpoints branch) and unwraps the
  /// chopper response exactly like the CRUD repository does.
  static String endpointUsecase({
    required EndpointSpec endpoint,
    required String featureName,
    required String packageName,
    String? corePackageName,
  }) {
    final p = pascal(endpoint.name);
    final corePkg = corePackageName ?? packageName;
    final hasReq = endpoint.hasRequestBody;
    final hasRes = endpoint.hasResponseBody;

    final paramsType = hasReq ? '${p}RequestModel' : 'Unit';
    final resultType = hasRes ? '${p}ResponseModel' : 'Unit';
    final baseClass = hasReq ? 'UseCase<$paramsType, $resultType>' : 'NoParamsUseCase<$resultType>';
    final executeSig = hasReq
        ? 'Future<$resultType> execute($paramsType params) async'
        : 'Future<$resultType> execute(Unit _) async';
    final callArg = hasReq ? 'params' : '';
    final body = hasRes
        ? '    final response = await _api.${endpoint.name}($callArg);\n'
            '    return unwrapChopperResponse(response);'
        : '    await _api.${endpoint.name}($callArg);\n'
            '    return Unit.instance;';

    final imports = [
      // Only needed to unwrap a response — a bodyless call (no request, no
      // response) never calls unwrapChopperResponse.
      if (hasRes) "import 'package:$corePkg/core/network/chopper_model_converter.dart';",
      "import 'package:$corePkg/core/usecases/use_case.dart';",
      if (hasReq || hasRes) "import '../../data/models/${endpoint.name}_model.dart';",
      "import '../../data/sources/${featureName}_api_source.dart';",
    ].join('\n');

    return '''$imports

class ${p}Usecase extends $baseClass {
  const ${p}Usecase(this._api);

  final ${pascal(featureName)}ApiSource _api;

  @override
  $executeSig {
$body
  }
}
''';
  }
}
