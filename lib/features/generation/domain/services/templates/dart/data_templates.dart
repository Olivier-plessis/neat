import 'package:neat/features/generation/domain/models/field_spec.dart';
import 'package:neat/features/generation/domain/services/templates/dart/_template_utils.dart';
import 'package:neat/features/generation/domain/services/templates/dart/field_codegen.dart';

class DataTemplates {
  DataTemplates._();

  // ── data/models ───────────────────────────────────────────────────────────

  static String featureModel({
    required String featureName,
    required String packageName,
    required bool hasFreezed,
    required bool hasJsonSerializable,
    List<FieldSpec> fields = FieldSpec.idName,
  }) {
    final p = pascal(featureName);
    final entityImport =
        "import 'package:$packageName/features/$featureName/domain/entities/${featureName}_entity.dart';";
    // Nested objects (and list-element objects) each become their own sub-model.
    final objects = collectObjectSpecs(fields);

    if (hasFreezed) {
      // freezed handles JSON serialization internally; json_serializable wires
      // nested model fromJson/toJson automatically. A private constructor (_())
      // is required to add custom methods (toEntity / fromEntity).
      final partJson = hasJsonSerializable ? "\npart '${featureName}_model.g.dart';" : '';
      final classes = [
        _modelFreezed(p, fields, hasJsonSerializable),
        for (final o in objects) _modelFreezed(o.objectName, o.children, hasJsonSerializable),
      ].join('\n\n');
      // The id converter (see FieldCodegen.idFromJsonName) is only needed once
      // per file — only the top-level entity ever carries an id.
      final idHelper = hasJsonSerializable && fields.any((f) => f.isId)
          ? '\n\n/// A real API may emit an int/num id; NEAT always types id as\n'
              '/// String, so this converts leniently instead of an unsafe cast.\n'
              'String _idFromJson(dynamic value) => value.toString();'
          : '';
      return '''import 'package:freezed_annotation/freezed_annotation.dart';
$entityImport
part '${featureName}_model.freezed.dart';$partJson

$classes$idHelper
''';
    }

    final classes = [
      _modelPlain(p, fields),
      for (final o in objects) _modelPlain(o.objectName, o.children),
    ].join('\n\n');
    return '''$entityImport

$classes
''';
  }

  /// One freezed model class with fromJson (when [hasJson]) + fromEntity/toEntity
  /// mappers ([base] → `<base>Model` ↔ `<base>Entity`).
  static String _modelFreezed(String base, List<FieldSpec> fields, bool hasJson) {
    final params = fields.map((f) {
      var ann = '';
      if (hasJson) {
        // Combine a rename (if any) with the id's lenient converter (see
        // FieldCodegen.idFromJsonName) into a single @JsonKey.
        final parts = <String>[
          if (f.needsJsonKey) "name: '${f.jsonKey}'",
          if (f.isId) 'fromJson: ${f.idFromJsonName}',
        ];
        if (parts.isNotEmpty) ann = '@JsonKey(${parts.join(', ')})';
      }
      final annLine = ann.isEmpty ? '' : '    $ann\n';
      return '$annLine    ${f.nullable ? '' : 'required '}${f.modelType} ${f.dartName},';
    }).join('\n');
    final fromJson = hasJson
        ? '\n  factory ${base}Model.fromJson(Map<String, dynamic> json) =>\n      _\$${base}ModelFromJson(json);\n'
        : '';
    final fromEntityArgs = fields.map((f) => '    ${f.dartName}: ${f.fromEntityValue('e')},').join('\n');
    final toEntityArgs = fields.map((f) => '    ${f.dartName}: ${f.toEntityValue()},').join('\n');
    return '''@freezed
abstract class ${base}Model with _\$${base}Model {
  const ${base}Model._();

  const factory ${base}Model({
$params
  }) = _${base}Model;
$fromJson
  factory ${base}Model.fromEntity(${base}Entity e) => ${base}Model(
$fromEntityArgs
  );

  ${base}Entity toEntity() => ${base}Entity(
$toEntityArgs
  );
}''';
  }

