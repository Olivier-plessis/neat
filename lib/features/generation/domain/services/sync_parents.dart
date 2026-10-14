import 'package:neat/features/generation/domain/models/field_spec.dart';
import 'package:neat/features/generation/domain/services/parent_references.dart';

/// Which already-synced features a new feature's rows point at.
///
/// A `<feature>_id` field (`worksite_id`) that names a feature of the project
/// makes the new feature a *child* of it: its writes must not reach the server
/// before the parent's, or the foreign key fails when both are queued offline
/// and flushed together (see SyncService.dependsOn).
///
/// The parent's Outbox `resource` is read back from the sync provider NEAT
/// generated for it — the one place that already holds the table name or REST
/// path it really uses, whatever the layout (split package, merged child,
/// feature-first folder). A parent without a sync provider has no queue to wait
/// for, so it is not a dependency.
class SyncParents {
  SyncParents._();

  static final _resource = RegExp(r"\bresource: '([^']+)'");

  /// Outbox resources of the synced features [fields] point at, sorted and
  /// without duplicates. Empty when none does.
  static Future<List<String>> resourcesFor({
    required String projectPath,
    required String featureName,
    required List<FieldSpec> fields,
  }) async {
    final parents = ParentReferences.of(featureName, fields).values.toSet();
    if (parents.isEmpty) return const [];

    final files = await ParentReferences.filesNamed(projectPath, {
      for (final p in parents) '${p}_repository_providers.dart',
    });
    final resources = <String>{};
    for (final file in files) {
      final match = _resource.firstMatch(await file.readAsString());
      if (match != null) resources.add(match.group(1)!);
    }
    return resources.toList()..sort();
  }
}
