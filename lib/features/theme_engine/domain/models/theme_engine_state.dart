import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'theme_engine_state.freezed.dart';

// ── Theme approach ─────────────────────────────────────────────────────────────

enum ThemeApproach { none, customM3, flexColorScheme }

/// Matches the `scheme: FlexScheme.xxx` argument the playground emits for
/// every built-in palette — see [ThemeEngineState._parsedFlexScheme].
final _flexSchemeNameRegex = RegExp(r'scheme:\s*FlexScheme\.(\w+)');

/// Matches `FlexSubThemesData` radius fields — see
/// [ThemeEngineState.filledButtonRadius]/[ThemeEngineState.outlinedButtonRadius].
final _flexDefaultRadiusRegex = RegExp(r'defaultRadius:\s*(-?\d+(?:\.\d+)?)');
final _flexFilledButtonRadiusRegex = RegExp(r'filledButtonRadius:\s*(-?\d+(?:\.\d+)?)');
final _flexOutlinedButtonRadiusRegex = RegExp(r'outlinedButtonRadius:\s*(-?\d+(?:\.\d+)?)');

// ── Design-system components (opt-in, generated into lib/components/) ─────────

enum AppComponent {
  button,
  card,
  textField;

  String get label => switch (this) {
    button => 'AppButton',
    card => 'AppCard',
    textField => 'AppTextField',
  };

  String get fileName => switch (this) {
    button => 'app_button.dart',
    card => 'app_card.dart',
    textField => 'app_text_field.dart',
  };

  String get description => switch (this) {
    button => 'Variants, sizes, icon, loading & dashed border',
    card => 'Surface card with padding, radius, optional tap & shadow',
    textField => 'Labeled input with error, password toggle & prefix/suffix',
  };
}

// ── Available font families ───────────────────────────────────────────────────

const _kFontFamilies = [
  'Inter',
  'Poppins',
  'Roboto',
  'Nunito',
  'DM Sans',
  'Plus Jakarta Sans',
  'Outfit',
  'Lato',
];

List<String> get availableFontFamilies => _kFontFamilies;

// ── Text style key — all 15 Material 3 roles ──────────────────────────────────

enum TextStyleKey {
  displayLarge,
  displayMedium,
  displaySmall,
  headlineLarge,
  headlineMedium,
  headlineSmall,
  titleLarge,
  titleMedium,
  titleSmall,
  bodyLarge,
  bodyMedium,
  bodySmall,
  labelLarge,
  labelMedium,
  labelSmall;

  String get label => switch (this) {
    displayLarge => 'Display Large',
    displayMedium => 'Display Medium',
    displaySmall => 'Display Small',
    headlineLarge => 'Headline Large',
    headlineMedium => 'Headline Medium',
    headlineSmall => 'Headline Small',
    titleLarge => 'Title Large',
    titleMedium => 'Title Medium',
    titleSmall => 'Title Small',
    bodyLarge => 'Body Large',
    bodyMedium => 'Body Medium',
    bodySmall => 'Body Small',
    labelLarge => 'Label Large',
    labelMedium => 'Label Medium',
    labelSmall => 'Label Small',
  };

  String get previewText => switch (this) {
    displayLarge || displayMedium || displaySmall => 'The quick brown fox',
    headlineLarge || headlineMedium || headlineSmall => 'The quick brown fox jumps',
    titleLarge || titleMedium || titleSmall => 'Section Title',
    bodyLarge || bodyMedium =>
      'The quick brown fox jumps over the lazy dog. '
          'A technical achievement in typography.',
    bodySmall => 'The quick brown fox jumps over the lazy dog.',
    labelLarge || labelMedium || labelSmall => 'STATUS: ONLINE',
  };
}

// ── M3 spec default text style configs ───────────────────────────────────────

@freezed
abstract class TextStyleConfig with _$TextStyleConfig {
  const factory TextStyleConfig({
    required double fontSize,
    required int fontWeight, // 100–900 step 100
    required double letterSpacing,
    @Default(1.5) double height,
  }) = _TextStyleConfig;
}

