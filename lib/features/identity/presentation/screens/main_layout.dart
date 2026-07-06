import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:neat/core/app_info/app_version_provider.dart';
import 'package:neat/features/architecture/presentation/providers/architecture_provider.dart';
import 'package:neat/features/architecture/presentation/screens/architecture_screen.dart';
import 'package:neat/features/cicd/presentation/screens/cicd_screen.dart';
import 'package:neat/features/dependencies/domain/models/pub_package.dart';
import 'package:neat/features/dependencies/presentation/providers/dependencies_provider.dart';
import 'package:neat/features/dependencies/presentation/screens/dependencies_screen.dart';
import 'package:neat/features/feature_gen/presentation/screens/feature_gen_screen.dart';
import 'package:neat/features/hub/presentation/screens/hub_screen.dart';
import 'package:neat/features/identity/domain/models/identity_state.dart';
import 'package:neat/features/identity/presentation/providers/identity_provider.dart';
import 'package:neat/features/identity/presentation/providers/stepper_provider.dart';
import 'package:neat/features/identity/presentation/screens/identity/identity_screen.dart';
import 'package:neat/features/identity/presentation/screens/launch_screen.dart';
import 'package:neat/features/infrastructure/presentation/providers/infrastructure_tab_provider.dart';
import 'package:neat/features/infrastructure/presentation/screens/infrastructure_screen.dart';
import 'package:neat/features/theme_engine/domain/models/theme_engine_state.dart';
import 'package:neat/features/theme_engine/presentation/providers/theme_engine_provider.dart';
import 'package:neat/features/theme_engine/presentation/screens/theme_engine_screen.dart';
import 'package:neat_ui/neat_ui.dart';

