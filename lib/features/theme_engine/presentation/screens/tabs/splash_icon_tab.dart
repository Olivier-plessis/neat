import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:neat/features/theme_engine/domain/models/theme_engine_state.dart';
import 'package:neat/features/theme_engine/presentation/providers/theme_engine_provider.dart';
import 'package:neat/features/theme_engine/presentation/screens/widget/card/branding_card.dart';
import 'package:neat/features/theme_engine/presentation/screens/widget/card/toggle/component_toggle_card.dart';
import 'package:neat/features/theme_engine/presentation/screens/widget/card/toggle/single_toggle_card.dart';
import 'package:neat/features/theme_engine/presentation/screens/widget/card/toggle/widget_book_toggle_card.dart';
import 'package:neat_ui/neat_ui.dart';

class SplashIconTab extends ConsumerWidget {
  const SplashIconTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(themeEngineProvider);
    final notifier = ref.read(themeEngineProvider.notifier);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (state.approach == ThemeApproach.customM3) ...[
            // ── Component Library (opt-in) ───────────────────────────────────
            SectionHeader(
              iconSize: 16,
              fontSize: 14,
              icon: Icons.widgets_outlined,
              label: 'Component Library',
            ),
            const SizedBox(height: 16),
            for (final c in AppComponent.values)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ComponentToggleCard(
                  component: c,
                  enabled: state.components.contains(c),
                  onChanged: (on) => notifier.toggleComponent(c, on),
                ),
              ),

            const SizedBox(height: 16),
            WidgetBookToggleCard(
              enabled: state.generateWidgetbook,
              hasComponents: state.components.isNotEmpty,
              onChanged: notifier.setGenerateWidgetbook,
            ),
            const SizedBox(height: 16),
          ],
          SectionHeader(icon: Icons.dns_outlined, label: 'Modular Monorepo'),
          const SizedBox(height: 16),
          SimpleToggleCard(
            icon: Icons.widgets_outlined,
            title: 'Extract UI into a package',
            description:
                'Move theme, tokens & components into a `<app>_ui` workspace package. '
                'The app and Widgetbook depend on it — clean decoupling.',
            enabled: state.extractUiPackage,
            onChanged: notifier.setExtractUiPackage,
          ),

          const SizedBox(height: 24),
          SectionHeader(
            iconSize: 16,
            fontSize: 14,
            icon: Icons.image_outlined,
            label: 'Branding (App Icon & Splash)',
          ),
          const SizedBox(height: 16),
          DropZone(
            allowedExtensions: const ['png'],
            onFilePicked: notifier.setLogoPath,
            onRejected: () => neatSnack(context, 'Drop a PNG logo', success: false),
            child: BrandingCard(
              logoPath: state.logoPath,
              onPick: () async {
                final result = await FilePicker.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: const ['png'],
                );
                final path = result?.files.single.path;
                if (path != null) notifier.setLogoPath(path);
              },
              onRemove: () => notifier.setLogoPath(''),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
