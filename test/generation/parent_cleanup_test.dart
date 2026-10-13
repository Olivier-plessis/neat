import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:neat/features/generation/domain/models/field_spec.dart';
import 'package:neat/features/generation/domain/services/parent_cleanup.dart';
import 'package:neat/features/generation/domain/services/templates/dart/data_templates.dart';
import 'package:neat/features/generation/domain/services/templates/dart/offline_test_templates.dart';
import 'package:neat/features/generation/domain/services/templates/local_storage_templates.dart';

/// ROADMAP §5ac — deleting a parent on the device removes its children's rows
/// and their queued writes. Found in archy: the worksite's local delete had to
/// be edited by hand to delete its tasks (Drift has no foreign key) and to drop
/// their writes from the Outbox, which could only fail on the server's foreign
/// key once the worksite was gone.
void main() {
  const id = FieldSpec(jsonKey: 'id', dartName: 'id', isId: true);
  const worksiteId = FieldSpec(jsonKey: 'worksite_id', dartName: 'worksiteId');
  const optionalWorksiteId = FieldSpec(
    jsonKey: 'worksite_id',
    dartName: 'worksiteId',
    nullable: true,
  );

  String localSource() => DataTemplates.featureLocalSource(
    featureName: 'worksite',
    offlineFirst: true,
    hasSync: true,
    localStoragePackage: 'demo_database',
  );

  group('templates', () {
    test(
      'the parent\'s local delete is a transaction with the anchor before its own delete',
      () {
        final code = localSource();
        expect(
          code,
          contains(
            'Future<void> deleteById(String id) => _db.transaction(() async {',
          ),
        );
        expect(code, contains(ParentCleanup.anchor));
        expect(
          code.indexOf(ParentCleanup.anchor),
          lessThan(code.indexOf('await _db.worksiteDao.deleteWorksite(id);')),
        );
      },
    );

    test('a child\'s DAO deletes its rows by each required reference', () {
      final dao = LocalStorageTemplates.featureDaoFile(
        'task',
        cascadeFields: [worksiteId],
      );
      expect(dao, contains('Future<void> deleteByWorksiteId(String value) =>'));
      expect(
        dao,
        contains(
          '(delete(taskRows)..where((t) => t.worksiteId.equals(value))).go();',
        ),
      );
      expect(
        LocalStorageTemplates.daoDeleteByReference(worksiteId),
        'deleteByWorksiteId',
      );
    });

    test('a DAO without parent has no such method', () {
      expect(
        LocalStorageTemplates.featureDaoFile('worksite'),
        isNot(contains('deleteBy')),
      );
    });

    test(
      'the Outbox DAO can discard the queued writes of a deleted parent\'s children',
      () {
        final dao = LocalStorageTemplates.outboxDaoFile();
        expect(dao, contains("import 'dart:convert';"));
        expect(dao, contains('Future<void> discardWrites({'));
        expect(dao, contains('required String resource,'));
        expect(dao, contains("path.startsWith('\$resource/')"));
        expect(dao, contains('on FormatException {'));
      },
    );

    test('the generated project ships a test for discardWrites', () {
      final code = OfflineTestTemplates.syncServiceTest(
        corePackage: 'core',
        localStoragePackage: 'demo_database',
        resource: 'worksites',
      );
      expect(code, contains("import 'dart:convert';"));
      expect(
        code,
        contains(
          'discardWrites drops only the queued writes of a deleted parent',
        ),
      );
      expect(
        code,
        contains(
          "resource: 'worksites_child', field: 'parent_id', value: 'p1'",
        ),
      );
    });
  });

  group('ParentCleanup', () {
    late Directory root;
    setUp(
      () => root = Directory.systemTemp.createTempSync('neat_parent_cleanup_'),
    );
    tearDown(() => root.deleteSync(recursive: true));

    File writeParent({
      String rel =
          'packages/worksite/lib/data/sources/worksite_local_source.dart',
      String? source,
    }) => File('${root.path}/$rel')
      ..createSync(recursive: true)
      ..writeAsStringSync(source ?? localSource());

    Future<List<ParentLink>> links(
      List<FieldSpec> fields, {
      String feature = 'task',
    }) => ParentCleanup.linksFor(
      projectPath: root.path,
      featureName: feature,
      fields: fields,
    );

    group('linksFor', () {
      test(
        'finds the parent\'s local source, split package or feature-first',
        () async {
          final file = writeParent();
          final found = await links([id, worksiteId]);
          expect(found, hasLength(1));
          expect(found.single.parent, 'worksite');
          expect(found.single.localSource.path, file.path);
          expect(found.single.cascades, isTrue);

          writeParent(
            rel: 'lib/features/room/data/sources/room_local_source.dart',
          );
          const roomId = FieldSpec(jsonKey: 'room_id', dartName: 'roomId');
          expect(
            (await links([id, roomId], feature: 'item')).single.parent,
            'room',
          );
        },
      );

      test('an optional reference does not cascade', () async {
        writeParent();
        expect(
          (await links([id, optionalWorksiteId])).single.cascades,
          isFalse,
        );
      });

      test(
        'a parent without a local source, a non-String reference and the id are ignored',
        () async {
          const ghost = FieldSpec(jsonKey: 'ghost_id', dartName: 'ghostId');
          const numeric = FieldSpec(
            jsonKey: 'worksite_id',
            dartName: 'worksiteId',
            dartType: 'int',
          );
          writeParent();
          expect(await links([id, ghost]), isEmpty);
          expect(await links([id, numeric]), isEmpty);
        },
      );
    });

    group('patch', () {
      Future<List<String>> patch(
        File file, {
        String child = 'task',
        String? resource = 'tasks',
        List<FieldSpec>? fields,
      }) async {
        final found = await links(fields ?? [id, worksiteId], feature: child);
        return ParentCleanup.patch(
          links: found,
          childFeature: child,
          resource: resource,
        );
      }

      test(
        'inserts the child\'s rows and queued writes cleanup before the parent\'s own delete',
        () async {
          final file = writeParent();
          expect(await patch(file), isEmpty);

          final code = file.readAsStringSync();
          const rows = 'await _db.taskDao.deleteByWorksiteId(id);';
          const writes =
              "await _db.outboxDao.discardWrites(resource: 'tasks', field: 'worksite_id', value: id);";
          const own = 'await _db.worksiteDao.deleteWorksite(id);';
          expect(
            code,
            contains(
              '    $rows\n    $writes\n    ${ParentCleanup.anchor}\n    $own',
            ),
          );
        },
      );

      test(
        'the anchor stays, so a second child goes after the first',
        () async {
          final file = writeParent();
          await patch(file);
          const noteWorksite = FieldSpec(
            jsonKey: 'worksite_id',
            dartName: 'worksiteId',
          );
          await patch(
            file,
            child: 'note',
            resource: 'notes',
            fields: [id, noteWorksite],
          );

          final code = file.readAsStringSync();
          expect(code, contains('taskDao.deleteByWorksiteId'));
          expect(code, contains('noteDao.deleteByWorksiteId'));
          expect(code.indexOf('taskDao'), lessThan(code.indexOf('noteDao')));
          expect(
            code.indexOf('noteDao'),
            lessThan(code.indexOf(ParentCleanup.anchor)),
          );
          expect(
            RegExp(RegExp.escape(ParentCleanup.anchor)).allMatches(code),
            hasLength(1),
          );
        },
      );

      test('is idempotent', () async {
        final file = writeParent();
        await patch(file);
        final once = file.readAsStringSync();
        await patch(file);
        expect(file.readAsStringSync(), once);
      });

      test('without sync there is no Outbox to clean: only the rows', () async {
        final file = writeParent();
        await patch(file, resource: null);
        final code = file.readAsStringSync();
        expect(code, contains('taskDao.deleteByWorksiteId(id);'));
        expect(code, isNot(contains('discardWrites')));
      });

      test('an optional reference is reported, not guessed', () async {
        final file = writeParent();
        final before = file.readAsStringSync();
        final notes = await patch(file, fields: [id, optionalWorksiteId]);
        expect(notes.single, contains('optional'));
        expect(notes.single, contains('set null'));
        expect(file.readAsStringSync(), before);
      });

      test(
        'a parent generated before the anchor existed is reported and left alone',
        () async {
          final old =
              'class WorksiteLocalSource {\n  Future<void> deleteById(String id) => _db.worksiteDao.deleteWorksite(id);\n}\n';
          final file = writeParent(source: old);
          final notes = await patch(file);
          expect(notes.single, contains(ParentCleanup.anchor));
          expect(notes.single, contains('queued writes'));
          expect(file.readAsStringSync(), old);
        },
      );
    });
  });
}
