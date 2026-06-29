import 'package:flutter_test/flutter_test.dart';
import 'package:neat/features/generation/domain/services/i18n_importer.dart';

void main() {
  group('I18nImporter.parseLocales', () {
    test('reads locale columns after the key column', () {
      const csv = 'key,en,fr,es\nappName,My App,Mon app,Mi app\n';
      expect(I18nImporter.parseLocales(csv), ['en', 'fr', 'es']);
    });

    test('trims whitespace and ignores blank columns', () {
      const csv = 'key, en , fr ,\nappName,A,B,\n';
      expect(I18nImporter.parseLocales(csv), ['en', 'fr']);
    });

    test('skips leading blank lines', () {
      const csv = '\n\nkey,de,it\nhello,Hallo,Ciao\n';
      expect(I18nImporter.parseLocales(csv), ['de', 'it']);
    });

    test('returns empty when there are no locale columns', () {
      expect(I18nImporter.parseLocales('key\n'), isEmpty);
      expect(I18nImporter.parseLocales(''), isEmpty);
    });
  });

  group('I18nImporter.slangCsvConfig', () {
    test('points slang at the CSV with the given base locale', () {
      final cfg = I18nImporter.slangCsvConfig('fr');
      expect(cfg, contains('base_locale: fr'));
      expect(cfg, contains('input_file_pattern: .i18n.csv'));
      expect(cfg, contains('output_file_name: strings.g.dart'));
    });
  });
}
