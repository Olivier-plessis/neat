part of 'widgets.dart';

class WeightSlider extends StatelessWidget {
  const WeightSlider({required this.value, required this.onChanged, super.key});

  final int value;
  final ValueChanged<int> onChanged;

  static const _weights = [100, 200, 300, 400, 500, 600, 700, 800, 900];

  @override
  Widget build(BuildContext context) {
    final idx = _weights.indexOf(value).clamp(0, _weights.length - 1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'FONT WEIGHT',
              style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1.0),
            ),
            Text(
              'w$value',
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
          child: Slider(
            value: idx.toDouble(),
            max: (_weights.length - 1).toDouble(),
            divisions: _weights.length - 1,
            onChanged: (v) => onChanged(_weights[v.round()]),
          ),
        ),
      ],
    );
  }
}
