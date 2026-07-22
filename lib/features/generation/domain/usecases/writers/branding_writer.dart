import 'dart:io';

import 'package:neat/features/generation/domain/services/templates/core_templates.dart';
import 'package:neat/features/generation/domain/usecases/writers/generation_io.dart';

/// Writes/runs branding (logo → app icons + splash screen) — split out of
/// `LaunchGenerationUsecase` (see ROADMAP.md for the per-domain writer
/// split).
abstract final class BrandingWriter {
  /// Copies the picked logo into `assets/branding/logo.png` and writes the
  /// flutter_launcher_icons / flutter_native_splash configs.
  static Future<void> write(
    Directory projectDir,
    String logoPath,
    List<String> platforms,
  ) async {
    final src = File(logoPath);
    if (!src.existsSync()) return;
    final dest = File('${projectDir.path}/assets/branding/logo.png');
    await dest.create(recursive: true);
    await dest.writeAsBytes(await src.readAsBytes());
    await writeFile(
      '${projectDir.path}/flutter_launcher_icons.yaml',
      CoreTemplates.launcherIconsConfig(platforms: platforms),
    );
    await writeFile(
      '${projectDir.path}/flutter_native_splash.yaml',
      CoreTemplates.nativeSplashConfig(platforms: platforms),
    );
  }

  /// Runs flutter_launcher_icons + flutter_native_splash. Best-effort: failures
  /// (e.g. a platform folder absent) are logged but never abort generation.
  static Future<void> runTools(
    Directory projectDir,
    String flutter,
    void Function(String) onLog,
  ) async {
    final dart = '${File(flutter).parent.path}/dart';
    const tasks = [
      ['run', 'flutter_launcher_icons'],
      ['run', 'flutter_native_splash:create'],
    ];
    for (final args in tasks) {
      try {
        final result = await Process.run(
          dart,
          args,
          workingDirectory: projectDir.path,
          environment: {
            ...Platform.environment,
            'PATH':
                '${Platform.environment['PATH']}:/usr/local/bin:/opt/homebrew/bin',
          },
        ).timeout(const Duration(minutes: 3));
        onLog(
          result.exitCode == 0
              ? '[✓] ${args.last} done.'
              : '[!] ${args.last}: ${result.stderr.toString().trim().split('\n').take(1).join()}',
        );
      } catch (e) {
        onLog('[!] ${args.last} skipped: $e');
      }
    }
  }
}