/// Official Material 3 typography scale defaults.
const Map<TextStyleKey, TextStyleConfig> kM3Defaults = {
  TextStyleKey.displayLarge: TextStyleConfig(
    fontSize: 57,
    fontWeight: 400,
    letterSpacing: -0.25,
    height: 1.12,
  ),
  TextStyleKey.displayMedium: TextStyleConfig(
    fontSize: 45,
    fontWeight: 400,
    letterSpacing: 0,
    height: 1.16,
  ),
  TextStyleKey.displaySmall: TextStyleConfig(
    fontSize: 36,
    fontWeight: 400,
    letterSpacing: 0,
    height: 1.22,
  ),
  TextStyleKey.headlineLarge: TextStyleConfig(
    fontSize: 32,
    fontWeight: 400,
    letterSpacing: 0,
    height: 1.25,
  ),
  TextStyleKey.headlineMedium: TextStyleConfig(
    fontSize: 28,
    fontWeight: 400,
    letterSpacing: 0,
    height: 1.29,
  ),
  TextStyleKey.headlineSmall: TextStyleConfig(
    fontSize: 24,
    fontWeight: 400,
    letterSpacing: 0,
    height: 1.33,
  ),
  TextStyleKey.titleLarge: TextStyleConfig(
    fontSize: 22,
    fontWeight: 400,
    letterSpacing: 0,
    height: 1.27,
  ),
  TextStyleKey.titleMedium: TextStyleConfig(fontSize: 16, fontWeight: 500, letterSpacing: 0.15),
  TextStyleKey.titleSmall: TextStyleConfig(
    fontSize: 14,
    fontWeight: 500,
    letterSpacing: 0.1,
    height: 1.43,
  ),
  TextStyleKey.bodyLarge: TextStyleConfig(fontSize: 16, fontWeight: 400, letterSpacing: 0.5),
  TextStyleKey.bodyMedium: TextStyleConfig(
    fontSize: 14,
    fontWeight: 400,
    letterSpacing: 0.25,
    height: 1.43,
  ),
  TextStyleKey.bodySmall: TextStyleConfig(
    fontSize: 12,
    fontWeight: 400,
    letterSpacing: 0.4,
    height: 1.33,
  ),
  TextStyleKey.labelLarge: TextStyleConfig(
    fontSize: 14,
    fontWeight: 500,
    letterSpacing: 0.1,
    height: 1.43,
  ),
  TextStyleKey.labelMedium: TextStyleConfig(
    fontSize: 12,
    fontWeight: 500,
    letterSpacing: 0.5,
    height: 1.33,
  ),
  TextStyleKey.labelSmall: TextStyleConfig(
    fontSize: 11,
    fontWeight: 500,
    letterSpacing: 0.5,
    height: 1.45,
  ),
};

// ── Button config ─────────────────────────────────────────────────────────────

@freezed
abstract class ButtonConfig with _$ButtonConfig {
  const factory ButtonConfig({
    required double hPadding,
    required double vPadding,

    /// null = fall back to [ThemeEngineState.containerRadius]
    double? radiusOverride,
    double? elevation, // ElevatedButton
    double? strokeWidth, // OutlinedButton
  }) = _ButtonConfig;
}

const kDefaultElevated = ButtonConfig(hPadding: 24, vPadding: 12, elevation: 4);
const kDefaultFilled = ButtonConfig(hPadding: 24, vPadding: 12, elevation: 0);
const kDefaultOutlined = ButtonConfig(hPadding: 24, vPadding: 12, strokeWidth: 1.5);
const kDefaultText = ButtonConfig(hPadding: 16, vPadding: 8);

// ── Main state ────────────────────────────────────────────────────────────────

@freezed
abstract class ThemeEngineState with _$ThemeEngineState {
  const ThemeEngineState._();

