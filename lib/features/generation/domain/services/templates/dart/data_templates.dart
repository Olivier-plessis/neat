import 'package:neat/features/generation/domain/services/templates/dart/_template_utils.dart';

class DataTemplates {
  DataTemplates._();

  // ── data/models ───────────────────────────────────────────────────────────

  static String featureModel({
    required String featureName,
    required String packageName,
    required bool hasFreezed,
    required bool hasJsonSerializable,
  }) {
    final p = pascal(featureName);
    final entityImport =
        "import 'package:$packageName/features/$featureName/domain/entities/${featureName}_entity.dart';";

    if (hasFreezed) {
      // freezed handles JSON serialization internally — do NOT add @JsonSerializable()
      // on the class, it conflicts with the generated constructor and causes build errors.
      // Private constructor (_()) is required to add custom methods on a freezed class.
      final partJson = hasJsonSerializable ? "\npart '${featureName}_model.g.dart';" : '';
      final fromJson = hasJsonSerializable
          ? '\n  factory ${p}Model.fromJson(Map<String, dynamic> json) =>\n      _\$${p}ModelFromJson(json);'
          : '';
      return '''import 'package:freezed_annotation/freezed_annotation.dart';
$entityImport
part '${featureName}_model.freezed.dart';$partJson

@freezed
abstract class ${p}Model with _\$${p}Model {
  const ${p}Model._(); // required to add methods on freezed class

  const factory ${p}Model({
    required String id,
    required String name,
  }) = _${p}Model;
$fromJson

  ${p}Entity toEntity() => ${p}Entity(
    id: id,
    name: name,
  );
}
''';
    }

    // Plain Dart model — independent from Entity, explicit toEntity() mapper
    return '''$entityImport

class ${p}Model {
  const ${p}Model({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;

  factory ${p}Model.fromJson(Map<String, dynamic> json) => ${p}Model(
    id: json['id'] as String,
    name: json['name'] as String,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
  };

  ${p}Entity toEntity() => ${p}Entity(
    id: id,
    name: name,
  );
}
''';
  }

  static String featureExampleModel({required String featureName}) {
    final p = pascal(featureName);
    return '''// Domain model for $featureName
class ${p}Model {
  const ${p}Model({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;
}
''';
  }

  // ── data/repositories (impl) ──────────────────────────────────────────────

  static String featureRepositoryImpl({
    required String featureName,
    required String packageName,
    required bool hasHttpClient,
    String httpClient = '',
  }) {
    final p = pascal(featureName);
    final sourceImport = hasHttpClient
        ? "import '../sources/${featureName}_api_source.dart';"
        : "import '../sources/${featureName}_local_source.dart';";
    final sourceName = hasHttpClient ? '${p}ApiSource' : '${p}LocalSource';

    // Chopper wraps responses in Response<T> — unwrap with .body!
    // Model and Entity are independent; toEntity() handles the mapping.
    final isChopper = httpClient == 'chopper';

    final getAllBody = isChopper
        ? '''    try {
      final response = await _source.getAll();
      return Result.success(response.body!.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Result.failure(e.toString());
    }'''
        : '''    try {
      final data = await _source.getAll();
      return Result.success(data.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Result.failure(e.toString());
    }''';

    final getByIdBody = isChopper
        ? '''    try {
      final response = await _source.getById(id);
      return Result.success(response.body!.toEntity());
    } catch (e) {
      return Result.failure(e.toString());
    }'''
        : '''    try {
      final data = await _source.getById(id);
      return Result.success(data.toEntity());
    } catch (e) {
      return Result.failure(e.toString());
    }''';

    return '''import 'package:$packageName/core/result/result.dart';
import 'package:$packageName/features/$featureName/domain/entities/${featureName}_entity.dart';
import 'package:$packageName/features/$featureName/domain/repositories/i_${featureName}_repository.dart';
$sourceImport

class ${p}RepositoryImpl implements I${p}Repository {
  const ${p}RepositoryImpl(this._source);

  final $sourceName _source;

  @override
  Future<Result<List<${p}Entity>>> getAll() async {
$getAllBody
  }

  @override
  Future<Result<${p}Entity>> getById(String id) async {
$getByIdBody
  }
}
''';
  }

  // ── data/sources (api) ────────────────────────────────────────────────────

  static String featureApiSource({
    required String featureName,
    required String packageName,
    required String httpClient,
  }) {
    final p = pascal(featureName);

    if (httpClient == 'retrofit') {
      return '''import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:$packageName/features/$featureName/data/models/${featureName}_model.dart';

part '${featureName}_api_source.g.dart';

@RestApi()
abstract class ${p}ApiSource {
  factory ${p}ApiSource(Dio dio, {String baseUrl}) = _${p}ApiSource;

  @GET('/${featureName}s')
  Future<List<${p}Model>> getAll();

  @GET('/${featureName}s/{id}')
  Future<${p}Model> getById(@Path('id') String id);
}
''';
    }

    if (httpClient == 'chopper') {
      return '''import 'package:chopper/chopper.dart';
import 'package:$packageName/features/$featureName/data/models/${featureName}_model.dart';

part '${featureName}_api_source.chopper.dart';

@ChopperApi(baseUrl: '/${featureName}s')
abstract class ${p}ApiSource extends ChopperService {
  static ${p}ApiSource create([ChopperClient? client]) => _\$${p}ApiSource(client);

  @GET()
  Future<Response<List<${p}Model>>> getAll();

  @GET(path: '/{id}')
  Future<Response<${p}Model>> getById(@Path() String id);
}
''';
    }

    // Dio plain
    return '''import 'package:dio/dio.dart';
import 'package:$packageName/features/$featureName/data/models/${featureName}_model.dart';

class ${p}ApiSource {
  const ${p}ApiSource(this._dio);

  final Dio _dio;

  Future<List<${p}Model>> getAll() async {
    final response = await _dio.get<List<dynamic>>('/${featureName}s');
    return (response.data ?? [])
        .cast<Map<String, dynamic>>()
        .map(${p}Model.fromJson)
        .toList();
  }

  Future<${p}Model> getById(String id) async {
    final response = await _dio.get<Map<String, dynamic>>('/${featureName}s/\$id');
    return ${p}Model.fromJson(response.data!);
  }
}
''';
  }

  // ── data/sources (local) ──────────────────────────────────────────────────

  static String featureLocalSource({
    required String featureName,
    required String packageName,
  }) {
    final p = pascal(featureName);
    return '''import 'package:$packageName/features/$featureName/data/models/${featureName}_model.dart';

class ${p}LocalSource {
  const ${p}LocalSource();

  Future<List<${p}Model>> getAll() async {
    return [];
  }

  Future<${p}Model> getById(String id) async {
    throw UnimplementedError('getById not implemented');
  }
}
''';
  }
}
