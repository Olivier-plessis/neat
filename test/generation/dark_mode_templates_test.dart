import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:neat/core/contract/neat_contract.dart';
import 'package:neat/features/dependencies/domain/models/pub_package.dart';
import 'package:neat/features/generation/domain/services/templates/agents_md_template.dart';
import 'package:neat/features/generation/domain/services/templates/core_package_templates.dart';
import 'package:neat/features/generation/domain/services/templates/dart/app_templates.dart';
import 'package:neat/features/generation/domain/usecases/writers/pubspec_writer.dart';
import 'package:neat/features/generation/domain/usecases/writers/ui_package_writer.dart';
import 'package:neat/features/theme_engine/domain/models/theme_engine_state.dart';
import 'package:neat/features/theme_engine/domain/services/theme_templates.dart';
import 'package:yaml/yaml.dart';

/// A generated app has a dark mode that works: the neutral colours (page, cards,
/// text, dividers) are read from a theme extension, not from `Palette`
/// constants — a constant stays light when the person goes dark. And the mode
/// the person chose is kept across restarts.

/// The neutrals, as `Palette` names them: constants, so light only.
final _neutralPalette = RegExp(
  r'\bPalette\.(textPrimary|textSecondary|textTertiary|divider|background|'
  r'backgroundAppBar|surface|accent|onAccent)\b',
);

int _hex(String template, String name, {String after = ''}) {
  final from = after.isEmpty ? 0 : template.indexOf(after);
  expect(from, isNonNegative, reason: 'no "$after" in the template');
  final match = RegExp(
    '$name(?: =|:) Color\\(0x([0-9A-Fa-f]{8})\\)',
  ).firstMatch(template.substring(from));
  expect(match, isNotNull, reason: 'no $name after "$after"');
  return int.parse(match!.group(1)!, radix: 16);
}

double _luminance(int argb) {
  double channel(int shift) {
    final v = ((argb >> shift) & 0xFF) / 255;
    return v <= 0.03928
        ? v / 12.92
        : math.pow((v + 0.055) / 1.055, 2.4) as double;
  }

  return 0.2126 * channel(16) + 0.7152 * channel(8) + 0.0722 * channel(0);
}

/// How readable [text] is on [background], from 1 (invisible) to 21.
double _contrast(int text, int background) {
  final a = _luminance(text);
  final b = _luminance(background);
  return (math.max(a, b) + 0.05) / (math.min(a, b) + 0.05);
}

