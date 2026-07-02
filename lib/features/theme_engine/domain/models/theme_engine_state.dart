import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'theme_engine_state.freezed.dart';

// ── Theme approach ─────────────────────────────────────────────────────────────

enum ThemeApproach { none, customM3, flexColorScheme }

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
    @Default(13.0) double surfaceBlendLevel,
    @Default(20.0) double onSurfaceBlendLevel,

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

  // ── Derived color schemes ─────────────────────────────────────────────────

  ColorScheme get lightScheme => _applyOverrides(ColorScheme.fromSeed(seedColor: seedColor));

  ColorScheme get darkScheme =>
      _applyOverrides(ColorScheme.fromSeed(seedColor: seedColor, brightness: Brightness.dark));

  ColorScheme get activeScheme => defaultBrightness == Brightness.dark ? darkScheme : lightScheme;

  ColorScheme _applyOverrides(ColorScheme base) {
    if (primaryOverride == null && secondaryOverride == null && tertiaryOverride == null) {
      return base;
    }
    return base.copyWith(
      primary: primaryOverride,
      secondary: secondaryOverride,
      tertiary: tertiaryOverride,
    );
  }

  /// ARGB hex for code generation, e.g. "0xFF00DCE5"
  String get seedColorHex => _hex(seedColor)!;

  /// Override hexes for code generation (null when not overridden).
  String? get primaryOverrideHex => _hex(primaryOverride);

  String? get secondaryOverrideHex => _hex(secondaryOverride);

  String? get tertiaryOverrideHex => _hex(tertiaryOverride);

  /// Semantic color hexes for code generation.
  String get accentColorHex => _hex(accentColor)!;

  String get destructiveColorHex => _hex(destructiveColor)!;

  String? _hex(Color? c) {
    if (c == null) return null;
    final v = c.toARGB32();
    return '0x${v.toRadixString(16).padLeft(8, '0').toUpperCase()}';
  }
}
