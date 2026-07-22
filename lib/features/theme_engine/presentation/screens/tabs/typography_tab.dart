import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:neat/features/theme_engine/domain/models/theme_engine_state.dart';
import 'package:neat/features/theme_engine/presentation/providers/theme_engine_provider.dart';
import 'package:neat/features/theme_engine/presentation/screens/widget/add_style_button.dart';
import 'package:neat/features/theme_engine/presentation/screens/widget/base_size_field.dart';
import 'package:neat/features/theme_engine/presentation/screens/widget/font_selector.dart';
import 'package:neat/features/theme_engine/presentation/screens/widget/text_style_card.dart';
import 'package:neat_ui/neat_ui.dart';

class TypographyTab extends ConsumerWidget {
  const TypographyTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(themeEngineProvider);
    final notifier = ref.read(themeEngineProvider.notifier);
    final styles = state.textStyles;

    // Ordered list of active keys (preserve M3 order)
    final activeKeys = TextStyleKey.values.where(styles.containsKey).toList();
    final inactiveKeys = TextStyleKey.values.where((k) => !styles.containsKey(k)).toList();

    return Column(
      children: [
        // Font family + base size row
        Row(
          spacing: 16,
          children: [
            // Font Family
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'FONT FAMILY',
                    style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 8),
                  FontSelector(value: state.fontFamily, onChanged: notifier.setFontFamily),
                ],
              ),
            ),

            // Base Size
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'BASE SIZE',
                    style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 8),
                  BaseSizeField(value: state.baseFontSize, onChanged: notifier.setBaseFontSize),
                ],
              ),
            ),
            // Reset defaults button
            Align(
              alignment: Alignment.bottomRight,
              child: TextButton.icon(
                onPressed: notifier.resetTextStyles,
                icon: const Icon(Icons.refresh, size: 14),
                label: const Text(
                  'RESET DEFAULTS',
                  style: TextStyle(fontSize: 10, letterSpacing: 0.8),
                ),
                style: TextButton.styleFrom(foregroundColor: Colors.white38),
              ),
            ),
          ],
        ),
        20.gapH,

        // Style list
        Expanded(
          child: ListView.separated(
            itemCount: activeKeys.length + 1, // +1 for "Add style" button
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              if (i == activeKeys.length) {
                // "Add style" button
                if (inactiveKeys.isEmpty) return const SizedBox.shrink();
                return AddStyleButton(inactiveKeys: inactiveKeys, onAdd: notifier.addTextStyle);
              }
              final key = activeKeys[i];
              final config = styles[key]!;
              return TextStyleCard(
                styleKey: key,
                config: config,
                fontFamily: state.fontFamily,
                onChanged: (cfg) => notifier.updateTextStyle(key, cfg),
                onRemove: () => notifier.removeTextStyle(key),
              );
            },
          ),
        ),
      ],
    );
  }
}
