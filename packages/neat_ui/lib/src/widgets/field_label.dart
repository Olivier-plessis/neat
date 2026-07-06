import 'package:flutter/material.dart';

import '../theme/app_theme_extension.dart';

/// A caps, bold, letter-spaced label placed above a form field (e.g.
/// "PROJECT NAME" above its `TextField`). Unifies a pattern that had drifted
/// into two slightly different copies across NEAT's wizard screens (some
/// used `context.neatColors.mainFont`, others a hardcoded `Colors.grey`).
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: context.neatColors.mainFont,
        letterSpacing: 1,
      ),
    );
  }
}
