part of 'widgets.dart';

class NeatSlider extends StatelessWidget {
  const NeatSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.unit,
    required this.decimals,
    required this.onChanged,
    super.key,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final String unit;
  final int decimals;
  final ValueChanged<double> onChanged;

  String _format(double v) =>
      decimals == 0 ? '${v.round()}$unit' : '${v.toStringAsFixed(decimals)}$unit';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1.0),
            ),
            Text(
              _format(value),
              style: const TextStyle(
                color: Palette.colorPrimaryCyan,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 2,
            thumbColor: Palette.colorPrimaryCyan,
            activeTrackColor: Palette.colorPrimaryCyan,
            inactiveTrackColor: Colors.white10,
            overlayColor: Palette.colorPrimaryCyan.withValues(alpha: 0.12),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          ),
          child: Slider(value: value.clamp(min, max), min: min, max: max, onChanged: onChanged),
        ),
      ],
    );
  }
}
