import 'package:flutter/material.dart';
import 'package:neat_ui/neat_ui.dart';

class SimpleToggleCard extends StatelessWidget {
  const SimpleToggleCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.enabled,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const .all(18),
      decoration: BoxDecoration(
        color: context.neatColors.colorSurfaceCard,
        borderRadius: .circular(12),
        border: .all(
          color: enabled
              ? context.neatColors.colorPrimaryCyan.withValues(alpha: 0.5)
              : Colors.white10,
        ),
      ),
      child: Row(
        spacing: 14,
        children: [
          Icon(icon, color: context.neatColors.colorPrimaryCyan, size: 20),

          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                4.gapH,
                Text(
                  description,
                  style: TextStyle(color: Colors.grey[500], fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
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
