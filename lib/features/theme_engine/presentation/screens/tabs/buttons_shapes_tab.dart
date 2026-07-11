import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:neat/features/theme_engine/presentation/providers/theme_engine_provider.dart';
import 'package:neat/features/theme_engine/presentation/screens/widget/button_config_card.dart';
import 'package:neat_ui/neat_ui.dart';

class ButtonsShapesTab extends ConsumerWidget {
  const ButtonsShapesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(themeEngineProvider);
    final notifier = ref.read(themeEngineProvider.notifier);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Global Shape Geometry ────────────────────────────────────────
          SectionHeader(
            iconSize: 16,
            fontSize: 14,
            icon: Icons.rounded_corner_outlined,
            label: 'Global Shape Geometry',
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: context.neatColors.colorSurfaceCard,
              borderRadius: .circular(12),
              border: .all(color: context.neatColors.surface10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      NeatSlider(
                        label: 'GLOBAL BORDER RADIUS',
                        value: state.containerRadius,
                        min: 0,
                        max: 32,
                        unit: '',
                        decimals: 0,
                        onChanged: notifier.setContainerRadius,
                      ),
                      16.gapH,
                      NeatSlider(
                        label: 'CARD ELEVATION',
                        value: state.cardElevation,
                        min: 0,
                        max: 8,
                        unit: 'dp',
                        decimals: 0,
                        onChanged: notifier.setCardElevation,
                      ),
                    ],
                  ),
                ),
                24.gapW,
                // Shape preview
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Palette.colorPrimaryCyan.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(state.containerRadius),
                    border: Border.all(color: Palette.colorPrimaryCyan.withValues(alpha: 0.5)),
                  ),
                  child: Icon(
                    Icons.crop_square_outlined,
                    color: Palette.colorPrimaryCyan.withValues(alpha: 0.6),
                    size: 28,
                  ),
                ),
              ],
            ),
          ),

          24.gapH,

          // ── Button Theme Customizer ──────────────────────────────────────
          SectionHeader(
            iconSize: 16,
            fontSize: 14,
            icon: Icons.smart_button_outlined,
            label: 'Button Theme Customizer',
          ),
          16.gapH,

          ButtonConfigCard(
            title: 'ELEVATED BUTTON',
            config: state.elevatedButton,
            globalRadius: state.containerRadius,
            previewColor: state.lightScheme.primary,
            onPrimaryColor: state.lightScheme.onPrimary,
            showElevation: true,
            onChanged: notifier.setElevatedButton,
          ),
          10.gapH,
          ButtonConfigCard(
            title: 'FILLED BUTTON',
            config: state.filledButton,
            globalRadius: state.containerRadius,
            previewColor: state.lightScheme.primary,
            onPrimaryColor: state.lightScheme.onPrimary,
            onChanged: notifier.setFilledButton,
          ),
          10.gapH,
          ButtonConfigCard(
            title: 'OUTLINED BUTTON',
            config: state.outlinedButton,
            globalRadius: state.containerRadius,
            previewColor: Colors.transparent,
            onPrimaryColor: state.lightScheme.primary,
            showStroke: true,
            borderColor: state.lightScheme.primary,
            onChanged: notifier.setOutlinedButton,
          ),
          10.gapH,
          ButtonConfigCard(
            title: 'TEXT BUTTON',
            config: state.textButton,
            globalRadius: state.containerRadius,
            previewColor: Colors.transparent,
            onPrimaryColor: state.lightScheme.primary,
            onChanged: notifier.setTextButton,
          ),

          24.gapH,
        ],
      ),
    );
  }
}