  /// One plain (no codegen) model class with hand-written JSON + mappers.
  static String _modelPlain(String base, List<FieldSpec> fields) {
    final ctorParams = fields
        .map((f) => f.nullable ? '    this.${f.dartName},' : '    required this.${f.dartName},')
        .join('\n');
    final decls = fields.map((f) => '  final ${f.modelType} ${f.dartName};').join('\n');
    final fromJsonArgs = fields.map((f) => '    ${f.dartName}: ${f.fromJsonExpr()},').join('\n');
    final toJsonEntries = fields.map((f) => "    '${f.jsonKey}': ${f.toJsonValue()},").join('\n');
    final fromEntityArgs = fields.map((f) => '    ${f.dartName}: ${f.fromEntityValue('e')},').join('\n');
    final toEntityArgs = fields.map((f) => '    ${f.dartName}: ${f.toEntityValue()},').join('\n');
    return '''class ${base}Model {
  const ${base}Model({
$ctorParams
  });

$decls

  factory ${base}Model.fromJson(Map<String, dynamic> json) => ${base}Model(
$fromJsonArgs
  );

  factory ${base}Model.fromEntity(${base}Entity e) => ${base}Model(
$fromEntityArgs
  );

  Map<String, dynamic> toJson() => {
$toJsonEntries
  };

  ${base}Entity toEntity() => ${base}Entity(
$toEntityArgs
  );
}''';
  }

