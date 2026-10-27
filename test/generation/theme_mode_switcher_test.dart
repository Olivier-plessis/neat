import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:neat/features/architecture/domain/models/architecture_state.dart';
import 'package:neat/features/feature_gen/domain/usecases/generate_feature_usecase.dart';
import 'package:neat/features/generation/domain/services/feature_scaffolder.dart';
import 'package:neat/features/generation/domain/services/templates/dart/i18n_templates.dart';
import 'package:neat/features/generation/domain/services/templates/dart/presentation_templates.dart';
import 'package:neat/features/generation/domain/usecases/writers/core_package_writer.dart';
import 'package:neat/features/generation/domain/usecases/writers/feature_writer.dart';
import 'package:neat/features/generation/domain/usecases/writers/theme_writer.dart';
import 'package:neat/features/theme_engine/domain/models/theme_engine_state.dart';
import 'package:neat/features/theme_engine/domain/services/theme_templates.dart';

/// The generated `ThemeModeSwitcher`: a picker for the theme mode (light, dark,
/// the device's) that sits next to `LanguageSwitcher`. It holds no state — the
/// page gives it the mode and what to do with a choice — so `core`, which does
/// not depend on Riverpod, can hold it.
void main() {
  group('the widget', () {
    final english = ThemeTemplates.themeModeSwitcher();
    final translated = ThemeTemplates.themeModeSwitcher(i18nPackage: 'shop');

    for (final (name, source) in [
      ('English', english),
      ('translated', translated),
    ]) {
      group(name, () {
        test('holds no state, and no state manager', () {
          expect(
            source,
            contains('class ThemeModeSwitcher extends StatelessWidget'),
          );
          expect(source, contains('final ThemeMode mode;'));
          expect(source, contains('final ValueChanged<ThemeMode> onChanged;'));
          expect(source, contains('required this.mode,'));
          expect(source, contains('required this.onChanged,'));
          expect(source, isNot(contains("import 'package:hooks_riverpod")));
          expect(source, isNot(contains("import 'package:flutter_riverpod")));
          expect(source, isNot(contains("import 'package:riverpod")));
          expect(source, isNot(contains('flutter_bloc')));
        });

        test(
          'is a popup of the three modes, light then dark then the device',
          () {
            expect(source, contains('PopupMenuButton<ThemeMode>('));
            expect(
              source,
              contains(
                'static const _order = [ThemeMode.light, ThemeMode.dark, ThemeMode.system];',
              ),
            );
            expect(source, contains('initialValue: mode,'));
            expect(source, contains('onSelected: onChanged,'));
            expect(source, contains('for (final each in _order)'));
          },
        );

        test(
          'shows the mode being worn on the button, and an icon on each item',
          () {
            expect(source, contains('icon: Icon(_icon(mode)),'));
            expect(source, contains('Icon(_icon(each), size: 20),'));
            expect(
              source,
              contains('ThemeMode.light => Icons.light_mode_outlined,'),
            );
            expect(
              source,
              contains('ThemeMode.dark => Icons.dark_mode_outlined,'),
            );
            expect(
              source,
              contains('ThemeMode.system => Icons.brightness_auto_outlined,'),
            );
          },
        );

        test('shows how to wire it to the generated controller', () {
          expect(source, contains('ref.watch(themeModeControllerProvider)'));
          expect(
            source,
            contains('ref.read(themeModeControllerProvider.notifier).set'),
          );
        });
      });
    }

    test('without i18n (or with a CSV one) the modes are named in English', () {
      expect(english, contains("ThemeMode.light => 'Light',"));
      expect(english, contains("ThemeMode.dark => 'Dark',"));
      expect(english, contains("ThemeMode.system => 'System',"));
      expect(english, isNot(contains('strings.g.dart')));
      expect(english, isNot(contains('context.t')));
    });

    test('with i18n the names come from the generated keys', () {
      expect(
        translated,
        contains("import 'package:shop/i18n/strings.g.dart';"),
      );
      expect(
        translated,
        contains('ThemeMode.light => context.t.themeMode.light,'),
      );
      expect(
        translated,
        contains('ThemeMode.dark => context.t.themeMode.dark,'),
      );
      expect(
        translated,
        contains('ThemeMode.system => context.t.themeMode.system,'),
      );
      expect(translated, isNot(contains("=> 'Light'")));
    });

    test('under packageSplit the keys are in core', () {
      expect(
        ThemeTemplates.themeModeSwitcher(i18nPackage: 'core'),
        contains("import 'package:core/i18n/strings.g.dart';"),
      );
    });
  });

  group('the translations', () {
    final byLocale = <String, Map<String, dynamic>>{
      'en':
          jsonDecode(I18nTemplates.baseTranslations('user_profile'))
              as Map<String, dynamic>,
      'fr':
          jsonDecode(I18nTemplates.frTranslations('user_profile'))
              as Map<String, dynamic>,
      'de':
          jsonDecode(I18nTemplates.deTranslations('user_profile'))
              as Map<String, dynamic>,
      'it':
          jsonDecode(I18nTemplates.itTranslations('user_profile'))
              as Map<String, dynamic>,
      'es':
          jsonDecode(I18nTemplates.spTranslations('user_profile'))
              as Map<String, dynamic>,
    };

    test('every locale NEAT ships names the three modes', () {
      for (final entry in byLocale.entries) {
        final modes = entry.value['themeMode'] as Map<String, dynamic>?;
        expect(modes, isNotNull, reason: entry.key);
        expect(modes!.keys.toSet(), {
          'light',
          'dark',
          'system',
        }, reason: entry.key);
        for (final name in modes.values) {
          expect(name, isA<String>(), reason: entry.key);
          expect((name as String).trim(), isNotEmpty, reason: entry.key);
        }
      }
    });

    test('in each language', () {
      Map<String, dynamic> modes(String locale) =>
          byLocale[locale]!['themeMode'] as Map<String, dynamic>;
      expect(modes('en'), {
        'light': 'Light',
        'dark': 'Dark',
        'system': 'System',
      });
      expect(modes('fr'), {
        'light': 'Clair',
        'dark': 'Sombre',
        'system': 'Système',
      });
      expect(modes('de'), {
        'light': 'Hell',
        'dark': 'Dunkel',
        'system': 'System',
      });
      expect(modes('it'), {
        'light': 'Chiaro',
        'dark': 'Scuro',
        'system': 'Sistema',
      });
      expect(modes('es'), {
        'light': 'Claro',
        'dark': 'Oscuro',
        'system': 'Sistema',
      });
    });

    test('are a group of their own, next to the language and the feature', () {
      for (final entry in byLocale.entries) {
        expect(
          entry.value.keys,
          containsAll([
            'appName',
            'hello',
            'language',
            'themeMode',
            'userProfile',
          ]),
          reason: entry.key,
        );
      }
    });
  });

  group('where it is written', () {
    late Directory dir;
    setUp(() async {
      dir = await Directory.systemTemp.createTemp('neat_switcher_');
      addTearDown(() => dir.delete(recursive: true));
    });

    Future<void> theme({
      bool riverpod = true,
      bool bloc = false,
      String? core,
      String? i18nStrings,
    }) => ThemeWriter.write(
      projectDir: dir,
      lib: '${dir.path}/lib',
      packageName: 'shop',
      hasRiverpod: riverpod,
      useAnnotations: true,
      hasBloc: bloc,
      useCubit: false,
      hasFlexColorScheme: false,
      useScreenUtil: false,
      theme: const ThemeEngineState(),
      corePackageName: core,
      i18nStringsPackage: i18nStrings,
    );

    File inApp() => File('${dir.path}/lib/core/theme/theme_mode_switcher.dart');
    File inCore() => File(
      '${dir.path}/packages/core/lib/core/theme/theme_mode_switcher.dart',
    );

    test('a Riverpod app has it next to the controller', () async {
      await theme();

      expect(inApp().existsSync(), isTrue);
      expect(
        File(
          '${dir.path}/lib/core/theme/theme_mode_controller.dart',
        ).existsSync(),
        isTrue,
      );
      expect(inApp().readAsStringSync(), isNot(contains('strings.g.dart')));
    });

    test('with i18n it names the modes with the app\'s keys', () async {
      await theme(i18nStrings: 'shop');

      expect(
        inApp().readAsStringSync(),
        contains("import 'package:shop/i18n/strings.g.dart';"),
      );
    });

    test(
      'a project split into packages has it in core, not in the app',
      () async {
        await theme(core: 'core', i18nStrings: 'shop');

        expect(inApp().existsSync(), isFalse);
      },
    );

    test(
      'a Bloc or Cubit app has none: nothing to hand it a mode with set()',
      () async {
        await theme(riverpod: false, bloc: true);

        expect(inApp().existsSync(), isFalse);
      },
    );

    Future<void> core({required bool keys}) => CorePackageWriter.write(
      dir,
      'core',
      featureName: 'home',
      httpClient: 'dio',
      hasI18n: keys,
      hasI18nKeys: keys,
    );

    test('the core package has it, with the keys when it has them', () async {
      await core(keys: true);

      expect(inCore().existsSync(), isTrue);
      expect(
        inCore().readAsStringSync(),
        contains("import 'package:core/i18n/strings.g.dart';"),
      );
      expect(
        inCore().readAsStringSync(),
        contains('context.t.themeMode.light'),
      );
    });

    test('and in English without them (no i18n, or a CSV one)', () async {
      await core(keys: false);

      expect(inCore().existsSync(), isTrue);
      expect(inCore().readAsStringSync(), isNot(contains('strings.g.dart')));
      expect(
        inCore().readAsStringSync(),
        contains("ThemeMode.light => 'Light',"),
      );
    });
  });

  group('the pages', () {
    String page({
      bool switcher = true,
      bool i18n = false,
      bool list = true,
      bool annotations = true,
      bool riverpod = true,
      bool bloc = false,
      bool cubit = false,
      bool crud = false,
      String? core,
    }) => PresentationTemplates.featurePage(
      featureName: 'recipe',
      packageName: 'demo',
      hasRiverpod: riverpod,
      useAnnotations: annotations,
      hasBloc: bloc,
      useCubit: cubit,
      dataList: list,
      i18n: i18n,
      includeCrudUi: crud,
      corePackageName: core,
      themeSwitcher: switcher,
    );

    for (final (name, list) in [('list', true), ('plain', false)]) {
      group('the Riverpod $name page', () {
        test('has the switcher, wired to the controller', () {
          final out = page(list: list);

          expect(out, contains('ThemeModeSwitcher('));
          expect(
            out,
            contains('mode: ref.watch(themeModeControllerProvider),'),
          );
          expect(
            out,
            contains(
              'onChanged: ref.read(themeModeControllerProvider.notifier).set,',
            ),
          );
          expect(
            out,
            contains(
              "import 'package:demo/core/theme/theme_mode_switcher.dart';",
            ),
          );
          expect(
            out,
            contains(
              "import 'package:demo/core/theme/theme_mode_controller.dart';",
            ),
          );
        });

        test(
          'no longer has the one-tap toggle, nor the brightness it read',
          () {
            final out = page(list: list);

            expect(out, isNot(contains('.toggle()')));
            expect(out, isNot(contains('isDark')));
            expect(out, isNot(contains('IconButton(')));
          },
        );

        test('keeps the one-tap toggle where the project has no switcher', () {
          final out = page(list: list, switcher: false);

          expect(out, contains('.toggle()'));
          expect(
            out,
            contains(
              'final isDark = Theme.of(context).brightness == Brightness.dark;',
            ),
          );
          expect(out, isNot(contains('ThemeModeSwitcher')));
          expect(out, isNot(contains('theme_mode_switcher.dart')));
        });

        test('reads it from core under packageSplit', () {
          final out = page(list: list, core: 'core');

          expect(
            out,
            contains(
              "import 'package:core/core/theme/theme_mode_switcher.dart';",
            ),
          );
          expect(
            out,
            isNot(contains('package:demo/core/theme/theme_mode_switcher.dart')),
          );
        });

        test('puts the language switcher before it', () {
          final out = page(list: list, i18n: true);

          expect(out, contains('const LanguageSwitcher(),'));
          expect(
            out.indexOf('LanguageSwitcher(),'),
            lessThan(out.indexOf('ThemeModeSwitcher(')),
          );
        });
      });
    }

    test('the list page keeps its add button before the switchers', () {
      final out = page(crud: true, i18n: true);

      expect(out.indexOf('IconButton('), isNonNegative);
      expect(
        out.indexOf('IconButton('),
        lessThan(out.indexOf('LanguageSwitcher(')),
      );
      expect(
        out.indexOf('LanguageSwitcher('),
        lessThan(out.indexOf('ThemeModeSwitcher(')),
      );
    });

    test('manual Riverpod has it too', () {
      final out = page(list: false, annotations: false);

      expect(out, contains('ThemeModeSwitcher('));
      expect(
        out,
        contains(
          'onChanged: ref.read(themeModeControllerProvider.notifier).set,',
        ),
      );
    });

    test('Bloc and Cubit pages keep their brightness toggle', () {
      final bloc = page(riverpod: false, bloc: true, list: false);
      final cubit = page(riverpod: false, cubit: true, list: false);

      expect(bloc, contains('BrightnessToggled'));
      expect(cubit, contains('context.read<BrightnessCubit>().toggle()'));
      for (final out in [bloc, cubit]) {
        expect(out, isNot(contains('ThemeModeSwitcher')));
        expect(out, isNot(contains('theme_mode_switcher.dart')));
      }
    });
  });

  group('a feature written to disk', () {
    late Directory dir;
    setUp(() async {
      dir = await Directory.systemTemp.createTemp('neat_switcher_feature_');
      addTearDown(() => dir.delete(recursive: true));
    });

    String pageOf(String lib) => File(
      '$lib/features/orders/presentation/pages/orders_page.dart',
    ).readAsStringSync();

    test('the scaffolder passes the switcher on to the page', () async {
      for (final switcher in [true, false]) {
        final lib = '${dir.path}/scaffolder_$switcher/lib';
        await const FeatureScaffolder().writeFeature(
          lib: lib,
          featureName: 'orders',
          packageName: 'demo',
          isFeatureFirst: true,
          mirrorTestStructure: false,
          hasRiverpod: true,
          hasBloc: false,
          useCubit: false,
          useAnnotations: true,
          hasGoRouter: true,
          hasGoRouterBuilder: false,
          hasHttpClient: true,
          httpClient: 'dio',
          hasFreezed: true,
          hasJsonSerializable: true,
          themeSwitcher: switcher,
        );

        final page = pageOf(lib);
        expect(page.contains('ThemeModeSwitcher('), switcher);
        expect(page.contains('.toggle()'), !switcher);
      }
    });

    test(
      'the first feature of a project gets it when the project has Riverpod',
      () async {
        final lib = '${dir.path}/writer/lib';
        await FeatureWriter.write(
          lib: lib,
          featureName: 'orders',
          packageName: 'demo',
          architecture: const ArchitectureState(),
          hasRiverpod: true,
          hasBloc: false,
          useCubit: false,
          useAnnotations: true,
          hasGoRouter: true,
          hasGoRouterBuilder: false,
          hasHttpClient: true,
          httpClient: 'dio',
          hasFreezed: true,
          hasJsonSerializable: true,
          themeSwitcher: true,
        );

        expect(pageOf(lib), contains('ThemeModeSwitcher('));
      },
    );
  });

  group('the Workshop', () {
    late Directory dir;
    setUp(() async {
      dir = await Directory.systemTemp.createTemp('neat_workshop_switcher_');
      addTearDown(() => dir.delete(recursive: true));
    });

    bool has({String? core}) => GenerateFeatureUsecase.hasThemeSwitcher(
      projectPath: dir.path,
      corePackageName: core,
    );

    test('a project with the switcher gets it in its new pages', () async {
      expect(has(), isFalse);
      await File(
        '${dir.path}/lib/core/theme/theme_mode_switcher.dart',
      ).create(recursive: true);

      expect(has(), isTrue);
    });

    test('a project generated before it keeps the toggle', () async {
      await File(
        '${dir.path}/lib/core/theme/theme_mode_controller.dart',
      ).create(recursive: true);

      expect(has(), isFalse);
    });

    test(
      'a split project is asked in its core package, not in the app',
      () async {
        await File(
          '${dir.path}/lib/core/theme/theme_mode_switcher.dart',
        ).create(recursive: true);
        expect(
          has(core: 'core'),
          isFalse,
          reason: 'the app\'s copy is not the one',
        );

        await File(
          '${dir.path}/packages/core/lib/core/theme/theme_mode_switcher.dart',
        ).create(recursive: true);
        expect(has(core: 'core'), isTrue);
      },
    );
  });
}
