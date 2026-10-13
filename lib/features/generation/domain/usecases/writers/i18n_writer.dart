import 'dart:convert';
import 'dart:io';

import 'package:neat/features/architecture/domain/models/architecture_state.dart';
import 'package:neat/features/generation/domain/services/i18n_importer.dart';
import 'package:neat/features/generation/domain/services/templates/dart/_template_utils.dart';
import 'package:neat/features/generation/domain/services/templates/dart/i18n_templates.dart';
import 'package:neat/features/generation/domain/usecases/writers/generation_io.dart';

/// Writes the opt-in slang i18n setup (config + translations + LocaleStore +
/// LanguageSwitcher) — split out of `LaunchGenerationUsecase`'s
/// `_buildScaffold` (see ROADMAP.md for the per-domain writer split).
///
/// packageSplit: single-sourced in the core package, same reasoning as
/// theme_mode_controller.dart — a split feature's page reads `context.t`/
/// `LanguageSwitcher` from there (see PresentationTemplates), so the app must
/// not keep its own separate copy (that would be a feature→app import if the
/// feature read the app's copy instead — the exact cycle packageSplit exists
/// to avoid).
abstract final class I18nWriter {
  static Future<void> write({
    required Directory projectDir,
    required String lib,
    required ArchitectureState architecture,
    required String featureName,
    required String packageName,
    required bool i18nFromCsv,
    String? corePackageName,
  }) async {
    final i18nRoot = corePackageName != null
        ? '${projectDir.path}/packages/$corePackageName'
        : projectDir.path;
    final i18nLib = corePackageName != null ? '$i18nRoot/lib' : lib;
    final i18nPackageName = corePackageName ?? packageName;
    if (i18nFromCsv) {
      // The user uploaded a compact CSV → it is the single source of truth.
      final csv = File(architecture.i18nCsvPath).readAsStringSync();
      final base = I18nImporter.parseLocales(csv).firstOrNull ?? 'en';
      await writeFile(
        '$i18nRoot/slang.yaml',
        I18nImporter.slangCsvConfig(base),
      );
      await writeFile('$i18nLib/i18n/strings.i18n.csv', csv);
    } else {
      // English preferred as the base locale when picked (matches NEAT's
      // long-standing default); otherwise fall back to whatever is selected
      // (at least one is always guaranteed — see ArchitectureNotifier.
      // toggleI18nLocale).
      final locales = architecture.i18nLocales;
      final baseLocale = locales.contains('en') ? 'en' : locales.first;
      await writeFile(
        '$i18nRoot/slang.yaml',
        I18nTemplates.slangConfig(baseLocale: baseLocale),
      );
      // Non-namespace mode → files are named `<locale>.i18n.json`.
      const translationsByLocale = <String, String Function(String)>{
        'en': I18nTemplates.baseTranslations,
        'fr': I18nTemplates.frTranslations,
        'de': I18nTemplates.deTranslations,
        'es': I18nTemplates.spTranslations,
        'it': I18nTemplates.itTranslations,
      };
      for (final entry in translationsByLocale.entries) {
        if (locales.contains(entry.key)) {
          await writeFile(
            '$i18nLib/i18n/${entry.key}.i18n.json',
            entry.value(featureName),
          );
        }
      }
    }
    await writeFile(
      '$i18nLib/core/i18n/locale_store.dart',
      I18nTemplates.localeStore(packageName: i18nPackageName),
    );
    await writeFile(
      '$i18nLib/core/i18n/language_switcher.dart',
      I18nTemplates.languageSwitcher(packageName: i18nPackageName),
    );
  }

  /// Adds a feature's `title` / `empty` entries to an **existing** project's
  /// slang sources (the Workshop), so the generated page can read
  /// `context.t.<feature>.title` instead of hardcoding its strings. Returns
  /// whether the keys are in place — false when there is nothing to add them to
  /// (no `*.i18n.json`; or the project imported a compact CSV, whose keys NEAT
  /// doesn't know, same as the launch-time sample page is skipped for a CSV).
  ///
  /// packageSplit: the sources live in the core package. An existing key is
  /// left alone (the user may have translated it). Writes pretty-printed JSON
  /// (2 spaces), the shape NEAT generates in the first place.
  static Future<bool> addFeatureKeys({
    required String projectPath,
    required String featureName,
    String? corePackageName,
  }) async {
    final dir = Directory(
      corePackageName != null
          ? '$projectPath/packages/$corePackageName/lib/i18n'
          : '$projectPath/lib/i18n',
    );
    if (!dir.existsSync()) return false;
    if (File('${dir.path}/strings.i18n.csv').existsSync()) return false;
    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.i18n.json'))
        .toList();
    if (files.isEmpty) return false;
    final key = camel(featureName);
    for (final file in files) {
      final locale = file.uri.pathSegments.last.split('.').first;
      final Object? decoded;
      try {
        decoded = jsonDecode(await file.readAsString());
      } on FormatException {
        return false; // hand-edited into something we can't safely rewrite
      }
      if (decoded is! Map<String, dynamic>) return false;
      final entries = I18nTemplates.featureEntries(featureName, locale);
      final existing = decoded[key];
      if (existing == null) {
        decoded[key] = entries;
      } else if (existing is Map<String, dynamic>) {
        // The key is already a group (hand-written, or a feature of that name):
        // only fill in what the page reads, never overwrite a translation.
        final missing = entries.keys
            .where((k) => !existing.containsKey(k))
            .toList();
        if (missing.isEmpty) continue;
        for (final k in missing) {
          existing[k] = entries[k];
        }
      } else {
        return false; // the key is a plain string — `context.t.$key.title` can't exist
      }
      await file.writeAsString(
        '${const JsonEncoder.withIndent('  ').convert(decoded)}\n',
      );
    }
    return true;
  }
}
