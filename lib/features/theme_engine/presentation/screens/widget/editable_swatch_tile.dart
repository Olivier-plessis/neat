import 'package:flutter/material.dart';
import 'package:neat/features/theme_engine/presentation/screens/widget/dialog/color_picker_dialog.dart';
import 'package:neat_ui/neat_ui.dart';

class EditableSwatchTile extends StatelessWidget {
  const EditableSwatchTile({
    required this.label,
    required this.color,
    required this.currentOverride,
    required this.onColorChanged,
    required this.onReset,
  });

  final String label;
  final Color color;
  final Color? currentOverride;
  final ValueChanged<Color> onColorChanged;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final isOverridden = currentOverride != null;
    final onColor = ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white
        : Colors.black;

    return Clickable(
      onTap: () => showDialog<void>(
        context: context,
        builder: (_) => ColorPickerDialog(
          initial: color,
          isOverridden: isOverridden,
          onPicked: onColorChanged,
          onReset: onReset,
        ),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 64,
        decoration: BoxDecoration(
          color: color,
          borderRadius: .circular(10),
          border: .all(
            color: isOverridden ? Colors.white54 : Colors.white12,
            width: isOverridden ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              bottom: 6,
              left: 8,
              child: Text(
                label,
                style: TextStyle(
                  color: onColor.withValues(alpha: 0.8),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Positioned(
              top: 6,
              right: 6,
              child: Icon(Icons.edit, size: 10, color: onColor.withValues(alpha: 0.5)),
            ),
          ],
        ),
      ),
    );
  }
}
