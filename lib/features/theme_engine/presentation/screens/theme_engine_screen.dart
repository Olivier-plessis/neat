import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:neat/features/dependencies/presentation/providers/dependencies_provider.dart';
import 'package:neat/features/identity/presentation/providers/identity_provider.dart';
import 'package:neat/features/theme_engine/domain/models/theme_engine_state.dart';
import 'package:neat/features/theme_engine/domain/services/color_extractor_service.dart';
import 'package:neat/features/theme_engine/domain/services/theme_templates.dart';
import 'package:neat/features/theme_engine/presentation/providers/theme_engine_provider.dart';
import 'package:neat/features/theme_engine/presentation/widgets/entry_point.dart';
import 'package:neat_ui/neat_ui.dart';

// ── Root screen ───────────────────────────────────────────────────────────────

class ThemeEngineScreen extends ConsumerWidget {
  const ThemeEngineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final approach = ref.watch(themeEngineProvider.select((s) => s.approach));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Text('Design System Architect', style: context.textTheme.headlineLarge),
        const SizedBox(height: 8),
        Text(
          'Generate a professional Material 3 design system for your Flutter application.\n'
          'Adjust parameters in real-time and preview the visual output.',
          style: context.textTheme.bodyLarge,
        ),
        const SizedBox(height: 32),

        Expanded(
          child: approach == ThemeApproach.none
              ? EntryPoint(
                  onTapCustom: () =>
                      ref.read(themeEngineProvider.notifier).setApproach(ThemeApproach.customM3),
                  onTapFlex: () => ref
                      .read(themeEngineProvider.notifier)
                      .setApproach(ThemeApproach.flexColorScheme),
                )
              : const _TabbedEditor(),
        ),
      ],
    );
  }
}

// ── Tabbed editor ─────────────────────────────────────────────────────────────

// Only the 3 Custom M3 tabs — Flex has its own dedicated view
const _kTabLabels = ['COLORS', 'TYPOGRAPHY', 'BUTTONS & SHAPES'];

class _TabbedEditor extends HookConsumerWidget {
  const _TabbedEditor();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final approach = ref.watch(themeEngineProvider.select((s) => s.approach));
    final activeTab = useState(0); // only relevant for customM3

    final isFlex = approach == ThemeApproach.flexColorScheme;
    final notifier = ref.read(themeEngineProvider.notifier);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Left: header + content ──────────────────────────────────────────
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Navigation header ─────────────────────────────────────────
              if (isFlex) ...[
                // FlexColorScheme mode: no tabs, just action buttons
                Row(
                  children: [
                    // Active badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Palette.colorPrimaryCyan.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Palette.colorPrimaryCyan.withValues(alpha: 0.35)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Palette.colorPrimaryCyan,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 7),
                          const Text(
                            'FLEX COLOR SCHEME',
                            style: TextStyle(
                              color: Palette.colorPrimaryCyan,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Switch to Custom M3
                    OutlinedButton.icon(
                      onPressed: () {
                        notifier.setApproach(ThemeApproach.customM3);
                        // Remove flex dep since user switches away
                        ref.read(selectedPackagesProvider.notifier).remove('flex_color_scheme');
                      },
                      icon: const Icon(Icons.tune, size: 14),
                      label: const Text('Use Custom M3', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white54,
                        side: const BorderSide(color: Colors.white24),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Change approach (back to entry point)
                    TextButton.icon(
                      onPressed: () {
                        notifier.resetApproach();
                        ref.read(selectedPackagesProvider.notifier).remove('flex_color_scheme');
                      },
                      icon: const Icon(Icons.arrow_back, size: 14),
                      label: const Text('Change approach', style: TextStyle(fontSize: 12)),
                      style: TextButton.styleFrom(foregroundColor: Colors.white60),
                    ),
                  ],
                ),
                const SizedBox(height: 1),
                const Divider(color: Colors.white10, height: 1),
                const SizedBox(height: 20),

                // FlexColorScheme content directly
                const Expanded(child: _FlexColorSchemeTab()),
              ] else ...[
                // Custom M3 mode: full tab bar
                Row(
                  children: [
                    Expanded(
                      child: _CustomTabBar(
                        activeIndex: activeTab.value,
                        onTabSelected: (i) => activeTab.value = i,
                      ),
                    ),
                    _Clickable(
                      onTap: notifier.resetApproach,
                      child: const Padding(
                        padding: EdgeInsets.only(left: 16, bottom: 2),
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
                  ],
                ),
                const SizedBox(height: 1),
                const Divider(color: Colors.white10, height: 1),
                const SizedBox(height: 20),

                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.015),
                          end: Offset.zero,
                        ).animate(anim),
                        child: child,
                      ),
                    ),
                    child: KeyedSubtree(
                      key: ValueKey(activeTab.value),
                      child: switch (activeTab.value) {
                        0 => const _ColorsTab(),
                        1 => const _TypographyTab(),
                        _ => const _ButtonsShapesTab(),
                      },
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(width: 28),

        // ── Right: live preview ─────────────────────────────────────────────
        const SizedBox(width: 272, child: _LivePreview()),
      ],
    );
  }
}

class _CustomTabBar extends StatelessWidget {
  const _CustomTabBar({required this.activeIndex, required this.onTabSelected});

