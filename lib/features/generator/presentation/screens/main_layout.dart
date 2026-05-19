import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:neat/core/theme/app_theme.dart';
import 'package:neat/features/generator/presentation/screens/identity_screen.dart';

import '../providers/stepper_provider.dart';

class MainLayout extends ConsumerWidget {
  const MainLayout({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentStep = ref.watch(currentStepProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: Row(
        children: [
          // 1. SIDEBAR FIXE (Gauche)
          Container(
            width: 260,
            color: theme.colorScheme.surface,
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NEAT',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        'Flutter Architect',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Les éléments du Stepper
                _buildSidebarItem(
                  ref,
                  NeatStep.identity,
                  'Identity',
                  Icons.badge_outlined,
                ),
                _buildSidebarItem(
                  ref,
                  NeatStep.dependencies,
                  'Dependencies',
                  Icons.boy_rounded,
                ),
                _buildSidebarItem(
                  ref,
                  NeatStep.cicd,
                  'CI/CD',
                  Icons.layers_outlined,
                ),
                _buildSidebarItem(
                  ref,
                  NeatStep.launch,
                  "Launch",
                  Icons.rocket_launch_outlined,
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Divider(
                    color: Colors.white10,
                    indent: 16,
                    endIndent: 16,
                  ),
                ),

                _buildSidebarItem(
                  ref,
                  NeatStep.featureGen,
                  "Feature Gen",
                  Icons.construction_outlined,
                ),
              ],
            ),
          ),

          // Séparateur fin style IDE
          Container(width: 1, color: Colors.white10),

          // 2. COMPOSANT CENTRAL DYNAMIQUE (Droite)
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(40),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _getScreenForStep(currentStep),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(
    WidgetRef ref,
    NeatStep step,
    String label,
    IconData icon,
  ) {
    final activeStep = ref.watch(currentStepProvider);
    final isSelected = activeStep == step;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      leading: Icon(
        icon,
        color: isSelected ? AppTheme.colorPrimaryCyan : Colors.grey,
        size: 20,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.grey[400],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 14,
        ),
      ),
      selected: isSelected,
      onTap: () => ref.read(currentStepProvider.notifier).setStep(step),
    );
  }

  Widget _getScreenForStep(NeatStep step) {
    // Écrans de transition temporaires en attendant de coder chaque vue
    switch (step) {
      case NeatStep.identity:
        return const IdentityScreen();
      case NeatStep.dependencies:
        return const Center(
          child: Text(
            "Dependencies Content",
            style: TextStyle(fontSize: 20, color: Colors.white),
          ),
        );
      case NeatStep.cicd:
        return const Center(
          child: Text(
            "CI/CD Pipeline Content",
            style: TextStyle(fontSize: 20, color: Colors.white),
          ),
        );
      case NeatStep.launch:
        return const Center(
          child: Text(
            "Ready for Launch Content",
            style: TextStyle(fontSize: 20, color: Colors.white),
          ),
        );
      case NeatStep.featureGen:
        return const Center(
          child: Text(
            "Feature Gen Content",
            style: TextStyle(fontSize: 20, color: Colors.white),
          ),
        );
    }
  }
}
