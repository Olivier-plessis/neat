import 'package:flutter/material.dart';
import 'package:neat/features/theme_engine/domain/models/theme_engine_state.dart';
import 'package:neat/features/theme_engine/presentation/screens/widget/add_style_dialog.dart';
import 'package:neat_ui/neat_ui.dart';

class AddStyleButton extends StatelessWidget {
  const AddStyleButton({required this.inactiveKeys, required this.onAdd, super.key});

  final List<TextStyleKey> inactiveKeys;
  final ValueChanged<TextStyleKey> onAdd;

  @override
  Widget build(BuildContext context) {
    return Clickable(
      onTap: () => showDialog<void>(
        context: context,
        builder: (_) => AddStyleDialog(keys: inactiveKeys, onAdd: onAdd),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white12),
        ),
        child: const Row(
          mainAxisAlignment: .center,
          spacing: 8,
          children: [
            Icon(Icons.add, size: 16, color: Colors.white38),
            Text('Add style', style: TextStyle(color: Colors.white38, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
