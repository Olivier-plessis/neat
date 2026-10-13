import 'package:neat/features/generation/domain/models/field_spec.dart';
import 'package:neat/features/generation/domain/services/templates/dart/_template_utils.dart';
import 'package:neat/features/generation/domain/services/templates/dart/field_codegen.dart';

/// Tests shipped with an offline-first + sync project, so the contract the
/// archy project had to discover the hard way (a write queued offline really
/// reaches the server; the list shows it meanwhile) is executable from day one
/// instead of living in prose. Both run with an in-memory Drift database and a
/// fake network — no device, no backend.
class OfflineTestTemplates {
  OfflineTestTemplates._();

  /// `test/core/sync/sync_service_test.dart` — the SyncService's own contract:
  /// start-up flush, flush on every queued write, serialised flushes,
  /// per-resource ownership of the shared Outbox, retries + backoff, and the
  /// sign-out wipe ([AppDatabase.clearAll]).
  ///
  /// [corePackage]: the app's own name, or the shared core package's when
  /// split. [resource]: the Outbox resource the first feature owns (a
  /// Supabase table / a REST path without slashes).
  static String syncServiceTest({
    required String corePackage,
    required String localStoragePackage,
    required String resource,
  }) =>
      '''import 'dart:async';

import 'package:$corePackage/core/network/network_info.dart';
import 'package:$corePackage/core/sync/sync_service.dart';
import 'package:$localStoragePackage/$localStoragePackage.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeNetwork implements NetworkInfo {
  bool connected = true;
  final changes = StreamController<bool>.broadcast();

  @override
  Future<bool> get isConnected async => connected;

  @override
  Stream<bool> get onConnectivityChanged => changes.stream;
}

/// The queue is drained by async stream callbacks: wait for [check] to hold.
Future<void> eventually(
  bool Function() check, {
  Duration timeout = const Duration(seconds: 3),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!check()) {
    if (DateTime.now().isAfter(deadline)) fail('Condition not met in \$timeout');
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

void main() {
  late AppDatabase db;
  late _FakeNetwork network;
  late List<OutboxEntry> replayed;
  late SyncService service;

  Future<void> enqueue(String endpoint, [String operation = 'create']) => db
      .outboxDao
      .enqueueOutbox(operation: operation, endpoint: endpoint, payload: '{}');

  Future<List<OutboxEntry>> pending() => db.outboxDao.pendingOutbox();

  SyncService makeService(
    Future<ReplaySyncResult> Function(OutboxEntry entry) replay,
  ) => SyncService(db, network, replay, resource: '$resource');

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    network = _FakeNetwork();
    replayed = [];
    service = makeService((entry) async {
      replayed.add(entry);
      return ReplaySyncResult.success;
    });
  });

  tearDown(() async {
    await service.dispose();
    await network.changes.close();
    await db.close();
  });

  test('start() sends what a previous session left in the queue', () async {
    await enqueue('/$resource');

    service.start();

    await eventually(() => replayed.length == 1);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(await pending(), isEmpty); // acknowledged and removed
  });

  test(
    'a write queued while running goes out without a connectivity event',
    () async {
      service.start();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(replayed, isEmpty);

      await enqueue('/$resource');

      await eventually(() => replayed.length == 1);
    },
  );

  test(
    'start() gives a write that exhausted its retries another chance',
    () async {
      await enqueue('/$resource');
      final parked = (await pending()).single;
      for (var i = 0; i < SyncService.maxRetries; i++) {
        await db.outboxDao.incrementRetry(parked.id);
      }

      service.start();

      await eventually(() => replayed.length == 1);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(await pending(), isEmpty);
    },
  );

  test('only handles its own resource and leaves the others queued', () async {
    await enqueue('/other_resource');
    await enqueue('/$resource/42', 'update');

    service.start();

    await eventually(() => replayed.length == 1);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(replayed.single.endpoint, '/$resource/42');
    final left = await pending();
    expect(left.map((e) => e.endpoint), ['/other_resource']);
  });

  test('offline: waits for the connection to come back', () async {
    network.connected = false;
    await enqueue('/$resource');

    service.start();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(replayed, isEmpty);

    network.connected = true;
    network.changes.add(true);

    await eventually(() => replayed.length == 1);
  });

  test('a failing replay stays queued with a retry scheduled', () async {
    await service.dispose();
    var calls = 0;
    service = makeService((entry) async {
      calls++;
      throw Exception('server down');
    });
    await enqueue('/$resource');

    service.start();

    await eventually(() => calls == 1);
    // Let the retry bookkeeping land, and check nothing hammers the server.
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final entry = (await pending()).single;
    expect(entry.retryCount, 1);
    expect(entry.nextRetryAt, isNotNull);
    expect(calls, 1);
  });

  test(
    'flushes triggered by the queue itself never replay an entry twice',
    () async {
      await service.dispose();
      final calls = <int>[];
      service = makeService((entry) async {
        calls.add(entry.id);
        await Future<void>.delayed(const Duration(milliseconds: 40));
        return ReplaySyncResult.success;
      });
      await enqueue('/$resource');
      await enqueue('/$resource');
      await enqueue('/$resource');

      service.start();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await enqueue('/$resource'); // lands mid-flush

      await eventually(() => calls.length >= 4);
      await Future<void>.delayed(const Duration(milliseconds: 300));
      expect(calls.toSet().length, calls.length, reason: 'no duplicate replay');
      expect(calls.length, 4);
      expect(await pending(), isEmpty);
    },
  );

  test('clearAll (sign-out) drops the writes still waiting in the queue', () async {
    await enqueue('/$resource');
    await enqueue('/other_resource');

    await db.clearAll();

    expect(await pending(), isEmpty);
  });
}
''';

