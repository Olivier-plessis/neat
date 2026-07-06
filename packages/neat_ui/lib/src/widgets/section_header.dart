import 'package:flutter/material.dart';
import 'package:neat_ui/src/constant/constant.dart';

import '../theme/app_theme_extension.dart';

/// A section title used across NEAT's wizard screens: an accent marker
/// (an icon, or a colored bar when [icon] is omitted) followed by a bold
/// label. Unifies what used to be near-identical private `_SectionHeader`
/// classes duplicated across several screens.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.label,
    this.icon,
    this.iconSize = 18,
    this.fontSize = 16,
    super.key,
  });

  final String label;
  final IconData? icon;
  final double iconSize;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final accent = context.neatColors.colorPrimaryCyan;
    return Row(
      children: [
        icon != null
            ? Icon(icon, color: accent, size: iconSize)
            : Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(2)),
              ),
        8.gapW,
        Text(label, style: context.textTheme.headlineMedium),
      ],
    );
  }
}