class MainLayout extends ConsumerWidget {
  const MainLayout({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentStep = ref.watch(currentStepProvider);

    // The Hub (landing) and the Workshop are full-screen modes — no wizard
    // sidebar. The sidebar belongs to the creation wizard only.
    if (currentStep == NeatStep.hub) return const HubScreen();
    if (currentStep == NeatStep.featureGen) return const _WorkshopMode();

    return Scaffold(
      body: Row(
        children: [
          // ── Sidebar ───────────────────────────────────────────────────────
          Container(
            width: 240,
            color: context.neatColors.mainDark,
            child: Column(
              children: [
                // Logo + version (click → back to the Hub)
                InkWell(
                  onTap: () => ref.read(currentStepProvider.notifier).setStep(NeatStep.hub),
                  child: Padding(
                    padding: const .fromLTRB(20, 28, 20, 24),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: context.neatColors.mainDark,
                            borderRadius: .circular(10),
                            border: .all(color: Palette.colorPrimaryCyan.withValues(alpha: 0.4)),
                          ),
                          child: const Icon(Icons.bolt, color: Palette.colorPrimaryCyan, size: 22),
                        ),
                        12.gapW,
                        Column(
                          crossAxisAlignment: .start,
                          children: [
                            Text(
                              'NEAT',
                              style: TextStyle(
                                color: context.neatColors.colorPrimaryCyan,
                                fontSize: 20,
                                fontWeight: .bold,
                                letterSpacing: 2,
                              ),
                            ),
                            Container(
                              padding: const .symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                border: .all(color: context.neatColors.surface10),
                                borderRadius: .circular(3),
                              ),
                              child: Text(
                                ref
                                    .watch(appVersionProvider)
                                    .maybeWhen(data: (v) => v.toUpperCase(), orElse: () => '…'),
                                style: TextStyle(
                                  color: context.neatColors.mainFont,
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
                ),

                Divider(color: context.neatColors.mainFont, height: 1),
                16.gapH,

                // Wizard steps (featureGen / Workshop is reached from the Hub).
                _buildItem(ref, NeatStep.identity, 'IDENTITY', Icons.fingerprint_outlined),
                _buildItem(ref, NeatStep.themeEngine, 'THEME ENGINE', Icons.palette_outlined),
                _buildItem(
                  ref,
                  NeatStep.infrastructure,
                  'INFRASTRUCTURE',
                  Icons.extension_outlined,
                ),
                if (currentStep == NeatStep.infrastructure) ...[
                  _buildSubItem(ref, InfrastructureTab.backend, 'BACKEND'),
                  _buildSubItem(ref, InfrastructureTab.navigation, 'NAVIGATION'),
                  _buildSubItem(ref, InfrastructureTab.localization, 'LOCALIZATION'),
                ],
                _buildItem(ref, NeatStep.packages, 'DEPENDENCIES', Icons.extension_outlined),
                _buildItem(ref, NeatStep.architecture, 'ARCHITECTURE', Icons.account_tree_outlined),
                _buildItem(ref, NeatStep.cicd, 'CI/CD', Icons.rocket_outlined),

                const Spacer(),

                // Progress bar
                if (currentStep.isWizardStep)
                  Padding(
                    padding: const .fromLTRB(20, 0, 20, 28),
                    child: Column(
                      crossAxisAlignment: .start,
                      spacing: 8,
                      children: [
                        Row(
                          mainAxisAlignment: .spaceBetween,
                          children: [
                            Text(
                              'PROGRESS',
                              style: context.textTheme.labelMedium!.copyWith(letterSpacing: 1.2),
                            ),
                            Text(
                              '${currentStep.wizardIndex + 1}/${NeatStepX.wizardTotal}',
                              style: context.textTheme.labelMedium,
                            ),
                          ],
                        ),

                        ClipRRect(
                          borderRadius: .circular(4),
                          child: LinearProgressIndicator(
                            value: (currentStep.wizardIndex + 1) / NeatStepX.wizardTotal,
                            backgroundColor: context.neatColors.surface10,
                            valueColor: const AlwaysStoppedAnimation(Palette.colorPrimaryCyan),
                            minHeight: 4,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          Container(width: 1, color: context.neatColors.surface10),

          // ── Contenu central ───────────────────────────────────────────────
          Expanded(
            child: Column(
              children: [
                // Screen content
                Expanded(
                  child: Container(
                    padding: const .fromLTRB(40, 40, 40, 0),
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
        margin: const .symmetric(horizontal: 12, vertical: 2),
        padding: const .symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Palette.colorPrimaryCyan.withValues(alpha: 0.08) : Colors.transparent,
          borderRadius: .circular(8),
          border: .all(
            color: isSelected
                ? Palette.colorPrimaryCyan.withValues(alpha: 0.3)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Palette.colorPrimaryCyan
                  : reachable
                  ? Colors.grey[600]
                  : Colors.grey[800],
              size: 16,
            ),
            10.gapW,
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

  /// A sub-item nested under a [NeatStep] (currently only Infrastructure's
  /// Backend/Navigation/Localization). Unlike [_buildItem], it never locks —
  /// these are groupings within one already-unlocked wizard step, not
  /// sequential milestones, so every sub-tab is freely clickable.
  Widget _buildSubItem(WidgetRef ref, InfrastructureTab tab, String label) {
    final current = ref.watch(currentInfrastructureTabProvider);
    final isSelected = current == tab;

    return InkWell(
      onTap: () => ref.read(currentInfrastructureTabProvider.notifier).setTab(tab),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const .fromLTRB(28, 1, 12, 1),
        padding: const .symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Palette.colorPrimaryCyan.withValues(alpha: 0.06) : Colors.transparent,
          borderRadius: .circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Palette.colorPrimaryCyan : Colors.grey[600],
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            letterSpacing: 0.6,
          ),
        ),
      ),
    );
  }

  Widget _screenFor(NeatStep step) {
    return switch (step) {
      NeatStep.identity => const IdentityScreen(),
      NeatStep.themeEngine => const ThemeEngineScreen(),
      NeatStep.infrastructure => const InfrastructureScreen(),
      NeatStep.packages => const DependenciesScreen(),
      NeatStep.architecture => const ArchitectureScreen(),
      NeatStep.cicd => const CicdScreen(),
      NeatStep.launch => const LaunchScreen(),
      // hub + featureGen are full-screen modes handled before _screenFor.
      NeatStep.hub || NeatStep.featureGen => const SizedBox.shrink(),
    };
  }
}

// ── Workshop mode (full screen, with a back-to-Hub bar) ─────────────────────────

class _WorkshopMode extends ConsumerWidget {
  const _WorkshopMode();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Column(
        children: [
          const Expanded(
            child: Padding(padding: EdgeInsets.fromLTRB(40, 16, 40, 0), child: FeatureGenScreen()),
          ),
        ],
      ),
    );
  }
}

// ── Shared nav bar ────────────────────────────────────────────────────────────

class _NavBar extends ConsumerWidget {
  const _NavBar({required this.step});

  final NeatStep step;

  static const _infraTabs = [
    InfrastructureTab.backend,
    InfrastructureTab.navigation,
    InfrastructureTab.localization,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(currentStepProvider.notifier);
    final prev = step.previousStep;
    final next = step.nextStep;

    // Infrastructure has 3 sub-tabs (see infrastructure_tab_provider.dart) —
    // Back/Next walk those first, and only cross into the previous/next
    // NeatStep once at the first/last sub-tab. The step-level PROGRESS bar
    // is unaffected: infrastructure stays a single wizardIndex throughout.
    final infraTab = step == NeatStep.infrastructure
        ? ref.watch(currentInfrastructureTabProvider)
        : null;
    final infraTabIndex = infraTab == null ? -1 : _infraTabs.indexOf(infraTab);
    final infraTabNotifier = ref.read(currentInfrastructureTabProvider.notifier);

    final bool canGoNext = _isStepValid(step, ref);

    // Launch: Back is locked while generation runs
    final bool canGoBack = switch (step) {
      NeatStep.launch => !ref.watch(isGeneratingProvider),
      _ => true,
    };

    void goNext() {
      if (infraTab != null && infraTabIndex < _infraTabs.length - 1) {
        infraTabNotifier.setTab(_infraTabs[infraTabIndex + 1]);
        return;
      }
      // Lazy: add flex dep here if user chose FlexColorScheme
      if (step == NeatStep.themeEngine) {
        final approach = ref.read(themeEngineProvider.select((s) => s.approach));
        if (approach == ThemeApproach.flexColorScheme) {
          ref.read(selectedPackagesProvider.notifier).addAll([
            const PubPackage(
              name: 'flex_color_scheme',
              version: '8.0.2',
              description: 'Advanced Flutter theming with Material 3 surface blending.',
              pubPoints: 160,
              popularity: 95,
            ),
          ]);
        }
      }
      if (next != null) {
        ref.read(furthestStepProvider.notifier).reach(next.wizardIndex);
        notifier.setStep(next);
      }
    }

    void goBack() {
      if (infraTab != null && infraTabIndex > 0) {
        infraTabNotifier.setTab(_infraTabs[infraTabIndex - 1]);
        return;
      }
      if (prev != null) notifier.setStep(prev);
    }

    final showBack = prev != null || infraTabIndex > 0;
    final showNext = next != null || (infraTab != null && infraTabIndex < _infraTabs.length - 1);

    return Container(
      padding: const .fromLTRB(40, 16, 40, 24),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white10)),
      ),

      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button (hidden on the very first step/sub-tab)
          if (showBack)
            OutlinedButton.icon(
              onPressed: canGoBack ? goBack : null,
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('Back'),
              style: OutlinedButton.styleFrom(minimumSize: const Size(120, 48)),
            )
          else
            120.gapW,

          // Next / Launch button (hidden on the very last step)
          if (showNext)
            OutlinedButton.icon(
              onPressed: canGoNext ? goNext : null,
              icon: Icon(step.nextIcon, size: 16),
              label: Text(step.nextLabel),
              style: FilledButton.styleFrom(
                minimumSize: const Size(160, 48),
                backgroundColor: Palette.colorPrimaryCyan,
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
    NeatStep.architecture => ref.watch(
      architectureProvider.select((s) => s.validateFirstFeatureName() == null),
    ),
    _ => true,
  };
}

/// Returns true if the user can navigate to [target] given the [current] step.
/// Going backwards (or staying) is always allowed. Going forward is limited to
/// steps already unlocked via the Next button — so every step is mandatory and
/// the side-nav can never skip ahead.
bool _canNavigateTo(NeatStep target, NeatStep current, WidgetRef ref) {
  if (!target.isWizardStep) return true; // featureGen is always accessible
  if (target.wizardIndex <= current.wizardIndex) return true; // back or self
  return target.wizardIndex <= ref.watch(furthestStepProvider);
}
