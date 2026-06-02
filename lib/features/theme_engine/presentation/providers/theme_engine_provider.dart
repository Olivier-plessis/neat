import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'theme_engine_provider.g.dart';

// ── Theme approach ─────────────────────────────────────────────────────────────

enum ThemeApproach { none, customM3, flexColorScheme }

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
        headlineLarge || headlineMedium || headlineSmall =>
          'The quick brown fox jumps',
        titleLarge || titleMedium || titleSmall => 'Section Title',
        bodyLarge || bodyMedium => 'The quick brown fox jumps over the lazy dog. '
            'A technical achievement in typography.',
        bodySmall => 'The quick brown fox jumps over the lazy dog.',
        labelLarge || labelMedium || labelSmall => 'STATUS: ONLINE',
      };
}

// ── M3 spec default text style configs ───────────────────────────────────────

@immutable
class TextStyleConfig {
  const TextStyleConfig({
    required this.fontSize,
    required this.fontWeight,
    required this.letterSpacing,
    this.height = 1.5,
  });

  final double fontSize;
  final int fontWeight; // 100–900 step 100
  final double letterSpacing;
  final double height;

  TextStyleConfig copyWith({
    double? fontSize,
    int? fontWeight,
    double? letterSpacing,
    double? height,
  }) =>
      TextStyleConfig(
        fontSize: fontSize ?? this.fontSize,
        fontWeight: fontWeight ?? this.fontWeight,
        letterSpacing: letterSpacing ?? this.letterSpacing,
        height: height ?? this.height,
      );
}

/// Official Material 3 typography scale defaults.
const Map<TextStyleKey, TextStyleConfig> kM3Defaults = {
  TextStyleKey.displayLarge:
      TextStyleConfig(fontSize: 57, fontWeight: 400, letterSpacing: -0.25, height: 1.12),
  TextStyleKey.displayMedium:
      TextStyleConfig(fontSize: 45, fontWeight: 400, letterSpacing: 0, height: 1.16),
  TextStyleKey.displaySmall:
      TextStyleConfig(fontSize: 36, fontWeight: 400, letterSpacing: 0, height: 1.22),
  TextStyleKey.headlineLarge:
      TextStyleConfig(fontSize: 32, fontWeight: 400, letterSpacing: 0, height: 1.25),
  TextStyleKey.headlineMedium:
      TextStyleConfig(fontSize: 28, fontWeight: 400, letterSpacing: 0, height: 1.29),
  TextStyleKey.headlineSmall:
      TextStyleConfig(fontSize: 24, fontWeight: 400, letterSpacing: 0, height: 1.33),
  TextStyleKey.titleLarge:
      TextStyleConfig(fontSize: 22, fontWeight: 400, letterSpacing: 0, height: 1.27),
  TextStyleKey.titleMedium:
      TextStyleConfig(fontSize: 16, fontWeight: 500, letterSpacing: 0.15),
  TextStyleKey.titleSmall:
      TextStyleConfig(fontSize: 14, fontWeight: 500, letterSpacing: 0.1, height: 1.43),
  TextStyleKey.bodyLarge:
      TextStyleConfig(fontSize: 16, fontWeight: 400, letterSpacing: 0.5),
  TextStyleKey.bodyMedium:
      TextStyleConfig(fontSize: 14, fontWeight: 400, letterSpacing: 0.25, height: 1.43),
  TextStyleKey.bodySmall:
      TextStyleConfig(fontSize: 12, fontWeight: 400, letterSpacing: 0.4, height: 1.33),
  TextStyleKey.labelLarge:
      TextStyleConfig(fontSize: 14, fontWeight: 500, letterSpacing: 0.1, height: 1.43),
  TextStyleKey.labelMedium:
      TextStyleConfig(fontSize: 12, fontWeight: 500, letterSpacing: 0.5, height: 1.33),
  TextStyleKey.labelSmall:
      TextStyleConfig(fontSize: 11, fontWeight: 500, letterSpacing: 0.5, height: 1.45),
};

// ── Button config ─────────────────────────────────────────────────────────────

@immutable
class ButtonConfig {
  const ButtonConfig({
    required this.hPadding,
    required this.vPadding,
    this.radiusOverride,
    this.elevation,
    this.strokeWidth,
  });

  /// null = fall back to [ThemeEngineState.containerRadius]
  final double? radiusOverride;
  final double hPadding;
  final double vPadding;
  final double? elevation; // ElevatedButton
  final double? strokeWidth; // OutlinedButton

