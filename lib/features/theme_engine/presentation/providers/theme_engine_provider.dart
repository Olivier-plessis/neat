import 'package:flutter/material.dart';
import 'package:neat/features/theme_engine/domain/models/theme_engine_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'theme_engine_provider.g.dart';

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
  void toggleComponent(AppComponent c, bool on) => state = state.copyWith(
        components: on
            ? {...state.components, c}
            : state.components.where((x) => x != c).toSet(),
      );
  void setGenerateWidgetbook(bool v) => state = state.copyWith(generateWidgetbook: v);
  void setExtractUiPackage(bool v) => state = state.copyWith(extractUiPackage: v);
  void setAccentColor(Color c) => state = state.copyWith(accentColor: c);
  void setDestructiveColor(Color c) => state = state.copyWith(destructiveColor: c);

  // FlexColorScheme
  void setFlexColorSchemeCode(String? code) =>
      state = state.copyWith(flexColorSchemeCode: code);
  void setSurfaceBlendLevel(double v) => state = state.copyWith(surfaceBlendLevel: v);
  void setOnSurfaceBlendLevel(double v) => state = state.copyWith(onSurfaceBlendLevel: v);

  // Preview
  void setDefaultBrightness(Brightness b) => state = state.copyWith(defaultBrightness: b);
}
