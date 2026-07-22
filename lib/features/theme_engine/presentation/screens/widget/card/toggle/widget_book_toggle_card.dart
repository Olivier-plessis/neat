import 'package:flutter/material.dart';
import 'package:neat_ui/neat_ui.dart';

class WidgetBookToggleCard extends StatelessWidget {
  const WidgetBookToggleCard({
    required this.enabled,
    required this.hasComponents,
    required this.onChanged,
    super.key,
  });

  final bool enabled;
  final bool hasComponents;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final active = enabled && hasComponents;
    return Opacity(
      opacity: hasComponents ? 1 : 0.5,
      child: Container(
        padding: const .all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF0E1A1A),
          borderRadius: .circular(12),
          border: .all(
            color: active
                ? context.neatColors.colorPrimaryCyan.withValues(alpha: 0.5)
                : Colors.white10,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.menu_book_outlined, color: context.neatColors.colorPrimaryCyan, size: 20),
            14.gapW,
            Expanded(
              child: Column(
                crossAxisAlignment: .start,
                children: [
                  const Text(
                    'Generate Widgetbook',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  4.gapH,
                  Text(
                    hasComponents
                        ? 'An interactive catalog of your components with knobs & light/dark '
                              'themes. Run: flutter run -t widgetbook/main.dart'
                        : 'Select at least one component above to enable the catalog.',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12, height: 1.4),
                  ),
                ],
              ),
            ),
            16.gapW,
            Clickable(
              onTap: hasComponents ? () => onChanged(!enabled) : () {},
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 48,
                height: 28,
                decoration: BoxDecoration(
                  color: active
                      ? context.neatColors.colorPrimaryCyan.withValues(alpha: 0.15)
                      : Colors.white10,
                  borderRadius: .circular(14),
                  border: .all(
                    color: active ? context.neatColors.colorPrimaryCyan : Colors.white12,
                    width: 1.5,
                  ),
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 200),
                  alignment: active ? Alignment.centerRight : Alignment.centerLeft,
                  child: Padding(
                    padding: const .all(3),
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: active ? context.neatColors.colorPrimaryCyan : Colors.grey[700],
                        shape: BoxShape.circle,
                      ),
                      child: active
                          ? const Icon(Icons.check, size: 11, color: Color(0xFF0E0E0E))
                          : null,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
