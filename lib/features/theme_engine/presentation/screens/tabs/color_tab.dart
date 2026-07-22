import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:neat/features/theme_engine/domain/services/color_extractor_service.dart';
import 'package:neat/features/theme_engine/presentation/providers/theme_engine_provider.dart';
import 'package:neat/features/theme_engine/presentation/screens/widget/color_hex_field.dart';
import 'package:neat/features/theme_engine/presentation/screens/widget/editable_swatch_tile.dart';
import 'package:neat_ui/neat_ui.dart';

class ColorsTab extends ConsumerStatefulWidget {
  const ColorsTab({super.key});

  @override
  ConsumerState<ColorsTab> createState() => _ColorsTabState();
}

class _ColorsTabState extends ConsumerState<ColorsTab> {
  Future<void> _pickImage() async {
    final result = await FilePicker.pickFiles(type: FileType.image);
    final path = result?.files.single.path;
    if (path != null) await _useImagePath(path);
  }

  /// Shared by both the click-to-browse picker and [DropZone]'s drop
  /// handler, so extracting a seed color works identically either way.
  Future<void> _useImagePath(String path) async {
    final extractingImage = ref.read(extractingImageProvider.notifier);
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
        crossAxisAlignment: .start,
        children: [
          // ── Palette Generator ────────────────────────────────────────────
          SectionHeader(
            iconSize: 16,
            fontSize: 14,
            icon: Icons.palette_outlined,
            label: 'Palette Generator',
          ),
          16.gapH,

          Row(
            crossAxisAlignment: .start,
            children: [
              // Image drop zone
              DropZone(
                allowedExtensions: const ['png', 'jpg', 'jpeg', 'webp'],
                onFilePicked: _useImagePath,
                onRejected: () =>
                    neatSnack(context, 'Drop an image file (PNG/JPG/WEBP)', success: false),
                child: Clickable(
                  onTap: _pickImage,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 260,
                    height: 230,
                    decoration: BoxDecoration(
                      color: context.neatColors.colorSurfaceCard,
                      borderRadius: .circular(12),
                      border: .all(
                        color: extractingImage ? Palette.colorPrimaryCyan : Colors.white12,
                        style: imagePath == null ? BorderStyle.solid : BorderStyle.solid,
                      ),
                    ),
                    child: imagePath != null
                        ? ClipRRect(
                            borderRadius: .circular(11),
                            child: Stack(
                              fit: .expand,
                              children: [
                                Image.file(File(imagePath), fit: .cover),
                                if (extractingImage)
                                  ColoredBox(
                                    color: context.neatColors.colorNeutralBg,
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
                              10.gapH,
                              Text(
                                'Extract from Image',
                                style: context.textTheme.titleMedium,
                                textAlign: TextAlign.center,
                              ),
                              4.gapH,
                              Text(
                                'Drop logo or reference board',
                                style: context.textTheme.labelSmall,
                                textAlign: TextAlign.center,
                              ),
                              18.gapH,
                              Container(
                                padding: const .symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  border: .all(color: Colors.white24),
                                  borderRadius: .circular(6),
                                ),
                                child: Text('BROWSE FILES', style: context.textTheme.labelSmall),
                              ),
                            ],
                          ),
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
                    ColorHexField(
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
                      Clickable(
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
                child: EditableSwatchTile(
                  label: 'primary',
                  color: scheme.primary,
                  currentOverride: state.primaryOverride,
                  onColorChanged: (c) =>
                      ref.read(themeEngineProvider.notifier).setPrimaryOverride(c),
                  onReset: () => ref.read(themeEngineProvider.notifier).setPrimaryOverride(null),
                ),
              ),
              Expanded(
                child: EditableSwatchTile(
                  label: 'primaryContainer',
                  color: scheme.primaryContainer,
                  currentOverride: state.primaryContainerOverride,
                  onColorChanged: (c) =>
                      ref.read(themeEngineProvider.notifier).setPrimaryContainerOverride(c),
                  onReset: () =>
                      ref.read(themeEngineProvider.notifier).setPrimaryContainerOverride(null),
                ),
              ),
              Expanded(
                child: EditableSwatchTile(
                  label: 'secondary',
                  color: scheme.secondary,
                  currentOverride: state.secondaryOverride,
                  onColorChanged: (c) =>
                      ref.read(themeEngineProvider.notifier).setSecondaryOverride(c),
                  onReset: () => ref.read(themeEngineProvider.notifier).setSecondaryOverride(null),
                ),
              ),
              Expanded(
                child: EditableSwatchTile(
                  label: 'surfaceHigh',
                  color: scheme.surfaceContainerHighest,
                  currentOverride: state.surfaceContainerHighestOverride,
                  onColorChanged: (c) =>
                      ref.read(themeEngineProvider.notifier).setSurfaceContainerHighestOverride(c),
                  onReset: () => ref
                      .read(themeEngineProvider.notifier)
                      .setSurfaceContainerHighestOverride(null),
                ),
              ),
            ],
          ),
          10.gapH,
          // Row 2: onPrimary, onPrimaryContainer, onSecondary, outline
          Row(
            spacing: 10,
            children: [
              Expanded(
                child: EditableSwatchTile(
                  label: 'onPrimary',
                  color: scheme.onPrimary,
                  currentOverride: state.onPrimaryOverride,
                  onColorChanged: (c) =>
                      ref.read(themeEngineProvider.notifier).setOnPrimaryOverride(c),
                  onReset: () => ref.read(themeEngineProvider.notifier).setOnPrimaryOverride(null),
                ),
              ),
              Expanded(
                child: EditableSwatchTile(
                  label: 'onPrimaryContainer',
                  color: scheme.onPrimaryContainer,
                  currentOverride: state.onPrimaryContainerOverride,
                  onColorChanged: (c) =>
                      ref.read(themeEngineProvider.notifier).setOnPrimaryContainerOverride(c),
                  onReset: () =>
                      ref.read(themeEngineProvider.notifier).setOnPrimaryContainerOverride(null),
                ),
              ),
              Expanded(
                child: EditableSwatchTile(
                  label: 'onSecondary',
                  color: scheme.onSecondary,
                  currentOverride: state.onSecondaryOverride,
                  onColorChanged: (c) =>
                      ref.read(themeEngineProvider.notifier).setOnSecondaryOverride(c),
                  onReset: () =>
                      ref.read(themeEngineProvider.notifier).setOnSecondaryOverride(null),
                ),
              ),
              Expanded(
                child: EditableSwatchTile(
                  label: 'outline',
                  color: scheme.outline,
                  currentOverride: state.outlineOverride,
                  onColorChanged: (c) =>
                      ref.read(themeEngineProvider.notifier).setOutlineOverride(c),
                  onReset: () => ref.read(themeEngineProvider.notifier).setOutlineOverride(null),
                ),
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
                child: EditableSwatchTile(
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
                child: EditableSwatchTile(
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
