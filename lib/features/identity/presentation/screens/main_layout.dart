import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:neat/core/theme/app_theme.dart';
import 'package:neat/features/architecture/presentation/screens/architecture_screen.dart';
import 'package:neat/features/cicd/presentation/screens/cicd_screen.dart';
import 'package:neat/features/dependencies/domain/models/pub_package.dart';
import 'package:neat/features/dependencies/presentation/providers/dependencies_provider.dart';
import 'package:neat/features/dependencies/presentation/screens/dependencies_screen.dart';
import 'package:neat/features/identity/presentation/providers/identity_provider.dart';
import 'package:neat/features/identity/presentation/providers/stepper_provider.dart';
import 'package:neat/features/identity/presentation/screens/identity/identity_screen.dart';
import 'package:neat/features/identity/presentation/screens/launch_screen.dart';
import 'package:neat/features/theme_engine/presentation/providers/theme_engine_provider.dart';
import 'package:neat/features/theme_engine/presentation/screens/theme_engine_screen.dart';

class MainLayout extends ConsumerWidget {
  const MainLayout({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentStep = ref.watch(currentStepProvider);

    return Scaffold(
      body: Row(
        children: [
          // ── Sidebar ───────────────────────────────────────────────────────
          Container(
            width: 240,
            color: Theme.of(context).colorScheme.surface,
            child: Column(
              children: [
                // Logo + version
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF111416),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppTheme.colorPrimaryCyan.withValues(alpha: 0.4),
                          ),
                        ),
                        child: const Icon(Icons.bolt, color: AppTheme.colorPrimaryCyan, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'NEAT',
                            style: TextStyle(
                              color: AppTheme.colorPrimaryCyan,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white12),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: const Text(
                              'V1.0.0-BETA',
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: 9,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const Divider(color: Colors.white10, height: 1),
                const SizedBox(height: 16),

                // Wizard steps
                _buildItem(ref, NeatStep.identity, 'IDENTITY', Icons.fingerprint_outlined),
                _buildItem(ref, NeatStep.themeEngine, 'THEME ENGINE', Icons.palette_outlined),
                _buildItem(ref, NeatStep.dependencies, 'DEPENDENCIES', Icons.extension_outlined),
                _buildItem(ref, NeatStep.architecture, 'ARCHITECTURE', Icons.account_tree_outlined),
                _buildItem(ref, NeatStep.cicd, 'CI/CD', Icons.rocket_outlined),

                const Divider(color: Colors.white10, height: 1, indent: 16, endIndent: 16),
                const SizedBox(height: 8),

                // Feature Gen (outil séparé)
                _buildItem(ref, NeatStep.featureGen, 'FEATURE GEN', Icons.construction_outlined),

                const Spacer(),

                // Progress bar
                if (currentStep.isWizardStep)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'PROGRESS',
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: 10,
                                letterSpacing: 1.2,
                              ),
                            ),
                            Text(
                              '${currentStep.wizardIndex + 1}/${NeatStepX.wizardTotal}',
                              style: const TextStyle(color: Colors.white38, fontSize: 10),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: (currentStep.wizardIndex + 1) / NeatStepX.wizardTotal,
                            backgroundColor: Colors.white10,
                            valueColor: const AlwaysStoppedAnimation(AppTheme.colorPrimaryCyan),
                            minHeight: 4,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          Container(width: 1, color: Colors.white10),

          // ── Contenu central ───────────────────────────────────────────────
          Expanded(
            child: Column(
              children: [
                // Screen content
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(40, 40, 40, 0),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: _screenFor(currentStep),
                    ),
                  ),
                ),
                // Nav bar (wizard steps only, not featureGen)
                if (currentStep.isWizardStep) _NavBar(step: currentStep),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(WidgetRef ref, NeatStep step, String label, IconData icon) {
    final current = ref.watch(currentStepProvider);
    final isSelected = current == step;
    final reachable = _canNavigateTo(step, current, ref);

    return InkWell(
      onTap: reachable ? () => ref.read(currentStepProvider.notifier).setStep(step) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.colorPrimaryCyan.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? AppTheme.colorPrimaryCyan.withValues(alpha: 0.3)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? AppTheme.colorPrimaryCyan
                  : reachable
                  ? Colors.grey[600]
                  : Colors.grey[800],
              size: 16,
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : reachable
                    ? Colors.grey[500]
                    : Colors.grey[700],
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                letterSpacing: 0.8,
              ),
            ),
            if (!reachable) ...[
              const Spacer(),
              const Icon(Icons.lock_outline, size: 11, color: Colors.white12),
            ],
          ],
        ),
      ),
    );
  }

  Widget _screenFor(NeatStep step) {
    return switch (step) {
      NeatStep.identity => const IdentityScreen(),
      NeatStep.themeEngine => const ThemeEngineScreen(),
      NeatStep.dependencies => const DependenciesScreen(),
      NeatStep.architecture => const ArchitectureScreen(),
      NeatStep.cicd => const CicdScreen(),
      NeatStep.launch => const LaunchScreen(),
      NeatStep.featureGen => const Center(
        child: Text('Feature Gen', style: TextStyle(fontSize: 20, color: Colors.white)),
      ),
    };
  }
}

// ── Shared nav bar ────────────────────────────────────────────────────────────

class _NavBar extends ConsumerWidget {
  const _NavBar({required this.step});

