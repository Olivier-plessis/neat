import 'dart:io';

import 'package:neat/features/generation/domain/usecases/writers/generation_io.dart';
import 'package:neat/features/generation/domain/usecases/writers/ui_package_writer.dart';
import 'package:neat/features/theme_engine/domain/models/theme_engine_state.dart';
import 'package:neat/features/theme_engine/domain/services/theme_templates.dart';

/// Writes the theme system: constants/typography/app_theme, opt-in
/// components, the extracted `<ui>` package (if any), Widgetbook, and the
/// app-level theme-mode controller (Riverpod/Bloc/Cubit) — split out of
/// `LaunchGenerationUsecase` (see ROADMAP.md for the per-domain writer split).
abstract final class ThemeWriter {
  static Future<void> write({
    required Directory projectDir,
    required String lib,
    required String packageName,
    required bool hasRiverpod,
    required bool useAnnotations,
    required bool hasBloc,
    required bool useCubit,
    required bool hasFlexColorScheme,
    required bool useScreenUtil,
    required ThemeEngineState theme,
    String? uiPackage,
    String? flexVersion,
    // Set when packageSplit is on: theme_mode_controller.dart is written into
    // the shared core package instead (see CorePackageWriter) — the app must
    // not keep its own separate copy, or the app shell and a split feature
    // page's toggle would watch two different provider instances.
    String? corePackageName,
  }) async {
    // When extracted, theme + tokens + components live in packages/<ui>/lib;
    // their imports target <ui> instead of the app. State (theme mode / bloc)
    // always stays in the app.
    final themePkg = uiPackage ?? packageName;
    final themeLib = uiPackage != null
        ? '${projectDir.path}/packages/$uiPackage/lib'
        : lib;
    final t = '$themeLib/core/theme';

    final useFlexColorScheme =
        hasFlexColorScheme || theme.approach == ThemeApproach.flexColorScheme;

    // constant/
    await writeFile(
      '$t/constant/constant.dart',
      ThemeTemplates.constantBarrel(useScreenUtil: useScreenUtil),
    );
    await writeFile(
      '$t/constant/app_color.dart',
      ThemeTemplates.appColor(
        seedHex: theme.seedColorHex,
        accentHex: theme.accentColorHex,
        errorHex: theme.destructiveColorHex,
      ),
    );
    await writeFile(
      '$t/constant/app_gap.dart',
      ThemeTemplates.appGap(useScreenUtil: useScreenUtil),
    );

    // typography/
    await writeFile(
      '$t/typography/typography.dart',
      ThemeTemplates.typographyBarrel(
        packageName: themePkg,
        useScreenUtil: useScreenUtil,
      ),
    );
    await writeFile(
      '$t/typography/font_size.dart',
      ThemeTemplates.fontSize(theme.textStyles, useScreenUtil: useScreenUtil),
    );
    await writeFile(
      '$t/typography/font_weight.dart',
      ThemeTemplates.fontWeight(theme.fontFamily),
    );
    await writeFile(
      '$t/typography/text_style.dart',
      ThemeTemplates.textStyle(theme.textStyles),
    );

    // app_theme_extensions.dart
    await writeFile(
      '$t/app_theme_extensions.dart',
      ThemeTemplates.appThemeExtensions(packageName: themePkg),
    );

    // app_theme.dart
    await writeFile(
      '$t/app_theme.dart',
      ThemeTemplates.appThemeForState(
        theme: theme,
        packageName: themePkg,
        forceFlex: useFlexColorScheme,
        useScreenUtil: useScreenUtil,
      ),
    );

    // components/ (opt-in design-system components)
    for (final c in theme.components) {
      final content = switch (c) {
        AppComponent.button => ThemeTemplates.appButtonComponent(
          packageName: themePkg,
        ),
        AppComponent.card => ThemeTemplates.appCardComponent(
          packageName: themePkg,
        ),
        AppComponent.textField => ThemeTemplates.appTextFieldComponent(
          packageName: themePkg,
        ),
      };
      await writeFile('$themeLib/components/${c.fileName}', content);
    }

    // <app>_ui package scaffolding (pubspec + public barrel).
    if (uiPackage != null) {
      await UiPackageWriter.write(
        projectDir,
        uiPackage,
        components: theme.components,
        useScreenUtil: useScreenUtil,
        flexVersion: useFlexColorScheme ? flexVersion : null,
        logoPath: theme.logoPath,
      );
    }

    // Widgetbook catalog.
    if (theme.generateWidgetbook) {
      final widgetbookApp = ThemeTemplates.widgetbookApp(
        packageName: themePkg,
        components: theme.components,
      );
      if (uiPackage != null) {
        // A proper workspace member that depends on <app>_ui.
        await writeFile(
          '${projectDir.path}/widgetbook/lib/main.dart',
          widgetbookApp,
        );
        await writeFile(
          '${projectDir.path}/widgetbook/pubspec.yaml',
          UiPackageWriter.widgetbookPubspec(packageName, uiPackage),
        );
      } else {
        await writeFile(
          '${projectDir.path}/widgetbook/main.dart',
          widgetbookApp,
        );
      }
    }

    // State (theme mode / brightness) ALWAYS stays in the app, never in <ui>.
    final appT = '$lib/core/theme';

    // theme mode controller — single-sourced from the core package when
    // packageSplit is on (see this function's corePackageName doc).
    if (hasRiverpod && corePackageName == null) {
      await writeFile(
        '$appT/theme_mode_controller.dart',
        useAnnotations
            ? ThemeTemplates.themeModeControllerRiverpod(
                packageName: packageName,
              )
            : ThemeTemplates.themeModeControllerRiverpodManual(),
      );
    }

    if (hasBloc || useCubit) {
      if (useCubit) {
        await writeFile(
          '$appT/brightness_theme/brightness_cubit.dart',
          ThemeTemplates.brightnessCubit(),
        );
        await writeFile(
          '$appT/brightness_theme/brightness_state.dart',
          ThemeTemplates.brightnessCubitState(),
        );
      } else {
        await writeFile(
          '$appT/brightness_theme/brightness_bloc.dart',
          ThemeTemplates.brightnessBloc(),
        );
        await writeFile(
          '$appT/brightness_theme/brightness_event.dart',
          ThemeTemplates.brightnessBlocEvent(),
        );
        await writeFile(
          '$appT/brightness_theme/brightness_state.dart',
          ThemeTemplates.brightnessBlocState(),
        );
      }
    }
  }
}
