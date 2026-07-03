import 'package:flutter_test/flutter_test.dart';
import 'package:neat/features/dependencies/domain/models/pub_package.dart';
import 'package:neat/features/generation/domain/services/templates/core_templates.dart';
import 'package:neat/features/generation/domain/usecases/launch_generation_usecase.dart';
import 'package:neat/features/theme_engine/domain/services/theme_templates.dart';

void main() {
  group('spider typed assets', () {
    test('spider config scans assets/ into an Assets class', () {
      final yaml = ThemeTemplates.spiderConfig();
      expect(yaml, contains('class_name: Assets'));
      expect(yaml, contains('path: assets'));
      expect(yaml, contains('.svg'));
    });

    test('Assets class includes the logo when present, empty otherwise', () {
      final withLogo = ThemeTemplates.assetsClass(hasLogo: true);
      expect(withLogo, contains('class Assets'));
      expect(withLogo, contains("brandingLogo = 'assets/branding/logo.png'"));

      final empty = ThemeTemplates.assetsClass(hasLogo: false);
      expect(empty, contains('class Assets'));
      expect(empty, isNot(contains('brandingLogo')));
    });
  });

  group('branding config templates', () {
    test('launcher icons config points at the logo across platforms', () {
      final yaml = CoreTemplates.launcherIconsConfig(
        platforms: const ['android', 'ios', 'macos', 'web'],
      );
      expect(yaml, contains('flutter_launcher_icons:'));
      expect(yaml, contains('image_path: "assets/branding/logo.png"'));
      expect(yaml, contains('adaptive_icon_foreground: "assets/branding/logo.png"'));
      expect(yaml, contains('macos:'));
      expect(yaml, contains('web:'));
    });

    test('launcher icons config only generates for the selected platforms', () {
      final yaml = CoreTemplates.launcherIconsConfig(platforms: const ['android', 'ios']);
      expect(yaml, contains('android: true'));
      expect(yaml, contains('ios: true'));
      expect(yaml, contains('generate: false')); // web/macos/windows/linux all off
    });

    test('native splash config has light + dark + android_12', () {
      final yaml = CoreTemplates.nativeSplashConfig(
        platforms: const ['android', 'ios', 'macos', 'web'],
      );
      expect(yaml, contains('flutter_native_splash:'));
      expect(yaml, contains('image: assets/branding/logo.png'));
      expect(yaml, contains('color: "#FFFFFF"'));
      expect(yaml, contains('color_dark:'));
      expect(yaml, contains('android_12:'));
    });
  });

  group('pubspec branding dev deps', () {
    const base = '''name: demo
description: x
publish_to: 'none'
version: 1.0.0+1
environment:
  sdk: ^3.12.0
  flutter: ">=1.17.0"
dependencies:
  flutter:
    sdk: flutter
dev_dependencies:
  flutter_test:
    sdk: flutter
''';

    test('addBranding injects the icon + splash dev deps', () {
      final out = LaunchGenerationUsecase.buildPubspecContent(
        base,
        const <PubPackage>[],
        addBranding: true,
      );
      expect(out, contains('flutter_launcher_icons:'));
      expect(out, contains('flutter_native_splash:'));
    });

    test('no branding deps when addBranding is false', () {
      final out = LaunchGenerationUsecase.buildPubspecContent(base, const <PubPackage>[]);
      expect(out, isNot(contains('flutter_launcher_icons')));
      expect(out, isNot(contains('flutter_native_splash')));
    });
  });
}
