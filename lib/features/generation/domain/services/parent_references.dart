import 'dart:io';

import 'package:neat/features/generation/domain/models/field_spec.dart';

/// How a feature's entity says "my rows belong to another feature's": a
/// `<feature>_id` String field (`worksite_id` → the `worksite` feature). The id
/// itself and a reference to the feature itself don't count.
///
/// Shared by what follows from it: the sync order (SyncParents) and the
/// foreign key of the Supabase migration (ParentTables).
class ParentReferences {
  ParentReferences._();

  /// Field `jsonKey` → name of the feature it points at.
  static Map<String, String> of(String featureName, List<FieldSpec> fields) => {
    for (final f in fields)
      if (!f.isId &&
          f.isScalar &&
          f.dartType == 'String' &&
          f.jsonKey.endsWith('_id') &&
          f.jsonKey.length > 3)
        if (f.jsonKey.substring(0, f.jsonKey.length - 3) != featureName)
          f.jsonKey: f.jsonKey.substring(0, f.jsonKey.length - 3),
  };

  /// The project's source files (under `lib/` and `packages/`) whose name is in
  /// [fileNames]. Looking them up by name finds a feature wherever it lives —
  /// split package, child merged into another package, feature-first folder.
  /// Build output and dot-folders (`.dart_tool`…) are skipped.
  static Future<List<File>> filesNamed(
    String projectPath,
    Set<String> fileNames,
  ) async {
    final found = <File>[];
    for (final root in const ['lib', 'packages']) {
      final pending = <Directory>[Directory('$projectPath/$root')];
      while (pending.isNotEmpty) {
        final dir = pending.removeLast();
        if (!dir.existsSync()) continue;
        await for (final entity in dir.list(followLinks: false)) {
          final name = entity.uri.pathSegments.lastWhere(
            (s) => s.isNotEmpty,
            orElse: () => '',
          );
          if (entity is Directory) {
            if (name.startsWith('.') || name == 'build') continue;
            pending.add(entity);
          } else if (entity is File && fileNames.contains(name)) {
            found.add(entity);
          }
        }
      }
    }
    return found;
  }
}
