import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:neat/core/theme/app_theme.dart';
import 'package:neat/features/dependencies/presentation/providers/dependencies_provider.dart';
import 'package:neat/features/theme_engine/domain/services/color_extractor_service.dart';
import 'package:neat/features/theme_engine/presentation/providers/theme_engine_provider.dart';

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
        const Text(
          'Design System Architect',
          style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Generate a professional Material 3 design system for your Flutter application.\n'
          'Adjust parameters in real-time and preview the visual output.',
          style: TextStyle(color: Colors.white54, fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 32),

        Expanded(
          child: approach == ThemeApproach.none ? const _EntryPoint() : const _TabbedEditor(),
        ),
      ],
    );
  }
}

// ── Entry point — approach selection ─────────────────────────────────────────

class _EntryPoint extends ConsumerWidget {
  const _EntryPoint();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: Row(
          children: [
            Expanded(
              child: _ApproachCard(
                icon: Icons.palette_outlined,
                title: 'Custom your scheme',
                description:
                    'Build a fully custom Material 3 design system.\nConfigure colors, typography, shapes and more.',
                onTap: () =>
                    ref.read(themeEngineProvider.notifier).setApproach(ThemeApproach.customM3),
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: _ApproachCard(
                icon: Icons.auto_awesome_outlined,
                title: 'Flex Color Scheme',
                description:
                    'Use FlexColorScheme for advanced surface\nblending and powerful tonal schemes.',
                onTap: () {
                  // Dep is added lazily when the user presses Next
                  ref.read(themeEngineProvider.notifier).setApproach(ThemeApproach.flexColorScheme);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ApproachCard extends StatefulWidget {
  const _ApproachCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  State<_ApproachCard> createState() => _ApproachCardState();
}

class _ApproachCardState extends State<_ApproachCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: _hovered
              ? AppTheme.colorPrimaryCyan.withValues(alpha: 0.06)
              : const Color(0xFF111316),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hovered
                ? AppTheme.colorPrimaryCyan.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.08),
            width: _hovered ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 8),
            Icon(
              widget.icon,
              size: 40,
              color: _hovered ? AppTheme.colorPrimaryCyan : Colors.white38,
            ),
            const SizedBox(height: 20),
            Text(
              widget.title,
              style: TextStyle(
                color: _hovered ? Colors.white : Colors.white70,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              widget.description,
              style: const TextStyle(color: Colors.white38, fontSize: 13, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: widget.onTap,
              style: OutlinedButton.styleFrom(
                foregroundColor: _hovered ? AppTheme.colorPrimaryCyan : Colors.white54,
                side: BorderSide(color: _hovered ? AppTheme.colorPrimaryCyan : Colors.white24),
                minimumSize: const Size(140, 42),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text(
                'STARTED',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
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
                        color: AppTheme.colorPrimaryCyan.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppTheme.colorPrimaryCyan.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppTheme.colorPrimaryCyan,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 7),
                          const Text(
                            'FLEX COLOR SCHEME',
                            style: TextStyle(
                              color: AppTheme.colorPrimaryCyan,
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
                    GestureDetector(
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
                  child: IndexedStack(
                    index: activeTab.value,
                    children: const [_ColorsTab(), _TypographyTab(), _ButtonsShapesTab()],
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
        return GestureDetector(
          onTap: () => onTabSelected(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.only(right: 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isActive ? AppTheme.colorPrimaryCyan : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
            child: Text(
              _kTabLabels[i],
              style: TextStyle(
                color: isActive ? AppTheme.colorPrimaryCyan : Colors.white38,
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
  bool _extracting = false;

  Future<void> _pickImage() async {
    final result = await FilePicker.pickFiles(type: FileType.image);
    if (result == null || result.files.single.path == null) return;
    final path = result.files.single.path!;
    ref.read(themeEngineProvider.notifier).setImagePath(path);
    setState(() => _extracting = true);
    final color = await const ColorExtractorService().extractSeedColor(path);
    if (color != null && mounted) {
      ref.read(themeEngineProvider.notifier).setSeedColor(color);
      ref.read(themeEngineProvider.notifier).clearColorOverrides();
    }
    if (mounted) setState(() => _extracting = false);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(themeEngineProvider);
    final scheme = state.lightScheme;
    final imagePath = state.imagePath;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Palette Generator ────────────────────────────────────────────
          _SectionHeader(icon: Icons.palette_outlined, label: 'Palette Generator'),
          const SizedBox(height: 16),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image drop zone
              GestureDetector(
                onTap: _pickImage,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 260,
                  height: 230,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _extracting ? AppTheme.colorPrimaryCyan : Colors.white12,
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
                              if (_extracting)
                                ColoredBox(
                                  color: Colors.black54,
                                  child: const Center(
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppTheme.colorPrimaryCyan,
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
                    const SizedBox(height: 8),
                    _ColorHexField(
                      color: state.seedColor,
                      onColorChanged: (c) {
                        ref.read(themeEngineProvider.notifier).setSeedColor(c);
                        ref.read(themeEngineProvider.notifier).clearColorOverrides();
                      },
                    ),
                    const SizedBox(height: 16),
                    // Overrides hint
                    if (state.primaryOverride != null ||
                        state.secondaryOverride != null ||
                        state.tertiaryOverride != null)
                      GestureDetector(
                        onTap: () => ref.read(themeEngineProvider.notifier).clearColorOverrides(),
                        child: const Text(
                          '↩ Reset all color overrides',
                          style: TextStyle(
                            color: AppTheme.colorPrimaryCyan,
                            fontSize: 11,
                            decoration: TextDecoration.underline,
                            decorationColor: AppTheme.colorPrimaryCyan,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Generated color swatches ─────────────────────────────────────
          _SectionHeader(icon: Icons.grid_view_outlined, label: 'Generated Palette'),
          const SizedBox(height: 12),

          // Row 1: primary, primaryContainer, secondary, surfaceHigh
          Row(
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
              const SizedBox(width: 10),
              Expanded(
                child: _SwatchTile(label: 'primaryContainer', color: scheme.primaryContainer),
              ),
              const SizedBox(width: 10),
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
              const SizedBox(width: 10),
              Expanded(
                child: _SwatchTile(label: 'surfaceHigh', color: scheme.surfaceContainerHighest),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Row 2: onPrimary, onPrimaryContainer, onSecondary, outline
          Row(
            children: [
              Expanded(
                child: _SwatchTile(label: 'onPrimary', color: scheme.onPrimary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SwatchTile(label: 'onPrimaryContainer', color: scheme.onPrimaryContainer),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SwatchTile(label: 'onSecondary', color: scheme.onSecondary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SwatchTile(label: 'outline', color: scheme.outline),
              ),
            ],
          ),

          const SizedBox(height: 24),
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

    return GestureDetector(
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
                  _FontDropdown(value: state.fontFamily, onChanged: notifier.setFontFamily),
                ],
              ),
            ),
            const SizedBox(width: 16),
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
            const SizedBox(width: 16),
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
        const SizedBox(height: 20),

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
              const SizedBox(width: 10),
              Text(
                '$fontFamily  ${config.fontSize.round().toDouble()} · w${config.fontWeight}',
                style: const TextStyle(
                  color: AppTheme.colorPrimaryCyan,
                  fontSize: 10,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onRemove,
                child: const Icon(Icons.close, size: 14, color: Colors.white24),
              ),
            ],
          ),
          const SizedBox(height: 12),

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
              style: TextStyle(
                color: Colors.white,
                fontSize: config.fontSize.clamp(10, 42),
                fontWeight: FontWeight.values.firstWhere(
                  (w) => w.value == config.fontWeight,
                  orElse: () => FontWeight.w400,
                ),
                letterSpacing: config.letterSpacing,
                height: config.height,
                fontFamily: fontFamily,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 14),

          // Sliders row
          Row(
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
              const SizedBox(width: 16),
              Expanded(
                child: _WeightSlider(
                  value: config.fontWeight,
                  onChanged: (v) => onChanged(config.copyWith(fontWeight: v)),
                ),
              ),
              const SizedBox(width: 16),
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
    return GestureDetector(
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
          _SectionHeader(icon: Icons.rounded_corner_outlined, label: 'Global Shape Geometry'),
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
                    color: AppTheme.colorPrimaryCyan.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(state.containerRadius),
                    border: Border.all(color: AppTheme.colorPrimaryCyan.withValues(alpha: 0.5)),
                  ),
                  child: Icon(
                    Icons.crop_square_outlined,
                    color: AppTheme.colorPrimaryCyan.withValues(alpha: 0.6),
                    size: 28,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Button Theme Customizer ──────────────────────────────────────
          _SectionHeader(icon: Icons.smart_button_outlined, label: 'Button Theme Customizer'),
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
                color: isOverridden ? AppTheme.colorPrimaryCyan : Colors.white24,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (isOverridden) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: onReset,
                child: const Icon(Icons.refresh, size: 12, color: AppTheme.colorPrimaryCyan),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 2,
            thumbColor: isOverridden ? AppTheme.colorPrimaryCyan : Colors.white24,
            activeTrackColor: isOverridden ? AppTheme.colorPrimaryCyan : Colors.white24,
            inactiveTrackColor: Colors.white10,
            overlayColor: AppTheme.colorPrimaryCyan.withValues(alpha: 0.12),
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
                foregroundColor: AppTheme.colorPrimaryCyan,
                side: const BorderSide(color: AppTheme.colorPrimaryCyan),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Code editor ──────────────────────────────────────────────────
          _SectionHeader(icon: Icons.code_outlined, label: 'Import Configuration'),
          const SizedBox(height: 12),

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
                          foregroundColor: AppTheme.colorPrimaryCyan,
                          side: const BorderSide(color: AppTheme.colorPrimaryCyan),
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
                        'abstract final class AppTheme {\n'
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
          _SectionHeader(icon: Icons.tune_outlined, label: 'Scheme Definition'),
          const SizedBox(height: 12),

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
        ],
      ),
    );
  }
}

// ── Live Preview ──────────────────────────────────────────────────────────────

class _LivePreview extends ConsumerWidget {
  const _LivePreview();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(themeEngineProvider);
    final isDark = state.defaultBrightness == Brightness.dark;
    final scheme = state.activeScheme;

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
                color: AppTheme.colorPrimaryCyan,
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
            GestureDetector(
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
                            style: TextStyle(
                              color: scheme.primary,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Card Anatomy',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Observing the fluid radius dynamics.',
                      style: TextStyle(color: textSecondary, fontSize: 11, height: 1.4),
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

              // Filled button
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                height: 38,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(filledRadius),
                ),
                alignment: Alignment.center,
                child: Text(
                  'PRIMARY ACTION',
                  style: TextStyle(
                    color: scheme.onPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Outlined button
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                height: 38,
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
                  style: TextStyle(
                    color: scheme.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
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
                  style: TextStyle(
                    color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
                    fontSize: 11,
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.colorPrimaryCyan, size: 16),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
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
                color: AppTheme.colorPrimaryCyan,
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
            thumbColor: AppTheme.colorPrimaryCyan,
            activeTrackColor: AppTheme.colorPrimaryCyan,
            inactiveTrackColor: Colors.white10,
            overlayColor: AppTheme.colorPrimaryCyan.withValues(alpha: 0.12),
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
                color: AppTheme.colorPrimaryCyan,
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
            thumbColor: AppTheme.colorPrimaryCyan,
            activeTrackColor: AppTheme.colorPrimaryCyan,
            inactiveTrackColor: Colors.white10,
            overlayColor: AppTheme.colorPrimaryCyan.withValues(alpha: 0.12),
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

class _FontDropdown extends StatelessWidget {
  const _FontDropdown({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: const Color(0xFF1E1E22),
          style: const TextStyle(color: Colors.white, fontSize: 13),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white38, size: 18),
          items: availableFontFamilies
              .map(
                (f) => DropdownMenuItem(
                  value: f,
                  child: Text(f == availableFontFamilies.first ? '$f (Recommended)' : f),
                ),
              )
              .toList(),
          onChanged: (v) => v != null ? onChanged(v) : null,
        ),
      ),
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
                return GestureDetector(
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
          style: FilledButton.styleFrom(backgroundColor: AppTheme.colorPrimaryCyan),
          child: const Text('Apply', style: TextStyle(color: Colors.black)),
        ),
      ],
    );
  }
}