  ButtonConfig copyWith({
    Object? radiusOverride = _kUnset,
    double? hPadding,
    double? vPadding,
    Object? elevation = _kUnset,
    Object? strokeWidth = _kUnset,
  }) =>
      ButtonConfig(
        radiusOverride:
            radiusOverride == _kUnset ? this.radiusOverride : radiusOverride as double?,
        hPadding: hPadding ?? this.hPadding,
        vPadding: vPadding ?? this.vPadding,
        elevation: elevation == _kUnset ? this.elevation : elevation as double?,
        strokeWidth: strokeWidth == _kUnset ? this.strokeWidth : strokeWidth as double?,
      );
}

const _kDefaultElevated = ButtonConfig(hPadding: 24, vPadding: 12, elevation: 4);
const _kDefaultFilled = ButtonConfig(hPadding: 24, vPadding: 12, elevation: 0);
const _kDefaultOutlined = ButtonConfig(hPadding: 24, vPadding: 12, strokeWidth: 1.5);
const _kDefaultText = ButtonConfig(hPadding: 16, vPadding: 8);

// ── Sentinel ──────────────────────────────────────────────────────────────────

const _kUnset = Object();

// ── Main state ────────────────────────────────────────────────────────────────

@immutable
class ThemeEngineState {
  const ThemeEngineState({
    this.approach = ThemeApproach.none,
    this.seedColor = const Color(0xFF00DCE5),
    this.containerRadius = 12.0,
    this.fontFamily = 'Inter',
    this.baseFontSize = 16.0,
    this.imagePath,
    this.primaryOverride,
    this.secondaryOverride,
    this.tertiaryOverride,
    this.defaultBrightness = Brightness.light,
    this.cardElevation = 0.0,
    this.textStyles = kM3Defaults,
    this.elevatedButton = _kDefaultElevated,
    this.filledButton = _kDefaultFilled,
    this.outlinedButton = _kDefaultOutlined,
    this.textButton = _kDefaultText,
    this.flexColorSchemeCode,
    this.surfaceBlendLevel = 13.0,
    this.onSurfaceBlendLevel = 20.0,
  });

  final ThemeApproach approach;

  // Colors
  final Color seedColor;
  final String? imagePath;
  final Color? primaryOverride;
  final Color? secondaryOverride;
  final Color? tertiaryOverride;

  // Shape / elevation (global)
  final double containerRadius;
  final double cardElevation;

  // Typography
  final String fontFamily;
  final double baseFontSize;
  final Map<TextStyleKey, TextStyleConfig> textStyles;

  // Buttons
  final ButtonConfig elevatedButton;
  final ButtonConfig filledButton;
  final ButtonConfig outlinedButton;
  final ButtonConfig textButton;

  // FlexColorScheme
  final String? flexColorSchemeCode;
  final double surfaceBlendLevel;
  final double onSurfaceBlendLevel;

  // Preview
  final Brightness defaultBrightness;

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Effective border radius for a button: override if set, else global.
  double effectiveRadius(ButtonConfig btn) => btn.radiusOverride ?? containerRadius;

  // ── copyWith ──────────────────────────────────────────────────────────────

  ThemeEngineState copyWith({
    ThemeApproach? approach,
    Color? seedColor,
    double? containerRadius,
    String? fontFamily,
    double? baseFontSize,
    Object? imagePath = _kUnset,
    Object? primaryOverride = _kUnset,
    Object? secondaryOverride = _kUnset,
    Object? tertiaryOverride = _kUnset,
    Brightness? defaultBrightness,
    double? cardElevation,
    Map<TextStyleKey, TextStyleConfig>? textStyles,
    ButtonConfig? elevatedButton,
    ButtonConfig? filledButton,
    ButtonConfig? outlinedButton,
    ButtonConfig? textButton,
    Object? flexColorSchemeCode = _kUnset,
    double? surfaceBlendLevel,
    double? onSurfaceBlendLevel,
  }) =>
      ThemeEngineState(
        approach: approach ?? this.approach,
        seedColor: seedColor ?? this.seedColor,
        containerRadius: containerRadius ?? this.containerRadius,
        fontFamily: fontFamily ?? this.fontFamily,
        baseFontSize: baseFontSize ?? this.baseFontSize,
        imagePath: imagePath == _kUnset ? this.imagePath : imagePath as String?,
        primaryOverride:
            primaryOverride == _kUnset ? this.primaryOverride : primaryOverride as Color?,
        secondaryOverride: secondaryOverride == _kUnset
            ? this.secondaryOverride
            : secondaryOverride as Color?,
        tertiaryOverride: tertiaryOverride == _kUnset
            ? this.tertiaryOverride
            : tertiaryOverride as Color?,
        defaultBrightness: defaultBrightness ?? this.defaultBrightness,
        cardElevation: cardElevation ?? this.cardElevation,
        textStyles: textStyles ?? this.textStyles,
        elevatedButton: elevatedButton ?? this.elevatedButton,
        filledButton: filledButton ?? this.filledButton,
        outlinedButton: outlinedButton ?? this.outlinedButton,
        textButton: textButton ?? this.textButton,
        flexColorSchemeCode: flexColorSchemeCode == _kUnset
            ? this.flexColorSchemeCode
            : flexColorSchemeCode as String?,
        surfaceBlendLevel: surfaceBlendLevel ?? this.surfaceBlendLevel,
        onSurfaceBlendLevel: onSurfaceBlendLevel ?? this.onSurfaceBlendLevel,
      );

