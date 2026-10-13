import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:neat/core/contract/neat_contract.dart';
import 'package:neat/features/generation/domain/models/field_spec.dart';
import 'package:neat/features/generation/domain/services/feature_scaffolder.dart';
import 'package:neat/features/generation/domain/services/templates/agents_md_template.dart';
import 'package:neat/features/generation/domain/services/templates/core_templates.dart';
import 'package:neat/features/generation/domain/services/templates/dart/_template_utils.dart';
import 'package:neat/features/generation/domain/services/templates/dart/auth_templates.dart';
import 'package:neat/features/generation/domain/services/templates/dart/data_templates.dart';
import 'package:neat/features/generation/domain/services/templates/dart/domain_templates.dart';
import 'package:neat/features/generation/domain/services/templates/dart/offline_test_templates.dart';
import 'package:neat/features/generation/domain/services/templates/dart/presentation_templates.dart';
import 'package:neat/features/generation/domain/services/templates/local_storage_templates.dart';
import 'package:neat/features/generation/domain/usecases/writers/pubspec_writer.dart';

/// ROADMAP §5w — offline-first sync: writes made offline (or just queued) must
/// really reach the server, and the list must show them meanwhile. These pin
/// the generated output; the executable proof (a generated project's own
/// SyncService / repository tests, run by `flutter test`) lives in
/// `offline_sync_integration_test.dart`.
void main() {
  group('SyncService template', () {
    final code = CoreTemplates.syncService(
      packageName: 'core',
      localStoragePackage: 'demo_database',
    );

    test('takes a required `resource` and only handles its own entries', () {
      expect(code, contains('required this.resource,'));
      expect(code, contains('bool _owns(OutboxEntry entry)'));
      expect(code, contains('.where(_owns)'));
      expect(code, contains("path.startsWith('\$resource/')"));
    });

    test('flushes at start, on every queued write and when connectivity returns', () {
      expect(code, contains('_db.outboxDao.watchPendingOutbox().listen('));
      expect(code, contains('_network.onConnectivityChanged.listen('));
      expect(code, contains('unawaited(_requeueExhausted());'));
    });

    test('flushes are serialised (a call mid-flush goes round once more)', () {
      expect(code, contains('bool _flushing = false;'));
      expect(code, contains('bool _flushAgain = false;'));
      expect(code, contains('} while (_flushAgain);'));
    });

    test('a failed replay is logged, never swallowed', () {
      expect(code, contains("import 'package:core/core/utils/app_logger.dart';"));
      expect(code, contains('AppLogger.w('));
      expect(code, contains('catch (error, stackTrace)'));
      expect(code, isNot(contains('catch (_)')));
    });

    test('exhausted writes get a fresh start at start()', () {
      expect(code, contains('_db.outboxDao.resetRetries(entry.id)'));
    });
  });

  group('Outbox DAO / database', () {
    test('OutboxDao.resetRetries clears the counter and the backoff', () {
      final dao = LocalStorageTemplates.outboxDaoFile();
      expect(dao, contains('Future<void> resetRetries(int id)'));
      expect(dao, contains('retryCount: Value(0)'));
      expect(dao, contains('nextRetryAt: Value(null)'));
    });

    test('AppDatabase.clearAll wipes every table in one transaction', () {
      final db = LocalStorageTemplates.database(featureName: 'order', withOutbox: true);
      expect(db, contains('Future<void> clearAll() => transaction('));
      expect(db, contains('for (final table in allTables)'));
    });
  });

  group('Supabase API source', () {
    test('has an idempotent upsert next to insert; the table name is configurable', () {
      final code = DataTemplates.featureApiSource(
        featureName: 'worksite',
        httpClient: 'supabase',
        tableName: 'worksites_v2',
      );
      expect(code, contains("static const String _table = 'worksites_v2';"));
      expect(code, contains('Future<WorksiteModel> upsert(WorksiteModel body)'));
      expect(code, contains('.upsert(body.toJson())'));
      expect(code, contains('.insert(body.toJson())'), reason: 'add() stays an insert');
    });

    test('the table defaults to <feature>s; dio has no upsert', () {
      expect(
        DataTemplates.featureApiSource(featureName: 'order', httpClient: 'supabase'),
        contains("static const String _table = 'orders';"),
      );
      expect(
        DataTemplates.featureApiSource(featureName: 'order', httpClient: 'dio'),
        isNot(contains('upsert')),
      );
    });
  });

  group('offline-first + sync repository', () {
    String impl({String httpClient = 'supabase', bool localWatch = true, bool realtime = false, String? apiPath, String? tableName}) =>
        DataTemplates.featureRepositoryImpl(
          featureName: 'worksite',
          packageName: 'demo',
          hasHttpClient: true,
          httpClient: httpClient,
          offlineFirst: true,
          hasSync: true,
          localWatch: localWatch,
          realtime: realtime,
          apiPath: apiPath,
          tableName: tableName,
        );

    test('watchAll() is the LOCAL stream — the list can never hide an Outbox write', () {
      final code = impl();
      expect(code, contains('Stream<List<WorksiteEntity>> watchAll() => _local.watchAll().map('));
      expect(code, isNot(contains('_remote.watchAll()')));
    });

    test('realtime does not generate a second, remote watchAll() beside the local one', () {
      // The scaffolder passes realtime=false when localWatch is on; even if a
      // caller passes both, the local meaning wins (one name, one behaviour).
      final code = impl(realtime: true);
      expect(code, isNot(contains('_remote.watchAll()')));
      expect('Stream<List<WorksiteEntity>> watchAll()'.allMatches(code).length, 1);
    });

    test('without sync nothing changes: no local watchAll, remote realtime kept', () {
      final read = DataTemplates.featureRepositoryImpl(
        featureName: 'worksite',
        packageName: 'demo',
        hasHttpClient: true,
        httpClient: 'supabase',
        offlineFirst: true,
        realtime: true,
      );
      expect(read, contains('_remote.watchAll()'));
      expect(read, isNot(contains('_local.watchAll()')));
    });

    test('Supabase queues writes under the TABLE name, ignoring a REST apiPath', () {
      final code = impl(apiPath: '/api/v1/ignored', tableName: 'worksites_v2');
      expect(code, contains("endpoint: '/worksites_v2'"));
      expect(code, contains(r"endpoint: '/worksites_v2/${entity.id}'"));
      expect(code, isNot(contains('ignored')));
    });

    test('REST keeps the apiPath override', () {
      final code = impl(httpClient: 'dio', apiPath: '/api/v1/jobs');
      expect(code, contains("endpoint: '/api/v1/jobs'"));
    });

    test('local source exposes watchAll() only with sync', () {
      final sync = DataTemplates.featureLocalSource(
        featureName: 'worksite',
        offlineFirst: true,
        hasSync: true,
        localStoragePackage: 'demo_database',
      );
      expect(sync, contains('Stream<List<WorksiteModel>> watchAll()'));
      expect(sync, contains('_db.worksiteDao.watchWorksites()'));
      final read = DataTemplates.featureLocalSource(
        featureName: 'worksite',
        offlineFirst: true,
        localStoragePackage: 'demo_database',
      );
      expect(read, isNot(contains('watchAll')));
    });

    test('the repository interface documents watchAll() as the local list', () {
      final code = DomainTemplates.featureIRepository(
        featureName: 'worksite',
        packageName: 'demo',
        hasHttpClient: true,
        offlineFirst: true,
        localWatch: true,
      );
      expect(code, contains('Stream<List<WorksiteEntity>> watchAll();'));
      expect(code, contains('local database'));
    });
  });

  group('sync provider (repository-level DI)', () {
    String providers({
      String httpClient = 'supabase',
      bool offlineFirst = true,
      bool hasSync = true,
      bool realtime = false,
      String? corePackageName,
      String? apiPath,
      String? tableName,
    }) => DataTemplates.featureRepositoryProviders(
      featureName: 'worksite',
      packageName: 'demo',
      httpClient: httpClient,
      offlineFirst: offlineFirst,
      hasSync: hasSync,
      localStoragePackage: 'demo_database',
      corePackageName: corePackageName,
      realtime: realtime,
      apiPath: apiPath,
      tableName: tableName,
    );

    test('scopes the SyncService to the feature\'s resource', () {
      expect(providers(), contains("resource: 'worksites'"));
      expect(providers(tableName: 'chantiers'), contains("resource: 'chantiers'"));
      expect(providers(httpClient: 'dio', apiPath: '/api/v1/jobs'), contains("resource: 'api/v1/jobs'"));
      expect(
        providers(httpClient: 'dio', apiPath: 'https://fakestoreapi.com/products'),
        contains("resource: 'products'"),
        reason: 'an absolute URL counts by its path, not its host',
      );
    });

    test('replays creates as upserts on Supabase, as add() elsewhere', () {
      expect(providers(), contains('await api.upsert(WorksiteModel.fromJson(data));'));
      expect(providers(httpClient: 'dio'), contains('await api.add(WorksiteModel.fromJson(data));'));
    });

    test('chopper replays unwrap the response: a non-2xx must retry, not count as sent', () {
      final code = providers(httpClient: 'chopper');
      expect(code, contains('unwrapChopperResponse(await api.add(WorksiteModel.fromJson(data)))'));
      expect(code, contains('unwrapChopperResponse(await api.update(model.id, model))'));
      expect(code, contains("unwrapChopperResponse(await api.delete(data['id'] as String))"));
      expect(code, contains("import 'package:demo/core/network/chopper_model_converter.dart';"));
    });

    test('is documented as started by the list notifier', () {
      expect(providers(), contains('the list notifier watches it'));
    });

    test('realtime + sync pipes the remote stream INTO Drift (never shown directly)', () {
      final code = providers(realtime: true);
      expect(code, contains('api.watchAll().listen('));
      expect(code, contains('local.cacheAll,'));
      expect(code, contains('AppLogger.w('));
      expect(code, contains("import 'package:demo/core/utils/app_logger.dart';"));
      expect(providers(), isNot(contains('api.watchAll()')));
    });

    test('no sync engine when the local layer is off (it needs the Drift providers)', () {
      final code = providers(offlineFirst: false);
      expect(code, isNot(contains('SyncService')));
      expect(code, isNot(contains('appDatabaseProvider')));
    });

    test('packageSplit: core imports', () {
      final code = providers(corePackageName: 'core');
      expect(code, contains("import 'package:core/core/sync/sync_service.dart';"));
    });
  });

  group('list notifier + page', () {
    test('local-first notifier watches the sync provider and streams the local list', () {
      final code = PresentationTemplates.featureProvider(
        featureName: 'worksite',
        useAnnotations: true,
        dataList: true,
        localFirst: true,
      );
      expect(code, contains('Stream<List<WorksiteEntity>> build()'));
      expect(code, contains('ref.watch(worksiteSyncProvider);'));
      expect(code, contains('unawaited(refresh());'));
      expect(code, contains('ref.watch(worksiteRepositoryProvider).watchAll()'));
      expect(code, contains('Future<void> refresh() async'));
      expect(code, contains('await ref.read(getWorksiteUsecaseProvider)();'));
    });

    test('local-first wins over the remote realtime stream notifier', () {
      final code = PresentationTemplates.featureProvider(
        featureName: 'worksite',
        useAnnotations: true,
        dataList: true,
        realtime: true,
        localFirst: true,
      );
      expect(code, contains('ref.watch(worksiteSyncProvider);'));
    });

    test('the plain future notifier is untouched without sync', () {
      final code = PresentationTemplates.featureProvider(
        featureName: 'worksite',
        useAnnotations: true,
        dataList: true,
      );
      expect(code, contains('Future<List<WorksiteEntity>> build() async'));
      expect(code, isNot(contains('SyncProvider')));
    });

    String page({bool localFirst = false, bool crud = false}) => PresentationTemplates.featurePage(
      featureName: 'worksite',
      packageName: 'demo',
      hasRiverpod: true,
      useAnnotations: true,
      hasBloc: false,
      useCubit: false,
      dataList: true,
      includeCrudUi: crud,
      localFirst: localFirst,
    );

    test('pull-to-refresh pulls into Drift instead of invalidating the stream', () {
      expect(page(localFirst: true), contains('ref.read(worksiteProvider.notifier).refresh()'));
      expect(page(localFirst: true), isNot(contains('ref.invalidate(worksiteProvider)')));
      expect(page(), contains('ref.invalidate(worksiteProvider)'));
    });

    test('the create/delete sheets do not add the item a second time to a local-first list', () {
      final local = page(localFirst: true, crud: true);
      expect(local, isNot(contains('.addItem(')));
      expect(local, isNot(contains('.removeItem(')));
      final plain = page(crud: true);
      expect(plain, contains('.addItem(created)'));
      expect(plain, contains('.removeItem('));
    });
  });

  group('sign-out wipes the device (verified hypothesis: it used to keep everything)', () {
    test('supabase sign-out clears the local data after the SDK sign-out succeeded', () {
      final code = AuthTemplates.authRepositoryImpl(packageName: 'demo', hasLocalData: true);
      expect(code, contains('await _client.auth.signOut();'));
      expect(code, contains('await _clearLocalData();'));
      expect(code, contains('final Future<void> Function() _clearLocalData;'));
      expect(
        code.indexOf('auth.signOut()'),
        lessThan(code.indexOf('_clearLocalData();')),
        reason: 'a failed sign-out must wipe nothing',
      );
    });

    test('firebase sign-out too', () {
      final code = AuthTemplates.authRepositoryImpl(
        packageName: 'demo',
        backend: 'firebase',
        hasLocalData: true,
      );
      expect(code, contains('await _clearLocalData();'));
    });

    test('a remote-only project signs out exactly as before', () {
      final code = AuthTemplates.authRepositoryImpl(packageName: 'demo');
      expect(code, isNot(contains('_clearLocalData')));
    });

    test('the provider hands the cleanup in from core (no auth → database dependency)', () {
      final code = AuthTemplates.authRepositoryProviders(
        packageName: 'demo',
        corePackageName: 'core',
        authPackageName: 'auth',
        hasLocalData: true,
      );
      expect(code, contains("import 'package:core/core/providers/infrastructure_providers.dart';"));
      expect(code, contains('ref.watch(clearLocalDataProvider)'));
    });

    test('core exposes clearLocalData over AppDatabase.clearAll', () {
      final code = CoreTemplates.infrastructureProviders(packageName: 'demo', localStoragePackage: 'demo_database');
      expect(code, contains('Future<void> Function() clearLocalData(Ref ref)'));
      expect(code, contains('ref.watch(appDatabaseProvider).clearAll'));
    });
  });

  group('outbox resource helpers', () {
    test('the REST base and the resource agree (the SyncService matches on it)', () {
      String res(String client, {String? apiPath, String? table}) => outboxResourceFor(
        httpClient: client,
        featureName: 'order',
        apiPath: apiPath,
        tableName: table,
      );
      expect(res('dio'), 'orders');
      expect(res('chopper', apiPath: '/v2/orders/'), 'v2/orders');
      expect(res('dio', apiPath: 'https://host.test/api/orders'), 'api/orders');
      expect(res('supabase', apiPath: '/ignored'), 'orders');
      expect(res('supabase', table: 'purchases'), 'purchases');
      expect(res('firebase', table: 'purchases'), 'purchases');
    });
  });

  group('shipped tests', () {
    test('SyncService test uses the feature resource and covers the contract', () {
      final code = OfflineTestTemplates.syncServiceTest(
        corePackage: 'core',
        localStoragePackage: 'demo_database',
        resource: 'worksites',
      );
      expect(code, contains("resource: 'worksites'"));
      expect(code, contains("import 'package:core/core/sync/sync_service.dart';"));
      expect(code, contains("import 'package:demo_database/demo_database.dart' hide isNotNull;"));
      for (final name in const [
        'start() sends what a previous session left in the queue',
        'a write queued while running goes out without a connectivity event',
        'start() gives a write that exhausted its retries another chance',
        'only handles its own resource and leaves the others queued',
        'never replay an entry twice',
        'clearAll (sign-out)',
      ]) {
        expect(code, contains(name));
      }
    });

    test('repository test fakes exactly the API source the backend generates', () {
      String test(String client, {bool realtime = false}) => OfflineTestTemplates.offlineFirstRepositoryTest(
        featureName: 'worksite',
        corePackage: 'core',
        localStoragePackage: 'demo_database',
        dataImport: 'package:worksite/data',
        domainImport: 'package:worksite/domain',
        httpClient: client,
        fields: FieldSpec.idName,
        realtime: realtime,
      );
      expect(test('supabase'), contains('Future<WorksiteModel> upsert(WorksiteModel body)'));
      expect(test('dio'), isNot(contains('upsert')));
      expect(test('supabase', realtime: true), contains('Stream<List<WorksiteModel>> watchAll()'));
      expect(test('supabase'), isNot(contains('Stream<List<WorksiteModel>> watchAll()')));
      expect(test('supabase'), contains("expect(entry.endpoint, '/worksites');"));
      expect(test('supabase'), contains("import 'package:worksite/data/repositories/worksite_repository_impl.dart';"));
    });
  });

  group('FeatureScaffolder ships the repository test where the CI runs it', () {
    late Directory root;
    setUp(() => root = Directory.systemTemp.createTempSync('neat_ship_test_'));
    tearDown(() => root.deleteSync(recursive: true));

    Future<void> scaffold({
      required String httpClient,
      bool packageSplit = false,
      bool mirror = true,
      bool sync = true,
      bool featureFirst = true,
    }) => const FeatureScaffolder().writeFeature(
      lib: packageSplit ? '${root.path}/packages/order/lib' : '${root.path}/lib',
      featureName: 'order',
      packageName: 'demo',
      isFeatureFirst: featureFirst,
      mirrorTestStructure: mirror,
      hasRiverpod: true,
      hasBloc: false,
      useCubit: false,
      useAnnotations: true,
      hasGoRouter: false,
      hasGoRouterBuilder: false,
      hasHttpClient: true,
      httpClient: httpClient,
      hasFreezed: true,
      hasJsonSerializable: true,
      localStoragePackage: 'demo_database',
      hasSync: sync,
      packageSplit: packageSplit,
      corePackageName: packageSplit ? 'core' : null,
      projectRoot: root.path,
    );

    bool exists(String rel) => File('${root.path}/$rel').existsSync();

    test('split + mirror: test/<pkg>/data/repositories/…', () async {
      await scaffold(httpClient: 'supabase', packageSplit: true);
      final path = 'test/order/data/repositories/order_repository_impl_test.dart';
      expect(exists(path), isTrue);
      final code = File('${root.path}/$path').readAsStringSync();
      expect(code, contains("import 'package:order/data/repositories/order_repository_impl.dart';"));
      expect(code, contains("import 'package:core/core/network/network_info.dart';"));
    });

    test('non-split + mirror: test/features/<f>/data/repositories/…', () async {
      await scaffold(httpClient: 'dio');
      final path = 'test/features/order/data/repositories/order_repository_impl_test.dart';
      expect(exists(path), isTrue);
      expect(
        File('${root.path}/$path').readAsStringSync(),
        contains("import 'package:demo/features/order/data/models/order_model.dart';"),
      );
    });

    test('flat when mirrorTestStructure is off', () async {
      await scaffold(httpClient: 'dio', mirror: false);
      expect(exists('test/order/order_offline_first_test.dart'), isTrue);
    });

    test('layer-first imports follow the layer layout', () async {
      await scaffold(httpClient: 'dio', featureFirst: false);
      final code = File(
        '${root.path}/test/data/order/repositories/order_repository_impl_test.dart',
      ).readAsStringSync();
      expect(code, contains("import 'package:demo/data/order/sources/order_api_source.dart';"));
    });

    test('not shipped for chopper (its API source is a ChopperService) or without sync', () async {
      await scaffold(httpClient: 'chopper');
      expect(exists('test/features/order/data/repositories/order_repository_impl_test.dart'), isFalse);
      expect(exists('test/order/order_offline_first_test.dart'), isFalse);
    });

    test('not shipped without sync', () async {
      await scaffold(httpClient: 'dio', sync: false);
      expect(exists('test/features/order/data/repositories/order_repository_impl_test.dart'), isFalse);
    });

    test('the written feature wires the whole local-first path', () async {
      await scaffold(httpClient: 'supabase');
      String read(String rel) => File('${root.path}/lib/features/order/$rel').readAsStringSync();
      expect(read('presentation/providers/order_provider.dart'), contains('ref.watch(orderSyncProvider);'));
      expect(read('data/repositories/order_repository_impl.dart'), contains('_local.watchAll()'));
      expect(read('data/sources/order_local_source.dart'), contains('watchAll()'));
      expect(read('domain/repositories/i_order_repository.dart'), contains('Stream<List<OrderEntity>> watchAll();'));
      expect(read('data/repositories/order_repository_providers.dart'), contains("resource: 'orders'"));
      expect(read('presentation/pages/order_page.dart'), contains('.refresh()'));
    });
  });

  group('root pubspec', () {
    test('declares drift for the shipped tests only when sync ships them', () {
      const original = 'dependencies:\n  flutter:\n    sdk: flutter\n\n'
          'dev_dependencies:\n  flutter_test:\n    sdk: flutter\n';
      expect(
        PubspecWriter.buildPubspecContent(original, const [], addDriftForTests: true),
        contains('  drift: ^2.35.2'),
      );
      expect(
        PubspecWriter.buildPubspecContent(original, const []),
        isNot(contains('drift:')),
      );
    });
  });

  group('AGENTS.md', () {
    NeatContract contract({bool split = false, String client = 'supabase', bool auth = false, bool realtime = false, String storage = 'offlineFirstSync'}) =>
        NeatContract(
          projectName: 'archy',
          architecture: 'feature_first',
          stateManagement: 'riverpod',
          navigation: 'go_router_builder',
          httpClient: client,
          themeApproach: 'customM3',
          storageStrategy: storage,
          packageSplit: split,
          generateAuth: auth,
          generateRealtime: realtime,
        );

    test('the SyncService path is right under packageSplit (it moved into core)', () {
      expect(AgentsMdTemplate.generate(contract(split: true)), contains('`packages/core/lib/core/sync/sync_service.dart`'));
      expect(AgentsMdTemplate.generate(contract()), contains('`lib/core/sync/sync_service.dart`'));
    });

    test('documents the Drift-is-the-truth / resource / start / upsert contract', () {
      final md = AgentsMdTemplate.generate(contract());
      expect(md, contains('**Drift as the source of truth**'));
      expect(md, contains('`repository.watchAll()`'));
      expect(md, contains('Never show a remote result directly'));
      expect(md, contains('shared by every feature'));
      expect(md, contains('`resource`'));
      expect(md, contains('watching `<feature>SyncProvider`'));
      expect(md, contains('Creates are replayed with `upsert`'));
    });

    test('upsert is a Supabase fact — not claimed for dio', () {
      expect(AgentsMdTemplate.generate(contract(client: 'dio')), isNot(contains('`upsert`')));
    });

    test('sign-out wipe is documented only with auth', () {
      expect(AgentsMdTemplate.generate(contract(auth: true)), contains('Signing out wipes the local database'));
      expect(AgentsMdTemplate.generate(contract()), isNot(contains('Signing out wipes')));
    });

    test('realtime + sync explains the reconciliation instead of promising a live StreamNotifier', () {
      final md = AgentsMdTemplate.generate(contract(realtime: true));
      expect(md, contains('written through into it by `<feature>SyncProvider`'));
      expect(md, isNot(contains('is a `StreamNotifier` over')));
    });

    test('offline read mode keeps the old, Outbox-free wording', () {
      final md = AgentsMdTemplate.generate(contract(storage: 'offlineFirstRead', auth: true));
      expect(md, isNot(contains('Outbox')));
      expect(md, contains('fall back to the Drift cache'));
    });
  });
}
