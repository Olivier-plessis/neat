import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:neat/features/dependencies/presentation/providers/dependencies_provider.dart';
import 'package:neat/features/theme_engine/domain/models/theme_engine_state.dart';
import 'package:neat/features/theme_engine/presentation/providers/theme_engine_provider.dart';
import 'package:neat/features/theme_engine/presentation/providers/theme_engine_tab_provider.dart';
import 'package:neat/features/theme_engine/presentation/screens/tabs/buttons_shapes_tab.dart';
import 'package:neat/features/theme_engine/presentation/screens/tabs/color_tab.dart';
import 'package:neat/features/theme_engine/presentation/screens/tabs/flex_color_scheme_tab.dart';
import 'package:neat/features/theme_engine/presentation/screens/tabs/splash_icon_tab.dart';
import 'package:neat/features/theme_engine/presentation/screens/tabs/typography_tab.dart';
import 'package:neat/features/theme_engine/presentation/screens/widget/card/live_preview_card.dart';
import 'package:neat/features/theme_engine/presentation/widgets/entry_point.dart';
import 'package:neat_ui/neat_ui.dart';

// ── Root screen ───────────────────────────────────────────────────────────────

class ThemeEngineScreen extends ConsumerWidget {
  const ThemeEngineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final approach = ref.watch(themeEngineProvider.select((s) => s.approach));
    final tab = ref.watch(currentThemeEngineTabProvider);
    final notifier = ref.read(themeEngineProvider.notifier);

    final title = switch (approach) {
      ThemeApproach.none => 'Design System Architect',
      ThemeApproach.flexColorScheme => switch (tab) {
        ThemeEngineTab.colors => 'Flex Color Scheme',
        ThemeEngineTab.icons => 'Icons',
        ThemeEngineTab.typography => throw UnimplementedError(),
        ThemeEngineTab.buttonsShapes => throw UnimplementedError(),
      },
      ThemeApproach.customM3 => switch (tab) {
        ThemeEngineTab.colors => 'Colors',
        ThemeEngineTab.typography => 'Typography',
        ThemeEngineTab.buttonsShapes => 'Buttons & Shapes',
        ThemeEngineTab.icons => 'Icons',
      },
    };
    final subtitle = switch (approach) {
      ThemeApproach.none =>
        'Generate a professional Material 3 design system for your Flutter application.\n'
            'Adjust parameters in real-time and preview the visual output.',
      ThemeApproach.flexColorScheme =>
        'Paste a FlexColorScheme playground export, or tune the scheme directly.',
      ThemeApproach.customM3 =>
        'Adjust parameters in real-time and preview the visual output on the right.',
    };

    final editor = switch (approach) {
      ThemeApproach.flexColorScheme => switch (tab) {
        ThemeEngineTab.colors => const FlexColorSchemeTab(),
        ThemeEngineTab.icons => const SplashIconTab(),
        ThemeEngineTab.typography => const SizedBox.shrink(),
        ThemeEngineTab.buttonsShapes => const SizedBox.shrink(),
      },
      ThemeApproach.customM3 => switch (tab) {
        ThemeEngineTab.colors => const ColorsTab(),
        ThemeEngineTab.typography => const TypographyTab(),
        ThemeEngineTab.buttonsShapes => const ButtonsShapesTab(),
        ThemeEngineTab.icons => const SplashIconTab(),
      },
      ThemeApproach.none => const SizedBox.shrink(), // unreachable — see child below
    };

    return ScreenForScaffold(
      title: title,
      subtitle: subtitle,
      child: approach == ThemeApproach.none
          ? EntryPoint(
              onTapCustom: () => notifier.setApproach(ThemeApproach.customM3),
              onTapFlex: () => notifier.setApproach(ThemeApproach.flexColorScheme),
            )
          : Column(
              crossAxisAlignment: .start,
              children: [
                Clickable(
                  onTap: () {
                    notifier.resetApproach();
                    ref.read(selectedPackagesProvider.notifier).remove('flex_color_scheme');
                  },
                  child: const Padding(
                    padding: .only(bottom: 16),
                    child: Text(
                      '← Change approach',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 11,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.white24,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Row(
                    crossAxisAlignment: .start,
                    spacing: 28,
                    children: [
                      Expanded(flex: 3, child: editor),
                      const SizedBox(width: 272, child: LivePreviewCard()),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