  // ── Derived color schemes ─────────────────────────────────────────────────

  ColorScheme get lightScheme => _applyOverrides(
      ColorScheme.fromSeed(seedColor: seedColor));

  ColorScheme get darkScheme => _applyOverrides(
      ColorScheme.fromSeed(seedColor: seedColor, brightness: Brightness.dark));

  ColorScheme get activeScheme =>
      defaultBrightness == Brightness.dark ? darkScheme : lightScheme;

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
  String get seedColorHex {
    final v = seedColor.toARGB32();
    return '0x${v.toRadixString(16).padLeft(8, '0').toUpperCase()}';
  }
}

// ── Notifier ──────────────────────────────────────────────────────────────────

@Riverpod(keepAlive: true)
class ThemeEngine extends _$ThemeEngine {
  @override
  ThemeEngineState build() => const ThemeEngineState();

  // Approach
  void setApproach(ThemeApproach approach) => state = state.copyWith(approach: approach);
  void resetApproach() => state = state.copyWith(approach: ThemeApproach.none);

  // Colors
  void setSeedColor(Color color) => state = state.copyWith(seedColor: color);
  void setImagePath(String path) => state = state.copyWith(imagePath: path);
  void setPrimaryOverride(Color? c) => state = state.copyWith(primaryOverride: c);
  void setSecondaryOverride(Color? c) => state = state.copyWith(secondaryOverride: c);
  void setTertiaryOverride(Color? c) => state = state.copyWith(tertiaryOverride: c);
  void clearColorOverrides() => state = state.copyWith(
        primaryOverride: null,
        secondaryOverride: null,
        tertiaryOverride: null,
      );

  // Global shape
  void setContainerRadius(double v) => state = state.copyWith(containerRadius: v);
  void setCardElevation(double v) => state = state.copyWith(cardElevation: v);

  // Typography
  void setFontFamily(String f) => state = state.copyWith(fontFamily: f);
  void setBaseFontSize(double v) => state = state.copyWith(baseFontSize: v);
  void updateTextStyle(TextStyleKey key, TextStyleConfig config) =>
      state = state.copyWith(textStyles: {...state.textStyles, key: config});
  void removeTextStyle(TextStyleKey key) {
    final updated = Map<TextStyleKey, TextStyleConfig>.from(state.textStyles);
    updated.remove(key);
    state = state.copyWith(textStyles: updated);
  }
  void addTextStyle(TextStyleKey key) {
    if (state.textStyles.containsKey(key)) return;
    state = state.copyWith(textStyles: {...state.textStyles, key: kM3Defaults[key]!});
  }
  void resetTextStyles() => state = state.copyWith(textStyles: kM3Defaults);

  // Buttons
  void setElevatedButton(ButtonConfig c) => state = state.copyWith(elevatedButton: c);
  void setFilledButton(ButtonConfig c) => state = state.copyWith(filledButton: c);
  void setOutlinedButton(ButtonConfig c) => state = state.copyWith(outlinedButton: c);
  void setTextButton(ButtonConfig c) => state = state.copyWith(textButton: c);

  // FlexColorScheme
  void setFlexColorSchemeCode(String? code) =>
      state = state.copyWith(flexColorSchemeCode: code);
  void setSurfaceBlendLevel(double v) => state = state.copyWith(surfaceBlendLevel: v);
  void setOnSurfaceBlendLevel(double v) => state = state.copyWith(onSurfaceBlendLevel: v);

  // Preview
  void setDefaultBrightness(Brightness b) => state = state.copyWith(defaultBrightness: b);
}