void main() {
  final extensions = ThemeTemplates.appThemeExtensions(packageName: 'shop');
  final palette = ThemeTemplates.appColor();
  const darkBlock = 'static const AppColors dark = AppColors(';

  group('AppColors', () {
    test('holds the neutrals, not only the brand and the semantic colours', () {
      for (final name in [
        'background',
        'surface',
        'textPrimary',
        'textSecondary',
        'textTertiary',
        'divider',
        'accent',
        'onAccent',
      ]) {
        expect(extensions, contains('required this.$name,'), reason: name);
        expect(extensions, contains('final Color $name;'), reason: name);
        expect(extensions, contains('Color? $name,'), reason: name);
        expect(
          extensions,
          contains('$name: $name ?? this.$name,'),
          reason: '$name is copied',
        );
        expect(
          extensions,
          contains('$name: mix($name, other.$name),'),
          reason: '$name is lerped',
        );
      }
    });

    test('light is the palette the project always had', () {
      for (final name in [
        'background',
        'surface',
        'textPrimary',
        'textSecondary',
        'textTertiary',
        'divider',
        'accent',
        'onAccent',
      ]) {
        expect(extensions, contains('$name: Palette.$name,'), reason: name);
      }
    });

    test(
      'dark turns the neutrals down and keeps the brand and the semantics',
      () {
        final block = extensions.substring(extensions.indexOf(darkBlock));
        for (final name in [
          'background',
          'surface',
          'textPrimary',
          'textSecondary',
          'textTertiary',
          'divider',
          'accent',
          'onAccent',
        ]) {
          expect(
            block,
            contains(RegExp('$name: Color\\(0x[0-9A-Fa-f]{8}\\)')),
            reason: '$name has a colour of its own in dark',
          );
        }
        for (final name in [
          'primary',
          'primaryDim',
          'primaryLight',
          'success',
          'warning',
          'error',
          'errorContainer',
        ]) {
          expect(block, contains('$name: Palette.$name,'), reason: name);
        }
      },
    );

    test('dark: a near-black page, cards a step lighter, near-white text', () {
      final background = _hex(extensions, 'background', after: darkBlock);
      final surface = _hex(extensions, 'surface', after: darkBlock);
      final text = _hex(extensions, 'textPrimary', after: darkBlock);

      expect(_luminance(background), lessThan(0.02));
      expect(_luminance(surface), lessThan(0.05));
      expect(_luminance(surface), greaterThan(_luminance(background)));
      expect(_luminance(text), greaterThan(0.8));
    });

    test('what is written can be read, in the light and in the dark', () {
      for (final (name, from) in [('light', ''), ('dark', darkBlock)]) {
        int pick(String field) => from.isEmpty
            ? _hex(palette, 'static const Color $field')
            : _hex(extensions, field, after: from);
        final background = pick('background');
        final surface = pick('surface');
        expect(
          _contrast(pick('textPrimary'), background),
          greaterThan(7),
          reason: name,
        );
        expect(
          _contrast(pick('textPrimary'), surface),
          greaterThan(7),
          reason: name,
        );
        expect(
          _contrast(pick('textSecondary'), background),
          greaterThan(4),
          reason: name,
        );
        expect(
          _contrast(pick('textSecondary'), surface),
          greaterThan(4),
          reason: name,
        );
        expect(
          _contrast(pick('onAccent'), pick('accent')),
          greaterThan(7),
          reason: '$name accent',
        );
        expect(
          pick('surface'),
          isNot(pick('background')),
          reason: '$name: a card shows',
        );
      }
    });

    test(
      'is read with context.colors, which falls back to the light colours',
      () {
        expect(extensions, contains('AppColors get colors =>'));
        expect(
          extensions,
          contains('Theme.of(this).extension<AppColors>() ?? AppColors.light'),
        );
        expect(extensions, isNot(contains('appColors')));
      },
    );

    test('says that the Palette neutrals are the light ones', () {
      expect(palette, contains('the LIGHT values'));
      expect(palette, contains('context.colors'));
    });
  });

  group('the components', () {
    final components = {
      'AppButton': ThemeTemplates.appButtonComponent(packageName: 'shop'),
      'AppCard': ThemeTemplates.appCardComponent(packageName: 'shop'),
      'AppTextField': ThemeTemplates.appTextFieldComponent(packageName: 'shop'),
    };

    components.forEach((name, source) {
      test('$name reads its neutrals from context.colors', () {
        expect(source, isNot(contains(_neutralPalette)));
        expect(source, contains('context.colors.'));
        expect(
          source,
          contains(
            "import 'package:shop/core/theme/app_theme_extensions.dart';",
          ),
        );
      });
    });

    test('AppCard names no Palette colour, so it does not import them', () {
      expect(components['AppCard'], isNot(contains('Palette.')));
      expect(
        components['AppCard'],
        isNot(contains('core/theme/constant/constant.dart')),
      );
    });

    test('AppButton and AppTextField keep the brand and the error colours', () {
      expect(components['AppButton'], contains('Palette.primary'));
      expect(components['AppButton'], contains('Palette.error'));
      expect(components['AppTextField'], contains('Palette.error'));
      expect(
        components['AppButton'],
        contains("import 'package:shop/core/theme/constant/constant.dart';"),
      );
      expect(
        components['AppTextField'],
        contains("import 'package:shop/core/theme/constant/constant.dart';"),
      );
    });

    test(
      'AppButton: the text on a destructive button is white, in both modes',
      () {
        expect(
          components['AppButton'],
          contains(
            'AppButtonVariant.destructive => styled(bg: Palette.error, fg: Palette.onPrimary)',
          ),
        );
      },
    );

    test('AppButton: the secondary one sits on the surface, with a divider', () {
      expect(
        components['AppButton'],
        contains(
          'styled(bg: context.colors.surface, fg: context.colors.textPrimary, border: context.colors.divider)',
        ),
      );
      expect(components['AppButton'], contains('fg: context.colors.onAccent'));
    });
  });

  group('app_theme.dart (basic)', () {
    final theme = ThemeTemplates.appThemeBasic(packageName: 'shop');

    test('is one builder for the two modes', () {
      expect(
        theme,
        contains(
          'static ThemeData get light => _build(Brightness.light, AppColors.light);',
        ),
      );
      expect(
        theme,
        contains(
          'static ThemeData get dark => _build(Brightness.dark, AppColors.dark);',
        ),
      );
      expect(
        theme,
        contains('static ThemeData _build(Brightness brightness, AppColors c)'),
      );
      expect(theme, contains('brightness: brightness,'));
      expect(theme, contains('extensions: [c],'));
    });

    test(
      'names no neutral Palette colour: they all come from the extension',
      () {
        expect(theme, isNot(contains(_neutralPalette)));
        for (final source in [
          'scaffoldBackgroundColor: c.background,',
          'foregroundColor: c.textPrimary,',
          'color: c.surface,',
          'fillColor: c.surface,',
          'BorderSide(color: c.divider)',
          'color: c.textSecondary',
          'DividerThemeData(color: c.divider',
          'backgroundColor: c.textPrimary,',
        ]) {
          expect(theme, contains(source), reason: source);
        }
      },
    );

    test('keeps the brand and the error colours as constants', () {
      expect(theme, contains('Palette.primary'));
      expect(theme, contains('Palette.onPrimary'));
      expect(theme, contains('Palette.error'));
    });

    test('writes in the text colour of the mode, whatever the style', () {
      expect(
        theme,
        contains(
          '.apply(bodyColor: c.textPrimary, displayColor: c.textPrimary)',
        ),
      );
    });

    test(
      'the dark scheme takes the neutrals, the light one is the seed\'s',
      () {
        expect(theme, contains('if (brightness == Brightness.dark) {'));
        for (final source in [
          'surface: c.surface,',
          'onSurface: c.textPrimary,',
          'onSurfaceVariant: c.textSecondary,',
          'outlineVariant: c.divider,',
          'surfaceContainerLowest: c.background,',
          'surfaceContainerLow: c.surface,',
          'surfaceContainer: c.surface,',
        ]) {
          expect(theme, contains(source), reason: source);
        }
      },
    );

    test(
      'the old dark theme, derived from light with the scheme\'s surfaces, is gone',
      () {
        expect(theme, isNot(contains('light.copyWith')));
        expect(theme, isNot(contains('surfaceContainerHighest, ')));
        expect(theme, isNot(contains('extensions: const [AppColors.light]')));
      },
    );

    test('without an override, no line assigns the scheme to itself', () {
      expect(theme, isNot(contains('scheme = scheme;')));
      expect(
        theme,
        isNot(contains('scheme = scheme.copyWith(\n      primary:')),
      );
    });

    test('what the person overrode in the Colors tab wins, in both modes', () {
      final overridden = ThemeTemplates.appThemeBasic(
        packageName: 'shop',
        primaryOverrideHex: '0xFF112233',
        outlineOverrideHex: '0xFF445566',
      );

      final neutrals = overridden.indexOf('surfaceContainer: c.surface,');
      final override = overridden.lastIndexOf('scheme = scheme.copyWith(');
      expect(neutrals, isNonNegative);
      expect(override, greaterThan(neutrals), reason: 'applied last');
      expect(overridden, contains('primary: Color(0xFF112233),'));
      expect(overridden, contains('outline: Color(0xFF445566),'));
      // After the `if`, not inside it: it covers the light scheme too.
      expect(
        overridden,
        contains(
          '      );\n    }\n    scheme = scheme.copyWith(\n      primary:',
        ),
      );
    });

    test(
      'responsive: the sizes follow ScreenUtil and the styles are not const',
      () {
        final responsive = ThemeTemplates.appThemeBasic(
          packageName: 'shop',
          useScreenUtil: true,
        );

        expect(
          responsive,
          contains(
            "import 'package:flutter_screenutil/flutter_screenutil.dart';",
          ),
        );
        expect(responsive, contains('fontSize: 14.sp'));
        expect(responsive, isNot(contains('const TextStyle(color: c.')));
      },
    );

    test('the live preview and the generator write the same file', () {
      expect(
        ThemeTemplates.appThemeForState(
          theme: const ThemeEngineState(),
          packageName: 'shop',
        ),
        contains('_build(Brightness.dark, AppColors.dark)'),
      );
    });
  });

  group('app_theme.dart (FlexColorScheme)', () {
    test(
      'the default dark theme wears the dark neutrals, the light one the light',
      () {
        final flex = ThemeTemplates.appThemeFlexColorScheme(
          packageName: 'shop',
        );
        final dark = flex.substring(flex.indexOf('static ThemeData get dark'));

        expect(dark, contains('extensions: const [AppColors.dark]'));
        expect(dark, isNot(contains('AppColors.light')));
        expect(
          flex.substring(0, flex.indexOf('static ThemeData get dark')),
          contains('extensions: const [AppColors.light]'),
        );
      },
    );

    test('a pasted dark config wears the dark neutrals', () {
      final flex = ThemeTemplates.appThemeFlexColorScheme(
        packageName: 'shop',
        customCode: '''
FlexThemeData.light(scheme: FlexScheme.blue);
FlexThemeData.dark(scheme: FlexScheme.blue);
''',
      );
      final dark = flex.substring(flex.indexOf('static ThemeData get dark'));

      expect(dark, contains('extensions: const [AppColors.dark]'));
    });

    test('a pasted light config only: the dark one is derived, so it keeps the '
        'light neutrals of the light scheme it is made of', () {
      final flex = ThemeTemplates.appThemeFlexColorScheme(
        packageName: 'shop',
        customCode: 'FlexThemeData.light(scheme: FlexScheme.blue);',
      );
      final dark = flex.substring(flex.indexOf('static ThemeData get dark'));

      expect(dark, contains('light.copyWith('));
      expect(dark, contains('extensions: const [AppColors.light]'));
    });
  });

  group('ThemeModeController', () {
    final annotated = ThemeTemplates.themeModeControllerRiverpod(
      packageName: 'shop',
    );
    final manual = ThemeTemplates.themeModeControllerRiverpodManual();

    for (final (name, source) in [
      ('annotated', annotated),
      ('manual', manual),
    ]) {
      test('($name) is light until the person chooses', () {
        expect(source, contains('ThemeMode build() => ThemeMode.light;'));
      });

      test(
        '($name) keeps the choice in shared_preferences, by the mode\'s name',
        () {
          expect(
            source,
            contains(
              "import 'package:shared_preferences/shared_preferences.dart';",
            ),
          );
          expect(source, contains("static const _prefsKey = 'theme_mode';"));
          expect(source, contains('prefs.setString(_prefsKey, mode.name)'));
          expect(source, contains('prefs.getString(_prefsKey)'));
        },
      );

      test('($name) loads it at start-up, and falls back to light', () {
        expect(source, contains('Future<void> load() async {'));
        expect(source, contains('(mode) => mode.name == saved,'));
        expect(source, contains('orElse: () => ThemeMode.light,'));
      });

      test('($name) wears a choice at once, even when it cannot be saved', () {
        final set = source.substring(
          source.indexOf('Future<void> set(ThemeMode mode)'),
        );
        expect(set, contains('state = mode;'));
        expect(
          set.indexOf('state = mode;'),
          lessThan(set.indexOf('SharedPreferences.getInstance()')),
        );
        expect(set, contains('} catch (error, stackTrace) {'));
        expect(
          set,
          isNot(contains('rethrow')),
          reason: 'a failed write is logged, not thrown',
        );
        expect(set, contains('AppLogger.w('));
        expect(source, contains("import '../utils/app_logger.dart';"));
      });

      test('($name) keeps toggle() and the three setters, all kept', () {
        expect(source, contains('Future<void> toggle() =>'));
        expect(
          source,
          contains(
            'set(state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light)',
          ),
        );
        expect(
          source,
          contains('Future<void> setLight() => set(ThemeMode.light);'),
        );
        expect(
          source,
          contains('Future<void> setDark() => set(ThemeMode.dark);'),
        );
        expect(
          source,
          contains('Future<void> setSystem() => set(ThemeMode.system);'),
        );
      });
    }

    test('annotated: a keepAlive @Riverpod class with its generated part', () {
      expect(annotated, contains('@Riverpod(keepAlive: true)'));
      expect(
        annotated,
        contains('class ThemeModeController extends _\$ThemeModeController'),
      );
      expect(annotated, contains("part 'theme_mode_controller.g.dart';"));
      expect(
        annotated,
        contains(
          "import 'package:riverpod_annotation/riverpod_annotation.dart';",
        ),
      );
    });

    test('manual: a NotifierProvider, no codegen', () {
      expect(
        manual,
        contains(
          'NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new)',
        ),
      );
      expect(
        manual,
        contains("import 'package:flutter_riverpod/flutter_riverpod.dart';"),
      );
      expect(manual, isNot(contains('part ')));
      expect(manual, isNot(contains('@Riverpod')));
    });
  });

  group('bootstrap', () {
    String bootstrap({
      bool riverpod = true,
      bool onboarding = false,
      String? core,
      bool i18n = false,
    }) => AppTemplates.bootstrap(
      packageName: 'shop',
      hasRiverpod: riverpod,
      useAnnotations: riverpod,
      useEnvied: false,
      isWeb: false,
      hasOnboarding: onboarding,
      hasI18n: i18n,
      corePackageName: core,
    );

    test('loads the theme mode before the first frame', () {
      final out = bootstrap();

      expect(
        out,
        contains(
          'await container.read(themeModeControllerProvider.notifier).load();',
        ),
      );
      expect(
        out.indexOf('themeModeControllerProvider.notifier).load()'),
        lessThan(out.indexOf('runApp(')),
      );
      expect(
        out,
        contains(
          'UncontrolledProviderScope(container: container, child: const App())',
        ),
      );
    });

    test('with onboarding: both flags are loaded, onboarding first', () {
      final out = bootstrap(onboarding: true);

      expect(
        out.indexOf('onboardingSeenProvider.notifier).load()'),
        lessThan(out.indexOf('themeModeControllerProvider.notifier).load()')),
      );
      // One container, not two.
      expect('final container ='.allMatches(out), hasLength(1));
    });

    test('without onboarding: the container is there all the same', () {
      expect(bootstrap(), isNot(contains('onboardingSeenProvider')));
      expect(
        bootstrap(),
        contains(
          'final container = ProviderContainer(observers: [RiverpodObserver()]);',
        ),
      );
    });

    test('imports the controller from the app, or from core when split', () {
      expect(
        bootstrap(),
        contains(
          "import 'package:shop/core/theme/theme_mode_controller.dart';",
        ),
      );
      expect(
        bootstrap(core: 'core'),
        contains(
          "import 'package:core/core/theme/theme_mode_controller.dart';",
        ),
      );
      expect(
        bootstrap(core: 'core'),
        isNot(
          contains(
            "import 'package:shop/core/theme/theme_mode_controller.dart';",
          ),
        ),
      );
    });

    test('the locale and the theme are both restored before runApp', () {
      final out = bootstrap(i18n: true);

      expect(
        out.indexOf('await LocaleStore.init();'),
        lessThan(out.indexOf('runApp(')),
      );
      expect(
        out.indexOf('themeModeControllerProvider.notifier).load()'),
        lessThan(out.indexOf('runApp(')),
      );
    });

    test('a project without Riverpod has no container and no controller', () {
      final out = bootstrap(riverpod: false);

      expect(out, isNot(contains('ProviderContainer')));
      expect(out, isNot(contains('themeModeControllerProvider')));
      expect(out, isNot(contains('theme_mode_controller.dart')));
      expect(out, contains('runApp(const App())'));
    });
  });

  group('shared_preferences', () {
    Map<dynamic, dynamic> depsOf(String content) =>
        (loadYaml(content) as YamlMap)['dependencies'] as YamlMap;
    const base = '''
name: my_app
environment:
  sdk: ^3.12.0
dependencies:
  flutter:
    sdk: flutter
dev_dependencies:
  flutter_test:
    sdk: flutter
''';

    test('the app declares it when it keeps the theme mode', () {
      final out = PubspecWriter.buildPubspecContent(
        base,
        const [],
        addThemePersistence: true,
      );

      expect(depsOf(out), contains('shared_preferences'));
      expect('shared_preferences:'.allMatches(out), hasLength(1));
    });

    test('and not otherwise (a split project keeps it in core)', () {
      expect(
        depsOf(PubspecWriter.buildPubspecContent(base, const [])),
        isNot(contains('shared_preferences')),
      );
    });

    test('once, when slang or onboarding already brought it', () {
      for (final out in [
        PubspecWriter.buildPubspecContent(
          base,
          const [],
          addThemePersistence: true,
          addSlang: true,
        ),
        PubspecWriter.buildPubspecContent(
          base,
          const [],
          addThemePersistence: true,
          addOnboarding: true,
        ),
        PubspecWriter.buildPubspecContent(base, [
          const PubPackage(
            name: 'shared_preferences',
            version: '^2.5.0',
            description: '',
          ),
        ], addThemePersistence: true),
      ]) {
        expect(
          'shared_preferences:'.allMatches(out),
          hasLength(1),
          reason: out,
        );
      }
    });

    test('the core package always declares it', () {
      for (final i18n in [false, true]) {
        final out = CorePackageTemplates.pubspec(
          corePackageName: 'core',
          hasI18n: i18n,
        );

        expect(
          depsOf(out),
          contains('shared_preferences'),
          reason: 'i18n: $i18n',
        );
        expect(
          'shared_preferences:'.allMatches(out),
          hasLength(1),
          reason: 'i18n: $i18n',
        );
      }
    });
  });

  group('the UI package', () {
    test(
      'exports AppColors, so a feature reads context.colors from it',
      () async {
        final dir = await Directory.systemTemp.createTemp('neat_ui_barrel_');
        addTearDown(() => dir.delete(recursive: true));

        await UiPackageWriter.write(
          dir,
          'shop_ui',
          components: {AppComponent.button, AppComponent.card},
          useScreenUtil: false,
        );

        final barrel = File(
          '${dir.path}/packages/shop_ui/lib/shop_ui.dart',
        ).readAsStringSync();
        expect(barrel, contains("export 'core/theme/app_theme.dart';"));
        expect(
          barrel,
          contains("export 'core/theme/app_theme_extensions.dart';"),
        );
        expect(barrel, contains("export 'core/theme/constant/constant.dart';"));
      },
    );
  });

  group('AGENTS.md', () {
    NeatContract contract({
      String stateManagement = 'riverpod',
      String themeApproach = 'customM3',
      bool extractUiPackage = false,
      bool useCubit = false,
    }) => NeatContract(
      projectName: 'shop',
      architecture: 'feature_first',
      stateManagement: stateManagement,
      navigation: 'go_router',
      httpClient: 'dio',
      themeApproach: themeApproach,
      storageStrategy: 'remoteOnly',
      extractUiPackage: extractUiPackage,
      useCubit: useCubit,
    );

    test('tells to read the neutrals from context.colors, and why', () {
      final md = AgentsMdTemplate.generate(contract());

      expect(md, contains('## Theme (light / dark)'));
      expect(md, contains('context.colors.surface'));
      expect(md, contains('stays light in dark mode'));
      expect(md, contains('AppColors.light'));
      expect(md, contains('lib/core/theme/'));
    });

    test('points at the UI package when it is extracted', () {
      final md = AgentsMdTemplate.generate(contract(extractUiPackage: true));

      expect(md, contains('packages/shop_ui/lib/core/theme/'));
    });

    test('Riverpod: the theme mode is a provider, kept across restarts', () {
      final md = AgentsMdTemplate.generate(contract());

      expect(md, contains('themeModeControllerProvider'));
      expect(md, contains('**kept** in shared_preferences'));
      expect(md, contains('load()'));
      expect(md, contains('UncontrolledProviderScope'));
      expect(md, isNot(contains('One `ProviderScope`')));
    });

    test('Bloc: the theme mode is light or dark, and not kept', () {
      final md = AgentsMdTemplate.generate(contract(stateManagement: 'bloc'));

      expect(md, contains('BrightnessCubit'));
      expect(md, contains('**not** kept across restarts'));
      expect(md, isNot(contains('themeModeControllerProvider')));
    });

    test(
      'FlexColorScheme says where the generated components get their colours',
      () {
        final md = AgentsMdTemplate.generate(
          contract(themeApproach: 'flexColorScheme'),
        );

        expect(md, contains('FlexColorScheme project'));
        expect(
          AgentsMdTemplate.generate(contract()),
          isNot(contains('FlexColorScheme project')),
        );
      },
    );
  });
}
