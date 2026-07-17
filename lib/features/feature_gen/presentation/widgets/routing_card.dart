import 'package:flutter/material.dart';
import 'package:neat_ui/neat_ui.dart';

class RoutingCard extends StatelessWidget {
  const RoutingCard({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    this.onTap,
    this.comingSoon = false,
    super.key,
  });

  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback? onTap;
  final bool comingSoon;

  @override
  Widget build(BuildContext context) {
    final cyan = context.neatColors.colorPrimaryCyan;
    return Opacity(
      opacity: comingSoon ? 0.45 : 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const .all(16),
          decoration: BoxDecoration(
            color: isSelected ? cyan.withValues(alpha: 0.08) : const Color(0xFF161619),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? cyan : Colors.white12,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? cyan : Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (comingSoon) ...[
                    6.gapW,
                    Container(
                      padding: const .symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'soon',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              4.gapH,
              Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}
