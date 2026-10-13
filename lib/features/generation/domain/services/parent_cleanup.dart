import 'dart:io';

import 'package:neat/features/generation/domain/models/field_spec.dart';
import 'package:neat/features/generation/domain/services/parent_references.dart';
import 'package:neat/features/generation/domain/services/templates/dart/_template_utils.dart';
import 'package:neat/features/generation/domain/services/templates/local_storage_templates.dart';

/// One reference of a new feature to a parent feature of the project.
class ParentLink {
  const ParentLink({required this.field, required this.parent, required this.localSource});

  /// The child's field (`worksite_id`).
  final FieldSpec field;

  /// The parent feature's name (`worksite`).
  final String parent;

  /// The parent's generated `<parent>_local_source.dart`.
  final File localSource;

  /// A required reference follows the parent's delete (`on delete cascade`); an
  /// optional one is cleared instead (`set null`) — see SupabaseTemplates.
  bool get cascades => !field.nullable;
}

/// What a child feature owes its parent's **local** delete.
///
/// Drift has no foreign key, so deleting a worksite on the device would leave
/// its tasks behind, and — worse — leave their writes in the Outbox, which can
/// only fail on the server's foreign key once the worksite is gone. The
/// parent's generated `deleteById` runs in a transaction with an anchor
/// ([anchor]); generating a child inserts two lines there: one deleting the
/// child's rows, one discarding its queued writes. Only a *required*
/// reference cascades; an optional one (`set null`) is reported, not guessed.
class ParentCleanup {
  ParentCleanup._();

  /// Where a child's cleanup goes in the parent's `deleteById`. Stays in place
  /// so the next child inserts after the previous one.
  static const anchor = '// neat:on-delete-children';

  /// The references of [fields] to a feature of the project that keeps a local
  /// source.
  static Future<List<ParentLink>> linksFor({
    required String projectPath,
    required String featureName,
    required List<FieldSpec> fields,
  }) async {
    final parents = ParentReferences.of(featureName, fields);
    if (parents.isEmpty) return const [];

    const suffix = '_local_source.dart';
    final files = await ParentReferences.filesNamed(projectPath, {
      for (final parent in parents.values.toSet()) '$parent$suffix',
    });
    final sourceOf = {
      for (final file in files)
        file.uri.pathSegments.last.substring(0, file.uri.pathSegments.last.length - suffix.length): file,
    };
    return [
      for (final field in fields)
        if (parents[field.jsonKey] case final parent? when sourceOf.containsKey(parent))
          ParentLink(field: field, parent: parent, localSource: sourceOf[parent]!),
    ];
  }

  /// Inserts the child's cleanup in each required parent's `deleteById` and
  /// returns what the developer still has to do by hand (optional references,
  /// a parent generated before the anchor existed).
  ///
  /// [resource]: the child's Outbox resource, null when it has no Outbox (no
  /// sync) — then only its rows are deleted.
  static Future<List<String>> patch({
    required List<ParentLink> links,
    required String childFeature,
    String? resource,
  }) async {
    final notes = <String>[];
    for (final link in links) {
      if (!link.cascades) {
        notes.add(
          '[i] "${link.field.jsonKey}" is optional: its delete rule is `set null`, so when a ${link.parent} '
          'is deleted, clear it on the $childFeature rows by hand (nothing is generated for it).',
        );
        continue;
      }
      final source = await link.localSource.readAsString();
      if (!source.contains(anchor)) {
        notes.add(
          '[i] ${link.parent}\'s local source has no `$anchor` (it was generated before it existed): when a '
          '${link.parent} is deleted, delete its $childFeature rows${resource == null ? '' : ' and their queued writes'} '
          'there by hand — see AGENTS.md.',
        );
        continue;
      }
      final lines = [
        'await _db.${camel(childFeature)}Dao.${LocalStorageTemplates.daoDeleteByReference(link.field)}(id);',
        if (resource != null)
          "await _db.outboxDao.discardWrites(resource: '$resource', field: '${link.field.jsonKey}', value: id);",
      ];
      if (source.contains(lines.first)) continue; // already there
      final indent = RegExp('^([ \\t]*)${RegExp.escape(anchor)}', multiLine: true).firstMatch(source)!.group(1)!;
      await link.localSource.writeAsString(
        source.replaceFirst(
          '$indent$anchor',
          '${lines.map((l) => '$indent$l').join('\n')}\n$indent$anchor',
        ),
      );
    }
    return notes;
  }
}