  const factory ThemeEngineState({
    @Default(ThemeApproach.none) ThemeApproach approach,

    // Colors
    @Default(Color(0xFF00DCE5)) Color seedColor,
    String? imagePath,
    Color? primaryOverride,
    Color? secondaryOverride,
    Color? tertiaryOverride,
    // Every other swatch shown on the Colors tab — same override pattern,
    // null = keep the seed-derived M3 default. Field names match
    // ColorScheme's own (surfaceContainerHighest, not the UI's "surfaceHigh"
    // label) so they can be passed straight to ColorScheme.copyWith below.
    Color? primaryContainerOverride,
    Color? surfaceContainerHighestOverride,
    Color? onPrimaryOverride,
    Color? onPrimaryContainerOverride,
    Color? onSecondaryOverride,
    Color? outlineOverride,

    // Shape / elevation (global)
    @Default(12.0) double containerRadius,
    @Default(0.0) double cardElevation,

    // Typography
    @Default('Inter') String fontFamily,
    @Default(16.0) double baseFontSize,
    @Default(kM3Defaults) Map<TextStyleKey, TextStyleConfig> textStyles,

    // Buttons
    @Default(kDefaultElevated) ButtonConfig elevatedButton,
    @Default(kDefaultFilled) ButtonConfig filledButton,
    @Default(kDefaultOutlined) ButtonConfig outlinedButton,
    @Default(kDefaultText) ButtonConfig textButton,

    // FlexColorScheme
    String? flexColorSchemeCode,

    // Components
    /// Design-system components to generate into lib/components/ (opt-in).
    @Default(<AppComponent>{}) Set<AppComponent> components,

    /// When true, scaffold a Widgetbook catalog (widgetbook/main.dart).
    @Default(false) bool generateWidgetbook,

    /// When true, extract theme + tokens + components into a workspace package
    /// `<app>_ui` (the app and Widgetbook depend on it).
    @Default(true) bool extractUiPackage,

    // Semantic palette colors (used by AppButton variants & the theme)
    @Default(Color(0xFF1E293B)) Color accentColor,
    @Default(Color(0xFFEF4444)) Color destructiveColor,

    // Preview
    @Default(Brightness.light) Brightness defaultBrightness,

    /// Absolute path to a logo (PNG) the user picked. When set, NEAT copies it
    /// into the project and generates app icons + splash (flutter_launcher_icons
    /// + flutter_native_splash) at generation time.
    @Default('') String logoPath,
  }) = _ThemeEngineState;

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Effective border radius for a button: override if set, else global.
  double effectiveRadius(ButtonConfig btn) => btn.radiusOverride ?? containerRadius;

  /// Filled/outlined button radius shown in the Live Preview. Custom M3 uses
  /// [effectiveRadius] as usual; FlexColorScheme instead best-effort-parses
  /// the pasted `FlexSubThemesData(filledButtonRadius: ..., defaultRadius:
  /// ...)` fields (same named-field approach as [_parsedFlexScheme]) so the
  /// preview matches what was actually pasted instead of the Custom M3
  /// button config, which FlexColorScheme users never touch.
  double get filledButtonRadius => approach == ThemeApproach.flexColorScheme
      ? _parsedFlexRadius(_flexFilledButtonRadiusRegex) ??
            _parsedFlexRadius(_flexDefaultRadiusRegex) ??
            containerRadius
      : effectiveRadius(filledButton);

  double get outlinedButtonRadius => approach == ThemeApproach.flexColorScheme
      ? _parsedFlexRadius(_flexOutlinedButtonRadiusRegex) ??
            _parsedFlexRadius(_flexDefaultRadiusRegex) ??
            containerRadius
      : effectiveRadius(outlinedButton);

  double? _parsedFlexRadius(RegExp pattern) {
    final code = flexColorSchemeCode;
    if (code == null) return null;
    return double.tryParse(pattern.firstMatch(code)?.group(1) ?? '');
  }

