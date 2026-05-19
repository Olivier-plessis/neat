import 'package:flutter/material.dart';

class AppTheme {
  // Définition des couleurs clés du Design System
  static const Color colorNeutralBg = Color(
    0xFF0E0E0E,
  ); // Fond principal (Neutral #0E0E0E)
  static const Color colorSurfaceCard = Color(
    0xFF18181C,
  ); // Surfaces des cartes / conteneurs
  static const Color colorPrimaryCyan = Color(
    0xFF00F5FF,
  ); // Accent Cyan Principal
  static const Color colorSecondaryBlue = Color(
    0xFF2E3C5A,
  ); // Teinte Bleutée Secondaire
  static const Color colorTertiaryPurple = Color(
    0xFF6366F1,
  ); // Touche Violette (Tertiary)

  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: colorNeutralBg,

      // Configuration globale des couleurs
      colorScheme: const ColorScheme.dark(
        primary: colorPrimaryCyan,
        secondary: colorTertiaryPurple,
        surface: colorSurfaceCard,
        error: Color(
          0xFFFF6B6B,
        ), // Teinte pour les boutons supprimer/erreur (comme ton icône poubelle)
      ),

      // Personnalisation des Inputs (TextFields) pour matcher le kit
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1A1A1E),
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.white10),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.white10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: colorPrimaryCyan, width: 1.5),
        ),
      ),

      // Style des boutons du design system (comme le bouton de recherche ou "+ New Project")
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorPrimaryCyan,
          foregroundColor:
              colorNeutralBg, // Écrit en sombre sur le cyan brillant
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Inter',
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
      ),

      // Style des boutons secondaires (Outlined)
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: Colors.white24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),

      // Style global du texte (Police 'Inter' recommandée d'après ton kit)
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        bodyLarge: TextStyle(fontFamily: 'Inter', color: Colors.white),
        bodyMedium: TextStyle(
          fontFamily: 'Inter',
          color: Color(0xFF9E9E9E),
        ), // Gris pour les descriptions secondaires
      ),
    );
  }
}
