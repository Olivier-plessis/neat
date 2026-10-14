import 'package:neat/features/generation/domain/models/field_spec.dart';
import 'package:neat/features/generation/domain/services/templates/dart/_template_utils.dart';
import 'package:neat/features/generation/domain/services/templates/dart/field_codegen.dart';

/// The SQL a Supabase-backed feature needs before the app can read or write a
/// single row: the table, an `updated_at` trigger, row level security and the
/// grants. Without it the generated `ApiSource` talks to a table that doesn't
/// exist (or, once someone creates it by hand in the dashboard, to one that is
/// readable by anyone holding the anon key — Supabase grants ALL on new public
/// tables to `anon` and `authenticated`). Written to
/// `supabase/migrations/<timestamp>_create_<table>.sql`, the layout the
/// Supabase CLI (`supabase db push`) and the dashboard's SQL editor both take.
///
/// Verified end to end on a real project (archy: two migrations applied and
/// exercised through the Outbox replay) before being ported here.
/// The parent table a field points at (`references public.<table> (<column>)`).
class ForeignKey {
  const ForeignKey(this.table, this.column);

  final String table;
  final String column;
}

class SupabaseTemplates {
  SupabaseTemplates._();

  /// `^[a-z][a-z0-9_]*$` — what the Workshop accepts as a table name: a plain
  /// lower-case Postgres identifier that needs no quoting, so the Dart side
  /// (`.from('<table>')`), the Outbox endpoint and the SQL can never disagree.
  static final RegExp _tableName = RegExp(r'^[a-z][a-z0-9_]*$');

  static String? validateTableName(String name) {
    if (name.isEmpty) return null; // empty → the default `<feature>s`
    if (!_tableName.hasMatch(name)) {
      return 'lowercase letters, digits & underscores; start with a letter';
    }
    return null;
  }

  /// Postgres words a column can't be named without quoting (the common
  /// offenders for an entity field: `order`, `user`, `group`…).
  static const _reserved = {
    'all',
    'and',
    'as',
    'asc',
    'by',
    'case',
    'check',
    'column',
    'create',
    'default',
    'desc',
    'else',
    'end',
    'for',
    'from',
    'grant',
    'group',
    'in',
    'is',
    'like',
    'limit',
    'not',
    'null',
    'offset',
    'on',
    'or',
    'order',
    'primary',
    'references',
    'select',
    'table',
    'then',
    'to',
    'true',
    'false',
    'unique',
    'user',
    'when',
    'where',
    'with',
  };

  /// A column name as it must be written in SQL: bare when it's a plain
  /// lower-case identifier, double-quoted otherwise (a camelCase JSON key is a
  /// *different* column in Postgres unless quoted, and PostgREST matches JSON
  /// keys to columns case-sensitively).
  static String column(String jsonKey) =>
      RegExp(r'^[a-z_][a-z0-9_]*$').hasMatch(jsonKey) &&
          !_reserved.contains(jsonKey)
      ? jsonKey
      : '"${jsonKey.replaceAll('"', '""')}"';

  /// Postgres type for a Dart field. Nested objects / lists are stored as JSON
  /// (the model's `toJson` sends them as such); an enum is `text` (its
  /// database value — see [checkFor]).
  static String sqlType(FieldSpec f) {
    if (f.isComplex) return 'jsonb';
    return switch (f.dartType) {
      'int' => 'integer',
      'double' => 'double precision',
      'bool' => 'boolean',
      'DateTime' => 'timestamptz',
      _ => 'text',
    };
  }

  /// The migration's file name: `<yyyyMMddHHmmss>_create_<table>.sql`
  /// ([timestamp] is UTC; the CLI orders and de-duplicates migrations by it).
  static String migrationFileName(DateTime timestamp, String table) {
    final t = timestamp.toUtc();
    String two(int n) => n.toString().padLeft(2, '0');
    final stamp =
        '${t.year.toString().padLeft(4, '0')}${two(t.month)}${two(t.day)}'
        '${two(t.hour)}${two(t.minute)}${two(t.second)}';
    return '${stamp}_create_$table.sql';
  }

