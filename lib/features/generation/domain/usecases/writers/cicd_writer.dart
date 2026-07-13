import 'dart:io';

import 'package:neat/features/cicd/domain/models/cicd_state.dart';
import 'package:neat/features/cicd/domain/usecases/generate_yaml_usecase.dart';
import 'package:neat/features/generation/domain/usecases/writers/generation_io.dart';

/// Writes the selected CI/CD provider's YAML files (+ the fastlane gitignore
/// entry) — split out of `LaunchGenerationUsecase` (see ROADMAP.md for the
/// per-domain writer split).
abstract final class CicdWriter {
  static Future<void> write(
    Directory projectDir,
    CicdState cicd, {
    bool hasFlavors = false,
  }) async {
    final generated = const GenerateYamlUsecase().execute(
      cicd,
      hasFlavors: hasFlavors,
    );

    for (final file in generated) {
      final f = File('${projectDir.path}/${file.filename}');
      await f.create(recursive: true);
      await f.writeAsString(file.content);
    }

    // Keep fastlane secrets + signing material out of git.
    if (cicd.isSelected(CiTool.fastlane)) {
      await appendGitignore(projectDir, '''

# fastlane secrets + Android signing (keep only the .example files)
**/fastlane/.env
android/key.properties
**/*.jks
**/*.keystore
''');
    }
  }
}