  /// `test/<…>/<feature>_offline_first_test.dart` — the offline-first
  /// repository's contract against a fake remote source: the list shows what
  /// the local database holds (rows pulled from the server **and** writes still
  /// in the Outbox), and writes are applied locally then queued on the
  /// feature's Outbox resource.
  ///
  /// [dataImport] / [domainImport]: package URIs of the feature's `data/` and
  /// `domain/` layer roots (they differ for split / layer-first / merged
  /// features). [apiSourceMethods] lists what the fake must implement — see
  /// [fakeApiMethods]. Only dio / supabase / firebase API sources are concrete
  /// classes a test can fake; a chopper one extends `ChopperService`, so it
  /// isn't shipped there.
  static String offlineFirstRepositoryTest({
    required String featureName,
    required String corePackage,
    required String localStoragePackage,
    required String dataImport,
    required String domainImport,
    required String httpClient,
    required List<FieldSpec> fields,
    String? apiPath,
    String? tableName,
    bool realtime = false,
  }) {
    final p = pascal(featureName);
    final id = idField(fields);
    final endpoint = outboxEndpointBase(
      httpClient: httpClient,
      featureName: featureName,
      apiPath: apiPath,
      tableName: tableName,
    );
    final entityArgs = fields
        .map((f) => f.isId ? '${f.dartName}: id' : '${f.dartName}: ${f.entityPlaceholder()}')
        .join(', ');
    return '''import 'dart:convert';

import 'package:$corePackage/core/network/network_info.dart';
import 'package:$localStoragePackage/$localStoragePackage.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import '$dataImport/models/${featureName}_model.dart';
import '$dataImport/repositories/${featureName}_repository_impl.dart';
import '$dataImport/sources/${featureName}_api_source.dart';
import '$dataImport/sources/${featureName}_local_source.dart';
import '$domainImport/entities/${featureName}_entity.dart';

class _FakeNetwork implements NetworkInfo {
  @override
  Future<bool> get isConnected async => true;

  @override
  Stream<bool> get onConnectivityChanged => const Stream.empty();
}

/// Stands in for the backend: whatever [remote] holds is what the server returns.
class _FakeApi implements ${p}ApiSource {
  List<${p}Model> remote = [];

  @override
  Future<List<${p}Model>> getAll() async => remote;
${fakeApiMethods(p, httpClient, realtime)}}

${p}Entity _entity(String id) => ${p}Entity($entityArgs);

void main() {
  late AppDatabase db;
  late _FakeApi api;
  late ${p}RepositoryImpl repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    api = _FakeApi();
    repo = ${p}RepositoryImpl(api, ${p}LocalSource(db), _FakeNetwork());
  });

  tearDown(() => db.close());

  test('watchAll keeps a write still in the Outbox after pulling the server '
      'rows while online', () async {
    await repo.create(_entity('mine'));

    await repo.getAll(); // the server knows nothing about it yet

    final shown = await repo.watchAll().first;
    expect(shown.map((e) => e.${id.dartName}), ['mine']);
  });

  test('rows pulled from the server show up in watchAll', () async {
    api.remote = [${p}Model.fromEntity(_entity('from-server'))];

    await repo.getAll();

    final shown = await repo.watchAll().first;
    expect(shown.map((e) => e.${id.dartName}), ['from-server']);
  });

  test('watchAll emits again when a write is made', () async {
    final emissions = <List<String>>[];
    final sub = repo.watchAll().listen(
      (list) => emissions.add([for (final e in list) e.${id.dartName}]),
    );
    addTearDown(sub.cancel);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    await repo.create(_entity('new'));
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(emissions.last, ['new']);
  });

  test('create queues a write on the $featureName endpoint carrying the JSON payload', () async {
    await repo.create(_entity('e1'));

    final entry = (await db.outboxDao.pendingOutbox()).single;
    expect(entry.operation, 'create');
    expect(entry.endpoint, '$endpoint');
    final payload = jsonDecode(entry.payload!) as Map<String, dynamic>;
    expect(payload['${id.jsonKey}'], 'e1');
  });

  test('delete removes the row locally and queues the write', () async {
    await repo.create(_entity('e1'));

    await repo.delete('e1');

    expect(await repo.watchAll().first, isEmpty);
    final operations = (await db.outboxDao.pendingOutbox()).map(
      (e) => e.operation,
    );
    expect(operations, ['create', 'delete']);
  });

  test('clearAll (sign-out) removes the local rows', () async {
    await repo.create(_entity('e1'));

    await db.clearAll();

    expect(await repo.watchAll().first, isEmpty);
  });
}
''';
  }

  /// The members a fake of the generated `<Feature>ApiSource` must implement
  /// besides `getAll()` — exactly the methods [DataTemplates.featureApiSource]
  /// emits for [httpClient]. Anything the repository doesn't exercise throws,
  /// so a test that wanders into it fails loudly instead of silently passing.
  static String fakeApiMethods(String p, String httpClient, bool realtime) {
    final upsert = httpClient == 'supabase'
        ? '''

  @override
  Future<${p}Model> upsert(${p}Model body) => throw UnimplementedError();'''
        : '';
    final watch = realtime
        ? '''

  @override
  Stream<List<${p}Model>> watchAll() => const Stream.empty();'''
        : '';
    return '''
  @override
  Future<${p}Model> getById(String id) => throw UnimplementedError();

  @override
  Future<${p}Model> add(${p}Model body) => throw UnimplementedError();$upsert

  @override
  Future<${p}Model> update(String id, ${p}Model body) =>
      throw UnimplementedError();

  @override
  Future<void> delete(String id) => throw UnimplementedError();$watch
''';
  }
}
