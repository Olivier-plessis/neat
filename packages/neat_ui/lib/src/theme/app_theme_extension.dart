import 'package:flutter/material.dart';

/// Extension pour les couleurs spécifiques au Design System Wesioo
/// non couvertes par le ColorScheme standard de Material 3.
class NeatColors extends ThemeExtension<NeatColors> {
  const NeatColors({
    required this.mainFont,
    required this.mainDark,
    required this.dark,
    required this.surface,
    required this.surface10,
    required this.surface24,
    required this.colorNeutralBg,
    required this.colorSurfaceCard,
    required this.colorPrimaryCyan,
    required this.colorSecondaryBlue,
    required this.colorTertiaryPurple,
    required this.errorColor,
  });

  final Color mainFont;
  final Color mainDark;
  final Color dark;
  final Color surface;
  final Color surface10;
  final Color surface24;
  final Color colorNeutralBg;
  final Color colorSurfaceCard;
  final Color colorPrimaryCyan;
  final Color colorSecondaryBlue;
  final Color colorTertiaryPurple;
  final Color errorColor;

  @override
  ThemeExtension<NeatColors> copyWith({
    Color? mainFont,
    Color? mainDark,
    Color? dark,
    Color? surface,
    Color? surface10,
    Color? surface24,
    Color? colorNeutralBg,
    Color? colorSurfaceCard,
    Color? colorPrimaryCyan,
    Color? colorSecondaryBlue,
    Color? colorTertiaryPurple,
    Color? errorColor,
  }) {
    return NeatColors(
      mainFont: mainFont ?? this.mainFont,
      mainDark: mainDark ?? this.mainDark,
      dark: dark ?? this.dark,
      surface: surface ?? this.surface,
      surface10: surface10 ?? this.surface10,
      surface24: surface24 ?? this.surface24,
      colorNeutralBg: colorNeutralBg ?? this.colorNeutralBg,
      colorSurfaceCard: colorSurfaceCard ?? this.colorSurfaceCard,
      colorPrimaryCyan: colorPrimaryCyan ?? this.colorPrimaryCyan,
      colorSecondaryBlue: colorSecondaryBlue ?? this.colorSecondaryBlue,
      colorTertiaryPurple: colorTertiaryPurple ?? this.colorTertiaryPurple,
      errorColor: errorColor ?? this.errorColor,
    );
  }

  @override
  ThemeExtension<NeatColors> lerp(covariant ThemeExtension<NeatColors>? other, double t) {
    if (other is! NeatColors) return this;
    return NeatColors(
      mainFont: Color.lerp(mainFont, other.mainFont, t)!,
      mainDark: Color.lerp(mainDark, other.mainDark, t)!,
      dark: Color.lerp(dark, other.dark, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surface10: Color.lerp(surface10, other.surface10, t)!,
      surface24: Color.lerp(surface24, other.surface24, t)!,
      colorNeutralBg: Color.lerp(colorNeutralBg, other.colorNeutralBg, t)!,
      colorSurfaceCard: Color.lerp(colorSurfaceCard, other.colorSurfaceCard, t)!,
      colorPrimaryCyan: Color.lerp(colorPrimaryCyan, other.colorPrimaryCyan, t)!,
      colorSecondaryBlue: Color.lerp(colorSecondaryBlue, other.colorSecondaryBlue, t)!,
      colorTertiaryPurple: Color.lerp(colorTertiaryPurple, other.colorTertiaryPurple, t)!,
      errorColor: Color.lerp(errorColor, other.errorColor, t)!,
    );
  }
}

/// Helper pour accéder facilement aux couleurs Wesioo via BuildContext
extension NeatThemeContext on BuildContext {
  NeatColors get neatColors => Theme.of(this).extension<NeatColors>()!;

  TextTheme get textTheme => Theme.of(this).textTheme;

  ColorScheme get colorScheme => Theme.of(this).colorScheme;
}
