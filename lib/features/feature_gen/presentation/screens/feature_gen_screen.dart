import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:neat/features/feature_gen/presentation/providers/workshop_controller.dart';
import 'package:neat/features/feature_gen/presentation/screens/workshop.dart';
import 'package:neat/features/shell/presentation/providers/stepper_provider.dart';
import 'package:neat_ui/neat_ui.dart';

/// Workshop mode: open an existing NEAT project (via its `.neat.json`) and
/// generate a new feature. The project stack is fixed by the contract; the
/// Workshop only exposes the choices that genuinely vary per feature (routing
/// shape + which Clean Architecture layers to scaffold).
class FeatureGenScreen extends HookConsumerWidget {
  const FeatureGenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workshopState = ref.watch(workshopControllerProvider);
    final workshopNotifier = ref.read(workshopControllerProvider.notifier);

    return Column(
      crossAxisAlignment: .start,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(color: Colors.transparent),
          child: Padding(
            padding: const .fromLTRB(0, 28, 20, 24),
            child: Row(
              spacing: 12,
              children: [
                InkWell(
                  onTap: () => ref.read(currentStepProvider.notifier).setStep(NeatStep.hub),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: context.neatColors.colorSurfaceCard,
                      borderRadius: .circular(10),
                      border: .all(
                        color: context.neatColors.colorPrimaryCyan.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Icon(Icons.bolt, color: context.neatColors.colorPrimaryCyan, size: 22),
                  ),
                ),

                Text('Feature Workshop', style: context.textTheme.headlineLarge),
              ],
            ),
          ),
        ),
        Text(
          'Generate production-ready features for your existing project. '
          'Select layers and routing strategy.',
          style: context.textTheme.bodyLarge,
        ),
        20.gapH,
        Expanded(
          child: Workshop(
            state: workshopState,
            onGenerate: workshopNotifier.generateFeature,
            onClose: () {
              workshopNotifier.close();
              ref.read(currentStepProvider.notifier).setStep(NeatStep.hub);
            },
            onImportTranslations: workshopNotifier.importTranslations,
          ),
        ),
        24.gapH,
      ],
    );
  }
}