  static String featureExampleModel({
    required String featureName,
    List<FieldSpec> fields = FieldSpec.idName,
  }) {
    final p = pascal(featureName);
    final objects = collectObjectSpecs(fields);
    String cls(String base, List<FieldSpec> fs) {
      final ctorParams = fs
          .map((f) => f.nullable ? '    this.${f.dartName},' : '    required this.${f.dartName},')
          .join('\n');
      final decls = fs.map((f) => '  final ${f.modelType} ${f.dartName};').join('\n');
      return '''class ${base}Model {
  const ${base}Model({
$ctorParams
  });

$decls
}''';
    }

    final classes = [
      cls(p, fields),
      for (final o in objects) cls(o.objectName, o.children),
    ].join('\n\n');
    return '''// Domain model for $featureName
$classes
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
    List<FieldSpec> fields = FieldSpec.idName,
  }) {
    final p = pascal(featureName);
    final isChopper = httpClient == 'chopper';
    // Deep entity→model conversion (handles nested objects/lists).
    final modelExpr = '${p}Model.fromEntity(entity)';

    // Chopper wraps responses in Response<T> and doesn't throw on non-2xx by
    // default — unwrapChopperResponse throws ChopperApiException instead of a
    // blind `.body!` (which just gives "Null check operator used on a null
    // value" with no status code). Other clients throw natively already.
    String remote(String call) =>
        isChopper ? 'unwrapChopperResponse(await _remote.$call)' : 'await _remote.$call';
    final chopperImport = isChopper
        ? "import 'package:$packageName/core/network/chopper_model_converter.dart';\n"
        : '';

    // Realtime: surface the source's live stream, mapped models → entities.
    final watchMethod = realtime
        ? '''

  @override
  Stream<List<${p}Entity>> watchAll() =>
      _remote.watchAll().map((list) => list.map((m) => m.toEntity()).toList());'''
        : '';

    // ── Offline-first (read-through cache) + optional sync (Outbox) ──────────
    if (offlineFirst && hasHttpClient) {
      // Write methods differ: sync mode queues to the Outbox (optimistic, no
      // network call to fail synchronously); read mode calls the network and
      // writes through to the local cache. Neither path catches its own errors
      // any more — UseCase.call() does that uniformly — except the reads
      // below, whose network→cache fallback is a deliberate resilience
      // strategy, not boilerplate error handling, so it stays here.
      final convertImport = hasSync ? "import 'dart:convert';\n" : '';
      final writeMethods = hasSync
          ? '''

  @override
  Future<${p}Entity> create(${p}Entity entity) async {
    final model = $modelExpr;
    await _local.upsert(model); // optimistic
    await _local.enqueueWrite(
      operation: 'create',
      endpoint: '/${featureName}s/add',
      payload: jsonEncode(model.toJson()),
    );
    return entity;
  }

  @override
  Future<${p}Entity> update(${p}Entity entity) async {
    final model = $modelExpr;
    await _local.upsert(model); // optimistic
    await _local.enqueueWrite(
      operation: 'update',
      endpoint: '/${featureName}s/\${entity.id}',
      payload: jsonEncode(model.toJson()),
    );
    return entity;
  }

  @override
  Future<bool> delete(String id) async {
    await _local.deleteById(id); // optimistic
    await _local.enqueueWrite(
      operation: 'delete',
      endpoint: '/${featureName}s/\$id',
      payload: jsonEncode({'id': id}),
    );
    return true;
  }'''
          : '''

  @override
  Future<${p}Entity> create(${p}Entity entity) async {
    if (!await _network.isConnected) {
      throw const Failure(message: 'No connection.');
    }
    final model = $modelExpr;
    final created = ${remote('add(model)')};
    await _local.upsert(created);
    return created.toEntity();
  }

  @override
  Future<${p}Entity> update(${p}Entity entity) async {
    if (!await _network.isConnected) {
      throw const Failure(message: 'No connection.');
    }
    final model = $modelExpr;
    final updated = ${remote('update(entity.id, model)')};
    await _local.upsert(updated);
    return updated.toEntity();
  }

  @override
  Future<bool> delete(String id) async {
    if (!await _network.isConnected) {
      throw const Failure(message: 'No connection.');
    }
    await _remote.delete(id);
    await _local.deleteById(id);
    return true;
  }''';

      return '''$convertImport${chopperImport}import 'package:$packageName/core/error/failure.dart';
import 'package:$packageName/core/network/network_info.dart';
import 'package:$packageName/core/result/result.dart';
import 'package:$packageName/core/utils/app_logger.dart';
import 'package:$packageName/features/$featureName/domain/entities/${featureName}_entity.dart';
import 'package:$packageName/features/$featureName/domain/repositories/i_${featureName}_repository.dart';
import '../models/${featureName}_model.dart';
import '../sources/${featureName}_api_source.dart';
import '../sources/${featureName}_local_source.dart';

/// Offline-first repository: reads the network when online (writing through to
/// the local cache), and falls back to the cache when offline or on error.
/// Reads keep their own try/catch (a resilience *strategy*, not boilerplate
/// error handling): every other method just throws and lets UseCase.call()
/// convert the exception to a Failure via NetworkErrorHandler.
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
      } catch (e, st) {
        // Logged, not swallowed: a 404/bad config/parse error looks identical
        // to "offline" otherwise — this keeps the graceful cache fallback but
        // surfaces real bugs instead of a silently empty list.
        AppLogger.w('$featureName.getAll() failed — falling back to cache', error: e, stackTrace: st);
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
      } catch (e, st) {
        AppLogger.w('$featureName.getById() failed — falling back to cache', error: e, stackTrace: st);
      }
    }
    final cached = await _local.getById(id);
    if (cached == null) {
      return Result.failure(const Failure(message: 'Not available offline.'));
    }
    return Result.success(cached.toEntity());
  }$writeMethods$watchMethod
}
''';
    }

    // ── Remote-only, full CRUD ────────────────────────────────────────────────
    if (hasHttpClient) {
      return '''${chopperImport}import 'package:$packageName/features/$featureName/domain/entities/${featureName}_entity.dart';
import 'package:$packageName/features/$featureName/domain/repositories/i_${featureName}_repository.dart';
import '../models/${featureName}_model.dart';
import '../sources/${featureName}_api_source.dart';

/// Throws on failure — UseCase.call() converts the exception to a Failure
/// via NetworkErrorHandler. No try/catch here: there's no fallback strategy
/// for a remote-only feature, so catching would just be boilerplate.
class ${p}RepositoryImpl implements I${p}Repository {
  const ${p}RepositoryImpl(this._remote);

  final ${p}ApiSource _remote;

  @override
  Future<List<${p}Entity>> getAll() async {
    final data = ${remote('getAll()')};
    return data.map((m) => m.toEntity()).toList();
  }

  @override
  Future<${p}Entity> getById(String id) async {
    final data = ${remote('getById(id)')};
    return data.toEntity();
  }

  @override
  Future<${p}Entity> create(${p}Entity entity) async {
    final model = $modelExpr;
    final created = ${remote('add(model)')};
    return created.toEntity();
  }

