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
    bool offlineFirst = false,
    bool hasSync = false,
    bool realtime = false,
  }) {
    final p = pascal(featureName);
    final isChopper = httpClient == 'chopper';
    final modelExpr = '${p}Model(id: entity.id, name: entity.name)';

    // Chopper wraps responses in Response<T>; unwrap with .body!.
    String remote(String call) =>
        isChopper ? '(await _remote.$call).body!' : 'await _remote.$call';

    // Realtime: surface the source's live stream, mapped models → entities.
    final watchMethod = realtime
        ? '''

  @override
  Stream<List<${p}Entity>> watchAll() =>
      _remote.watchAll().map((list) => list.map((m) => m.toEntity()).toList());'''
        : '';

    // ── Offline-first (read-through cache) + optional sync (Outbox) ──────────
    if (offlineFirst && hasHttpClient) {
      // Write methods differ: sync mode queues to the Outbox; read mode needs
      // the network and writes through to the local cache.
      final convertImport = hasSync ? "import 'dart:convert';\n" : '';
      final writeMethods = hasSync
          ? '''

  @override
  Future<Result<${p}Entity>> create(${p}Entity entity) async {
    final model = $modelExpr;
    await _local.upsert(model); // optimistic
    await _local.enqueueWrite(
      operation: 'create',
      endpoint: '/${featureName}s/add',
      payload: jsonEncode(model.toJson()),
    );
    return Result.success(entity);
  }

  @override
  Future<Result<${p}Entity>> update(${p}Entity entity) async {
    final model = $modelExpr;
    await _local.upsert(model); // optimistic
    await _local.enqueueWrite(
      operation: 'update',
      endpoint: '/${featureName}s/\${entity.id}',
      payload: jsonEncode(model.toJson()),
    );
    return Result.success(entity);
  }

  @override
  Future<Result<bool>> delete(String id) async {
    await _local.deleteById(id); // optimistic
    await _local.enqueueWrite(
      operation: 'delete',
      endpoint: '/${featureName}s/\$id',
      payload: jsonEncode({'id': id}),
    );
    return Result.success(true);
  }'''
          : '''

  @override
  Future<Result<${p}Entity>> create(${p}Entity entity) async {
    if (!await _network.isConnected) return Result.failure('No connection.');
    try {
      final model = $modelExpr;
      final created = ${remote('add(model)')};
      await _local.upsert(created);
      return Result.success(created.toEntity());
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  @override
  Future<Result<${p}Entity>> update(${p}Entity entity) async {
    if (!await _network.isConnected) return Result.failure('No connection.');
    try {
      final model = $modelExpr;
      final updated = ${remote('update(entity.id, model)')};
      await _local.upsert(updated);
      return Result.success(updated.toEntity());
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  @override
  Future<Result<bool>> delete(String id) async {
    if (!await _network.isConnected) return Result.failure('No connection.');
    try {
      await _remote.delete(id);
      await _local.deleteById(id);
      return Result.success(true);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }''';

      return '''${convertImport}import 'package:$packageName/core/network/network_info.dart';
import 'package:$packageName/core/result/result.dart';
import 'package:$packageName/features/$featureName/domain/entities/${featureName}_entity.dart';
import 'package:$packageName/features/$featureName/domain/repositories/i_${featureName}_repository.dart';
import '../models/${featureName}_model.dart';
import '../sources/${featureName}_api_source.dart';
import '../sources/${featureName}_local_source.dart';

/// Offline-first repository: reads the network when online (writing through to
/// the local cache), and falls back to the cache when offline or on error.
class ${p}RepositoryImpl implements I${p}Repository {
  const ${p}RepositoryImpl(this._remote, this._local, this._network);

  final ${p}ApiSource _remote;
  final ${p}LocalSource _local;
  final NetworkInfo _network;

  @override
  Future<Result<List<${p}Entity>>> getAll() async {
    if (await _network.isConnected) {
      try {
        final fresh = ${remote('getAll()')};
        await _local.cacheAll(fresh);
        return Result.success(fresh.map((m) => m.toEntity()).toList());
      } catch (_) {
        // Network failed — fall through to the cache below.
      }
    }
    final cached = await _local.getAll();
    return Result.success(cached.map((m) => m.toEntity()).toList());
  }

  @override
  Future<Result<${p}Entity>> getById(String id) async {
    if (await _network.isConnected) {
      try {
        final fresh = ${remote('getById(id)')};
        return Result.success(fresh.toEntity());
      } catch (_) {
        // Network failed — fall through to the cache below.
      }
    }
    final cached = await _local.getById(id);
    if (cached == null) {
      return Result.failure('Not available offline.');
    }
    return Result.success(cached.toEntity());
  }$writeMethods$watchMethod
}
''';
    }

    // ── Remote-only, full CRUD ────────────────────────────────────────────────
    if (hasHttpClient) {
      return '''import 'package:$packageName/core/result/result.dart';
import 'package:$packageName/features/$featureName/domain/entities/${featureName}_entity.dart';
import 'package:$packageName/features/$featureName/domain/repositories/i_${featureName}_repository.dart';
import '../models/${featureName}_model.dart';
import '../sources/${featureName}_api_source.dart';

class ${p}RepositoryImpl implements I${p}Repository {
  const ${p}RepositoryImpl(this._remote);

  final ${p}ApiSource _remote;

  @override
  Future<Result<List<${p}Entity>>> getAll() async {
    try {
      final data = ${remote('getAll()')};
      return Result.success(data.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  @override
  Future<Result<${p}Entity>> getById(String id) async {
    try {
      final data = ${remote('getById(id)')};
      return Result.success(data.toEntity());
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  @override
  Future<Result<${p}Entity>> create(${p}Entity entity) async {
    try {
      final model = $modelExpr;
      final created = ${remote('add(model)')};
      return Result.success(created.toEntity());
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  @override
  Future<Result<${p}Entity>> update(${p}Entity entity) async {
    try {
      final model = $modelExpr;
      final updated = ${remote('update(entity.id, model)')};
      return Result.success(updated.toEntity());
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  @override
  Future<Result<bool>> delete(String id) async {
    try {
      await _remote.delete(id);
      return Result.success(true);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }$watchMethod
}
''';
    }

    // ── No HTTP client: read-only local stub ──────────────────────────────────
    return '''import 'package:$packageName/core/result/result.dart';
import 'package:$packageName/features/$featureName/domain/entities/${featureName}_entity.dart';
import 'package:$packageName/features/$featureName/domain/repositories/i_${featureName}_repository.dart';
import '../sources/${featureName}_local_source.dart';

class ${p}RepositoryImpl implements I${p}Repository {
  const ${p}RepositoryImpl(this._source);

  final ${p}LocalSource _source;

  @override
  Future<Result<List<${p}Entity>>> getAll() async {
    try {
      final data = await _source.getAll();
      return Result.success(data.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  @override
  Future<Result<${p}Entity>> getById(String id) async {
    try {
      final data = await _source.getById(id);
      return Result.success(data.toEntity());
    } catch (e) {
      return Result.failure(e.toString());
    }
  }
}
''';
  }

  // ── data/sources (api) ────────────────────────────────────────────────────

  static String featureApiSource({
    required String featureName,
    required String packageName,
    required String httpClient,
    bool realtime = false,
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

  @POST('/${featureName}s/add')
  Future<${p}Model> add(@Body() ${p}Model body);

  @PUT('/${featureName}s/{id}')
  Future<${p}Model> update(@Path('id') String id, @Body() ${p}Model body);

  @DELETE('/${featureName}s/{id}')
  Future<void> delete(@Path('id') String id);
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

  @POST(path: '/add')
  Future<Response<${p}Model>> add(@Body() ${p}Model body);

  @PUT(path: '/{id}')
  Future<Response<${p}Model>> update(@Path() String id, @Body() ${p}Model body);

  @DELETE(path: '/{id}')
  Future<Response<dynamic>> delete(@Path() String id);
}
''';
    }

    if (httpClient == 'supabase') {
      return '''import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:$packageName/features/$featureName/data/models/${featureName}_model.dart';

/// Supabase-backed remote source. Exposes the same contract as the REST api
/// source, so the repository / usecases / providers stay unchanged.
class ${p}ApiSource {
  const ${p}ApiSource(this._client);

  final SupabaseClient _client;

  static const String _table = '${featureName}s';

  Future<List<${p}Model>> getAll() async {
    final rows = await _client.from(_table).select();
    return rows.map(${p}Model.fromJson).toList();
  }
${realtime ? '''
  /// Realtime: a live stream of every row, pushed on any INSERT/UPDATE/DELETE.
  Stream<List<${p}Model>> watchAll() => _client
      .from(_table)
      .stream(primaryKey: ['id'])
      .map((rows) => rows.map(${p}Model.fromJson).toList());
''' : ''}

  Future<${p}Model> getById(String id) async {
    final row = await _client.from(_table).select().eq('id', id).single();
    return ${p}Model.fromJson(row);
  }

  Future<${p}Model> add(${p}Model body) async {
    final row = await _client.from(_table).insert(body.toJson()).select().single();
    return ${p}Model.fromJson(row);
  }

  Future<${p}Model> update(String id, ${p}Model body) async {
    final row =
        await _client.from(_table).update(body.toJson()).eq('id', id).select().single();
    return ${p}Model.fromJson(row);
  }

  Future<void> delete(String id) async {
    await _client.from(_table).delete().eq('id', id);
  }
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

  Future<${p}Model> add(${p}Model body) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/${featureName}s/add',
      data: body.toJson(),
    );
    return ${p}Model.fromJson(response.data!);
  }

  Future<${p}Model> update(String id, ${p}Model body) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/${featureName}s/\$id',
      data: body.toJson(),
    );
    return ${p}Model.fromJson(response.data!);
  }

  Future<void> delete(String id) async {
    await _dio.delete<void>('/${featureName}s/\$id');
  }
}
''';
  }

  // ── data/sources (local) ──────────────────────────────────────────────────

  static String featureLocalSource({
    required String featureName,
    required String packageName,
    bool offlineFirst = false,
    bool hasSync = false,
    String? localStoragePackage,
  }) {
    final p = pascal(featureName);

    // Offline-first: back the local source with the typed Drift table, mapping
    // rows to/from the model for full local CRUD.
    if (offlineFirst && localStoragePackage != null) {
      // Sync mode adds an Outbox enqueue helper for offline writes.
      final enqueue = hasSync
          ? '''

  /// Queue a write to be replayed by the SyncService when back online.
  Future<void> enqueueWrite({
    required String operation,
    required String endpoint,
    String? payload,
  }) =>
      _db.enqueueOutbox(operation: operation, endpoint: endpoint, payload: payload);'''
          : '';

      return '''import 'package:$localStoragePackage/$localStoragePackage.dart';
import 'package:$packageName/features/$featureName/data/models/${featureName}_model.dart';

class ${p}LocalSource {
  const ${p}LocalSource(this._db);

  final AppDatabase _db;

  Future<List<${p}Model>> getAll() async =>
      (await _db.getAll${p}s()).map(_toModel).toList();

  Future<${p}Model?> getById(String id) async {
    final row = await _db.get$p(id);
    return row == null ? null : _toModel(row);
  }

  Future<void> cacheAll(List<${p}Model> models) =>
      _db.upsertAll${p}s(models.map(_toRow).toList());

  Future<void> upsert(${p}Model model) => _db.upsert$p(_toRow(model));

  Future<void> deleteById(String id) => _db.delete$p(id);

  ${p}Model _toModel(${p}Row row) => ${p}Model(id: row.id, name: row.name);

  ${p}Row _toRow(${p}Model model) => ${p}Row(id: model.id, name: model.name);$enqueue
}
''';
    }

    // Remote-only: in-memory stub the user fills in.
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
