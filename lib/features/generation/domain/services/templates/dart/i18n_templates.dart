import 'package:neat/features/generation/domain/services/templates/dart/_template_utils.dart';

/// Templates for the opt-in **slang** internationalisation setup: the slang
/// config, the base (`en`) + `fr` translation files, and a sample language
/// switcher. Codegen (`strings.g.dart`) is produced by `slang_build_runner`
/// during the normal `build_runner` step.
class I18nTemplates {
  I18nTemplates._();

  // ── slang.yaml ────────────────────────────────────────────────────────────
  /// slang config read by the standalone CLI (`dart run slang`). NEAT runs the
  /// CLI rather than `slang_build_runner` because the build_runner integration
  /// clashes with source_gen builders (freezed/json_serializable), throwing an
  /// `InvalidOutputException` on `strings.g.dart`.
  ///
  /// [baseLocale] must be one of the locales actually scaffolded (see
  /// [baseTranslations]/[frTranslations]) — defaults to `en` to match NEAT's
  /// long-standing default, but the caller picks `fr` when English wasn't
  /// selected (see ArchitectureState.i18nLocales).
  static String slangConfig({String baseLocale = 'en'}) => '''base_locale: $baseLocale
fallback_strategy: base_locale
input_directory: lib/i18n
input_file_pattern: .i18n.json
output_directory: lib/i18n
output_file_name: strings.g.dart
''';

  // ── lib/i18n/en.i18n.json (base locale) ───────────────────────────────────
  static String baseTranslations(String featureName) {
    final key = camel(featureName);
    final p = pascal(featureName);
    return '''{
  "appName": "My App",
  "hello": "Hello",
  "language": "Language",
  "$key": {
    "title": "$p",
    "greeting": "Welcome to your app"
  }
}
''';
  }

  // ── lib/i18n/fr.i18n.json ─────────────────────────────────────────────────
  static String frTranslations(String featureName) {
    final key = camel(featureName);
    return '''{
  "appName": "Mon application",
  "hello": "Bonjour",
  "language": "Langue",
  "$key": {
    "title": "Accueil",
    "greeting": "Bienvenue dans votre application"
  }
}
''';
  }

  // ── core/i18n/locale_store.dart (persistence) ─────────────────────────────
  /// Persists the chosen locale in shared_preferences so it survives restarts.
  static String localeStore({required String packageName}) =>
      '''import 'package:shared_preferences/shared_preferences.dart';
import 'package:$packageName/i18n/strings.g.dart';

/// Persists the user's language choice across restarts.
///
/// Call [init] once at start-up (before `runApp`): it applies the saved locale,
/// or falls back to the device locale. Switch language with [setLocale] (never
/// call `LocaleSettings.setLocale` directly, or the choice won't be saved).
abstract final class LocaleStore {
  static const _key = 'app_locale';

  /// Applies the persisted locale, or the device locale if none was saved.
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved != null) {
      LocaleSettings.setLocaleRaw(saved);
    } else {
      LocaleSettings.useDeviceLocale();
    }
  }

  /// Applies [locale] and persists it.
  static Future<void> setLocale(AppLocale locale) async {
    LocaleSettings.setLocale(locale);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, locale.languageTag);
  }
}
''';

  // ── core/i18n/language_switcher.dart ──────────────────────────────────────
  static String languageSwitcher({required String packageName}) =>
      '''import 'package:flutter/material.dart';
import 'package:$packageName/core/i18n/locale_store.dart';
import 'package:$packageName/i18n/strings.g.dart';

/// A compact language picker. Switching persists the choice via [LocaleStore];
/// [TranslationProvider] rebuilds the UI, so `context.t` updates everywhere.
class LanguageSwitcher extends StatelessWidget {
  const LanguageSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<AppLocale>(
      icon: const Icon(Icons.language),
      initialValue: TranslationProvider.of(context).locale,
      onSelected: LocaleStore.setLocale,
      itemBuilder: (context) => AppLocale.values
          .map(
            (locale) => PopupMenuItem<AppLocale>(
              value: locale,
              child: Text(locale.languageTag.toUpperCase()),
            ),
          )
          .toList(),
    );
  }
}
''';
}
