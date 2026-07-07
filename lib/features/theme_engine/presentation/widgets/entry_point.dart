import 'package:flutter/material.dart';
import 'package:neat_ui/neat_ui.dart';

class EntryPoint extends StatelessWidget {
  const EntryPoint({required this.onTapCustom, required this.onTapFlex, super.key});

  final VoidCallback onTapCustom;
  final VoidCallback onTapFlex;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 350),
        child: Row(
          spacing: 24,
          children: [
            Expanded(
              child: ApproachCard(
                icon: Icons.palette_outlined,
                title: 'Custom your scheme',
                subtitle:
                    'Build a fully custom Material 3 design system.\nConfigure colors, typography, shapes and more.',
                button: 'started',
                onTap: onTapCustom,
                accent: false,
              ),
            ),

            Expanded(
              child: ApproachCard(
                icon: Icons.auto_awesome_outlined,
                title: 'Flex Color Scheme',
                subtitle:
                    'Use FlexColorScheme for advanced surface\nblending and powerful tonal schemes.',
                button: 'started',
                onTap: onTapFlex,
                accent: false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
