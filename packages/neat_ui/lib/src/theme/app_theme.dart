import 'package:flutter/material.dart';

import '../constant/constant.dart';
import '../typography/typography.dart';
import 'app_theme_extension.dart';

class AppTheme {
  // Définition des couleurs clés du Design System

  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: Palette.colorNeutralBg,

      // ── Typography ────────────────────────────────────────────────────────
      textTheme: TextTheme(
        displayLarge: StyleTheme.displayLarge,
        displayMedium: StyleTheme.displayMedium,
        displaySmall: StyleTheme.displaySmall,
        headlineLarge: StyleTheme.headlineLarge.copyWith(color: Palette.surface),
        headlineMedium: StyleTheme.headlineMedium,
        headlineSmall: StyleTheme.headlineSmall,
        titleLarge: StyleTheme.titleLarge,
        titleMedium: StyleTheme.titleMedium,
        titleSmall: StyleTheme.titleSmall,
        bodyLarge: StyleTheme.bodyLarge,
        bodyMedium: StyleTheme.bodyMedium,
        bodySmall: StyleTheme.bodySmall,
        labelLarge: StyleTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        labelMedium: StyleTheme.labelMedium,
        labelSmall: StyleTheme.bodySmall.copyWith(fontSize: FontSizeTheme.bodySmall),
      ),

      // Configuration globale des couleurs
      colorScheme: const ColorScheme.dark(
        primary: Palette.colorPrimaryCyan,
        secondary: Palette.colorTertiaryPurple,
        surface: Palette.colorSurfaceCard,
        error: Palette.errorColor,
      ),

      // Personnalisation des Inputs (TextFields) pour matcher le kit
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Palette.mainDark,
        hintStyle: const TextStyle(color: Palette.mainFont, fontSize: FontSizeTheme.bodyLarge),
        contentPadding: const .symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: .circular(8),
          borderSide: const BorderSide(color: Palette.surface10),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: .circular(8),
          borderSide: const BorderSide(color: Palette.surface10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: .circular(8),
          borderSide: const BorderSide(color: Palette.colorPrimaryCyan, width: 1.5),
        ),
      ),

      // Style des boutons du design system (comme le bouton de recherche ou "+ New Project")
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Palette.colorPrimaryCyan,
          foregroundColor: Palette.colorNeutralBg,
          // Écrit en sombre sur le cyan brillant
          textStyle: const TextStyle(fontWeight: FontWeightTheme.bold),
          shape: RoundedRectangleBorder(borderRadius: .circular(8)),
          elevation: 0,
        ),
      ),

      // Style des boutons secondaires (Outlined)
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Palette.surface,
          side: const BorderSide(color: Palette.surface24),
          shape: RoundedRectangleBorder(borderRadius: .circular(8)),
        ),
      ),

      // Couleurs Wesioo non couvertes par le ColorScheme standard, exposées
      // via context.neatColors (voir app_theme_extension.dart).
      extensions: const <ThemeExtension<NeatColors>>[
        NeatColors(
          mainFont: Palette.mainFont,
          mainDark: Palette.mainDark,
          dark: Palette.dark,
          surface: Palette.surface,
          surface10: Palette.surface10,
          surface24: Palette.surface24,
          colorNeutralBg: Palette.colorNeutralBg,
          colorSurfaceCard: Palette.colorSurfaceCard,
          colorPrimaryCyan: Palette.colorPrimaryCyan,
          colorSecondaryBlue: Palette.colorSecondaryBlue,
          colorTertiaryPurple: Palette.colorTertiaryPurple,
          errorColor: Palette.errorColor,
          colorYellow: Palette.colorYellow,
          colorGreen: Palette.colorGreen,
          colorLightGreen: Palette.colorLightGreen,
        ),
      ],
    );
  }
}
