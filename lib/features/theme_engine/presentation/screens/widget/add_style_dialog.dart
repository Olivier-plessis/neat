import 'package:flutter/material.dart';
import 'package:neat/features/theme_engine/domain/models/theme_engine_state.dart';
import 'package:neat_ui/neat_ui.dart';

class AddStyleDialog extends StatelessWidget {
  const AddStyleDialog({required this.keys, required this.onAdd, super.key});

  final List<TextStyleKey> keys;
  final ValueChanged<TextStyleKey> onAdd;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: context.neatColors.colorSurfaceCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Add text style', style: TextStyle(color: Colors.white, fontSize: 16)),
      content: SizedBox(
        width: 280,
        child: Column(
          mainAxisSize: .min,
          children: keys
              .map(
                (k) => ListTile(
                  title: Text(k.label, style: const TextStyle(color: Colors.white, fontSize: 14)),
                  subtitle: Text(
                    '${kM3Defaults[k]!.fontSize.round().toDouble()} · w${kM3Defaults[k]!.fontWeight}',
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                  onTap: () {
                    onAdd(k);
                    Navigator.pop(context);
                  },
                  contentPadding: const .symmetric(horizontal: 4),
                ),
              )
              .toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.white38)),
        ),
      ],
    );
  }
}
