import 'dart:io';

import 'package:neat/features/architecture/domain/models/architecture_state.dart';
import 'package:neat/features/generation/domain/services/i18n_importer.dart';
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
}
