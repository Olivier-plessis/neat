import 'package:flutter/material.dart';
import 'package:neat_ui/neat_ui.dart';

class ParentRoutingSelector extends StatelessWidget {
  const ParentRoutingSelector({
    required this.features,
    required this.selected,
    required this.enabled,
    required this.error,
    required this.onSelect,
    super.key,
  });

  final List<String> features;
  final String? selected;
  final bool enabled;
  final String? error;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: 'Parent feature',
        labelStyle: const TextStyle(color: Colors.white54, fontSize: 13),
        errorText: error,
        filled: true,
        fillColor: context.neatColors.colorSurfaceCard,
        contentPadding: const .symmetric(horizontal: 12, vertical: 4),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.white10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Palette.colorPrimaryCyan),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selected,
          isExpanded: true,
          dropdownColor: context.neatColors.colorSurfaceCard,
          hint: Text('Select a feature', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          style: const TextStyle(color: Colors.white, fontSize: 13),
          onChanged: enabled ? onSelect : null,
          items: features.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
        ),
      ),
    );
  }
}