  final int activeIndex;
  final ValueChanged<int> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(_kTabLabels.length, (i) {
        final isActive = i == activeIndex;
        return _Clickable(
          onTap: () => onTabSelected(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.only(right: 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isActive ? Palette.colorPrimaryCyan : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
            child: Text(
              _kTabLabels[i],
              style: TextStyle(
                color: isActive ? Palette.colorPrimaryCyan : Colors.white38,
                fontSize: 11,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                letterSpacing: 0.8,
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ── TAB 1: Colors ─────────────────────────────────────────────────────────────

class _ColorsTab extends ConsumerStatefulWidget {
  const _ColorsTab();

  @override
  ConsumerState<_ColorsTab> createState() => _ColorsTabState();
}

class _ColorsTabState extends ConsumerState<_ColorsTab> {
  Future<void> _pickImage() async {
    final extractingImage = ref.read(extractingImageProvider.notifier);
    final result = await FilePicker.pickFiles(type: FileType.image);
    if (result == null || result.files.single.path == null) return;
    final path = result.files.single.path!;
    ref.read(themeEngineProvider.notifier).setImagePath(path);
    extractingImage.set(true);
    final color = await const ColorExtractorService().extractSeedColor(path);
    if (!mounted) return;
    if (color != null) {
      ref.read(themeEngineProvider.notifier).setSeedColor(color);
      ref.read(themeEngineProvider.notifier).clearColorOverrides();
      neatSnack(context, 'Seed color extracted from image');
    } else {
      neatSnack(context, "Couldn't extract a color from this image", success: false);
    }
    extractingImage.set(false);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(themeEngineProvider);
    final scheme = state.lightScheme;
    final imagePath = state.imagePath;
    final extractingImage = ref.watch(extractingImageProvider);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Palette Generator ────────────────────────────────────────────
          SectionHeader(
            iconSize: 16,
            fontSize: 14,
            icon: Icons.palette_outlined,
            label: 'Palette Generator',
          ),
          const SizedBox(height: 16),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image drop zone
              _Clickable(
                onTap: _pickImage,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 260,
                  height: 230,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: extractingImage ? Palette.colorPrimaryCyan : Colors.white12,
                      style: imagePath == null ? BorderStyle.solid : BorderStyle.solid,
                    ),
                  ),
                  child: imagePath != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.file(File(imagePath), fit: BoxFit.cover),
                              if (extractingImage)
                                ColoredBox(
                                  color: Colors.black54,
                                  child: const Center(
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Palette.colorPrimaryCyan,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate_outlined,
                              color: Colors.white24,
                              size: 28,
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Extract from Image',
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Drop logo or reference board',
                              style: TextStyle(color: Colors.white30, fontSize: 11),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.white24),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'BROWSE FILES',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(width: 24),

              // Seed color + overrides
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Seed Color',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.edit_outlined, color: Colors.white24, size: 14),
                      ],
                    ),
                    6.gapH,
                    _ColorHexField(
                      color: state.seedColor,
                      onColorChanged: (c) {
                        ref.read(themeEngineProvider.notifier).setSeedColor(c);
                        ref.read(themeEngineProvider.notifier).clearColorOverrides();
                      },
                    ),
                    16.gapH,
                    // Overrides hint
                    if (state.primaryOverride != null ||
                        state.secondaryOverride != null ||
                        state.tertiaryOverride != null)
                      _Clickable(
                        onTap: () => ref.read(themeEngineProvider.notifier).clearColorOverrides(),
                        child: const Text(
                          '↩ Reset all color overrides',
                          style: TextStyle(
                            color: Palette.colorPrimaryCyan,
                            fontSize: 11,
                            decoration: TextDecoration.underline,
                            decorationColor: Palette.colorPrimaryCyan,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          24.gapH,

          // ── Generated color swatches ─────────────────────────────────────
          SectionHeader(
            iconSize: 16,
            fontSize: 14,
            icon: Icons.grid_view_outlined,
            label: 'Generated Palette',
          ),
          16.gapH,

          // Row 1: primary, primaryContainer, secondary, surfaceHigh
          Row(
            spacing: 10,
            children: [
              Expanded(
                child: _EditableSwatchTile(
                  label: 'primary',
                  color: scheme.primary,
                  currentOverride: state.primaryOverride,
                  onColorChanged: (c) =>
                      ref.read(themeEngineProvider.notifier).setPrimaryOverride(c),
                  onReset: () => ref.read(themeEngineProvider.notifier).setPrimaryOverride(null),
                ),
              ),
              Expanded(
                child: _SwatchTile(label: 'primaryContainer', color: scheme.primaryContainer),
              ),
              Expanded(
                child: _EditableSwatchTile(
                  label: 'secondary',
                  color: scheme.secondary,
                  currentOverride: state.secondaryOverride,
                  onColorChanged: (c) =>
                      ref.read(themeEngineProvider.notifier).setSecondaryOverride(c),
                  onReset: () => ref.read(themeEngineProvider.notifier).setSecondaryOverride(null),
                ),
              ),
              Expanded(
                child: _SwatchTile(label: 'surfaceHigh', color: scheme.surfaceContainerHighest),
              ),
            ],
          ),
          10.gapH,
          // Row 2: onPrimary, onPrimaryContainer, onSecondary, outline
          Row(
            spacing: 10,
            children: [
              Expanded(
                child: _SwatchTile(label: 'onPrimary', color: scheme.onPrimary),
              ),
              Expanded(
                child: _SwatchTile(label: 'onPrimaryContainer', color: scheme.onPrimaryContainer),
              ),
              Expanded(
                child: _SwatchTile(label: 'onSecondary', color: scheme.onSecondary),
              ),
              Expanded(
                child: _SwatchTile(label: 'outline', color: scheme.outline),
              ),
            ],
          ),

          24.gapH,

          // ── Semantic colors (palette tokens used by AppButton & theme) ───
          SectionHeader(
            iconSize: 16,
            fontSize: 14,
            icon: Icons.bookmark_outline,
            label: 'Semantic Colors',
          ),
          12.gapH,
          Row(
            spacing: 10,
            children: [
              Expanded(
                child: _EditableSwatchTile(
                  label: 'accent',
                  color: state.accentColor,
                  currentOverride: state.accentColor,
                  onColorChanged: (c) => ref.read(themeEngineProvider.notifier).setAccentColor(c),
                  onReset: () => ref
                      .read(themeEngineProvider.notifier)
                      .setAccentColor(const Color(0xFF1E293B)),
                ),
              ),
              Expanded(
                child: _EditableSwatchTile(
                  label: 'error',
                  color: state.destructiveColor,
                  currentOverride: state.destructiveColor,
                  onColorChanged: (c) =>
                      ref.read(themeEngineProvider.notifier).setDestructiveColor(c),
                  onReset: () => ref
                      .read(themeEngineProvider.notifier)
                      .setDestructiveColor(const Color(0xFFEF4444)),
                ),
              ),
              // Spacers to keep the row aligned with the 4-column grid above.
              const Expanded(child: SizedBox()),
              const Expanded(child: SizedBox()),
            ],
          ),

          24.gapH,
        ],
      ),
    );
  }
}

// ── Swatch tiles ──────────────────────────────────────────────────────────────

class _EditableSwatchTile extends StatelessWidget {
  const _EditableSwatchTile({
    required this.label,
    required this.color,
    required this.currentOverride,
    required this.onColorChanged,
    required this.onReset,
  });

  final String label;
  final Color color;
  final Color? currentOverride;
  final ValueChanged<Color> onColorChanged;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final isOverridden = currentOverride != null;
    final onColor = ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white
        : Colors.black;

    return _Clickable(
      onTap: () => showDialog<void>(
        context: context,
        builder: (_) => _ColorPickerDialog(
          initial: color,
          isOverridden: isOverridden,
          onPicked: onColorChanged,
          onReset: onReset,
        ),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 64,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isOverridden ? Colors.white54 : Colors.white12,
            width: isOverridden ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              bottom: 6,
              left: 8,
              child: Text(
                label,
                style: TextStyle(
                  color: onColor.withValues(alpha: 0.8),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Positioned(
              top: 6,
              right: 6,
              child: Icon(Icons.edit, size: 10, color: onColor.withValues(alpha: 0.5)),
            ),
          ],
        ),
      ),
    );
  }
}

class _SwatchTile extends StatelessWidget {
  const _SwatchTile({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final onColor = ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white
        : Colors.black;
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: Align(
        alignment: Alignment.bottomLeft,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            label,
            style: TextStyle(
              color: onColor.withValues(alpha: 0.8),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

// ── TAB 2: Typography ─────────────────────────────────────────────────────────

class _TypographyTab extends ConsumerWidget {
  const _TypographyTab();

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
                  _FontSelector(value: state.fontFamily, onChanged: notifier.setFontFamily),
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
                  _BaseSizeField(value: state.baseFontSize, onChanged: notifier.setBaseFontSize),
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
                return _AddStyleButton(inactiveKeys: inactiveKeys, onAdd: notifier.addTextStyle);
              }
              final key = activeKeys[i];
              final config = styles[key]!;
              return _TextStyleCard(
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

class _TextStyleCard extends StatelessWidget {
  const _TextStyleCard({
    required this.styleKey,
    required this.config,
    required this.fontFamily,
    required this.onChanged,
    required this.onRemove,
  });

  final TextStyleKey styleKey;
  final TextStyleConfig config;
  final String fontFamily;
  final ValueChanged<TextStyleConfig> onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111316),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: style name + summary + remove btn
          Row(
            spacing: 10,
            children: [
              Text(
                styleKey.label.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),

              Text(
                '$fontFamily  ${config.fontSize.round().toDouble()} · w${config.fontWeight}',
                style: const TextStyle(
                  color: Palette.colorPrimaryCyan,
                  fontSize: 10,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              _Clickable(
                onTap: onRemove,
                child: const Icon(Icons.close, size: 14, color: Colors.white24),
              ),
            ],
          ),
          12.gapH,

          // Text preview
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF0D0D0F),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              styleKey.previewText,
              style: neatTextStyle(
                family: fontFamily,
                cfg: config,
                color: Colors.white,
                sizeOverride: config.fontSize.clamp(10, 42),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          16.gapH,

          // Sliders row
          Row(
            spacing: 16,
            children: [
              Expanded(
                child: _NeatSlider(
                  label: 'FONT SIZE',
                  value: config.fontSize,
                  min: 8,
                  max: 96,
                  unit: '.0',
                  decimals: 0,
                  onChanged: (v) => onChanged(config.copyWith(fontSize: v)),
                ),
              ),
              Expanded(
                child: _WeightSlider(
                  value: config.fontWeight,
                  onChanged: (v) => onChanged(config.copyWith(fontWeight: v)),
                ),
              ),
              Expanded(
                child: _NeatSlider(
                  label: 'LETTER SPACING',
                  value: config.letterSpacing,
                  min: -2,
                  max: 4,
                  unit: '',
                  decimals: 2,
                  onChanged: (v) => onChanged(config.copyWith(letterSpacing: v)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddStyleButton extends StatelessWidget {
  const _AddStyleButton({required this.inactiveKeys, required this.onAdd});

  final List<TextStyleKey> inactiveKeys;
  final ValueChanged<TextStyleKey> onAdd;

  @override
  Widget build(BuildContext context) {
    return _Clickable(
      onTap: () => showDialog<void>(
        context: context,
        builder: (_) => _AddStyleDialog(keys: inactiveKeys, onAdd: onAdd),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white12),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, size: 16, color: Colors.white38),
            SizedBox(width: 8),
            Text('Add style', style: TextStyle(color: Colors.white38, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _AddStyleDialog extends StatelessWidget {
  const _AddStyleDialog({required this.keys, required this.onAdd});

  final List<TextStyleKey> keys;
  final ValueChanged<TextStyleKey> onAdd;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E22),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Add text style', style: TextStyle(color: Colors.white, fontSize: 16)),
      content: SizedBox(
        width: 280,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: keys
              .map(
                (k) => ListTile(
                  title: Text(k.label, style: const TextStyle(color: Colors.white, fontSize: 14)),
                  subtitle: Text(
                    '${kM3Defaults[k]!.fontSize.round().toDouble()} · w${kM3Defaults[k]!.fontWeight}',
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                  onTap: () {
                    onAdd(k);
                    Navigator.pop(context);
                  },
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                ),
              )
              .toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.white38)),
        ),
      ],
    );
  }
}

// ── TAB 3: Buttons & Shapes ───────────────────────────────────────────────────

class _ButtonsShapesTab extends ConsumerWidget {
  const _ButtonsShapesTab();

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
              color: const Color(0xFF111316),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _NeatSlider(
                        label: 'GLOBAL BORDER RADIUS',
                        value: state.containerRadius,
                        min: 0,
                        max: 32,
                        unit: '',
                        decimals: 0,
                        onChanged: notifier.setContainerRadius,
                      ),
                      const SizedBox(height: 16),
                      _NeatSlider(
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
                const SizedBox(width: 24),
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

          const SizedBox(height: 24),

          // ── Button Theme Customizer ──────────────────────────────────────
          SectionHeader(
            iconSize: 16,
            fontSize: 14,
            icon: Icons.smart_button_outlined,
            label: 'Button Theme Customizer',
          ),
          const SizedBox(height: 16),

          _ButtonConfigCard(
            title: 'ELEVATED BUTTON',
            config: state.elevatedButton,
            globalRadius: state.containerRadius,
            previewColor: state.lightScheme.primary,
            onPrimaryColor: state.lightScheme.onPrimary,
            showElevation: true,
            onChanged: notifier.setElevatedButton,
          ),
          const SizedBox(height: 10),
          _ButtonConfigCard(
            title: 'FILLED BUTTON',
            config: state.filledButton,
            globalRadius: state.containerRadius,
            previewColor: state.lightScheme.primary,
            onPrimaryColor: state.lightScheme.onPrimary,
            onChanged: notifier.setFilledButton,
          ),
          const SizedBox(height: 10),
          _ButtonConfigCard(
            title: 'OUTLINED BUTTON',
            config: state.outlinedButton,
            globalRadius: state.containerRadius,
            previewColor: Colors.transparent,
            onPrimaryColor: state.lightScheme.primary,
            showStroke: true,
            borderColor: state.lightScheme.primary,
            onChanged: notifier.setOutlinedButton,
          ),
          const SizedBox(height: 10),
          _ButtonConfigCard(
            title: 'TEXT BUTTON',
            config: state.textButton,
            globalRadius: state.containerRadius,
            previewColor: Colors.transparent,
            onPrimaryColor: state.lightScheme.primary,
            onChanged: notifier.setTextButton,
          ),

          const SizedBox(height: 24),

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
              child: _ComponentToggleCard(
                component: c,
                enabled: state.components.contains(c),
                onChanged: (on) => notifier.toggleComponent(c, on),
              ),
            ),

          const SizedBox(height: 6),
          _WidgetbookToggleCard(
            enabled: state.generateWidgetbook,
            hasComponents: state.components.isNotEmpty,
            onChanged: notifier.setGenerateWidgetbook,
          ),

          const SizedBox(height: 6),
          _SimpleToggleCard(
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
          _BrandingCard(
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

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

/// Upload a PNG logo → NEAT copies it in and generates app icons + native splash
/// (flutter_launcher_icons + flutter_native_splash) at generation time.
class _BrandingCard extends StatelessWidget {
  const _BrandingCard({required this.logoPath, required this.onPick, required this.onRemove});

  final String logoPath;
  final Future<void> Function() onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final hasLogo = logoPath.isNotEmpty && File(logoPath).existsSync();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF18181C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: hasLogo
                ? Image.file(File(logoPath), width: 52, height: 52, fit: BoxFit.cover)
                : Container(
                    width: 52,
                    height: 52,
                    color: Colors.white10,
                    child: Icon(Icons.image_outlined, color: Colors.grey[600]),
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'App icon & splash',
                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  hasLogo
                      ? logoPath.split('/').last
                      : 'Upload a square PNG logo → icons + splash generated for you.',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (hasLogo)
            TextButton(
              onPressed: onRemove,
              style: TextButton.styleFrom(foregroundColor: Colors.white54),
              child: const Text('Remove'),
            ),
          FilledButton.icon(
            onPressed: onPick,
            icon: const Icon(Icons.upload_outlined, size: 16),
            label: Text(hasLogo ? 'Replace' : 'Upload PNG'),
            style: FilledButton.styleFrom(
              backgroundColor: Palette.colorPrimaryCyan,
              foregroundColor: const Color(0xFF0E0E0E),
            ),
          ),
        ],
      ),
    );
  }
}

/// Opt-in card to scaffold a Widgetbook catalog of the generated components.
class _WidgetbookToggleCard extends StatelessWidget {
  const _WidgetbookToggleCard({
    required this.enabled,
    required this.hasComponents,
    required this.onChanged,
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
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF0E1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? Palette.colorPrimaryCyan.withValues(alpha: 0.5) : Colors.white10,
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.menu_book_outlined, color: Palette.colorPrimaryCyan, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Generate Widgetbook',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
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
            const SizedBox(width: 16),
            _Clickable(
              onTap: hasComponents ? () => onChanged(!enabled) : () {},
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 48,
                height: 28,
                decoration: BoxDecoration(
                  color: active ? Palette.colorPrimaryCyan.withValues(alpha: 0.15) : Colors.white10,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: active ? Palette.colorPrimaryCyan : Colors.white12,
                    width: 1.5,
                  ),
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 200),
                  alignment: active ? Alignment.centerRight : Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(3),
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: active ? Palette.colorPrimaryCyan : Colors.grey[700],
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

/// Generic always-enabled toggle card (title + description + switch).
class _SimpleToggleCard extends StatelessWidget {
  const _SimpleToggleCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.enabled,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: enabled ? Palette.colorPrimaryCyan.withValues(alpha: 0.5) : Colors.white10,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: Palette.colorPrimaryCyan, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(color: Colors.grey[500], fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          _Clickable(
            onTap: () => onChanged(!enabled),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48,
              height: 28,
              decoration: BoxDecoration(
                color: enabled ? Palette.colorPrimaryCyan.withValues(alpha: 0.15) : Colors.white10,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: enabled ? Palette.colorPrimaryCyan : Colors.white12,
                  width: 1.5,
                ),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment: enabled ? Alignment.centerRight : Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: enabled ? Palette.colorPrimaryCyan : Colors.grey[700],
                      shape: BoxShape.circle,
                    ),
                    child: enabled
                        ? const Icon(Icons.check, size: 11, color: Color(0xFF0E0E0E))
                        : null,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Opt-in card to generate a reusable design-system component.
class _ComponentToggleCard extends StatelessWidget {
  const _ComponentToggleCard({
    required this.component,
    required this.enabled,
    required this.onChanged,
  });

  final AppComponent component;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF111316),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: enabled ? Palette.colorPrimaryCyan.withValues(alpha: 0.4) : Colors.white10,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  component.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  component.description,
                  style: TextStyle(color: Colors.grey[500], fontSize: 12, height: 1.4),
                ),
                const SizedBox(height: 6),
                Text(
                  'lib/components/${component.fileName}',
                  style: TextStyle(
                    color: Palette.colorPrimaryCyan.withValues(alpha: 0.7),
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          _Clickable(
            onTap: () => onChanged(!enabled),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48,
              height: 28,
              decoration: BoxDecoration(
                color: enabled ? Palette.colorPrimaryCyan.withValues(alpha: 0.15) : Colors.white10,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: enabled ? Palette.colorPrimaryCyan : Colors.white12,
                  width: 1.5,
                ),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment: enabled ? Alignment.centerRight : Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: enabled ? Palette.colorPrimaryCyan : Colors.grey[700],
                      shape: BoxShape.circle,
                    ),
                    child: enabled
                        ? const Icon(Icons.check, size: 11, color: Color(0xFF0E0E0E))
                        : null,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ButtonConfigCard extends StatelessWidget {
  const _ButtonConfigCard({
    required this.title,
    required this.config,
    required this.globalRadius,
    required this.previewColor,
    required this.onPrimaryColor,
    required this.onChanged,
    this.showElevation = false,
    this.showStroke = false,
    this.borderColor,
  });

  final String title;
  final ButtonConfig config;
  final double globalRadius;
  final Color previewColor;
  final Color onPrimaryColor;
  final ValueChanged<ButtonConfig> onChanged;
  final bool showElevation;
  final bool showStroke;
  final Color? borderColor;

  bool get _hasRadiusOverride => config.radiusOverride != null;

  double get _effectiveRadius => config.radiusOverride ?? globalRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111316),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          // Sliders
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),

                // Row 1
                Row(
                  children: [
                    if (showElevation) ...[
                      Expanded(
                        child: _NeatSlider(
                          label: 'Elevation',
                          value: config.elevation ?? 0,
                          min: 0,
                          max: 8,
                          unit: '',
                          decimals: 0,
                          onChanged: (v) => onChanged(config.copyWith(elevation: v)),
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                    if (showStroke) ...[
                      Expanded(
                        child: _NeatSlider(
                          label: 'Stroke',
                          value: config.strokeWidth ?? 1.5,
                          min: 0.5,
                          max: 4,
                          unit: '',
                          decimals: 1,
                          onChanged: (v) => onChanged(config.copyWith(strokeWidth: v)),
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                    // Radius with global fallback indicator
                    Expanded(
                      child: _RadiusOverrideSlider(
                        value: _effectiveRadius,
                        isOverridden: _hasRadiusOverride,
                        globalRadius: globalRadius,
                        onChanged: (v) => onChanged(config.copyWith(radiusOverride: v)),
                        onReset: () => onChanged(config.copyWith(radiusOverride: null)),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Row 2: padding
                Row(
                  children: [
                    Expanded(
                      child: _NeatSlider(
                        label: showElevation ? 'H-Padding' : 'Padding',
                        value: config.hPadding,
                        min: 8,
                        max: 48,
                        unit: '',
                        decimals: 0,
                        onChanged: (v) => onChanged(config.copyWith(hPadding: v)),
                      ),
                    ),
                    if (showElevation) ...[
                      const SizedBox(width: 16),
                      Expanded(
                        child: _NeatSlider(
                          label: 'V-Padding',
                          value: config.vPadding,
                          min: 4,
                          max: 24,
                          unit: '',
                          decimals: 0,
                          onChanged: (v) => onChanged(config.copyWith(vPadding: v)),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 20),

          // Button preview
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFF0D0D0F),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: EdgeInsets.symmetric(
                horizontal: config.hPadding.clamp(8, 32),
                vertical: config.vPadding.clamp(4, 20),
              ),
              decoration: BoxDecoration(
                color: previewColor,
                borderRadius: BorderRadius.circular(_effectiveRadius),
                border: showStroke
                    ? Border.all(
                        color: borderColor ?? Colors.white54,
                        width: config.strokeWidth ?? 1.5,
                      )
                    : null,
                boxShadow: showElevation && (config.elevation ?? 0) > 0
                    ? [
                        BoxShadow(
                          color: Colors.black38,
                          blurRadius: (config.elevation ?? 0) * 2,
                          offset: Offset(0, (config.elevation ?? 0) * 0.5),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                title.split(' ').first,
                style: TextStyle(
                  color: onPrimaryColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RadiusOverrideSlider extends StatelessWidget {
  const _RadiusOverrideSlider({
    required this.value,
    required this.isOverridden,
    required this.globalRadius,
    required this.onChanged,
    required this.onReset,
  });

  final double value;
  final bool isOverridden;
  final double globalRadius;
  final ValueChanged<double> onChanged;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Radius',
              style: const TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1.2),
            ),
            const SizedBox(width: 6),
            Text(
              isOverridden ? '${value.round()}px' : '${globalRadius.round()}px (global)',
              style: TextStyle(
                color: isOverridden ? Palette.colorPrimaryCyan : Colors.white24,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (isOverridden) ...[
              const SizedBox(width: 6),
              _Clickable(
                onTap: onReset,
                child: const Icon(Icons.refresh, size: 12, color: Palette.colorPrimaryCyan),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 2,
            thumbColor: isOverridden ? Palette.colorPrimaryCyan : Colors.white24,
            activeTrackColor: isOverridden ? Palette.colorPrimaryCyan : Colors.white24,
            inactiveTrackColor: Colors.white10,
            overlayColor: Palette.colorPrimaryCyan.withValues(alpha: 0.12),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          ),
          child: Slider(value: value, max: 32, divisions: 32, onChanged: onChanged),
        ),
      ],
    );
  }
}

// ── TAB 4: Flex Color Scheme ──────────────────────────────────────────────────

class _FlexColorSchemeTab extends ConsumerStatefulWidget {
  const _FlexColorSchemeTab();

  @override
  ConsumerState<_FlexColorSchemeTab> createState() => _FlexColorSchemeTabState();
}

class _FlexColorSchemeTabState extends ConsumerState<_FlexColorSchemeTab> {
  late TextEditingController _codeCtrl;

  @override
  void initState() {
    super.initState();
    final existingCode = ref.read(themeEngineProvider.select((s) => s.flexColorSchemeCode));
    _codeCtrl = TextEditingController(text: existingCode ?? '');
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _openPlayground() async {
    await Process.run('open', ['https://rydmike.com/flexcolorscheme/themesplayground-latest/']);
  }

  void _applyCode() {
    final code = _codeCtrl.text.trim();
    ref.read(themeEngineProvider.notifier).setFlexColorSchemeCode(code.isEmpty ? null : code);
    ref.read(themeEngineProvider.notifier).setApproach(ThemeApproach.flexColorScheme);
    neatSnack(
      context,
      code.isEmpty ? 'Code cleared — using default scheme' : 'FlexColorScheme code applied',
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(themeEngineProvider);
    final notifier = ref.read(themeEngineProvider.notifier);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Playground link
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: _openPlayground,
              icon: const Icon(Icons.open_in_new, size: 14),
              label: const Text('Open Playground', style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(
                foregroundColor: Palette.colorPrimaryCyan,
                side: const BorderSide(color: Palette.colorPrimaryCyan),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Code editor ──────────────────────────────────────────────────
          SectionHeader(
            iconSize: 16,
            fontSize: 14,
            icon: Icons.code_outlined,
            label: 'Import Configuration',
          ),
          const SizedBox(height: 16),

          DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFF0D0D0F),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              children: [
                // Top bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: const BoxDecoration(
                    color: Color(0xFF18181C),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.insert_drive_file_outlined, size: 14, color: Colors.white38),
                      const SizedBox(width: 8),
                      const Text(
                        'IMPORT CONFIGURATION',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const Spacer(),
                      OutlinedButton(
                        onPressed: _applyCode,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Palette.colorPrimaryCyan,
                          side: const BorderSide(color: Palette.colorPrimaryCyan),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          minimumSize: Size.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          textStyle: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                        child: const Text('APPLY CODE'),
                      ),
                    ],
                  ),
                ),

                // Code area
                TextField(
                  controller: _codeCtrl,
                  onChanged: (value) {
                    final code = value.trim();
                    ref
                        .read(themeEngineProvider.notifier)
                        .setFlexColorSchemeCode(code.isEmpty ? null : code);
                  },
                  maxLines: 14,
                  style: const TextStyle(
                    color: Color(0xFF9ECE6A),
                    fontFamily: 'monospace',
                    fontSize: 12,
                    height: 1.6,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                    hintText:
                        'Paste the full code generated by the FlexColorScheme playground.\n'
                        'You can paste everything — imports, class, light & dark themes.\n'
                        'NEAT will inject its own extensions automatically.\n\n'
                        'import \'package:flex_color_scheme/flex_color_scheme.dart\';\n'
                        'import \'package:flutter/material.dart\';\n'
                        '...\n'
                        'abstract final class Palette {\n'
                        '  static ThemeData light = FlexThemeData.light(...);\n'
                        '  static ThemeData dark  = FlexThemeData.dark(...);\n'
                        '}',
                    hintStyle: const TextStyle(
                      color: Colors.white12,
                      fontFamily: 'monospace',
                      fontSize: 12,
                      height: 1.6,
                    ),
                  ),
                ),

                // Footer hint
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 11, color: Colors.white12),
                      const SizedBox(width: 6),
                      const Expanded(
                        child: Text(
                          'Paste the full playground output — NEAT handles the rest',
                          style: TextStyle(color: Colors.white12, fontSize: 10),
                        ),
                      ),
                      const Text(
                        'FLEXCOLORSCHEME 8.x',
                        style: TextStyle(color: Colors.white12, fontSize: 10, letterSpacing: 0.8),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Scheme Definition ────────────────────────────────────────────
          SectionHeader(
            iconSize: 16,
            fontSize: 14,
            icon: Icons.tune_outlined,
            label: 'Scheme Definition',
          ),
          const SizedBox(height: 16),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Color tokens
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111316),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.circle_outlined, size: 12, color: Colors.white38),
                          SizedBox(width: 6),
                          Text(
                            'COLOR TOKENS',
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Primary base
                      Row(
                        children: [
                          SizedBox(
                            width: 80,
                            child: Text(
                              'Primary\nBase',
                              style: TextStyle(color: Colors.white54, fontSize: 11),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _ColorHexField(
                              color: state.seedColor,
                              onColorChanged: (c) {
                                notifier.setSeedColor(c);
                                notifier.clearColorOverrides();
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Secondary base (read-only swatch)
                      Row(
                        children: [
                          SizedBox(
                            width: 80,
                            child: Text(
                              'Secondary\nBase',
                              style: TextStyle(color: Colors.white54, fontSize: 11),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              height: 44,
                              decoration: BoxDecoration(
                                color: state.lightScheme.secondary,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.white12),
                              ),
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                '#${state.lightScheme.secondary.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
                                style: TextStyle(
                                  color:
                                      ThemeData.estimateBrightnessForColor(
                                            state.lightScheme.secondary,
                                          ) ==
                                          Brightness.dark
                                      ? Colors.white70
                                      : Colors.black54,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Surface blending
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111316),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.blur_on_outlined, size: 12, color: Colors.white38),
                          SizedBox(width: 6),
                          Text(
                            'SURFACE BLENDING',
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _NeatSlider(
                        label: 'Blend Level',
                        value: state.surfaceBlendLevel,
                        min: 0,
                        max: 40,
                        unit: '%',
                        decimals: 0,
                        onChanged: notifier.setSurfaceBlendLevel,
                      ),
                      const SizedBox(height: 12),
                      _NeatSlider(
                        label: 'On Surface Blend',
                        value: state.onSurfaceBlendLevel,
                        min: 0,
                        max: 40,
                        unit: '%',
                        decimals: 0,
                        onChanged: notifier.setOnSurfaceBlendLevel,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Packaging — available in FlexColorScheme too (not just Custom M3).
          SectionHeader(
            iconSize: 16,
            fontSize: 14,
            icon: Icons.widgets_outlined,
            label: 'Packaging',
          ),
          const SizedBox(height: 12),
          _SimpleToggleCard(
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
          _BrandingCard(
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

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── Live Preview ──────────────────────────────────────────────────────────────

/// Builds a real [TextStyle] from a [TextStyleConfig] using the chosen Google
/// font, so the preview renders exactly what the generated theme will use.
TextStyle neatTextStyle({
  required String family,
  required TextStyleConfig cfg,
  Color? color,
  double? sizeOverride,
}) {
  final weight = FontWeight.values.firstWhere(
    (w) => w.value == cfg.fontWeight,
    orElse: () => FontWeight.w400,
  );
  final base = TextStyle(
    fontSize: sizeOverride ?? cfg.fontSize,
    fontWeight: weight,
    letterSpacing: cfg.letterSpacing,
    height: cfg.height,
    color: color,
  );
  try {
    return GoogleFonts.getFont(family, textStyle: base);
  } catch (_) {
    // Unknown family (typo / offline): fall back to the raw family name.
    return base.copyWith(fontFamily: family);
  }
}

class _LivePreview extends ConsumerWidget {
  const _LivePreview();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(themeEngineProvider);
    final isDark = state.defaultBrightness == Brightness.dark;
    final scheme = state.activeScheme;

    // Resolve a configured text style (falls back to M3 default if removed).
    TextStyle styleFor(TextStyleKey key, Color color, {double? size}) => neatTextStyle(
      family: state.fontFamily,
      cfg: state.textStyles[key] ?? kM3Defaults[key]!,
      color: color,
      sizeOverride: size,
    );

    final surfaceBg = isDark ? const Color(0xFF1C1C1F) : const Color(0xFFF9FAFB);
    final cardBg = isDark ? const Color(0xFF2A2A2E) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF111827);
    final textSecondary = isDark ? Colors.white54 : const Color(0xFF6B7280);

    final shadow = state.cardElevation > 0
        ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06 + state.cardElevation * 0.025),
              blurRadius: state.cardElevation * 3,
              offset: Offset(0, state.cardElevation),
            ),
          ]
        : <BoxShadow>[];

    final filledRadius = state.effectiveRadius(state.filledButton);
    final outlinedRadius = state.effectiveRadius(state.outlinedButton);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header + brightness toggle
        Row(
          children: [
            Container(
              width: 3,
              height: 16,
              decoration: BoxDecoration(
                color: Palette.colorPrimaryCyan,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Live Preview',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            // View generated code
            _Clickable(
              onTap: () {
                final identity = ref.read(identityProvider);
                final pkg = identity.name.trim();
                final webOnly =
                    identity.targetPlatforms.length == 1 && identity.targetPlatforms.first == 'web';
                final code = ThemeTemplates.appThemeForState(
                  theme: state,
                  packageName: pkg.isEmpty ? 'app' : pkg,
                  useScreenUtil: !webOnly,
                );
                showDialog<void>(
                  context: context,
                  builder: (_) => _GeneratedCodeDialog(code: code),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Palette.colorPrimaryCyan.withValues(alpha: 0.4)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.code, size: 13, color: Palette.colorPrimaryCyan),
                    SizedBox(width: 5),
                    Text(
                      'Code',
                      style: TextStyle(
                        color: Palette.colorPrimaryCyan,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _Clickable(
              onTap: () => ref
                  .read(themeEngineProvider.notifier)
                  .setDefaultBrightness(isDark ? Brightness.light : Brightness.dark),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 28,
                width: 60,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2A2A2E) : const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
                ),
                child: Stack(
                  children: [
                    AnimatedAlign(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      alignment: isDark ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white12 : Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isDark ? Icons.dark_mode : Icons.light_mode,
                          size: 13,
                          color: isDark ? Colors.white54 : const Color(0xFFF59E0B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: surfaceBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
          ),
          child: Column(
            children: [
              // Card
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(state.containerRadius),
                  border: isDark ? Border.all(color: Colors.white.withValues(alpha: 0.08)) : null,
                  boxShadow: shadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: scheme.primaryContainer,
                            borderRadius: BorderRadius.circular(state.containerRadius * 0.6),
                          ),
                          child: Icon(
                            Icons.auto_fix_high_outlined,
                            color: scheme.onPrimaryContainer,
                            size: 17,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: scheme.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'NEW THEME',
                            style: styleFor(TextStyleKey.labelSmall, scheme.primary, size: 8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text('Card Anatomy', style: styleFor(TextStyleKey.titleMedium, textPrimary)),
                    const SizedBox(height: 3),
                    Text(
                      'Observing the fluid radius dynamics.',
                      style: styleFor(TextStyleKey.bodySmall, textSecondary),
                    ),
                    if (state.cardElevation > 0) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.layers_outlined, size: 10, color: textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            '${state.cardElevation.round()}dp elevation',
                            style: TextStyle(color: textSecondary, fontSize: 9),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Filled button — reflects radius, padding & elevation from config
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  vertical: state.filledButton.vPadding.clamp(6, 18),
                  horizontal: state.filledButton.hPadding,
                ),
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(filledRadius),
                  boxShadow: (state.filledButton.elevation ?? 0) > 0
                      ? [
                          BoxShadow(
                            color: scheme.primary.withValues(alpha: 0.4),
                            blurRadius: (state.filledButton.elevation ?? 0) * 2.5,
                            offset: Offset(0, (state.filledButton.elevation ?? 0) * 0.6),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  'PRIMARY ACTION',
                  style: styleFor(TextStyleKey.labelLarge, scheme.onPrimary),
                ),
              ),

              const SizedBox(height: 8),

              // Outlined button — reflects radius, padding & stroke from config
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  vertical: state.outlinedButton.vPadding.clamp(6, 18),
                  horizontal: state.outlinedButton.hPadding,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(outlinedRadius),
                  border: Border.all(
                    color: scheme.primary,
                    width: state.outlinedButton.strokeWidth ?? 1.5,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  'SECONDARY GHOST',
                  style: styleFor(TextStyleKey.labelLarge, scheme.primary),
                ),
              ),

              const SizedBox(height: 8),

              // Text field
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 36,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A1A1E) : Colors.white,
                  borderRadius: BorderRadius.circular(state.effectiveRadius(state.outlinedButton)),
                  border: Border.all(color: isDark ? Colors.white24 : const Color(0xFFD1D5DB)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                alignment: Alignment.centerLeft,
                child: Text(
                  'Text field…',
                  style: styleFor(
                    TextStyleKey.bodySmall,
                    isDark ? Colors.white38 : const Color(0xFF9CA3AF),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

/// Shows a consistent floating snackbar (cyan = success, red = error).
void neatSnack(BuildContext context, String message, {bool success = true}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: success ? const Color(0xFF0E1A1A) : const Color(0xFF2A1A1A),
        duration: const Duration(seconds: 2),
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              success ? Icons.check_circle_outline : Icons.error_outline,
              color: success ? Palette.colorPrimaryCyan : Colors.redAccent,
              size: 18,
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(message, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
}

/// A tap target that shows the pointer cursor on hover (desktop affordance).
/// Drop-in replacement for a simple `GestureDetector(onTap:, child:)`.
class _Clickable extends StatelessWidget {
  const _Clickable({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(onTap: onTap, behavior: HitTestBehavior.opaque, child: child),
    );
  }
}

/// Reusable styled slider
class _NeatSlider extends StatelessWidget {
  const _NeatSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.unit,
    required this.decimals,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final String unit;
  final int decimals;
  final ValueChanged<double> onChanged;

  String _format(double v) =>
      decimals == 0 ? '${v.round()}$unit' : '${v.toStringAsFixed(decimals)}$unit';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1.0),
            ),
            Text(
              _format(value),
              style: const TextStyle(
                color: Palette.colorPrimaryCyan,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 2,
            thumbColor: Palette.colorPrimaryCyan,
            activeTrackColor: Palette.colorPrimaryCyan,
            inactiveTrackColor: Colors.white10,
            overlayColor: Palette.colorPrimaryCyan.withValues(alpha: 0.12),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          ),
          child: Slider(value: value.clamp(min, max), min: min, max: max, onChanged: onChanged),
        ),
      ],
    );
  }
}

class _WeightSlider extends StatelessWidget {
  const _WeightSlider({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  static const _weights = [100, 200, 300, 400, 500, 600, 700, 800, 900];

  @override
  Widget build(BuildContext context) {
    final idx = _weights.indexOf(value).clamp(0, _weights.length - 1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'FONT WEIGHT',
              style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1.0),
            ),
            Text(
              'w$value',
              style: const TextStyle(
                color: Palette.colorPrimaryCyan,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 2,
            thumbColor: Palette.colorPrimaryCyan,
            activeTrackColor: Palette.colorPrimaryCyan,
            inactiveTrackColor: Colors.white10,
            overlayColor: Palette.colorPrimaryCyan.withValues(alpha: 0.12),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          ),
          child: Slider(
            value: idx.toDouble(),
            max: (_weights.length - 1).toDouble(),
            divisions: _weights.length - 1,
            onChanged: (v) => onChanged(_weights[v.round()]),
          ),
        ),
      ],
    );
  }
}

/// Popular Google Fonts shown as suggestions. Any other valid Google Font name
/// can still be typed — it's validated by attempting to load it.
const _popularGoogleFonts = <String>[
  'Inter',
  'Poppins',
  'Roboto',
  'Open Sans',
  'Lato',
  'Montserrat',
  'Nunito',
  'Raleway',
  'Work Sans',
  'DM Sans',
  'Plus Jakarta Sans',
  'Outfit',
  'Manrope',
  'Sora',
  'Space Grotesk',
  'Rubik',
  'Mulish',
  'Karla',
  'Quicksand',
  'Josefin Sans',
  'Source Sans 3',
  'PT Sans',
  'Noto Sans',
  'Lexend',
  'Playfair Display',
  'Merriweather',
  'Lora',
  'Bitter',
  'Roboto Slab',
  'Roboto Mono',
  'JetBrains Mono',
  'Fira Code',
];

/// Searchable font picker: filter the popular list, or type any Google Font
/// name (validated on submit).
class _FontSelector extends StatelessWidget {
  const _FontSelector({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  void _apply(BuildContext context, String font, {TextEditingController? controller}) {
    final name = font.trim();
    if (name.isEmpty) return;
    try {
      GoogleFonts.getFont(name); // throws if not a known Google Font
      onChanged(name);
    } catch (_) {
      controller?.text = value;
      neatSnack(context, '"$name" not found on Google Fonts', success: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      // Autocomplete only reads initialValue when its internal state is first
      // created — without this key, an external change to [value] (the
      // typography Reset button) would never reach the visible text field.
      key: ValueKey(value),
      initialValue: TextEditingValue(text: value),
      optionsBuilder: (t) {
        final q = t.text.trim().toLowerCase();
        if (q.isEmpty) return _popularGoogleFonts;
        return _popularGoogleFonts.where((f) => f.toLowerCase().contains(q));
      },
      onSelected: (f) => _apply(context, f),
      fieldViewBuilder: (context, controller, focusNode, onSubmit) {
        return Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1E),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            children: [
              const Icon(Icons.search, color: Colors.white24, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    hintText: 'Search a Google Font…',
                    hintStyle: TextStyle(color: Colors.white24, fontSize: 13),
                  ),
                  onSubmitted: (v) => _apply(context, v, controller: controller),
                ),
              ),
            ],
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            color: const Color(0xFF1E1E22),
            elevation: 8,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260, maxWidth: 320),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 4),
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, i) {
                  final f = options.elementAt(i);
                  return InkWell(
                    onTap: () => onSelected(f),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      child: Text(
                        f,
                        style: TextStyle(
                          color: f == value ? Palette.colorPrimaryCyan : Colors.white70,
                          fontSize: 13,
                          fontWeight: f == value ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BaseSizeField extends StatefulWidget {
  const _BaseSizeField({required this.value, required this.onChanged});

  final double value;
  final ValueChanged<double> onChanged;

  @override
  State<_BaseSizeField> createState() => _BaseSizeFieldState();
}

class _BaseSizeFieldState extends State<_BaseSizeField> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value.round().toString());
  }

  @override
  void didUpdateWidget(_BaseSizeField old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _ctrl.text = widget.value.round().toString();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: TextField(
        controller: _ctrl,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(2),
        ],
        decoration: const InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 11),
        ),
        onSubmitted: (v) {
          final n = double.tryParse(v);
          if (n != null && n >= 10 && n <= 24) widget.onChanged(n);
        },
        onTapOutside: (_) {
          final n = double.tryParse(_ctrl.text);
          if (n != null && n >= 10 && n <= 24) widget.onChanged(n);
          FocusScope.of(context).unfocus();
        },
      ),
    );
  }
}

// ── Hex color field ───────────────────────────────────────────────────────────

class _ColorHexField extends StatefulWidget {
  const _ColorHexField({required this.color, required this.onColorChanged});

  final Color color;
  final ValueChanged<Color> onColorChanged;

  @override
  State<_ColorHexField> createState() => _ColorHexFieldState();
}

class _ColorHexFieldState extends State<_ColorHexField> {
  late TextEditingController _ctrl;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: _toHex(widget.color));
  }

  @override
  void didUpdateWidget(_ColorHexField old) {
    super.didUpdateWidget(old);
    if (!_focused && old.color != widget.color) {
      _ctrl.text = _toHex(widget.color);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _toHex(Color c) {
    final v = c.toARGB32();
    return '#${v.toRadixString(16).substring(2).toUpperCase()}';
  }

  void _submit() {
    var text = _ctrl.text.trim().replaceAll('#', '');
    if (text.length == 6) text = 'FF$text';
    final v = int.tryParse(text, radix: 16);
    if (v != null) widget.onColorChanged(Color(v | 0xFF000000));
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (f) => setState(() => _focused = f),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1E),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.white12),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _ctrl,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[#0-9a-fA-F]')),
                  LengthLimitingTextInputFormatter(7),
                ],
                onSubmitted: (_) => _submit(),
                onTapOutside: (_) {
                  _submit();
                  FocusScope.of(context).unfocus();
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.colorize_outlined, size: 18, color: Colors.white38),
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => _ColorPickerDialog(
                  initial: widget.color,
                  onPicked: (c) {
                    widget.onColorChanged(c);
                    _ctrl.text = _toHex(c);
                  },
                ),
              ),
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}

// ── Color picker dialog ───────────────────────────────────────────────────────

class _ColorPickerDialog extends StatefulWidget {
  const _ColorPickerDialog({
    required this.initial,
    required this.onPicked,
    this.isOverridden = false,
    this.onReset,
  });

  final Color initial;
  final ValueChanged<Color> onPicked;
  final bool isOverridden;
  final VoidCallback? onReset;

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late Color _current;
  late TextEditingController _hexCtrl;

  static const _swatches = [
    Color(0xFF00DCE5),
    Color(0xFF6366F1),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
    Color(0xFFEF4444),
    Color(0xFFF97316),
    Color(0xFFEAB308),
    Color(0xFF22C55E),
    Color(0xFF14B8A6),
    Color(0xFF3B82F6),
    Color(0xFF0EA5E9),
    Color(0xFF64748B),
    Color(0xFF1E293B),
    Color(0xFF000000),
    Color(0xFFFFFFFF),
  ];

  @override
  void initState() {
    super.initState();
    _current = widget.initial;
    _hexCtrl = TextEditingController(text: _toHex(widget.initial));
  }

  @override
  void dispose() {
    _hexCtrl.dispose();
    super.dispose();
  }

  String _toHex(Color c) {
    final v = c.toARGB32();
    return '#${v.toRadixString(16).substring(2).toUpperCase()}';
  }

  void _submitHex() {
    var text = _hexCtrl.text.trim().replaceAll('#', '');
    if (text.length == 6) text = 'FF$text';
    final v = int.tryParse(text, radix: 16);
    if (v != null) setState(() => _current = Color(v | 0xFF000000));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E22),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Pick a color', style: TextStyle(color: Colors.white, fontSize: 16)),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Hex input
            Container(
              height: 40,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF111316),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 10),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: _current,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.white12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _hexCtrl,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[#0-9a-fA-F]')),
                        LengthLimitingTextInputFormatter(7),
                      ],
                      onSubmitted: (_) => _submitHex(),
                      onTapOutside: (_) => _submitHex(),
                    ),
                  ),
                ],
              ),
            ),
            // Swatches
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _swatches.map((c) {
                final selected = _current.toARGB32() == c.toARGB32();
                return _Clickable(
                  onTap: () => setState(() {
                    _current = c;
                    _hexCtrl.text = _toHex(c);
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: c,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: selected ? Colors.white : Colors.white12,
                        width: selected ? 2 : 1,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        if (widget.isOverridden && widget.onReset != null)
          TextButton(
            onPressed: () {
              widget.onReset!();
              Navigator.pop(context);
            },
            child: const Text('Reset to auto', style: TextStyle(color: Colors.white38)),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.white38)),
        ),
        FilledButton(
          onPressed: () {
            widget.onPicked(_current);
            Navigator.pop(context);
          },
          style: FilledButton.styleFrom(backgroundColor: Palette.colorPrimaryCyan),
          child: const Text('Apply', style: TextStyle(color: Colors.black)),
        ),
      ],
    );
  }
}

// ── Generated code preview dialog ───────────────────────────────────────────

class _GeneratedCodeDialog extends StatelessWidget {
  const _GeneratedCodeDialog({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0D0D0F),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760, maxHeight: 640),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFF18181C),
                borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.code, size: 16, color: Palette.colorPrimaryCyan),
                  const SizedBox(width: 8),
                  const Text(
                    'app_theme.dart',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '· preview of generated code',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 11),
                  ),
                  const Spacer(),
                  _Clickable(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: code));
                      neatSnack(context, 'Copied to clipboard');
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Palette.colorPrimaryCyan.withValues(alpha: 0.4)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.copy_outlined, size: 13, color: Palette.colorPrimaryCyan),
                          SizedBox(width: 6),
                          Text(
                            'Copy',
                            style: TextStyle(
                              color: Palette.colorPrimaryCyan,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _Clickable(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.close, size: 18, color: Colors.white38),
                  ),
                ],
              ),
            ),
            // Code body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SelectableText(
                    code,
                    style: const TextStyle(
                      color: Color(0xFF9ECE6A),
                      fontFamily: 'monospace',
                      fontSize: 12,
                      height: 1.5,
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
