import 'package:flutter/material.dart';

import '../theme/app_theme_extension.dart';

/// A [TextField] pre-styled with NEAT's design system: typed text renders in
/// [NeatColors.surface] rather than the theme's default `textTheme.bodyLarge`
/// (deliberately muted grey — used elsewhere for secondary/body copy, so it
/// isn't a good default for what the user is actively typing).
class NeatTextField extends StatelessWidget {
  const NeatTextField({
    required this.controller,
    this.onChanged,
    this.decoration,
    this.readOnly = false,
    super.key,
  });

  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final InputDecoration? decoration;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      readOnly: readOnly,
      style: context.textTheme.bodyLarge!.copyWith(color: context.neatColors.surface),
      decoration: decoration,
    );
  }
}
