import 'package:flutter/material.dart';
import 'package:neat/features/theme_engine/domain/models/theme_engine_state.dart';
import 'package:neat/features/theme_engine/presentation/screens/widget/radius_override_slider.dart';
import 'package:neat_ui/neat_ui.dart';

class ButtonConfigCard extends StatelessWidget {
  const ButtonConfigCard({
    required this.title,
    required this.config,
    required this.globalRadius,
    required this.previewColor,
    required this.onPrimaryColor,
    required this.onChanged,
    this.showElevation = false,
    this.showStroke = false,
    this.borderColor,
    super.key,
  });

  final String title;
  final ButtonConfig config;
  final double globalRadius;
  final Color previewColor;
  final Color onPrimaryColor;
  final ValueChanged<ButtonConfig> onChanged;
  final bool showElevation;
  final bool showStroke;
  final Color? borderColor;

  bool get _hasRadiusOverride => config.radiusOverride != null;

  double get _effectiveRadius => config.radiusOverride ?? globalRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.neatColors.colorSurfaceCard,
        borderRadius: .circular(12),
        border: .all(color: context.neatColors.surface10),
      ),
      child: Row(
        children: [
          // Sliders
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                12.gapH,

                // Row 1
                Row(
                  children: [
                    if (showElevation) ...[
                      Expanded(
                        child: NeatSlider(
                          label: 'Elevation',
                          value: config.elevation ?? 0,
                          min: 0,
                          max: 8,
                          unit: '',
                          decimals: 0,
                          onChanged: (v) => onChanged(config.copyWith(elevation: v)),
                        ),
                      ),
                      16.gapW,
                    ],
                    if (showStroke) ...[
                      Expanded(
                        child: NeatSlider(
                          label: 'Stroke',
                          value: config.strokeWidth ?? 1.5,
                          min: 0.5,
                          max: 4,
                          unit: '',
                          decimals: 1,
                          onChanged: (v) => onChanged(config.copyWith(strokeWidth: v)),
                        ),
                      ),
                      16.gapW,
                    ],
                    // Radius with global fallback indicator
                    Expanded(
                      child: RadiusOverrideSlider(
                        value: _effectiveRadius,
                        isOverridden: _hasRadiusOverride,
                        globalRadius: globalRadius,
                        onChanged: (v) => onChanged(config.copyWith(radiusOverride: v)),
                        onReset: () => onChanged(config.copyWith(radiusOverride: null)),
                      ),
                    ),
                  ],
                ),

                10.gapH,

                // Row 2: padding
                Row(
                  children: [
                    Expanded(
                      child: NeatSlider(
                        label: showElevation ? 'H-Padding' : 'Padding',
                        value: config.hPadding,
                        min: 8,
                        max: 48,
                        unit: '',
                        decimals: 0,
                        onChanged: (v) => onChanged(config.copyWith(hPadding: v)),
                      ),
                    ),
                    if (showElevation) ...[
                      16.gapW,
                      Expanded(
                        child: NeatSlider(
                          label: 'V-Padding',
                          value: config.vPadding,
                          min: 4,
                          max: 24,
                          unit: '',
                          decimals: 0,
                          onChanged: (v) => onChanged(config.copyWith(vPadding: v)),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          10.gapW,

          // Button preview
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: context.neatColors.colorSurfaceCard,
              borderRadius: .circular(10),
            ),
            alignment: Alignment.center,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: .symmetric(
                horizontal: config.hPadding.clamp(8, 32),
                vertical: config.vPadding.clamp(4, 20),
              ),
              decoration: BoxDecoration(
                color: previewColor,
                borderRadius: .circular(_effectiveRadius),
                border: showStroke
                    ? .all(color: borderColor ?? Colors.white54, width: config.strokeWidth ?? 1.5)
                    : null,
                boxShadow: showElevation && (config.elevation ?? 0) > 0
                    ? [
                        BoxShadow(
                          color: Colors.black38,
                          blurRadius: (config.elevation ?? 0) * 2,
                          offset: Offset(0, (config.elevation ?? 0) * 0.5),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                title.split(' ').first,
                style: TextStyle(
                  color: onPrimaryColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