  // ── Derived color schemes ─────────────────────────────────────────────────

  ColorScheme get lightScheme => approach == ThemeApproach.flexColorScheme
      ? _flexScheme(Brightness.light)
      : _applyOverrides(ColorScheme.fromSeed(seedColor: seedColor));

  ColorScheme get darkScheme => approach == ThemeApproach.flexColorScheme
      ? _flexScheme(Brightness.dark)
      : _applyOverrides(ColorScheme.fromSeed(seedColor: seedColor, brightness: Brightness.dark));

  ColorScheme get activeScheme => defaultBrightness == Brightness.dark ? darkScheme : lightScheme;

  /// Best-effort Live Preview for a pasted FlexColorScheme export: only
  /// recognizes the named-scheme form (`scheme: FlexScheme.xxx`, what the
  /// playground emits for every built-in palette). Calls the real
  /// FlexThemeData.light/dark so the preview matches FlexColorScheme's own
  /// blending instead of a from-seed approximation. Falls back to Material
  /// baseline when nothing's pasted yet, or the paste uses fully custom
  /// inline colors instead of a named scheme (not parsed — see ROADMAP).
  ColorScheme _flexScheme(Brightness brightness) {
    final scheme = _parsedFlexScheme ?? FlexScheme.materialBaseline;
    return brightness == Brightness.dark
        ? FlexThemeData.dark(scheme: scheme).colorScheme
        : FlexThemeData.light(scheme: scheme).colorScheme;
  }

  FlexScheme? get _parsedFlexScheme {
    final code = flexColorSchemeCode;
    if (code == null) return null;
    final name = _flexSchemeNameRegex.firstMatch(code)?.group(1);
    if (name == null) return null;
    return FlexScheme.values.asNameMap()[name];
  }

  ColorScheme _applyOverrides(ColorScheme base) {
    if (primaryOverride == null &&
        secondaryOverride == null &&
        tertiaryOverride == null &&
        primaryContainerOverride == null &&
        surfaceContainerHighestOverride == null &&
        onPrimaryOverride == null &&
        onPrimaryContainerOverride == null &&
        onSecondaryOverride == null &&
        outlineOverride == null) {
      return base;
    }
    return base.copyWith(
      primary: primaryOverride,
      secondary: secondaryOverride,
      tertiary: tertiaryOverride,
      primaryContainer: primaryContainerOverride,
      surfaceContainerHighest: surfaceContainerHighestOverride,
      onPrimary: onPrimaryOverride,
      onPrimaryContainer: onPrimaryContainerOverride,
      onSecondary: onSecondaryOverride,
      outline: outlineOverride,
    );
  }

  /// ARGB hex for code generation, e.g. "0xFF00DCE5"
  String get seedColorHex => _hex(seedColor)!;

  /// Override hexes for code generation (null when not overridden).
  String? get primaryOverrideHex => _hex(primaryOverride);

  String? get secondaryOverrideHex => _hex(secondaryOverride);

  String? get tertiaryOverrideHex => _hex(tertiaryOverride);

  String? get primaryContainerOverrideHex => _hex(primaryContainerOverride);

  String? get surfaceContainerHighestOverrideHex => _hex(surfaceContainerHighestOverride);

  String? get onPrimaryOverrideHex => _hex(onPrimaryOverride);

  String? get onPrimaryContainerOverrideHex => _hex(onPrimaryContainerOverride);

  String? get onSecondaryOverrideHex => _hex(onSecondaryOverride);

  String? get outlineOverrideHex => _hex(outlineOverride);

  /// Semantic color hexes for code generation.
  String get accentColorHex => _hex(accentColor)!;

  String get destructiveColorHex => _hex(destructiveColor)!;

  String? _hex(Color? c) {
    if (c == null) return null;
    final v = c.toARGB32();
    return '0x${v.toRadixString(16).padLeft(8, '0').toUpperCase()}';
  }
}