  final NeatStep step;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(currentStepProvider.notifier);
    final prev = step.previousStep;
    final next = step.nextStep;

    final bool canGoNext = _isStepValid(step, ref);

    // Launch: Back is locked while generation runs
    final bool canGoBack = switch (step) {
      NeatStep.launch => !ref.watch(isGeneratingProvider),
      _ => true,
    };

    return Container(
      padding: const EdgeInsets.fromLTRB(40, 16, 40, 24),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white10)),
      ),

      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button (hidden on first step)
          if (prev != null)
            OutlinedButton.icon(
              onPressed: canGoBack ? () => notifier.setStep(prev) : null,
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('Back'),
              style: OutlinedButton.styleFrom(minimumSize: const Size(120, 48)),
            )
          else
            const SizedBox(width: 120),

          // Next / Launch button (hidden on last step)
          if (next != null)
            OutlinedButton.icon(
              onPressed: canGoNext
                  ? () {
                      // Lazy: add flex dep here if user chose FlexColorScheme
                      if (step == NeatStep.themeEngine) {
                        final approach = ref.read(themeEngineProvider.select((s) => s.approach));
                        if (approach == ThemeApproach.flexColorScheme) {
                          ref.read(selectedPackagesProvider.notifier).addAll([
                            const PubPackage(
                              name: 'flex_color_scheme',
                              version: '8.0.2',
                              description:
                                  'Advanced Flutter theming with Material 3 surface blending.',
                              pubPoints: 160,
                              popularity: 95,
                            ),
                          ]);
                        }
                      }
                      notifier.setStep(next);
                    }
                  : null,
              icon: Icon(step.nextIcon, size: 16),
              label: Text(step.nextLabel),
              style: FilledButton.styleFrom(
                minimumSize: const Size(160, 48),
                backgroundColor: AppTheme.colorPrimaryCyan,
                foregroundColor: Colors.black,
                disabledBackgroundColor: Colors.white12,
                disabledForegroundColor: Colors.white24,
                iconColor: Colors.black,
                disabledIconColor: Colors.white24,
              ),
            ),
        ],
      ),
    );
  }
}

// ── Step validation helpers ───────────────────────────────────────────────────

/// Returns true if [step]'s own requirements are met (used for Next button).
bool _isStepValid(NeatStep step, WidgetRef ref) {
  return switch (step) {
    NeatStep.identity => ref.watch(
      identityProvider.select((s) => s.isIdentityValid && s.projectPath.isNotEmpty),
    ),
    NeatStep.themeEngine => ref.watch(
      themeEngineProvider.select((s) => s.approach != ThemeApproach.none),
    ),
    _ => true,
  };
}

/// Returns true if the user can navigate to [target] given the [current] step.
/// Going backwards (or staying) is always allowed.
/// Going forward requires all preceding steps to be valid.
bool _canNavigateTo(NeatStep target, NeatStep current, WidgetRef ref) {
  if (!target.isWizardStep) return true; // featureGen is always accessible
  if (target.wizardIndex <= current.wizardIndex) return true;

  // Every step before the target must be valid
  final steps = [
    NeatStep.identity,
    NeatStep.themeEngine,
    NeatStep.dependencies,
    NeatStep.architecture,
    NeatStep.cicd,
    NeatStep.launch,
  ];
  for (var i = 0; i < target.wizardIndex; i++) {
    if (!_isStepValid(steps[i], ref)) return false;
  }
  return true;
}
