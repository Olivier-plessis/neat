@Tags(['integration'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:neat/features/architecture/domain/models/architecture_state.dart';
import 'package:neat/features/cicd/domain/models/cicd_state.dart';
import 'package:neat/features/dependencies/domain/models/pub_package.dart';
import 'package:neat/features/feature_gen/domain/models/feature_gen_options.dart';
import 'package:neat/features/feature_gen/domain/services/project_loader.dart';
import 'package:neat/features/feature_gen/domain/usecases/generate_feature_usecase.dart';
import 'package:neat/features/generation/domain/models/field_spec.dart';
import 'package:neat/features/generation/domain/usecases/launch_generation_usecase.dart';
import 'package:neat/features/identity/domain/models/identity_state.dart';
import 'package:neat/features/theme_engine/domain/models/theme_engine_state.dart';

/// ROADMAP §5w — the offline-first sync contract, proven on real generated
/// projects: `flutter analyze` must pass as the generated CI runs it (fatal on
/// infos too), and `flutter test` must run — and pass — the SyncService and
/// offline-first repository tests the project ships (in-memory Drift, no
/// device, no backend).
void main() {
  late Directory tempRoot;

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('neat_sync_');
  });

  tearDown(() async {
    if (tempRoot.existsSync()) await tempRoot.delete(recursive: true);
  });

  final supabasePackages = <PubPackage>[
    _dep('hooks_riverpod', '3.4.3'),
    _dep('flutter_hooks', '0.21.3+1'),
    _dep('riverpod_annotation', '4.0.7'),
    _dep('json_annotation', '4.11.0'),
    _dep('freezed_annotation', '3.1.0'),
    _dep('supabase_flutter', '2.14.1'),
    _dep('go_router', '17.5.0'),
    _dev('riverpod_generator', '4.0.9'),
    _dev('riverpod_lint', '3.1.9'),
    _dev('json_serializable', '6.14.1'),
    _dev('build_runner', '2.16.2'),
    _dev('freezed', '4.0.2'),
    _dev('go_router_builder', '4.5.0'), // required by generateAuth
  ];

  final dioPackages = <PubPackage>[
    _dep('hooks_riverpod', '3.4.3'),
    _dep('flutter_hooks', '0.21.3+1'),
    _dep('riverpod_annotation', '4.0.7'),
    _dep('json_annotation', '4.11.0'),
    _dep('freezed_annotation', '3.1.0'),
    _dep('dio', '5.9.2'),
    _dep('go_router', '17.5.0'),
    _dev('riverpod_generator', '4.0.9'),
    _dev('riverpod_lint', '3.1.9'),
    _dev('json_serializable', '6.14.1'),
    _dev('build_runner', '2.16.2'),
    _dev('freezed', '4.0.2'),
    _dev('go_router_builder', '4.5.0'),
  ];

  Future<Directory> generate({
    required String projectName,
    required List<PubPackage> packages,
    required ArchitectureState architecture,
  }) async {
    final logs = <String>[];
    try {
      await const LaunchGenerationUsecase().execute(
        identity: IdentityState(
          name: projectName,
          organization: 'com.neat.test',
          projectPath: tempRoot.path,
          description: 'NEAT offline-first sync integration test',
          targetPlatforms: const ['macos'],
        ),
        packages: packages,
        architecture: architecture,
        cicd: const CicdState(),
        theme: const ThemeEngineState(approach: ThemeApproach.customM3),
        onLog: logs.add,
      );
    } catch (e) {
      fail('Generation threw:\n$e\n\n--- logs ---\n${logs.join('\n')}');
    }
    return Directory('${tempRoot.path}/$projectName');
  }

  /// CI-faithful gate: `flutter analyze` exits 0 (infos are fatal), then
  /// `flutter test` passes — which runs the tests the project ships.
  Future<void> expectCiGreen(Directory projectDir) async {
    final analyze = await Process.run('flutter', [
      'analyze',
      '--no-pub',
    ], workingDirectory: projectDir.path);
    final out = '${analyze.stdout}\n${analyze.stderr}';
    final problems = const LineSplitter()
        .convert(out)
        .where(
          (l) =>
              (l.contains(' error •') ||
                  l.contains(' warning •') ||
                  l.contains(' info •')) &&
              !l.contains('• build/'),
        )
        .toList();
    expect(
      problems,
      isEmpty,
      reason: 'flutter analyze reported:\n${problems.join('\n')}\n\n$out',
    );
    expect(analyze.exitCode, 0, reason: out);

    final test = await Process.run('flutter', [
      'test',
      '--no-pub',
    ], workingDirectory: projectDir.path);
    expect(
      test.exitCode,
      0,
      reason: 'flutter test failed:\n${test.stdout}\n${test.stderr}',
    );
  }

  test(
    'packageSplit + Supabase + offline-first sync + realtime + auth: the list '
    'watches Drift and the sync engine, creates are upserts, sign-out wipes '
    'the device, and the shipped tests pass',
    () async {
      final projectDir = await generate(
        projectName: 'neat_sync_supabase_test',
        packages: supabasePackages,
        architecture: const ArchitectureState(
          firstFeatureName: 'worksite',
          packageSplit: true,
          generateAuth: true,
          generateRealtime: true,
          storageStrategy: StorageStrategy.offlineFirstSync,
        ),
      );
      String read(String rel) => File('${projectDir.path}/$rel').readAsStringSync();

      // The list notifier watches the sync provider and the local stream.
      final notifier = read(
        'packages/worksite/lib/presentation/providers/worksite_provider.dart',
      );
      expect(notifier, contains('ref.watch(worksiteSyncProvider);'));
      expect(notifier, contains('.watchAll()'));
      expect(notifier, contains('Future<void> refresh()'));

      // Provider: resource filter, upsert for creates, realtime → Drift.
      final di = read(
        'packages/worksite/lib/data/repositories/worksite_repository_providers.dart',
      );
      expect(di, contains("resource: 'worksites'"));
      expect(di, contains('api.upsert('));
      expect(di, contains('api.watchAll().listen('));

      // Shipped tests exist where the CI runs them.
      expect(
        File('${projectDir.path}/test/core/sync/sync_service_test.dart')
            .existsSync(),
        isTrue,
      );
      expect(
        File(
          '${projectDir.path}/test/worksite/data/repositories/'
          'worksite_repository_impl_test.dart',
        ).existsSync(),
        isTrue,
      );
      expect(read('pubspec.yaml'), contains('drift:'));

      // Sign-out wipes the device (rows + Outbox).
      expect(
        read('packages/auth/lib/data/repositories/auth_repository_impl.dart'),
        contains('await _clearLocalData();'),
      );

      await expectCiGreen(projectDir);
    },
    timeout: const Timeout(Duration(minutes: 14)),
  );

  test(
    'non-split dio + offline-first sync, flat tests: same contract, no '
    'packages, repository test not mirrored',
    () async {
      final projectDir = await generate(
        projectName: 'neat_sync_dio_test',
        packages: dioPackages,
        architecture: const ArchitectureState(
          firstFeatureName: 'order',
          mirrorTestStructure: false,
          storageStrategy: StorageStrategy.offlineFirstSync,
        ),
      );
      String read(String rel) => File('${projectDir.path}/$rel').readAsStringSync();

      expect(
        read('lib/features/order/presentation/providers/order_provider.dart'),
        contains('ref.watch(orderSyncProvider);'),
      );
      expect(
        read('lib/features/order/data/repositories/order_repository_providers.dart'),
        contains("resource: 'orders'"),
      );
      expect(
        File(
          '${projectDir.path}/test/order/order_offline_first_test.dart',
        ).existsSync(),
        isTrue,
        reason: 'mirrorTestStructure is off → flat test/<feature>/',
      );

      await expectCiGreen(projectDir);
    },
    timeout: const Timeout(Duration(minutes: 14)),
  );

  test(
    'packageSplit + Supabase + sync + enum fields: the enum, the client-id '
    'factory and the SQL migration are generated, analyze clean, and pass',
    () async {
      final projectDir = await generate(
        projectName: 'neat_enum_supabase_test',
        packages: supabasePackages,
        architecture: const ArchitectureState(
          firstFeatureName: 'worksite',
          packageSplit: true,
          generateAuth: true,
          storageStrategy: StorageStrategy.offlineFirstSync,
          firstFeatureFields: [
            FieldSpec(jsonKey: 'id', dartName: 'id', isId: true),
            FieldSpec(jsonKey: 'title', dartName: 'title'),
            FieldSpec(
              jsonKey: 'status',
              dartName: 'status',
              kind: FieldKind.enumeration,
              enumValues: ['planned', 'in_progress', 'done'],
            ),
            FieldSpec(
              jsonKey: 'category',
              dartName: 'category',
              kind: FieldKind.enumeration,
              nullable: true,
              enumValues: ['other', 'kitchen', 'living_room'],
            ),
            FieldSpec(
              jsonKey: 'start_date',
              dartName: 'startDate',
              dartType: 'DateTime',
              nullable: true,
            ),
            FieldSpec(jsonKey: 'budget_cents', dartName: 'budgetCents', dartType: 'int'),
          ],
        ),
      );
      String read(String rel) => File('${projectDir.path}/$rel').readAsStringSync();

      // The domain enums + the client-id factory.
      expect(
        read('packages/worksite/lib/domain/entities/worksite_status.dart'),
        contains("inProgress('in_progress')"),
      );
      final entity = read('packages/worksite/lib/domain/entities/worksite_entity.dart');
      expect(entity, contains('factory WorksiteEntity.create('));
      expect(entity, contains('const Uuid().v4()'));
      expect(read('packages/worksite/pubspec.yaml'), contains('uuid:'));

      // DTO + Drift row stay String; the mapper converts.
      final model = read('packages/worksite/lib/data/models/worksite_model.dart');
      expect(model, contains('required String status,'));
      expect(model, contains('WorksiteStatus.fromValue(status)'));
      expect(
        read('packages/neat_enum_supabase_test_database/lib/src/table/worksite_table.dart'),
        contains('TextColumn get status => text()();'),
      );

      // The SQL migration, with the CHECKs.
      final migrations = Directory('${projectDir.path}/supabase/migrations').listSync();
      expect(migrations, hasLength(1));
      final sql = File(migrations.single.path).readAsStringSync();
      expect(sql, contains('create table public.worksites ('));
      expect(sql, contains("check (status in ('planned', 'in_progress', 'done'))"));
      expect(sql, contains("check (category in ('other', 'kitchen', 'living_room'))"));

      await expectCiGreen(projectDir);
    },
    timeout: const Timeout(Duration(minutes: 14)),
  );

  test(
    'Workshop on a packageSplit Supabase project with sync + i18n + UI package: '
    'a feature with an enum and a custom table name gets its migration, i18n '
    'keys, project-SDK pubspec, uuid, and the whole workspace stays CI-green',
    () async {
      final projectDir = await generate(
        projectName: 'neat_workshop_sync_test',
        packages: supabasePackages,
        architecture: const ArchitectureState(
          packageSplit: true,
          generateAuth: true,
          generateFirstFeature: false,
          generateI18n: true,
          storageStrategy: StorageStrategy.offlineFirstSync,
        ),
      );
      String read(String rel) => File('${projectDir.path}/$rel').readAsStringSync();

      final loaded = await const ProjectLoader().load(projectDir.path);
      expect(loaded, isNotNull);
      final logs = <String>[];
      await const GenerateFeatureUsecase().execute(
        project: loaded!,
        options: const FeatureGenOptions(
          name: 'person',
          tableName: 'people',
          fields: [
            FieldSpec(jsonKey: 'id', dartName: 'id', isId: true),
            FieldSpec(jsonKey: 'full_name', dartName: 'fullName'),
            FieldSpec(
              jsonKey: 'role',
              dartName: 'role',
              kind: FieldKind.enumeration,
              enumValues: ['member', 'admin'],
            ),
          ],
        ),
        onLog: logs.add,
      );

      // §5x: the irregular plural is the table, in the SQL, the API source and the Outbox.
      final migration = Directory('${projectDir.path}/supabase/migrations')
          .listSync()
          .single
          .uri
          .pathSegments
          .last;
      expect(migration, endsWith('_create_people.sql'));
      expect(read('supabase/migrations/$migration'), contains('create table public.people ('));
      expect(read('packages/person/lib/data/sources/person_api_source.dart'), contains("_table = 'people'"));
      expect(
        read('packages/person/lib/data/repositories/person_repository_providers.dart'),
        contains("resource: 'people'"),
      );

      // §5y: client id, enum.
      expect(read('packages/person/pubspec.yaml'), contains('uuid:'));
      expect(read('packages/person/lib/domain/entities/person_entity.dart'), contains('factory PersonEntity.create('));
      expect(read('packages/person/lib/domain/entities/person_role.dart'), contains("admin('admin')"));

      // §5z: the project's SDK (not ^3.7.0), the UI package, the i18n keys + page.
      final rootSdk = RegExp(r'sdk: (\^[\d.]+)').firstMatch(read('pubspec.yaml'))!.group(1)!;
      final pubspec = read('packages/person/pubspec.yaml');
      expect(pubspec, contains('sdk: $rootSdk'));
      expect(pubspec, isNot(contains('^3.7.0')));
      expect(pubspec, contains('neat_workshop_sync_test_ui:'));
      expect(
        (jsonDecode(read('packages/core/lib/i18n/en.i18n.json')) as Map<String, dynamic>)['person'],
        {'title': 'Person', 'empty': 'No items yet.'},
      );
      final page = read('packages/person/lib/presentation/pages/person_page.dart');
      expect(page, contains('context.t.person.title'));
      expect(page, contains('context.t.person.empty'));

      // §5w: the shipped repository test.
      expect(
        File(
          '${projectDir.path}/test/person/data/repositories/person_repository_impl_test.dart',
        ).existsSync(),
        isTrue,
      );

      // §5aa + §5ab: a child feature (its rows point at `person` through
      // `person_id`) waits for the parent's writes — its sync names the
      // parent's resource, the parent's own names nothing — and its migration
      // makes the column a real foreign key.
      final reloaded = await const ProjectLoader().load(projectDir.path);
      expect(reloaded, isNotNull);
      await const GenerateFeatureUsecase().execute(
        project: reloaded!,
        options: const FeatureGenOptions(
          name: 'note',
          fields: [
            FieldSpec(jsonKey: 'id', dartName: 'id', isId: true),
            FieldSpec(jsonKey: 'person_id', dartName: 'personId'),
            FieldSpec(jsonKey: 'body', dartName: 'body'),
          ],
        ),
        onLog: logs.add,
      );
      final noteSync = read('packages/note/lib/data/repositories/note_repository_providers.dart');
      expect(noteSync, contains("resource: 'notes',"));
      expect(noteSync, contains("dependsOn: const {'people'},"));
      expect(
        read('packages/person/lib/data/repositories/person_repository_providers.dart'),
        isNot(contains('dependsOn')),
      );
      // The shipped SyncService test (run below) covers the waiting itself.
      expect(read('test/core/sync/sync_service_test.dart'), contains('a resource that depends on another'));
      final noteMigration = Directory('${projectDir.path}/supabase/migrations')
          .listSync()
          .whereType<File>()
          .singleWhere((f) => f.path.endsWith('_create_notes.sql'))
          .readAsStringSync();
      expect(noteMigration, contains('person_id uuid not null\n    references public.people (id) on delete cascade'));
      expect(noteMigration, contains('create index notes_person_id_idx on public.notes (person_id);'));

      // §5ac: deleting a person on the device deletes its notes and discards
      // their queued writes — generated into the parent's local source (it
      // compiles and runs, as `flutter analyze` / `flutter test` below prove).
      // (The Workshop formats the project, so the call may span several lines.)
      final personSource = read('packages/person/lib/data/sources/person_local_source.dart');
      final compact = personSource.replaceAll(RegExp(r'\s+'), '');
      expect(compact, contains('deleteById(Stringid)=>_db.transaction(()async{'));
      expect(compact, contains('await_db.noteDao.deleteByPersonId(id);'));
      expect(compact, contains("await_db.outboxDao.discardWrites(resource:'notes',field:'person_id',value:id"));
      expect(personSource, contains('// neat:on-delete-children'));
      expect(
        read('packages/neat_workshop_sync_test_database/lib/src/dao/note_dao.dart'),
        contains('Future<void> deleteByPersonId(String value) =>'),
      );

      await expectCiGreen(projectDir);
    },
    timeout: const Timeout(Duration(minutes: 20)),
  );
}

PubPackage _dep(String name, String version) =>
    PubPackage(name: name, version: version, description: '');

PubPackage _dev(String name, String version) =>
    PubPackage(name: name, version: version, description: '', isDev: true);