  @override
  Future<${p}Entity> update(${p}Entity entity) async {
    final model = $modelExpr;
    final updated = ${remote('update(entity.id, model)')};
    return updated.toEntity();
  }

  @override
  Future<bool> delete(String id) async {
    await _remote.delete(id);
    return true;
  }$watchMethod
}
''';
    }

    // ── No HTTP client: read-only local stub ──────────────────────────────────
    return '''import 'package:$packageName/features/$featureName/domain/entities/${featureName}_entity.dart';
import 'package:$packageName/features/$featureName/domain/repositories/i_${featureName}_repository.dart';
import '../sources/${featureName}_local_source.dart';

class ${p}RepositoryImpl implements I${p}Repository {
  const ${p}RepositoryImpl(this._source);

  final ${p}LocalSource _source;

  @override
  Future<List<${p}Entity>> getAll() async {
    final data = await _source.getAll();
    return data.map((m) => m.toEntity()).toList();
  }

  @override
  Future<${p}Entity> getById(String id) async {
    final data = await _source.getById(id);
    return data.toEntity();
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

    if (httpClient == 'firebase') {
      return '''import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:$packageName/features/$featureName/data/models/${featureName}_model.dart';

/// Firestore-backed remote source. The document id is merged into the model's
/// JSON, so the repository / usecases / providers stay unchanged.
class ${p}ApiSource {
  const ${p}ApiSource(this._db);

  final FirebaseFirestore _db;

  static const String _collection = '${featureName}s';

  CollectionReference<Map<String, dynamic>> get _ref => _db.collection(_collection);

  ${p}Model _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      ${p}Model.fromJson({...?doc.data(), 'id': doc.id});

  Future<List<${p}Model>> getAll() async {
    final snap = await _ref.get();
    return snap.docs.map(_fromDoc).toList();
  }
${realtime ? '''
  /// Realtime: a live stream of the collection via Firestore snapshots.
  Stream<List<${p}Model>> watchAll() =>
      _ref.snapshots().map((snap) => snap.docs.map(_fromDoc).toList());
''' : ''}
  Future<${p}Model> getById(String id) async {
    final doc = await _ref.doc(id).get();
    return _fromDoc(doc);
  }

  Future<${p}Model> add(${p}Model body) async {
    final ref = await _ref.add(body.toJson()..remove('id'));
    return _fromDoc(await ref.get());
  }

  Future<${p}Model> update(String id, ${p}Model body) async {
    await _ref.doc(id).update(body.toJson()..remove('id'));
    return _fromDoc(await _ref.doc(id).get());
  }

  Future<void> delete(String id) => _ref.doc(id).delete();
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
    List<FieldSpec> fields = FieldSpec.idName,
  }) {
    final p = pascal(featureName);
    // Complex fields are stored as serialised JSON in the Drift row → encode on
    // write, decode on read. Scalars pass through unchanged.
    final hasComplex = fields.any((f) => f.isComplex);
    final toModelArgs = fields.map((f) => '${f.dartName}: ${f.driftDecode('row')}').join(', ');
    final toRowArgs = fields.map((f) => '${f.dartName}: ${f.driftEncode('model')}').join(', ');
    final convertImport = hasComplex ? "import 'dart:convert';\n\n" : '';

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

      return '''${convertImport}import 'package:$localStoragePackage/$localStoragePackage.dart';
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

  ${p}Model _toModel(${p}Row row) => ${p}Model($toModelArgs);

  ${p}Row _toRow(${p}Model model) => ${p}Row($toRowArgs);$enqueue
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

  // ── data/repositories/<f>_repository_providers.dart (repository-level DI) ──

  /// Wires the repository-level Riverpod graph: the API source, the local
  /// source (offline-first), the repository provider — typed to the
  /// **abstract** domain interface — and the offline sync engine.
  ///
  /// Lives in `data/`, not `presentation/`: every provider here is built from
  /// concrete Data types (ApiSource, Model, RepositoryImpl). Presentation-side
  /// usecase providers consume only the abstract-typed repository provider
  /// exposed here — they never import a concrete Data class directly.
  static String featureRepositoryProviders({
    required String featureName,
    required String packageName,
    required String httpClient,
    required bool offlineFirst,
    bool hasSync = false,
    String? localStoragePackage,
  }) {
    final p = pascal(featureName);
    final c = camel(featureName);

    final imports = StringBuffer();
    if (hasSync) imports.writeln("import 'dart:convert';\n");
    imports.writeln("import 'package:riverpod_annotation/riverpod_annotation.dart';");
    if (offlineFirst) {
      // Shared app-wide singletons (Drift db + connectivity) live in core, not
      // per feature, so every feature reuses the same instances.
      imports.writeln(
          "import 'package:$packageName/core/providers/infrastructure_providers.dart';");
    }
    imports.writeln(switch (httpClient) {
      'chopper' => "import 'package:$packageName/core/network/chopper_client_provider.dart';",
      'supabase' => "import 'package:$packageName/core/network/supabase_provider.dart';",
      'firebase' => "import 'package:$packageName/core/network/firebase_provider.dart';",
      _ => "import 'package:$packageName/core/network/dio_provider.dart';",
    });
    if (hasSync) {
      imports.writeln("import 'package:$packageName/core/sync/sync_service.dart';");
    }
    imports
      ..writeln(
          "import 'package:$packageName/features/$featureName/domain/repositories/i_${featureName}_repository.dart';")
      ..writeln("import '${featureName}_repository_impl.dart';")
      ..writeln("import '../sources/${featureName}_api_source.dart';");
    if (hasSync) {
      imports.writeln("import '../models/${featureName}_model.dart';");
    }
    if (offlineFirst) {
      imports.writeln("import '../sources/${featureName}_local_source.dart';");
    }

    final apiConstruct = switch (httpClient) {
      'chopper' => '${p}ApiSource.create(ref.watch(chopperClientProvider))',
      'supabase' => '${p}ApiSource(ref.watch(supabaseClientProvider))',
      'firebase' => '${p}ApiSource(ref.watch(firestoreProvider))',
      _ => '${p}ApiSource(ref.watch(dioProvider))',
    };

    // appDatabaseProvider + networkInfoProvider come from the shared
    // core/providers/infrastructure_providers.dart (single instance app-wide).
    final offlineProviders = offlineFirst
        ? '''

@Riverpod(keepAlive: true)
${p}LocalSource ${c}LocalSource(Ref ref) => ${p}LocalSource(ref.watch(appDatabaseProvider));'''
        : '';

    final repoConstruct = offlineFirst
        ? '${p}RepositoryImpl(\n      ref.watch(${c}ApiSourceProvider),\n      ref.watch(${c}LocalSourceProvider),\n      ref.watch(networkInfoProvider),\n    )'
        : '${p}RepositoryImpl(ref.watch(${c}ApiSourceProvider))';

    // Chopper API calls return Response<T>; the result is ignored either way.
    final syncProvider = hasSync
        ? '''

/// Drains the offline write queue via the API source when back online.
/// Auto-starts on first read; cancels its subscription on dispose.
@Riverpod(keepAlive: true)
SyncService ${c}Sync(Ref ref) {
  final api = ref.watch(${c}ApiSourceProvider);
  final service = SyncService(
    ref.watch(appDatabaseProvider),
    ref.watch(networkInfoProvider),
    (entry) async {
      final data = entry.payload == null
          ? const <String, dynamic>{}
          : jsonDecode(entry.payload!) as Map<String, dynamic>;
      switch (entry.operation) {
        case 'create':
          await api.add(${p}Model.fromJson(data));
        case 'update':
          final model = ${p}Model.fromJson(data);
          await api.update(model.id, model);
        case 'delete':
          await api.delete(data['id'] as String);
      }
      return true;
    },
  )..start();
  ref.onDispose(service.dispose);
  return service;
}'''
        : '';

    return '''${imports.toString()}
part '${featureName}_repository_providers.g.dart';

@Riverpod(keepAlive: true)
${p}ApiSource ${c}ApiSource(Ref ref) => $apiConstruct;$offlineProviders

@Riverpod(keepAlive: true)
I${p}Repository ${c}Repository(Ref ref) => $repoConstruct;$syncProvider
''';
  }
}
