import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:neat/features/theme_engine/domain/models/theme_engine_state.dart';

/// Builds a real [TextStyle] from a [TextStyleConfig] using the chosen Google
/// font, so the preview renders exactly what the generated theme will use.
TextStyle neatTextStyle({
  required String family,
  required TextStyleConfig cfg,
  Color? color,
  double? sizeOverride,
}) {
  final weight = FontWeight.values.firstWhere(
    (w) => w.value == cfg.fontWeight,
    orElse: () => FontWeight.w400,
  );
  final base = TextStyle(
    fontSize: sizeOverride ?? cfg.fontSize,
    fontWeight: weight,
    letterSpacing: cfg.letterSpacing,
    height: cfg.height,
    color: color,
  );
  try {
    return GoogleFonts.getFont(family, textStyle: base);
  } catch (_) {
    // Unknown family (typo / offline): fall back to the raw family name.
    return base.copyWith(fontFamily: family);
  }
}
