import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neat/features/theme_engine/domain/models/theme_engine_state.dart';

void main() {
  group('ThemeEngineState.lightScheme/darkScheme — FlexColorScheme approach', () {
    test('named scheme paste: matches the real FlexThemeData output', () {
      const code = '''
        static ThemeData light = FlexThemeData.light(
          scheme: FlexScheme.pinkM3,
          subThemesData: const FlexSubThemesData(interactionEffects: true),
        );
      ''';
      const state = ThemeEngineState(
        approach: ThemeApproach.flexColorScheme,
        flexColorSchemeCode: code,
      );

      expect(
        state.lightScheme.primary,
        FlexThemeData.light(scheme: FlexScheme.pinkM3).colorScheme.primary,
      );
      expect(
        state.darkScheme.primary,
        FlexThemeData.dark(scheme: FlexScheme.pinkM3).colorScheme.primary,
      );
    });

    test('no code pasted yet: falls back to Material baseline', () {
      const state = ThemeEngineState(approach: ThemeApproach.flexColorScheme);

      expect(
        state.lightScheme.primary,
        FlexThemeData.light(scheme: FlexScheme.materialBaseline).colorScheme.primary,
      );
    });

    test('custom inline colors (no named scheme): falls back to Material baseline', () {
      const code = '''
        static ThemeData light = FlexThemeData.light(
          colors: FlexSchemeColor(primary: Color(0xFF123456)),
        );
      ''';
      const state = ThemeEngineState(
        approach: ThemeApproach.flexColorScheme,
        flexColorSchemeCode: code,
      );

      expect(
        state.lightScheme.primary,
        FlexThemeData.light(scheme: FlexScheme.materialBaseline).colorScheme.primary,
      );
    });

    test('unknown scheme name: falls back to Material baseline instead of throwing', () {
      const code = 'scheme: FlexScheme.doesNotExist,';
      const state = ThemeEngineState(
        approach: ThemeApproach.flexColorScheme,
        flexColorSchemeCode: code,
      );

      expect(
        state.lightScheme.primary,
        FlexThemeData.light(scheme: FlexScheme.materialBaseline).colorScheme.primary,
      );
    });

    test('customM3 approach is unaffected: still derives from seedColor', () {
      const state = ThemeEngineState(
        approach: ThemeApproach.customM3,
        seedColor: Color(0xFF123456),
      );

      expect(
        state.lightScheme.primary,
        ColorScheme.fromSeed(seedColor: const Color(0xFF123456)).primary,
      );
    });
  });

  group('ThemeEngineState.filledButtonRadius/outlinedButtonRadius — FlexColorScheme approach', () {
    test('per-button radius paste: reads filledButtonRadius/outlinedButtonRadius', () {
      const code = '''
        subThemesData: const FlexSubThemesData(
          filledButtonRadius: 4.0,
          outlinedButtonRadius: 6,
        ),
      ''';
      const state = ThemeEngineState(
        approach: ThemeApproach.flexColorScheme,
        flexColorSchemeCode: code,
      );

      expect(state.filledButtonRadius, 4.0);
      expect(state.outlinedButtonRadius, 6.0);
    });

    test('falls back to defaultRadius when the per-button field is absent', () {
      const code = 'subThemesData: const FlexSubThemesData(defaultRadius: 8.0),';
      const state = ThemeEngineState(
        approach: ThemeApproach.flexColorScheme,
        flexColorSchemeCode: code,
      );

      expect(state.filledButtonRadius, 8.0);
      expect(state.outlinedButtonRadius, 8.0);
    });

    test('falls back to containerRadius when nothing is pasted', () {
      const state = ThemeEngineState(approach: ThemeApproach.flexColorScheme);

      expect(state.filledButtonRadius, state.containerRadius);
      expect(state.outlinedButtonRadius, state.containerRadius);
    });

    test('customM3 approach is unaffected: still uses effectiveRadius/radiusOverride', () {
      const state = ThemeEngineState(
        approach: ThemeApproach.customM3,
        filledButton: ButtonConfig(hPadding: 24, vPadding: 12, radiusOverride: 99),
      );

      expect(state.filledButtonRadius, 99);
      expect(state.outlinedButtonRadius, state.containerRadius);
    });
  });
}