  /// The full migration for [featureName]'s table.
  ///
  /// - [ownedByUser]: every row belongs to the signed-in user — an `owner_id`
  ///   column defaulting to `auth.uid()`, RLS policies that only let a user
  ///   touch their own rows. Off: a **shared** table, every signed-in user
  ///   (every client, without [hasAuth]) can read and change every row — said
  ///   loudly in the file, to tighten before shipping.
  /// - [hasAuth]: whether the app has sign-in at all (decides who a shared
  ///   table is open to).
  /// - `owner_id` / `created_at` / `updated_at` are **database-only** columns:
  ///   never in the Dart model, entity or Drift table; the defaults and the
  ///   trigger fill them. (An entity field that already carries one of these
  ///   names wins over the automatic column.)
  /// - [references]: fields (by JSON key) that point at another table's rows —
  ///   a `worksite_id` on a task. Such a column is a `uuid` (the parent's id
  ///   is one), a real foreign key, and indexed (Postgres doesn't index the
  ///   referencing side, and the parent's delete and any "rows of this parent"
  ///   query scan it). A required one is `on delete cascade` — the row can't
  ///   outlive its parent; an optional one is `on delete set null`.
  static String migration({
    required String featureName,
    required List<FieldSpec> fields,
    String? tableName,
    bool ownedByUser = true,
    bool hasAuth = true,
    String modelName = '',
    Map<String, ForeignKey> references = const {},
  }) {
    final table = (tableName == null || tableName.isEmpty)
        ? '${featureName}s'
        : tableName;
    final p = modelName.isEmpty ? pascal(featureName) : modelName;
    final id = idField(fields);
    final entityKeys = {for (final f in fields) f.jsonKey};
    bool auto(String key) => !entityKeys.contains(key);

    final columns = <String>[
      '  -- Generated by the client (offline-first: a row is created locally and\n'
          '  -- queued before the server ever sees it); the default only serves inserts\n'
          '  -- made straight from the dashboard.\n'
          '  ${column(id.jsonKey)} uuid primary key default gen_random_uuid()',
      if (ownedByUser && auto('owner_id'))
        '  owner_id uuid not null default auth.uid()\n'
            '    references auth.users (id) on delete cascade',
      for (final f in fields)
        if (!f.isId)
          if (references[f.jsonKey] case final parent?)
            '  -- ${f.nullable ? 'Optional link to' : 'Belongs to'} a row of `${parent.table}`: '
                '${f.nullable ? 'deleting that row clears it' : 'deleting that row deletes this one too'}.\n'
                '  ${column(f.jsonKey)} uuid${f.nullable ? '' : ' not null'}\n'
                '    references public.${parent.table} (${column(parent.column)}) '
                'on delete ${f.nullable ? 'set null' : 'cascade'}'
          else
            '  ${column(f.jsonKey)} ${sqlType(f)}${f.nullable ? '' : ' not null'}',
      if (auto('created_at')) '  created_at timestamptz not null default now()',
      if (auto('updated_at')) '  updated_at timestamptz not null default now()',
    ];
    final checks = [for (final f in fields) ?checkFor(f, table)];
    final body = [...columns, ...checks.map((c) => '  $c')].join(',\n');
    final referenceIndexes = [
      for (final f in fields)
        if (references.containsKey(f.jsonKey))
          'create index ${table}_${_identifier(f.jsonKey)}_idx on public.$table (${column(f.jsonKey)});\n',
    ].join();

    final roles = ownedByUser || hasAuth
        ? 'authenticated'
        : 'anon, authenticated';
    final ownerSql = ownedByUser ? 'owner_id = (select auth.uid())' : 'true';

    final dbOnly = [
      if (ownedByUser && auto('owner_id')) '`owner_id`',
      if (auto('created_at')) '`created_at`',
      if (auto('updated_at')) '`updated_at`',
    ];
    final dbOnlyDoc = dbOnly.isEmpty
        ? ''
        : '-- ${_list(dbOnly)} ${dbOnly.length == 1 ? 'is a' : 'are'} database-only column'
              '${dbOnly.length == 1 ? '' : 's'}: the app never sends '
              '${dbOnly.length == 1 ? 'it' : 'them'}, the defaults and the\n'
              '-- trigger below fill ${dbOnly.length == 1 ? 'it' : 'them'}.\n';

    final sharedWarning = ownedByUser
        ? ''
        : '''
-- SHARED TABLE: rows have no owner, so the policies below let ${hasAuth ? 'every signed-in user' : 'every client holding the anon key'}
-- read and change every row. Tighten them (add an owner column and check it)
-- before shipping anything that holds private data.
''';

    final ownedPolicies = ownedByUser
        ? '''
-- The Outbox replays creates as upserts (insert ... on conflict do update),
-- which needs both the insert and the update policies.
'''
        : '';

    return '''-- $p — backs the `$featureName` feature.
--
-- Columns mirror ${p}Model's JSON keys.
$dbOnlyDoc--
-- Apply it from the Supabase dashboard (SQL Editor) or with the CLI
-- (`supabase db push`). Do it on the dev project first.
$sharedWarning
-- Keeps `updated_at` current on every update. Shared by every table.
create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as \$\$
begin
  new.updated_at = now();
  return new;
end;
\$\$;

create table public.$table (
$body
);
${ownedByUser && auto('owner_id') ? '\ncreate index ${table}_owner_id_idx on public.$table (owner_id);\n' : ''}${referenceIndexes.isEmpty ? '' : '\n$referenceIndexes'}
create trigger ${table}_set_updated_at
  before update on public.$table
  for each row execute function public.set_updated_at();

-- Row level security${ownedByUser ? ': each user only ever sees and changes their own rows' : ''}.
-- Without it the table would be readable by anyone holding the anon key.
alter table public.$table enable row level security;

${ownedByUser ? '-- `(select auth.uid())` is evaluated once per statement instead of per row.\n' : ''}create policy "${table}_select" on public.$table
  for select to $roles
  using ($ownerSql);

create policy "${table}_insert" on public.$table
  for insert to $roles
  with check ($ownerSql);

${ownedPolicies}create policy "${table}_update" on public.$table
  for update to $roles
  using ($ownerSql)
  with check ($ownerSql);

create policy "${table}_delete" on public.$table
  for delete to $roles
  using ($ownerSql);

-- Explicit grants, whatever the project's default privileges are (Supabase
-- grants ALL on new public tables to anon and authenticated): start from
-- nothing, then give signed-in clients only what the app uses. TRUNCATE in
-- particular bypasses RLS.
revoke all on public.$table from anon, authenticated;
grant select, insert, update, delete on public.$table to $roles;
''';
  }

  /// A `constraint … check (…)` clause for a field whose values are a closed
  /// set (an enum field), or null. Filled in by the enum field type.
  static String? checkFor(FieldSpec f, String table) {
    final values = f.enumValues;
    if (values.isEmpty) return null;
    final list = values.map((v) => "'${v.replaceAll("'", "''")}'").join(', ');
    final id = _identifier(f.jsonKey);
    return 'constraint ${table}_${id}_check check (${column(f.jsonKey)} in ($list))';
  }

  /// A JSON key as a lower-case identifier fragment (for constraint and index names).
  static String _identifier(String jsonKey) =>
      jsonKey.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '_');

  static String _list(List<String> items) => items.length <= 1
      ? items.join()
      : '${items.sublist(0, items.length - 1).join(', ')} and ${items.last}';
}
