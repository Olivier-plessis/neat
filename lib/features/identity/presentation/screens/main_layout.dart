import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:neat/core/theme/app_theme.dart';
import 'package:neat/features/architecture/presentation/screens/architecture_screen.dart';
import 'package:neat/features/cicd/presentation/screens/cicd_screen.dart';
import 'package:neat/features/dependencies/presentation/screens/dependencies_screen.dart';
import 'package:neat/features/identity/presentation/screens/identity/identity_screen.dart';
import 'package:neat/features/identity/presentation/screens/launch_screen.dart';

import '../providers/stepper_provider.dart';

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
            child: Container(
              padding: const EdgeInsets.all(40),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _screenFor(currentStep),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(WidgetRef ref, NeatStep step, String label, IconData icon) {
    final current = ref.watch(currentStepProvider);
    final isSelected = current == step;

    return InkWell(
      onTap: () => ref.read(currentStepProvider.notifier).setStep(step),
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
            Icon(icon, color: isSelected ? AppTheme.colorPrimaryCyan : Colors.grey[600], size: 16),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[500],
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _screenFor(NeatStep step) {
    return switch (step) {
      NeatStep.identity => const IdentityScreen(),
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
