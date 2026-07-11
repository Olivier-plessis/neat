import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class BaseSizeField extends HookWidget {
  const BaseSizeField({required this.value, required this.onChanged, super.key});

  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final ctrl = useTextEditingController(text: value.round().toString());

    useEffect(() {
      ctrl.text = value.round().toString();
      return null;
    }, [value]);

    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: TextField(
        controller: ctrl,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(2),
        ],
        decoration: const InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 11),
        ),
        onSubmitted: (v) {
          final n = double.tryParse(v);
          if (n != null && n >= 10 && n <= 24) onChanged(n);
        },
        onTapOutside: (_) {
          final n = double.tryParse(ctrl.text);
          if (n != null && n >= 10 && n <= 24) onChanged(n);
          FocusScope.of(context).unfocus();
        },
      ),
    );
  }
}
