import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:neat/features/identity/presentation/providers/identity_provider.dart';
import 'package:neat/features/theme_engine/domain/models/theme_engine_state.dart';
import 'package:neat/features/theme_engine/domain/services/theme_templates.dart';
import 'package:neat/features/theme_engine/presentation/providers/theme_engine_provider.dart';
import 'package:neat/features/theme_engine/presentation/screens/widget/dialog/generated_code_dialog.dart';
import 'package:neat/features/theme_engine/utils/neat_text_style.dart';
import 'package:neat_ui/neat_ui.dart';

class LivePreviewCard extends ConsumerWidget {
  const LivePreviewCard({super.key});

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

    final filledRadius = state.filledButtonRadius;
    final outlinedRadius = state.outlinedButtonRadius;

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
            Clickable(
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
                  builder: (_) => GeneratedCodeDialog(code: code),
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
            Clickable(
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
                  borderRadius: BorderRadius.circular(outlinedRadius),
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
