import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:material_color_utilities/material_color_utilities.dart';

class ColorExtractorService {
  const ColorExtractorService();

  /// Extracts the best Material 3 seed color from a local image file.
  /// Returns null on failure.
  Future<Color?> extractSeedColor(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return null;

      final bytes = await file.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return null;

      // Resize to 128×128 — more than enough for palette extraction
      final resized = img.copyResize(decoded, width: 128, height: 128);

      final pixels = <int>[];
      for (var y = 0; y < resized.height; y++) {
        for (var x = 0; x < resized.width; x++) {
          final p = resized.getPixel(x, y);
          final a = p.a.toInt();
          final r = p.r.toInt();
          final g = p.g.toInt();
          final b = p.b.toInt();
          // Skip nearly-transparent pixels
          if (a < 128) continue;
          pixels.add((a << 24) | (r << 16) | (g << 8) | b);
        }
      }

      if (pixels.isEmpty) return null;

      final result = await QuantizerCelebi().quantize(pixels, 128);
      final ranked = Score.score(result.colorToCount);
      if (ranked.isEmpty) return null;

      return Color(ranked.first);
    } catch (_) {
      return null;
    }
  }
}
