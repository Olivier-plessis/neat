import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:neat/features/theme_engine/presentation/screens/widget/dialog/color_picker_dialog.dart';
import 'package:neat_ui/neat_ui.dart';

String _toHex(Color c) {
  final v = c.toARGB32();
  return '0x${v.toRadixString(16).padLeft(8, '0').toUpperCase()}';
}

class ColorHexField extends HookWidget {
  const ColorHexField({required this.color, required this.onColorChanged, super.key});

  final Color color;
  final ValueChanged<Color> onColorChanged;

  @override
  Widget build(BuildContext context) {
    final ctrl = useTextEditingController(text: _toHex(color));
    final focusNode = useFocusNode();
    final focused = useState(false);

    useEffect(() {
      void listener() => focused.value = focusNode.hasFocus;
      focusNode.addListener(listener);
      return () => focusNode.removeListener(listener);
    }, [focusNode]);

    final previousColor = usePrevious(color);
    useEffect(() {
      if (!focused.value && previousColor != null && previousColor != color) {
        ctrl.text = _toHex(color);
      }
      return null;
    }, [color]);

    void submit() {
      var text = ctrl.text.trim();
      if (text.toLowerCase().startsWith('0x')) text = text.substring(2);
      if (text.length == 6) text = 'FF$text';
      final v = int.tryParse(text, radix: 16);
      if (v != null) onColorChanged(Color(v | 0xFF000000));
    }

    return Focus(
      focusNode: focusNode,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1E),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          children: [
            12.gapW,
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: color,
                borderRadius: .circular(4),
                border: .all(color: Colors.white12),
              ),
            ),
            10.gapW,
            Expanded(
              child: TextField(
                controller: ctrl,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9a-fA-Fx]')),
                  LengthLimitingTextInputFormatter(10),
                ],
                onSubmitted: (_) => submit(),
                onTapOutside: (_) {
                  submit();
                  FocusScope.of(context).unfocus();
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.colorize_outlined, size: 18, color: Colors.white38),
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => ColorPickerDialog(
                  initial: color,
                  onPicked: (c) {
                    onColorChanged(c);
                    ctrl.text = _toHex(c);
                  },
                ),
              ),
              padding: const .all(8),
              constraints: const BoxConstraints(),
            ),
            4.gapW,
          ],
        ),
      ),
    );
  }
}
