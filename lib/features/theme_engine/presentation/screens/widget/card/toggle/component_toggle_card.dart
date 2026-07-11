import 'package:flutter/material.dart';
import 'package:neat/features/theme_engine/domain/models/theme_engine_state.dart';
import 'package:neat_ui/neat_ui.dart';

class ComponentToggleCard extends StatelessWidget {
  const ComponentToggleCard({
    required this.component,
    required this.enabled,
    required this.onChanged,
    super.key,
  });

  final AppComponent component;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.neatColors.colorSurfaceCard,
        borderRadius: .circular(12),
        border: .all(
          color: enabled
              ? context.neatColors.colorPrimaryCyan.withValues(alpha: 0.4)
              : Colors.white10,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              children: [
                Text(
                  component.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                4.gapH,
                Text(
                  component.description,
                  style: TextStyle(color: Colors.grey[500], fontSize: 12, height: 1.4),
                ),
                6.gapH,
                Text(
                  'lib/components/${component.fileName}',
                  style: TextStyle(
                    color: context.neatColors.colorPrimaryCyan.withValues(alpha: 0.7),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          16.gapW,
          Clickable(
            onTap: () => onChanged(!enabled),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48,
              height: 28,
              decoration: BoxDecoration(
                color: enabled
                    ? context.neatColors.colorPrimaryCyan.withValues(alpha: 0.15)
                    : Colors.white10,
                borderRadius: .circular(14),
                border: .all(
                  color: enabled ? context.neatColors.colorPrimaryCyan : Colors.white12,
                  width: 1.5,
                ),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment: enabled ? Alignment.centerRight : Alignment.centerLeft,
                child: Padding(
                  padding: const .all(3),
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: enabled ? context.neatColors.colorPrimaryCyan : Colors.grey[700],
                      shape: BoxShape.circle,
                    ),
                    child: enabled
                        ? const Icon(Icons.check, size: 11, color: Color(0xFF0E0E0E))
                        : null,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
