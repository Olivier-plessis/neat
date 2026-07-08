import 'package:flutter_test/flutter_test.dart';
import 'package:neat/features/generation/domain/services/templates/dart/i18n_templates.dart';

void main() {
  group('I18nTemplates.slangConfig', () {
    test('points slang at the JSON scaffold with the given base locale', () {
      final cfg = I18nTemplates.slangConfig(baseLocale: 'fr');
      expect(cfg, contains('base_locale: fr'));
      expect(cfg, contains('input_file_pattern: .i18n.json'));
      expect(cfg, contains('output_file_name: strings.g.dart'));
      // Without this, a `{variable}` placeholder added to the scaffold later
      // renders literally instead of being substituted (slang defaults to
      // $-style Dart interpolation) — same fix as I18nImporter.slangCsvConfig.
      expect(cfg, contains('string_interpolation: braces'));
    });

    test('defaults to en', () {
      final cfg = I18nTemplates.slangConfig();
      expect(cfg, contains('base_locale: en'));
    });
  });
}
