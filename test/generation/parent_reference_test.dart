import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:neat/core/contract/neat_contract.dart';
import 'package:neat/features/generation/domain/models/field_spec.dart';
import 'package:neat/features/generation/domain/services/feature_scaffolder.dart';
import 'package:neat/features/generation/domain/services/parent_tables.dart';
import 'package:neat/features/generation/domain/services/templates/agents_md_template.dart';
import 'package:neat/features/generation/domain/services/templates/supabase_templates.dart';

/// ROADMAP §5ab — a `<parent>_id` field is a foreign key, not a loose `text`
/// column. Found in archy: the generated migration declared `worksite_id text`,
/// which can't reference the parent's `uuid` id; the foreign key (and its index)
/// was written by hand.
void main() {
  const id = FieldSpec(jsonKey: 'id', dartName: 'id', isId: true);
  const title = FieldSpec(jsonKey: 'title', dartName: 'title');
  const worksiteId = FieldSpec(jsonKey: 'worksite_id', dartName: 'worksiteId');
  const optionalWorksiteId = FieldSpec(
    jsonKey: 'worksite_id',
    dartName: 'worksiteId',
    nullable: true,
  );

  group('migration', () {
    String sql(
      List<FieldSpec> fields, {
      Map<String, ForeignKey> references = const {},
    }) => SupabaseTemplates.migration(
      featureName: 'task',
      fields: fields,
      references: references,
    );
    const worksites = {'worksite_id': ForeignKey('worksites', 'id')};

    test('a required reference is a uuid foreign key that cascades', () {
      final code = sql([id, title, worksiteId], references: worksites);
      expect(
        code,
        contains(
          'worksite_id uuid not null\n    references public.worksites (id) on delete cascade',
        ),
      );
      expect(code, isNot(contains('worksite_id text')));
      expect(code, contains('deleting that row deletes this one too'));
    });

    test('an optional reference is cleared, not cascaded', () {
      final code = sql([id, title, optionalWorksiteId], references: worksites);
      expect(
        code,
        contains(
          'worksite_id uuid\n    references public.worksites (id) on delete set null',
        ),
      );
      expect(code, isNot(contains('worksite_id uuid not null')));
    });

    test('the referencing column is indexed (Postgres does not do it)', () {
      final code = sql([id, worksiteId], references: worksites);
      expect(
        code,
        contains(
          'create index tasks_worksite_id_idx on public.tasks (worksite_id);',
        ),
      );
      // …next to the owner index, before the trigger.
      expect(
        code.indexOf('tasks_owner_id_idx'),
        lessThan(code.indexOf('tasks_worksite_id_idx')),
      );
      expect(
        code.indexOf('tasks_worksite_id_idx'),
        lessThan(code.indexOf('create trigger')),
      );
    });

    test('only the fields that reference something change', () {
      final code = sql([id, title, worksiteId], references: worksites);
      expect(code, contains('title text not null'));
      expect(
        code,
        isNot(
          contains(
            'owner_id uuid not null default auth.uid()\n    references public.worksites',
          ),
        ),
      );
    });

    test('without references the migration is what it was', () {
      final plain = sql([id, title, worksiteId]);
      expect(plain, contains('worksite_id text not null'));
      expect(plain, isNot(contains('references public.worksites')));
      expect(plain, isNot(contains('worksite_id_idx')));
    });

    test('a parent whose id column needs quoting is quoted', () {
      final code = sql(
        [id, worksiteId],
        references: {'worksite_id': const ForeignKey('worksites', 'order')},
      );
      expect(code, contains('references public.worksites ("order")'));
    });
  });

  group('ParentTables', () {
    late Directory root;
    setUp(
      () => root = Directory.systemTemp.createTempSync('neat_parent_tables_'),
    );
    tearDown(() => root.deleteSync(recursive: true));

    void write(String rel, String content) => File('${root.path}/$rel')
      ..createSync(recursive: true)
      ..writeAsStringSync(content);

    void parent(
      String feature,
      String table, {
      String idLine = 'id uuid primary key default gen_random_uuid()',
      String? apiPath,
    }) {
      write(
        apiPath ??
            'packages/$feature/lib/data/sources/${feature}_api_source.dart',
        "class Api {\n  static const String _table = '$table';\n}\n",
      );
      write(
        'supabase/migrations/20261013120000_create_$table.sql',
        'create table public.$table (\n  $idLine,\n  title text\n);\n',
      );
    }

    Future<Map<String, ForeignKey>> refs(
      List<FieldSpec> fields, {
      String feature = 'task',
    }) => ParentTables.referencesFor(
      projectPath: root.path,
      featureName: feature,
      fields: fields,
    );

    test(
      'reads the parent\'s table from its API source and its id from its migration',
      () async {
        parent('worksite', 'worksites');
        final found = await refs([id, title, worksiteId]);
        expect(found.keys, ['worksite_id']);
        expect(found['worksite_id']!.table, 'worksites');
        expect(found['worksite_id']!.column, 'id');
      },
    );

    test('a custom table name is the one used, not <feature>s', () async {
      parent('worksite', 'chantiers');
      expect((await refs([id, worksiteId]))['worksite_id']!.table, 'chantiers');
    });

    test(
      'a parent merged into another package is found all the same',
      () async {
        parent(
          'room',
          'rooms',
          apiPath: 'packages/house/lib/data/room/sources/room_api_source.dart',
        );
        const roomId = FieldSpec(jsonKey: 'room_id', dartName: 'roomId');
        expect(
          (await refs([id, roomId], feature: 'item'))['room_id']!.table,
          'rooms',
        );
      },
    );

    test(
      'without the parent\'s migration there is nothing to reference',
      () async {
        write(
          'packages/worksite/lib/data/sources/worksite_api_source.dart',
          "static const String _table = 'worksites';",
        );
        expect(await refs([id, worksiteId]), isEmpty);
      },
    );

    test(
      'a parent whose key is not a uuid cannot be referenced by a uuid column',
      () async {
        parent('worksite', 'worksites', idLine: 'id text primary key');
        expect(await refs([id, worksiteId]), isEmpty);
      },
    );

    test(
      'an unknown feature, the id, and a reference to itself are left alone',
      () async {
        parent('task', 'tasks');
        const ghost = FieldSpec(jsonKey: 'ghost_id', dartName: 'ghostId');
        const self = FieldSpec(jsonKey: 'task_id', dartName: 'taskId');
        expect(await refs([id, ghost, self]), isEmpty);
      },
    );

    test('a non-Supabase parent (no `_table`) is not a table', () async {
      write(
        'packages/worksite/lib/data/sources/worksite_api_source.dart',
        'class Api {}',
      );
      write(
        'supabase/migrations/20261013120000_create_worksites.sql',
        'id uuid primary key',
      );
      expect(await refs([id, worksiteId]), isEmpty);
    });
  });

  group('FeatureScaffolder', () {
    late Directory root;
    setUp(
      () => root = Directory.systemTemp.createTempSync('neat_fk_scaffold_'),
    );
    tearDown(() => root.deleteSync(recursive: true));

    Future<String> migrationOf(Map<String, ForeignKey> foreignKeys) async {
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
        fields: const [id, worksiteId, title],
        foreignKeys: foreignKeys,
      );
      final dir = Directory('${root.path}/supabase/migrations');
      return dir.listSync().whereType<File>().single.readAsStringSync();
    }

    test('writes the foreign key into the feature\'s migration', () async {
      final sql = await migrationOf({
        'worksite_id': const ForeignKey('worksites', 'id'),
      });
      expect(
        sql,
        contains('references public.worksites (id) on delete cascade'),
      );
    });

    test(
      'and leaves the column a plain one when nothing is referenced',
      () async {
        expect(
          await migrationOf(const {}),
          contains('worksite_id text not null'),
        );
      },
    );
  });

  test('AGENTS.md documents the generated foreign key (Supabase only)', () {
    NeatContract contract(String client) => NeatContract(
      projectName: 'archy',
      architecture: 'feature_first',
      stateManagement: 'riverpod',
      navigation: 'go_router_builder',
      httpClient: client,
      themeApproach: 'customM3',
      storageStrategy: 'offlineFirstSync',
    );
    expect(
      AgentsMdTemplate.generate(contract('supabase')),
      contains('uuid` foreign key with an index'),
    );
    expect(
      AgentsMdTemplate.generate(contract('dio')),
      isNot(contains('uuid` foreign key')),
    );
  });
}
