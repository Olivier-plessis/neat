import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:neat/core/contract/neat_contract.dart';
import 'package:neat/features/generation/domain/models/field_spec.dart';
import 'package:neat/features/generation/domain/services/feature_scaffolder.dart';
import 'package:neat/features/generation/domain/services/sync_parents.dart';
import 'package:neat/features/generation/domain/services/templates/agents_md_template.dart';
import 'package:neat/features/generation/domain/services/templates/core_templates.dart';
import 'package:neat/features/generation/domain/services/templates/dart/data_templates.dart';
import 'package:neat/features/generation/domain/services/templates/dart/offline_test_templates.dart';

/// ROADMAP §5aa — a child feature's sync waits for its parent's. Found in
/// archy: a task created offline reached Supabase before its worksite when the
/// network came back (both SyncServices flush at the same moment) and failed on
/// the foreign key (23503).
void main() {
  group('SyncService template', () {
    final code = CoreTemplates.syncService(
      packageName: 'core',
      localStoragePackage: 'demo_database',
    );

    test('takes the resources it depends on, none by default', () {
      expect(code, contains('this.dependsOn = const {},'));
      expect(code, contains('final Set<String> dependsOn;'));
    });

    test(
      'a write waits for the OLDER writes of those resources, in queue order',
      () {
        expect(
          code,
          contains(
            'bool _waitsForParent(OutboxEntry entry, List<OutboxEntry> pending)',
          ),
        );
        expect(code, contains('other.id < entry.id'));
        expect(
          code,
          contains('if (_waitsForParent(entry, pending)) continue;'),
        );
      },
    );

    test('waiting is neither an attempt nor a failure', () {
      // The skip sits before the replay: no retry bump, no log.
      expect(
        code.indexOf('if (_waitsForParent(entry, pending)) continue;'),
        lessThan(code.indexOf('await _replay(entry)')),
      );
    });

    test(
      'a parent is matched like an own resource (its path, or under it — not a prefix)',
      () {
        expect(
          code,
          contains('static bool _isUnder(String path, String resource)'),
        );
        expect(code, contains("path.startsWith('\$resource/')"));
        expect(
          code,
          contains(
            'dependsOn.any((parent) => _isUnder(_pathOf(other), parent))',
          ),
        );
      },
    );
  });

  group('sync provider', () {
    String providers({
      List<String> dependsOn = const [],
      String httpClient = 'supabase',
    }) => DataTemplates.featureRepositoryProviders(
      featureName: 'task',
      packageName: 'demo',
      httpClient: httpClient,
      offlineFirst: true,
      hasSync: true,
      localStoragePackage: 'demo_database',
      dependsOn: dependsOn,
    );

    test('a feature that points at no other one declares nothing', () {
      expect(providers(), isNot(contains('dependsOn')));
    });

    test('lists the parents\' resources', () {
      final code = providers(dependsOn: ['worksites']);
      expect(code, contains("dependsOn: const {'worksites'},"));
      expect(code, contains("resource: 'tasks',"));
    });

    test('several parents, REST paths included', () {
      expect(
        providers(httpClient: 'dio', dependsOn: ['api/v1/orders', 'customers']),
        contains("dependsOn: const {'api/v1/orders', 'customers'},"),
      );
    });

    test('is not emitted without sync (no Outbox, nothing to wait for)', () {
      final code = DataTemplates.featureRepositoryProviders(
        featureName: 'task',
        packageName: 'demo',
        httpClient: 'supabase',
        offlineFirst: true,
        localStoragePackage: 'demo_database',
        dependsOn: ['worksites'],
      );
      expect(code, isNot(contains('dependsOn')));
    });
  });

  group('shipped SyncService test', () {
    final code = OfflineTestTemplates.syncServiceTest(
      corePackage: 'core',
      localStoragePackage: 'demo_database',
      resource: 'worksites',
    );

    test(
      'covers the dependency: waits for older parent writes, ignores newer ones',
      () {
        expect(code, contains("group('a resource that depends on another'"));
        expect(code, contains("dependsOn: const {'worksites'},"));
        expect(code, contains("resource: 'worksites_child',"));
        expect(
          code,
          contains('waits for the older writes of its parent, without failing'),
        );
        expect(
          code,
          contains('is not held back by a parent write queued after its own'),
        );
      },
    );
  });

  group('docs of the generated project', () {
    NeatContract contract() => const NeatContract(
      projectName: 'archy',
      architecture: 'feature_first',
      stateManagement: 'riverpod',
      navigation: 'go_router_builder',
      httpClient: 'supabase',
      themeApproach: 'customM3',
      storageStrategy: 'offlineFirstSync',
    );

    test(
      'AGENTS.md tells a child feature to declare its parent, and parents to drop child writes',
      () {
        final md = AgentsMdTemplate.generate(contract());
        expect(md, contains("dependsOn: const {'worksites'}"));
        expect(md, contains('foreign key violation'));
        expect(md, contains('their writes still in the'));
      },
    );

    test('OFFLINE.md explains dependsOn', () {
      final doc = CoreTemplates.offlineDoc(
        packageName: 'demo',
        featureName: 'task',
        localStoragePackage: 'demo_database',
        hasSync: true,
      );
      expect(doc, contains("`dependsOn: const {'worksites'}`"));
    });
  });

  group('SyncParents', () {
    late Directory root;
    setUp(
      () => root = Directory.systemTemp.createTempSync('neat_sync_parents_'),
    );
    tearDown(() => root.deleteSync(recursive: true));

    void write(String rel, String content) {
      File('${root.path}/$rel')
        ..createSync(recursive: true)
        ..writeAsStringSync(content);
    }

    String syncProvider(String resource) =>
        """
SyncService worksiteSync(Ref ref) {
  final service = SyncService(
    ref.watch(appDatabaseProvider),
    ref.watch(networkInfoProvider),
    (entry) async => ReplaySyncResult.success,
    resource: '$resource',
  )..start();
  return service;
}
""";

    const worksiteId = FieldSpec(
      jsonKey: 'worksite_id',
      dartName: 'worksiteId',
    );
    const id = FieldSpec(jsonKey: 'id', dartName: 'id', isId: true);
    const title = FieldSpec(jsonKey: 'title', dartName: 'title');

    Future<List<String>> resources(
      List<FieldSpec> fields, {
      String feature = 'task',
    }) => SyncParents.resourcesFor(
      projectPath: root.path,
      featureName: feature,
      fields: fields,
    );

    test(
      'a <feature>_id field points at that synced feature (split package layout)',
      () async {
        write(
          'packages/worksite/lib/data/repositories/worksite_repository_providers.dart',
          syncProvider('worksites'),
        );
        expect(await resources([id, worksiteId, title]), ['worksites']);
      },
    );

    test(
      'whatever the layout: feature-first folder, or a child merged into another package',
      () async {
        write(
          'lib/features/worksite/data/repositories/worksite_repository_providers.dart',
          syncProvider('chantiers'),
        );
        expect(await resources([id, worksiteId]), ['chantiers']);

        write(
          'packages/house/lib/data/room/repositories/room_repository_providers.dart',
          syncProvider('rooms'),
        );
        const roomId = FieldSpec(jsonKey: 'room_id', dartName: 'roomId');
        expect(await resources([id, roomId], feature: 'item'), ['rooms']);
      },
    );

    test(
      'a parent that is not synced, or not generated, is not a dependency',
      () async {
        write(
          'packages/worksite/lib/data/repositories/worksite_repository_providers.dart',
          '// remote only: no SyncService here\nWorksiteApiSource worksiteApiSource(Ref ref) => throw 0;\n',
        );
        expect(await resources([id, worksiteId]), isEmpty);
        expect(
          await resources([
            id,
            const FieldSpec(jsonKey: 'ghost_id', dartName: 'ghostId'),
          ]),
          isEmpty,
        );
      },
    );

    test(
      'the feature\'s own id, a bare `_id`, and a self reference are ignored',
      () async {
        write(
          'packages/task/lib/data/repositories/task_repository_providers.dart',
          syncProvider('tasks'),
        );
        const parentTask = FieldSpec(jsonKey: 'task_id', dartName: 'taskId');
        const bare = FieldSpec(jsonKey: '_id', dartName: 'underscoreId');
        expect(await resources([id, parentTask, bare]), isEmpty);
      },
    );

    test('sorted, without duplicates, and build output is not read', () async {
      write(
        'packages/worksite/lib/data/repositories/worksite_repository_providers.dart',
        syncProvider('worksites'),
      );
      write(
        'packages/zone/lib/data/repositories/zone_repository_providers.dart',
        syncProvider('areas'),
      );
      // Stale copies in tooling folders must not count.
      write(
        'packages/worksite/.dart_tool/x/worksite_repository_providers.dart',
        syncProvider('stale'),
      );
      write(
        'packages/worksite/build/worksite_repository_providers.dart',
        syncProvider('stale'),
      );
      const zoneId = FieldSpec(jsonKey: 'zone_id', dartName: 'zoneId');
      expect(await resources([id, zoneId, worksiteId]), ['areas', 'worksites']);
    });
  });

  group('FeatureScaffolder', () {
    late Directory root;
    setUp(() => root = Directory.systemTemp.createTempSync('neat_sync_deps_'));
    tearDown(() => root.deleteSync(recursive: true));

    Future<String> providersOf({List<String> dependsOn = const []}) async {
      await const FeatureScaffolder().writeFeature(
        lib: '${root.path}/packages/task/lib',
        featureName: 'task',
        packageName: 'demo',
        isFeatureFirst: true,
        mirrorTestStructure: true,
        hasRiverpod: true,
        hasBloc: false,
        useCubit: false,
        useAnnotations: true,
        hasGoRouter: false,
        hasGoRouterBuilder: false,
        hasHttpClient: true,
        httpClient: 'supabase',
        hasFreezed: true,
        hasJsonSerializable: true,
        localStoragePackage: 'demo_database',
        hasSync: true,
        packageSplit: true,
        corePackageName: 'core',
        projectRoot: root.path,
        syncDependsOn: dependsOn,
      );
      return File(
        '${root.path}/packages/task/lib/data/repositories/task_repository_providers.dart',
      ).readAsStringSync();
    }

    test('writes the parent into the generated sync provider', () async {
      expect(
        await providersOf(dependsOn: ['worksites']),
        contains("dependsOn: const {'worksites'},"),
      );
    });

    test('and nothing when the feature has no parent', () async {
      expect(await providersOf(), isNot(contains('dependsOn')));
    });
  });
}
