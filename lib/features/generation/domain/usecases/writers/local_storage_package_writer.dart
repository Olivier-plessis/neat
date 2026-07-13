import 'dart:io';

import 'package:neat/features/generation/domain/models/field_spec.dart';
import 'package:neat/features/generation/domain/services/templates/local_storage_templates.dart';
import 'package:neat/features/generation/domain/usecases/writers/generation_io.dart';

/// Writes the minimal `packages/<name>_local_storage` workspace member —
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
      ),
    );
  }
}
