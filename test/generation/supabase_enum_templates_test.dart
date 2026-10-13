import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neat/features/feature_gen/domain/usecases/generate_feature_usecase.dart';
import 'package:neat/features/feature_gen/presentation/widgets/entity_fields_editor.dart';
import 'package:neat/features/feature_gen/presentation/widgets/field_edit_utils.dart';
import 'package:neat/features/generation/domain/models/field_spec.dart';
import 'package:neat/features/generation/domain/services/feature_scaffolder.dart';
import 'package:neat/features/generation/domain/services/json_entity_inferencer.dart';
import 'package:neat/features/generation/domain/services/templates/core_package_templates.dart';
import 'package:neat/features/generation/domain/services/templates/dart/data_templates.dart';
import 'package:neat/features/generation/domain/services/templates/dart/domain_templates.dart';
import 'package:neat/features/generation/domain/services/templates/dart/field_codegen.dart';
import 'package:neat/features/generation/domain/services/templates/local_storage_templates.dart';
import 'package:neat/features/generation/domain/services/templates/supabase_templates.dart';
import 'package:neat/features/generation/domain/usecases/writers/pubspec_writer.dart';

/// ROADMAP §5x (Supabase SQL / RLS / table name) and §5y (enum field type,
/// client-side ids): generator-level pins. The executable proof — a generated
/// project with an enum field analyzing cleanly and passing its own tests —
/// lives in `offline_sync_integration_test.dart`.
void main() {
  const status = FieldSpec(
    jsonKey: 'status',
    dartName: 'status',
    kind: FieldKind.enumeration,
    enumName: 'WorksiteStatus',
    enumValues: ['planned', 'in_progress', 'done'],
  );
  const worksiteFields = [
    FieldSpec(jsonKey: 'id', dartName: 'id', isId: true),
    FieldSpec(jsonKey: 'title', dartName: 'title'),
    status,
    FieldSpec(jsonKey: 'start_date', dartName: 'startDate', dartType: 'DateTime', nullable: true),
    FieldSpec(jsonKey: 'budget_cents', dartName: 'budgetCents', dartType: 'int'),
    FieldSpec(jsonKey: 'ratio', dartName: 'ratio', dartType: 'double'),
    FieldSpec(jsonKey: 'urgent', dartName: 'urgent', dartType: 'bool'),
  ];

  group('SupabaseTemplates.migration', () {
    final sql = SupabaseTemplates.migration(featureName: 'worksite', fields: worksiteFields);

    test('creates the table with a client-generated uuid id and an owner', () {
      expect(sql, contains('create table public.worksites ('));
      expect(sql, contains('id uuid primary key default gen_random_uuid()'));
      expect(sql, contains('owner_id uuid not null default auth.uid()'));
      expect(sql, contains('references auth.users (id) on delete cascade'));
      expect(sql, contains('created_at timestamptz not null default now()'));
      expect(sql, contains('updated_at timestamptz not null default now()'));
    });

    test('maps String/int/double/bool/DateTime and honours nullability', () {
      expect(sql, contains('title text not null'));
      expect(sql, contains('budget_cents integer not null'));
      expect(sql, contains('ratio double precision not null'));
      expect(sql, contains('urgent boolean not null'));
      expect(sql, contains('start_date timestamptz,'), reason: 'nullable → no `not null`');
    });

    test('an enum is text with a CHECK over its values', () {
      expect(sql, contains('status text not null'));
      expect(
        sql,
        contains(
          "constraint worksites_status_check check (status in ('planned', 'in_progress', 'done'))",
        ),
      );
    });

    test('set_updated_at is (re)created and wired by a trigger', () {
      expect(sql, contains('create or replace function public.set_updated_at()'));
      expect(sql, contains('create trigger worksites_set_updated_at'));
      expect(sql, contains('before update on public.worksites'));
    });

    test('indexes owner_id and turns RLS on with the four owner-scoped policies', () {
      expect(sql, contains('create index worksites_owner_id_idx on public.worksites (owner_id);'));
      expect(sql, contains('alter table public.worksites enable row level security;'));
      for (final op in ['select', 'insert', 'update', 'delete']) {
        expect(sql, contains('create policy "worksites_$op" on public.worksites'));
      }
      expect(sql, contains('using (owner_id = (select auth.uid()))'));
      expect(sql, contains('with check (owner_id = (select auth.uid()))'));
      expect(sql, isNot(contains('using (owner_id = auth.uid())')), reason: 'per statement, not per row');
      expect(sql, contains('insert ... on conflict do update'), reason: 'why update AND insert policies exist');
    });

    test('revokes the default ALL grant BEFORE granting only what the app uses', () {
      final revoke = sql.indexOf('revoke all on public.worksites from anon, authenticated;');
      final grant = sql.indexOf(
        'grant select, insert, update, delete on public.worksites to authenticated;',
      );
      expect(revoke, greaterThan(-1));
      expect(grant, greaterThan(revoke));
    });

    test('owner_id / created_at / updated_at are database-only', () {
      expect(sql, contains('`owner_id`, `created_at` and `updated_at` are database-only columns'));
    });

    test('a shared table has no owner and says so loudly', () {
      final shared = SupabaseTemplates.migration(
        featureName: 'worksite',
        fields: worksiteFields,
        ownedByUser: false,
      );
      expect(shared, isNot(contains('owner_id')));
      expect(shared, contains('SHARED TABLE'));
      expect(shared, contains('every signed-in user'));
      expect(shared, contains('using (true)'));
      expect(shared, contains('to authenticated'));
    });

    test('a shared table without sign-in is open to the anon key — and says that', () {
      final open = SupabaseTemplates.migration(
        featureName: 'worksite',
        fields: worksiteFields,
        ownedByUser: false,
        hasAuth: false,
      );
      expect(open, contains('every client holding the anon key'));
      expect(open, contains('to anon, authenticated'));
    });

    test('an irregular plural is the configured table, everywhere in the file', () {
      final custom = SupabaseTemplates.migration(
        featureName: 'person',
        fields: worksiteFields,
        tableName: 'people',
      );
      expect(custom, contains('create table public.people ('));
      expect(custom, contains('people_owner_id_idx'));
      expect(custom, isNot(contains('persons')));
    });

    test('camelCase and reserved column names are quoted; nested objects are jsonb', () {
      final quoted = SupabaseTemplates.migration(
        featureName: 'order',
        fields: const [
          FieldSpec(jsonKey: 'id', dartName: 'id', isId: true),
          FieldSpec(jsonKey: 'createdBy', dartName: 'createdBy'),
          FieldSpec(jsonKey: 'order', dartName: 'order', dartType: 'int'),
          FieldSpec(
            jsonKey: 'rating',
            dartName: 'rating',
            kind: FieldKind.object,
            objectName: 'Rating',
            children: [FieldSpec(jsonKey: 'rate', dartName: 'rate', dartType: 'double')],
          ),
        ],
      );
      expect(quoted, contains('"createdBy" text not null'));
      expect(quoted, contains('"order" integer not null'));
      expect(quoted, contains('rating jsonb not null'));
    });

    test('an entity field already named created_at wins over the automatic column', () {
      final dup = SupabaseTemplates.migration(
        featureName: 'note',
        fields: const [
          FieldSpec(jsonKey: 'id', dartName: 'id', isId: true),
          FieldSpec(jsonKey: 'created_at', dartName: 'createdAt', dartType: 'DateTime'),
        ],
      );
      expect('created_at timestamptz'.allMatches(dup).length, 1);
      expect(dup, contains('created_at timestamptz not null,'), reason: 'the entity field\'s own (no default)');
      expect(dup, contains('`owner_id` and `updated_at` are database-only columns'));
    });

    test('file name is <utc yyyyMMddHHmmss>_create_<table>.sql', () {
      expect(
        SupabaseTemplates.migrationFileName(DateTime.utc(2026, 10, 13, 12, 0, 5), 'worksites'),
        '20261013120005_create_worksites.sql',
      );
    });

    test('table names: lowercase identifier or empty', () {
      expect(SupabaseTemplates.validateTableName(''), isNull);
      expect(SupabaseTemplates.validateTableName('people'), isNull);
      expect(SupabaseTemplates.validateTableName('people_v2'), isNull);
      expect(SupabaseTemplates.validateTableName('People'), isNotNull);
      expect(SupabaseTemplates.validateTableName('2people'), isNotNull);
      expect(SupabaseTemplates.validateTableName('a-b'), isNotNull);
    });
  });

  group('FeatureScaffolder writes the migration', () {
    late Directory root;
    setUp(() => root = Directory.systemTemp.createTempSync('neat_sql_test_'));
    tearDown(() => root.deleteSync(recursive: true));

    Future<void> scaffold({
      String httpClient = 'supabase',
      String name = 'worksite',
      String? tableName,
      bool owned = true,
      bool hasAuth = true,
      bool remote = true,
      bool sync = true,
      DateTime? time,
      List<FieldSpec> fields = worksiteFields,
      bool freezed = true,
    }) => const FeatureScaffolder().writeFeature(
      lib: '${root.path}/lib',
      featureName: name,
      packageName: 'demo',
      isFeatureFirst: true,
      mirrorTestStructure: false,
      hasRiverpod: true,
      hasBloc: false,
      useCubit: false,
      useAnnotations: true,
      hasGoRouter: false,
      hasGoRouterBuilder: false,
      hasHttpClient: remote,
      httpClient: remote ? httpClient : '',
      hasFreezed: freezed,
      hasJsonSerializable: true,
      localStoragePackage: 'demo_database',
      hasSync: sync,
      fields: fields,
      tableName: tableName,
      ownedByUser: owned,
      hasAuth: hasAuth,
      projectRoot: root.path,
      migrationTime: time ?? DateTime.utc(2026, 10, 13, 12),
    );

    List<String> migrations() => Directory('${root.path}/supabase/migrations').existsSync()
        ? Directory('${root.path}/supabase/migrations')
              .listSync()
              .map((e) => e.uri.pathSegments.last)
              .toList()
        : [];

    test('Supabase + remote source → one migration, named after the table', () async {
      await scaffold(name: 'person', tableName: 'people');
      expect(migrations(), ['20261013120000_create_people.sql']);
      final api = File('${root.path}/lib/features/person/data/sources/person_api_source.dart')
          .readAsStringSync();
      expect(api, contains("static const String _table = 'people';"));
    });

    test('no migration for REST backends or a feature without a remote source', () async {
      await scaffold(httpClient: 'dio');
      expect(migrations(), isEmpty);
      await scaffold(name: 'local_only', remote: false);
      expect(migrations(), isEmpty);
    });

    test('two features generated in the same second never share a migration timestamp', () async {
      await scaffold(name: 'alpha');
      await scaffold(name: 'beta');
      final names = migrations()..sort();
      expect(names.length, 2);
      expect(names.map((n) => n.split('_').first).toSet().length, 2);
    });

    test('owner_id / created_at / updated_at stay out of the Dart side and the Drift table', () async {
      await scaffold();
      final dartFiles = Directory('${root.path}/lib').listSync(recursive: true).whereType<File>();
      for (final f in dartFiles) {
        final text = f.readAsStringSync();
        expect(text, isNot(contains('owner_id')), reason: f.path);
        expect(text, isNot(contains('ownerId')), reason: f.path);
        expect(text, isNot(contains('created_at')), reason: f.path);
      }
      expect(
        LocalStorageTemplates.featureTableFile('worksite', fields: worksiteFields),
        isNot(contains('owner')),
      );
    });

    test('the owner / shared choice reaches the SQL', () async {
      await scaffold(owned: false, hasAuth: false);
      final sql = File('${root.path}/supabase/migrations/${migrations().single}').readAsStringSync();
      expect(sql, contains('SHARED TABLE'));
      expect(sql, contains('to anon, authenticated'));
    });
  });

  group('enum fields (domain enum, String DTO)', () {
    test('picking the enum type seeds values; picking a plain type drops them', () {
      const f = FieldSpec(jsonKey: 'kind', dartName: 'kind');
      final asEnum = f.withType('enum');
      expect(asEnum.kind, FieldKind.enumeration);
      expect(asEnum.enumValues, FieldSpec.defaultEnumValues);
      expect(asEnum.copyWith(enumValues: ['a', 'b', 'c']).withType('enum').enumValues, ['a', 'b', 'c']);
      final back = asEnum.withType('int');
      expect(back.kind, FieldKind.scalar);
      expect(back.dartType, 'int');
      expect(back.enumValues, isEmpty);
      expect(FieldSpec.supportedTypes.last, 'enum');
    });

    test('JSON inference never produces an enum', () {
      final r = const JsonEntityInferencer().infer('{"id": 1, "status": "planned", "kind": "a"}');
      expect(r.fields.where((f) => f.kind == FieldKind.enumeration), isEmpty);
    });

    test('member names: snake → camel, keywords/digits/reserved are made valid', () {
      expect(enumMemberName('in_progress'), 'inProgress');
      expect(enumMemberName('living_room'), 'livingRoom');
      expect(enumMemberName('Done'), 'done');
      expect(enumMemberName('2fa'), 'v2fa');
      expect(enumMemberName('default'), 'defaultValue');
      expect(enumMemberName('value'), 'valueValue', reason: 'would shadow the enum\'s own `value`');
      expect(enumMemberName('values'), 'valuesValue');
      expect(enumMemberName('in-progress'), 'inProgress');
    });

    test('resolveEnumNames fills <Feature><Field>, recursing into objects, and de-conflicts', () {
      final fields = resolveEnumNames('worksite', const [
        FieldSpec(jsonKey: 'id', dartName: 'id', isId: true),
        FieldSpec(jsonKey: 'status', dartName: 'status', kind: FieldKind.enumeration, enumValues: ['a', 'b']),
        FieldSpec(
          jsonKey: 'meta',
          dartName: 'meta',
          kind: FieldKind.object,
          objectName: 'Meta',
          children: [
            FieldSpec(jsonKey: 'status', dartName: 'status', kind: FieldKind.enumeration, enumValues: ['x', 'y']),
          ],
        ),
      ]);
      expect(fields[1].enumName, 'WorksiteStatus');
      expect(fields[2].children.single.enumName, 'WorksiteStatus2', reason: 'same name, other values');
      expect(collectEnumSpecs(fields).map((e) => e.enumName), ['WorksiteStatus', 'WorksiteStatus2']);
    });

    test('the enum file carries value, fromValue and a first-value fallback', () {
      final code = DomainTemplates.featureEnum(
        field: status,
        featureName: 'worksite',
        checkedBy: 'worksites',
      );
      expect(code, contains('enum WorksiteStatus {'));
      expect(code, contains("planned('planned'),"));
      expect(code, contains("inProgress('in_progress'),"));
      expect(code, contains("done('done');"));
      expect(code, contains('final String value;'));
      expect(code, contains('static WorksiteStatus fromValue(String value) => values.firstWhere('));
      expect(code, contains('orElse: () => planned,'));
      expect(code, contains('constrained by a CHECK in the Supabase migration'));
    });

    test('entity: typed as the enum and re-exports it (model/page/tests get it for free)', () {
      final code = DomainTemplates.featureEntity(
        featureName: 'worksite',
        hasFreezed: true,
        fields: resolveEnumNames('worksite', worksiteFields),
      );
      expect(code, contains('required WorksiteStatus status,'));
      expect(code, contains("import 'worksite_status.dart';"));
      expect(code, contains("export 'worksite_status.dart';"));
    });

    test('model: DTO stays String; mappers convert both ways with a safe fallback', () {
      final fields = resolveEnumNames('worksite', worksiteFields);
      final freezed = DataTemplates.featureModel(
        featureName: 'worksite',
        hasFreezed: true,
        hasJsonSerializable: true,
        fields: fields,
      );
      expect(freezed, contains('required String status,'));
      expect(freezed, contains('status: e.status.value,'));
      expect(freezed, contains('status: WorksiteStatus.fromValue(status),'));
      final plain = DataTemplates.featureModel(
        featureName: 'worksite',
        hasFreezed: false,
        hasJsonSerializable: false,
        fields: fields,
      );
      expect(plain, contains("status: json['status'] as String,"));
      expect(plain, contains("'status': status,"));
      expect(plain, contains('status: WorksiteStatus.fromValue(status),'));
    });

    test('a nullable enum maps null safely both ways', () {
      const opt = FieldSpec(
        jsonKey: 'kind',
        dartName: 'kind',
        kind: FieldKind.enumeration,
        nullable: true,
        enumName: 'NoteKind',
        enumValues: ['memo'],
      );
      expect(opt.fromEntityValue('e'), 'e.kind?.value');
      expect(opt.toEntityValue(), 'kind == null ? null : NoteKind.fromValue(kind!)');
      expect(opt.entityPlaceholder(), 'null');
      expect(opt.modelType, 'String?');
      expect(opt.entityType, 'NoteKind?');
    });

    test('Drift keeps a plain text column, passed through untouched', () {
      expect(status.driftColumnLine(), 'TextColumn get status => text()();');
      expect(status.driftEncode('model'), 'model.status');
      expect(status.driftDecode('row'), 'row.status');
      expect(status.isComplex, isFalse);
    });

    test('the skeleton placeholder uses a real member', () {
      expect(status.entityPlaceholder(), 'WorksiteStatus.planned');
    });

    test('the scaffolder writes one enum file per enum field', () async {
      final root = Directory.systemTemp.createTempSync('neat_enum_test_');
      addTearDown(() => root.deleteSync(recursive: true));
      await const FeatureScaffolder().writeFeature(
        lib: '${root.path}/lib',
        featureName: 'worksite',
        packageName: 'demo',
        isFeatureFirst: true,
        mirrorTestStructure: false,
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
        fields: worksiteFields.map((f) => f.isEnum ? f.copyWith(enumName: '') : f).toList(),
        projectRoot: root.path,
      );
      final enumFile = File('${root.path}/lib/features/worksite/domain/entities/worksite_status.dart');
      expect(enumFile.existsSync(), isTrue);
      expect(enumFile.readAsStringSync(), contains('enum WorksiteStatus'));
      final sql = File(
        Directory('${root.path}/supabase/migrations').listSync().single.path,
      ).readAsStringSync();
      expect(sql, contains("check (status in ('planned', 'in_progress', 'done'))"));
    });
  });

  group('client-side ids', () {
    final fields = resolveEnumNames('worksite', worksiteFields);

    test('sync on → a `create` factory generates the uuid v4 (freezed)', () {
      final code = DomainTemplates.featureEntity(
        featureName: 'worksite',
        hasFreezed: true,
        fields: fields,
        clientId: true,
      );
      expect(code, contains("import 'package:uuid/uuid.dart';"));
      expect(code, contains('const WorksiteEntity._();'));
      expect(code, contains('factory WorksiteEntity.create({'));
      expect(code, contains('id: const Uuid().v4()'));
      expect(code, contains('required String title'));
      expect(code, contains('DateTime? startDate'), reason: 'nullable → optional');
      final create = code.substring(code.indexOf('factory WorksiteEntity.create({'));
      expect(create.split('=>').first, isNot(contains('String id')), reason: 'the id is not an argument');
    });

    test('same for a plain entity', () {
      final code = DomainTemplates.featureEntity(
        featureName: 'worksite',
        fields: fields,
        clientId: true,
      );
      expect(code, contains('factory WorksiteEntity.create({'));
      expect(code, contains('id: const Uuid().v4()'));
    });

    test('no sync → no factory, no uuid import', () {
      final code = DomainTemplates.featureEntity(featureName: 'worksite', hasFreezed: true, fields: fields);
      expect(code, isNot(contains('uuid')));
      expect(code, isNot(contains('.create(')));
    });

    test('uuid reaches the pubspecs: root, split feature package, existing project', () async {
      const original = 'dependencies:\n  flutter:\n    sdk: flutter\n\n'
          'dev_dependencies:\n  flutter_test:\n    sdk: flutter\n';
      expect(
        PubspecWriter.buildPubspecContent(original, const [], addUuid: true),
        contains('  uuid: ${CorePackageTemplates.uuidConstraint}'),
      );
      expect(PubspecWriter.buildPubspecContent(original, const []), isNot(contains('uuid')));
      expect(
        CorePackageTemplates.featurePackagePubspec(
          featurePackageName: 'worksite',
          corePackageName: 'core',
          clientIds: true,
        ),
        contains('uuid: ${CorePackageTemplates.uuidConstraint}'),
      );

      final dir = Directory.systemTemp.createTempSync('neat_pubspec_test_');
      addTearDown(() => dir.deleteSync(recursive: true));
      final file = File('${dir.path}/pubspec.yaml')..writeAsStringSync(original);
      await GenerateFeatureUsecase.ensureDependency(file.path, 'uuid', '^4.6.0');
      await GenerateFeatureUsecase.ensureDependency(file.path, 'uuid', '^4.6.0');
      final text = file.readAsStringSync();
      expect(text, contains('dependencies:\n  uuid: ^4.6.0\n  flutter:'));
      expect('uuid:'.allMatches(text).length, 1, reason: 'idempotent');
    });
  });

  group('field editor', () {
    testWidgets('an enum field shows its values; typing them reports the cleaned list', (tester) async {
      List<String>? reported;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: EntityFieldsEditor(
                fields: const [
                  FieldSpec(jsonKey: 'id', dartName: 'id', isId: true),
                  FieldSpec(
                    jsonKey: 'status',
                    dartName: 'status',
                    kind: FieldKind.enumeration,
                    enumValues: ['planned', 'done'],
                  ),
                ],
                onAddField: () {},
                onName: (_, _) {},
                onType: (_, _) {},
                onNullable: (_, _) {},
                onRemove: (_) {},
                onChildrenChanged: (_, _) {},
                onEnumValues: (i, v) => reported = v,
              ),
            ),
          ),
        ),
      );
      expect(find.text('Values (database text, comma separated)'), findsOneWidget);
      await tester.enterText(find.widgetWithText(TextField, 'planned, done'), 'a, b ,, a, c');
      expect(reported, ['a', 'b', 'c'], reason: 'trimmed, no blanks, no duplicates, order kept');
    });

    testWidgets('without onEnumValues (custom endpoints) the enum type is not offered', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: EntityFieldsEditor(
                fields: const [
                  FieldSpec(jsonKey: 'id', dartName: 'id', isId: true),
                  FieldSpec(jsonKey: 'title', dartName: 'title'),
                ],
                onAddField: () {},
                onName: (_, _) {},
                onType: (_, _) {},
                onNullable: (_, _) {},
                onRemove: (_) {},
                onChildrenChanged: (_, _) {},
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(DropdownButton<String>).last);
      await tester.pumpAndSettle();
      expect(find.text('DateTime'), findsWidgets);
      expect(find.text('enum'), findsNothing);
    });

    test('renaming a hand-added field renames its wire key too; an inferred one keeps its key', () {
      const manual = FieldSpec(jsonKey: 'field1', dartName: 'field1');
      expect(renameField(manual, 'budget_cents').jsonKey, 'budget_cents');
      const inferred = FieldSpec(jsonKey: 'start_date', dartName: 'startDate');
      final renamed = renameField(inferred, 'begin');
      expect(renamed.dartName, 'begin');
      expect(renamed.jsonKey, 'start_date');
    });
  });
}
