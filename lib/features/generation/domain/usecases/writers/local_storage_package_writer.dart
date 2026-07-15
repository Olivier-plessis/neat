import 'dart:io';

import 'package:neat/features/generation/domain/models/field_spec.dart';
import 'package:neat/features/generation/domain/services/templates/local_storage_templates.dart';
import 'package:neat/features/generation/domain/usecases/writers/generation_io.dart';

/// Writes the minimal `packages/<name>_database` workspace member —
/// split out of `LaunchGenerationUsecase` (see ROADMAP.md for the per-domain
/// writer split).
abstract final class LocalStoragePackageWriter {
  static Future<void> write(
    Directory projectDir,
    String localStoragePackage, {
    required String featureName,
    bool hasSync = false,
    List<FieldSpec> fields = FieldSpec.idName,
    bool includeFirstTable = true,
    bool isWeb = false,
  }) async {
    final root = '${projectDir.path}/packages/$localStoragePackage';
    await writeFile(
      '$root/pubspec.yaml',
      LocalStorageTemplates.packagePubspec(packageName: localStoragePackage),
    );
    await writeFile('$root/build.yaml', LocalStorageTemplates.buildYaml());
    await writeFile(
      '$root/lib/$localStoragePackage.dart',
      LocalStorageTemplates.publicApi(packageName: localStoragePackage),
    );
    await writeFile(
      '$root/lib/src/database.dart',
      LocalStorageTemplates.database(
        featureName: featureName,
        withOutbox: hasSync,
        fields: fields,
        includeFirstTable: includeFirstTable,
        isWeb: isWeb,
      ),
    );
    // One dedicated file per table + per DAO (see LocalStorageTemplates.
    // featureTableFile/featureDaoFile/outboxTableFile/outboxDaoFile's doc) —
    // database.dart only imports + registers them.
    if (includeFirstTable) {
      await writeFile(
        '$root/lib/src/table/${featureName}_table.dart',
        LocalStorageTemplates.featureTableFile(featureName, fields: fields),
      );
      await writeFile(
        '$root/lib/src/dao/${featureName}_dao.dart',
        LocalStorageTemplates.featureDaoFile(featureName),
      );
    }
    if (hasSync) {
      await writeFile(
        '$root/lib/src/table/outbox_table.dart',
        LocalStorageTemplates.outboxTableFile(),
      );
      await writeFile(
        '$root/lib/src/dao/outbox_dao.dart',
        LocalStorageTemplates.outboxDaoFile(),
      );
    }
  }
}
