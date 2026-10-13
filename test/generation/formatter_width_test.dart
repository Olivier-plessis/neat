import 'package:flutter_test/flutter_test.dart';
import 'package:neat/features/generation/domain/services/templates/config_templates.dart';

/// A generated project pins `dart format`'s width in its analysis_options.yaml:
/// the IDE has its own line-length setting (Android Studio's hard wrap was 100
/// in archy), and a project that does not say what it wants loses to it — the CI
/// then rejects files the IDE formatted.
void main() {
  // What `flutter create` writes (shortened).
  const created = '''# This file configures the analyzer.
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    # avoid_print: false
''';

  group('withFormatterWidth', () {
    test('adds the pinned width to the file flutter create wrote', () {
      final out = ConfigTemplates.withFormatterWidth(created);
      expect(out, startsWith(created));
      expect(out, contains('\nformatter:\n  page_width: 80\n'));
      expect(out, endsWith('\n'));
    });

    test('is idempotent', () {
      final once = ConfigTemplates.withFormatterWidth(created);
      expect(ConfigTemplates.withFormatterWidth(once), once);
    });

    test('never overwrites a width the developer chose', () {
      const custom = 'include: package:flutter_lints/flutter.yaml\n\nformatter:\n  page_width: 100\n';
      expect(ConfigTemplates.withFormatterWidth(custom), custom);
    });

    test('a file without a final newline still gets a clean block', () {
      final out = ConfigTemplates.withFormatterWidth('include: package:flutter_lints/flutter.yaml');
      expect(out, startsWith('include: package:flutter_lints/flutter.yaml\n\n'));
      expect(out, contains('formatter:\n  page_width: 80\n'));
    });

    test('a comment mentioning the formatter is not mistaken for the section', () {
      final out = ConfigTemplates.withFormatterWidth('# formatter: page_width: 120 is not set here\ninclude: x\n');
      expect(out, contains('\nformatter:\n  page_width: 80\n'));
    });
  });

  test('the full analysis_options template pins it too', () {
    for (final veryGood in [false, true]) {
      final out = ConfigTemplates.analysisOptions(veryGoodAnalysis: veryGood);
      expect(out, contains('formatter:\n  page_width: 80\n'));
      expect(out, contains('analyzer:\n  exclude:\n    - build/**'));
    }
  });
}
