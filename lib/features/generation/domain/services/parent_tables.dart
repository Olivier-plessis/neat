import 'dart:io';

import 'package:neat/features/generation/domain/models/field_spec.dart';
import 'package:neat/features/generation/domain/services/parent_references.dart';
import 'package:neat/features/generation/domain/services/templates/supabase_templates.dart';

/// The foreign keys of a new Supabase feature's migration: which of its fields
/// point at another feature's table, and at which column.
///
/// A `<feature>_id` field (`worksite_id`) naming a feature of the project is
/// read back from what NEAT generated for that parent — the table from its API
/// source (`_table = 'worksites'`, the same name the Outbox and the SQL use,
/// custom or not), the id column from its migration — so nothing is guessed:
/// without the parent's migration in `supabase/migrations/` (a table made by
/// hand, another project) the field stays a plain column and the foreign key is
/// left to the developer.
class ParentTables {
  ParentTables._();

  static final _table = RegExp(r"\b_table = '([^']+)'");
  static final _idColumn = RegExp(r'^\s*("?[A-Za-z_][A-Za-z0-9_]*"?)\s+uuid primary key', multiLine: true);

  /// Field `jsonKey` → the table and column it references. Empty when none does.
  static Future<Map<String, ForeignKey>> referencesFor({
    required String projectPath,
    required String featureName,
    required List<FieldSpec> fields,
  }) async {
    final parents = ParentReferences.of(featureName, fields);
    if (parents.isEmpty) return const {};

    const suffix = '_api_source.dart';
    final files = await ParentReferences.filesNamed(projectPath, {
      for (final parent in parents.values.toSet()) '$parent$suffix',
    });
    final tables = <String, String>{};
    for (final file in files) {
      final match = _table.firstMatch(await file.readAsString());
      if (match == null) continue;
      final name = file.uri.pathSegments.last;
      tables[name.substring(0, name.length - suffix.length)] = match.group(1)!;
    }

    final references = <String, ForeignKey>{};
    for (final entry in parents.entries) {
      final table = tables[entry.value];
      if (table == null) continue;
      final column = _idColumnOf(projectPath, table);
      if (column != null) references[entry.key] = ForeignKey(table, column);
    }
    return references;
  }

  /// The parent's primary key, from its `create_<table>` migration — null when
  /// there is none, or its key isn't a `uuid` (a foreign key couldn't match it).
  static String? _idColumnOf(String projectPath, String table) {
    final dir = Directory('$projectPath/supabase/migrations');
    if (!dir.existsSync()) return null;
    for (final file in dir.listSync().whereType<File>()) {
      if (!file.path.endsWith('_create_$table.sql')) continue;
      final match = _idColumn.firstMatch(file.readAsStringSync());
      if (match == null) continue;
      final raw = match.group(1)!;
      return raw.startsWith('"') ? raw.substring(1, raw.length - 1).replaceAll('""', '"') : raw;
    }
    return null;
  }
}
