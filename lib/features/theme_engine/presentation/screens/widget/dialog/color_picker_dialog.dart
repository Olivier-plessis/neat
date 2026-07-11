import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:neat_ui/neat_ui.dart';

String _toHex(Color c) {
  final v = c.toARGB32();
  return '0x${v.toRadixString(16).padLeft(8, '0').toUpperCase()}';
}

class ColorPickerDialog extends HookWidget {
  const ColorPickerDialog({
    required this.initial,
    required this.onPicked,
    this.isOverridden = false,
    this.onReset,
    super.key,
  });

  final Color initial;
  final ValueChanged<Color> onPicked;
  final bool isOverridden;
  final VoidCallback? onReset;

  static const _swatches = [
    Color(0xFF00DCE5),
    Color(0xFF6366F1),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
    Color(0xFFEF4444),
    Color(0xFFF97316),
    Color(0xFFEAB308),
    Color(0xFF22C55E),
    Color(0xFF14B8A6),
    Color(0xFF3B82F6),
    Color(0xFF0EA5E9),
    Color(0xFF64748B),
    Color(0xFF1E293B),
    Color(0xFF000000),
    Color(0xFFFFFFFF),
  ];

  @override
  Widget build(BuildContext context) {
    final current = useState(initial);
    final hexCtrl = useTextEditingController(text: _toHex(initial));

    void submitHex() {
      var text = hexCtrl.text.trim();
      if (text.toLowerCase().startsWith('0x')) text = text.substring(2);
      if (text.length == 6) text = 'FF$text';
      final v = int.tryParse(text, radix: 16);
      if (v != null) current.value = Color(v | 0xFF000000);
    }

    return AlertDialog(
      backgroundColor: context.neatColors.colorSurfaceCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Pick a color', style: context.textTheme.titleMedium),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: .min,
          children: [
            // Hex input
            Container(
              height: 40,
              margin: const .only(bottom: 16),
              decoration: BoxDecoration(
                color: context.neatColors.surface10,
                borderRadius: .circular(8),
                border: .all(color: Colors.white12),
              ),
              child: Row(
                children: [
                  10.gapW,
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: current.value,
                      borderRadius: .circular(4),
                      border: .all(color: Colors.white12),
                    ),
                  ),
                  8.gapW,
                  Expanded(
                    child: TextField(
                      controller: hexCtrl,
                      style: context.textTheme.bodyMedium!.copyWith(color: Colors.white),
                      decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9a-fA-Fx]')),
                        LengthLimitingTextInputFormatter(10),
                      ],
                      onSubmitted: (_) => submitHex(),
                      onTapOutside: (_) => submitHex(),
                    ),
                  ),
                ],
              ),
            ),
            // Swatches
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _swatches.map((c) {
                final selected = current.value.toARGB32() == c.toARGB32();
                return Clickable(
                  onTap: () {
                    current.value = c;
                    hexCtrl.text = _toHex(c);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: c,
                      borderRadius: .circular(8),
                      border: .all(
                        color: selected ? Colors.white : Colors.white12,
                        width: selected ? 2 : 1,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        if (isOverridden && onReset != null)
          TextButton(
            onPressed: () {
              onReset!();
              Navigator.pop(context);
            },
            child: const Text('Reset to auto', style: TextStyle(color: Colors.white38)),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.white38)),
        ),
        FilledButton(
          onPressed: () {
            onPicked(current.value);
            Navigator.pop(context);
          },
          style: FilledButton.styleFrom(backgroundColor: context.neatColors.colorPrimaryCyan),
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
