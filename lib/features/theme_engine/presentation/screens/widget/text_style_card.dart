import 'package:flutter/material.dart';
import 'package:neat/features/theme_engine/domain/models/theme_engine_state.dart';
import 'package:neat/features/theme_engine/utils/neat_text_style.dart';
import 'package:neat_ui/neat_ui.dart';

class TextStyleCard extends StatelessWidget {
  const TextStyleCard({
    required this.styleKey,
    required this.config,
    required this.fontFamily,
    required this.onChanged,
    required this.onRemove,
    super.key,
  });

  final TextStyleKey styleKey;
  final TextStyleConfig config;
  final String fontFamily;
  final ValueChanged<TextStyleConfig> onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const .all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111316),
        borderRadius: .circular(12),
        border: .all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          // Header: style name + summary + remove btn
          Row(
            spacing: 10,
            children: [
              Text(
                styleKey.label.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),

              Text(
                '$fontFamily  ${config.fontSize.round().toDouble()} · w${config.fontWeight}',
                style: TextStyle(
                  color: context.neatColors.colorPrimaryCyan,
                  fontSize: 10,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Clickable(
                onTap: onRemove,
                child: const Icon(Icons.close, size: 14, color: Colors.white24),
              ),
            ],
          ),
          12.gapH,

          // Text preview
          Container(
            width: .infinity,
            padding: const .symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(color: const Color(0xFF0D0D0F), borderRadius: .circular(8)),
            child: Text(
              styleKey.previewText,
              style: neatTextStyle(
                family: fontFamily,
                cfg: config,
                color: Colors.white,
                sizeOverride: config.fontSize.clamp(10, 42),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          16.gapH,

          // Sliders row
          Row(
            spacing: 16,
            children: [
              Expanded(
                child: NeatSlider(
                  label: 'FONT SIZE',
                  value: config.fontSize,
                  min: 8,
                  max: 96,
                  unit: '.0',
                  decimals: 0,
                  onChanged: (v) => onChanged(config.copyWith(fontSize: v)),
                ),
              ),
              Expanded(
                child: WeightSlider(
                  value: config.fontWeight,
                  onChanged: (v) => onChanged(config.copyWith(fontWeight: v)),
                ),
              ),
              Expanded(
                child: NeatSlider(
                  label: 'LETTER SPACING',
                  value: config.letterSpacing,
                  min: -2,
                  max: 4,
                  unit: '',
                  decimals: 2,
                  onChanged: (v) => onChanged(config.copyWith(letterSpacing: v)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
