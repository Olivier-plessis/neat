import 'package:flutter/material.dart';
import 'package:neat_ui/neat_ui.dart';

class LayerToggle extends StatelessWidget {
  const LayerToggle({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.enabled,
    this.onChanged,
    this.locked = false,
    super.key,
  });

  final String title;
  final String subtitle;
  final bool value;
  final bool enabled;
  final ValueChanged<bool>? onChanged;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const .symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)),
                    if (locked) ...[
                      6.gapW,
                      const Icon(Icons.lock_outline, size: 12, color: Colors.white38),
                    ],
                  ],
                ),
                2.gapH,
                Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: enabled ? onChanged : null,
            activeThumbColor: context.neatColors.colorPrimaryCyan,
          ),
        ],
      ),
    );
  }
}
