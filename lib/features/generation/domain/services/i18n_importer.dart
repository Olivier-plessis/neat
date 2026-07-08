import 'dart:convert';
import 'dart:io';

/// Wires an uploaded **compact CSV** translation file into a slang project and
/// runs the slang CLI. A compact CSV holds every locale in one file:
///
/// ```csv
/// key,en,fr
/// appName,My App,Mon application
/// home.title,Home,Accueil
/// ```
///
/// Shared by the generation flow (wizard upload) and the Workshop (import into
/// an existing project), so both behave identically.
class I18nImporter {
  const I18nImporter();

  /// The locale columns of a compact CSV header (everything after the key
  /// column, excluding slang's `(comments)` column). `key,en,fr` →
  /// `['en', 'fr']`; `key,(comments),en,fr` → `['en', 'fr']`. Empty when it
  /// can't be parsed.
  static List<String> parseLocales(String csvContent) {
    final firstLine = const LineSplitter()
        .convert(csvContent)
        .firstWhere((l) => l.trim().isNotEmpty, orElse: () => '');
    final cols = firstLine.split(',').map((c) => c.trim()).toList();
    if (cols.length <= 1) return const [];
    return cols.sublist(1).where((c) => c.isNotEmpty && !c.startsWith('(')).toList();
  }

  /// slang.yaml pointing at the compact CSV. [baseLocale] must be one of the
  /// CSV's locale columns.
  ///
  /// `string_interpolation: braces` is required here — slang's own default
  /// is Dart-style `$variable` interpolation, so without it a CSV cell like
  /// `You have {n} messages` is copied verbatim (literal `{n}` at runtime)
  /// instead of being recognized as the plural/placeholder variable.
  static String slangCsvConfig(String baseLocale) => '''base_locale: $baseLocale
fallback_strategy: base_locale
input_directory: lib/i18n
input_file_pattern: .i18n.csv
output_directory: lib/i18n
output_file_name: strings.g.dart
string_interpolation: braces
''';

  /// Places [csvContent] as the single source of translations under
  /// `lib/i18n/strings.i18n.csv`, points slang.yaml at it (base locale = the
  /// first CSV column), removes any leftover default JSON files, and regenerates
  /// `strings.g.dart` via the slang CLI. Returns the detected locales.
  Future<List<String>> importCsv({
    required String projectPath,
    required String csvContent,
    void Function(String)? onLog,
  }) async {
    final log = onLog ?? (_) {};
    final locales = parseLocales(csvContent);
    final baseLocale = locales.isEmpty ? 'en' : locales.first;

    final i18nDir = Directory('$projectPath/lib/i18n')..createSync(recursive: true);
    await File('${i18nDir.path}/strings.i18n.csv').writeAsString(csvContent);

    // The CSV is the single source — drop the default JSON scaffold if present.
    for (final name in const ['en.i18n.json', 'fr.i18n.json']) {
      final file = File('${i18nDir.path}/$name');
      if (file.existsSync()) file.deleteSync();
    }

    await File('$projectPath/slang.yaml').writeAsString(slangCsvConfig(baseLocale));

    log('[▶] Importing translations (CSV) + regenerating (dart run slang)...');
    await runSlang(Directory(projectPath), log);
    return locales;
  }

  /// Runs `dart run slang` to (re)generate `lib/i18n/strings.g.dart`.
  /// Best-effort: a failure is logged, not fatal.
  Future<void> runSlang(Directory projectDir, void Function(String) onLog) async {
    final result = await Process.run(
      'dart',
      ['run', 'slang'],
      workingDirectory: projectDir.path,
      environment: {
        ...Platform.environment,
        'PATH': '${Platform.environment['PATH']}:/usr/local/bin:/opt/homebrew/bin',
      },
    );
    if (result.stdout.toString().trim().isNotEmpty) {
      onLog(result.stdout.toString().trim());
    }
    if (result.exitCode != 0) {
      final stderr = result.stderr.toString().trim();
      if (stderr.isNotEmpty) onLog('[⚠] $stderr');
      onLog('[ℹ] Run i18n codegen manually: dart run slang');
      return;
    }
    onLog('[✓] i18n codegen complete.');
  }
}
