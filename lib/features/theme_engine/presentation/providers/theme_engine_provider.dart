import 'package:flutter/material.dart';
import 'package:neat/features/theme_engine/domain/models/theme_engine_state.dart';
import 'package:neat/features/theme_engine/presentation/providers/theme_engine_tab_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'theme_engine_provider.g.dart';

// ── Notifier ──────────────────────────────────────────────────────────────────

/// Shared flag: true while the launch generation process is running.
/// Read by main_layout to disable the Back button during generation.
@Riverpod(keepAlive: true)
class ExtractingImage extends _$ExtractingImage {
  @override
  bool build() => false;

  // ignore: use_setters_to_change_properties
  void set(bool value) => state = value;
}

@Riverpod(keepAlive: true)
class ThemeEngine extends _$ThemeEngine {
  @override
  ThemeEngineState build() => const ThemeEngineState();

  // Approach
  //
  // Custom M3 and FlexColorScheme have different sub-tab sets (4 vs 2, see
  // main_layout.dart's _themeTabs/_themeTabsFlex) but share one tab provider
  // — reset it on every approach change so a stale tab (e.g. Typography,
  // customM3-only) can't leak into an approach that doesn't have it.
  void setApproach(ThemeApproach approach) {
    state = state.copyWith(approach: approach);
    ref.read(currentThemeEngineTabProvider.notifier).setTab(ThemeEngineTab.colors);
  }

  void resetApproach() {
    state = state.copyWith(approach: ThemeApproach.none);
    ref.read(currentThemeEngineTabProvider.notifier).setTab(ThemeEngineTab.colors);
  }

  // Branding (logo → app icons + splash)
  void setLogoPath(String path) => state = state.copyWith(logoPath: path);

  // Colors
  void setSeedColor(Color color) => state = state.copyWith(seedColor: color);

  void setImagePath(String path) => state = state.copyWith(imagePath: path);

  void setPrimaryOverride(Color? c) => state = state.copyWith(primaryOverride: c);

  void setSecondaryOverride(Color? c) => state = state.copyWith(secondaryOverride: c);

  void setTertiaryOverride(Color? c) => state = state.copyWith(tertiaryOverride: c);

  void setPrimaryContainerOverride(Color? c) =>
      state = state.copyWith(primaryContainerOverride: c);

  void setSurfaceContainerHighestOverride(Color? c) =>
      state = state.copyWith(surfaceContainerHighestOverride: c);

  void setOnPrimaryOverride(Color? c) => state = state.copyWith(onPrimaryOverride: c);

  void setOnPrimaryContainerOverride(Color? c) =>
      state = state.copyWith(onPrimaryContainerOverride: c);

  void setOnSecondaryOverride(Color? c) => state = state.copyWith(onSecondaryOverride: c);

  void setOutlineOverride(Color? c) => state = state.copyWith(outlineOverride: c);

  void clearColorOverrides() => state = state.copyWith(
    primaryOverride: null,
    secondaryOverride: null,
    tertiaryOverride: null,
    primaryContainerOverride: null,
    surfaceContainerHighestOverride: null,
    onPrimaryOverride: null,
    onPrimaryContainerOverride: null,
    onSecondaryOverride: null,
    outlineOverride: null,
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

  /// Resets the whole typography section — the per-style map AND the font
  /// family / base size fields sitting next to the Reset button (defaults
  /// mirror ThemeEngineState's @Default values, which copyWith can't reach).
  void resetTextStyles() => state = state.copyWith(
    textStyles: kM3Defaults,
    fontFamily: 'Inter',
    baseFontSize: 16.0,
  );

  // Buttons
  void setElevatedButton(ButtonConfig c) => state = state.copyWith(elevatedButton: c);

  void setFilledButton(ButtonConfig c) => state = state.copyWith(filledButton: c);

  void setOutlinedButton(ButtonConfig c) => state = state.copyWith(outlinedButton: c);

  void setTextButton(ButtonConfig c) => state = state.copyWith(textButton: c);

  void toggleComponent(AppComponent c, bool on) => state = state.copyWith(
    components: on ? {...state.components, c} : state.components.where((x) => x != c).toSet(),
  );

  void setGenerateWidgetbook(bool v) => state = state.copyWith(generateWidgetbook: v);

  void setExtractUiPackage(bool v) => state = state.copyWith(extractUiPackage: v);

  void setAccentColor(Color c) => state = state.copyWith(accentColor: c);

  void setDestructiveColor(Color c) => state = state.copyWith(destructiveColor: c);

  // FlexColorScheme
  void setFlexColorSchemeCode(String? code) => state = state.copyWith(flexColorSchemeCode: code);

  // Preview
  void setDefaultBrightness(Brightness b) => state = state.copyWith(defaultBrightness: b);
}
