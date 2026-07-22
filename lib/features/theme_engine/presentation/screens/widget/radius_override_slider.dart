import 'package:flutter/material.dart';
import 'package:neat_ui/neat_ui.dart';

class RadiusOverrideSlider extends StatelessWidget {
  const RadiusOverrideSlider({
    required this.value,
    required this.isOverridden,
    required this.globalRadius,
    required this.onChanged,
    required this.onReset,
    super.key,
  });

  final double value;
  final bool isOverridden;
  final double globalRadius;
  final ValueChanged<double> onChanged;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: .start,
      children: [
        Row(
          children: [
            Text(
              'Radius',
              style: const TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1.2),
            ),
            6.gapW,
            Text(
              isOverridden ? '${value.round()}px' : '${globalRadius.round()}px (global)',
              style: TextStyle(
                color: isOverridden ? context.neatColors.colorPrimaryCyan : Colors.white24,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (isOverridden) ...[
              6.gapW,
              Clickable(
                onTap: onReset,
                child: Icon(Icons.refresh, size: 12, color: context.neatColors.colorPrimaryCyan),
              ),
            ],
          ],
        ),
        6.gapH,
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 2,
            thumbColor: isOverridden ? context.neatColors.colorPrimaryCyan : Colors.white24,
            activeTrackColor: isOverridden ? context.neatColors.colorPrimaryCyan : Colors.white24,
            inactiveTrackColor: Colors.white10,
            overlayColor: context.neatColors.colorPrimaryCyan.withValues(alpha: 0.12),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          ),
          child: Slider(value: value, max: 32, divisions: 32, onChanged: onChanged),
        ),
      ],
    );
  }
}
