import 'package:flutter/material.dart';
import 'package:neat/features/architecture/presentation/providers/architecture_provider.dart';
import 'package:neat/features/cicd/presentation/providers/cicd_provider.dart';
import 'package:neat/features/dependencies/presentation/providers/dependencies_provider.dart';
import 'package:neat/features/identity/presentation/providers/identity_provider.dart';
import 'package:neat/features/infrastructure/presentation/providers/infrastructure_tab_provider.dart';
import 'package:neat/features/theme_engine/presentation/providers/theme_engine_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'stepper_provider.g.dart';

/// [hub] is the landing screen (Create vs. Open). The middle six are the
/// creation wizard; [featureGen] is the Workshop (reached from the Hub).
enum NeatStep {
  hub,
  identity,
  themeEngine,
  infrastructure,
  packages,
  architecture,
  cicd,
  launch,
  featureGen,
}

extension NeatStepX on NeatStep {
  static const _wizardSteps = [
    NeatStep.identity,
    NeatStep.themeEngine,
    NeatStep.infrastructure,
    NeatStep.packages,
    NeatStep.architecture,
    NeatStep.cicd,
    NeatStep.launch,
  ];

  int get wizardIndex => _wizardSteps.indexOf(this);

  bool get isWizardStep => wizardIndex >= 0;

  static int get wizardTotal => _wizardSteps.length;

  NeatStep? get previousStep {
    if (!isWizardStep) return null;
    final idx = wizardIndex;
    return idx > 0 ? _wizardSteps[idx - 1] : null;
  }

  NeatStep? get nextStep {
    if (!isWizardStep) return null;
    final idx = wizardIndex;
    return idx < _wizardSteps.length - 1 ? _wizardSteps[idx + 1] : null;
  }

  String get nextLabel {
    final next = nextStep;
    if (next == NeatStep.launch) return 'Launch';
    return 'Next Step';
  }

  IconData get nextIcon {
    final next = nextStep;
    if (next == NeatStep.launch) return Icons.rocket_launch_outlined;
    return Icons.arrow_forward;
  }
}

@Riverpod(keepAlive: true)
class CurrentStep extends _$CurrentStep {
  @override
  NeatStep build() => NeatStep.hub;

  void setStep(NeatStep step) => state = step;

  /// Every wizard-input provider is `keepAlive: true` (state must survive
  /// navigating *between* steps of one flow) — which also means it survives
  /// leaving the wizard entirely. Without this, a 2nd "Create New Project"
  /// (after generating, or after a detour through the Workshop) reopens the
  /// wizard still full of the previous project's name/architecture/packages/
  /// theme/CI-CD choices. Call from the Hub's "Create New Project" button.
  void startNewProject() {
    ref.invalidate(identityProvider);
    ref.invalidate(architectureProvider);
    ref.invalidate(themeEngineProvider);
    ref.invalidate(extractingImageProvider);
    ref.invalidate(selectedPackagesProvider);
    ref.invalidate(searchQueryProvider);
    ref.invalidate(cicdProvider);
    ref.invalidate(currentInfrastructureTabProvider);
    ref.read(furthestStepProvider.notifier).reset();
    state = NeatStep.identity;
  }
}

/// The furthest wizard step the user has unlocked (its [NeatStepX.wizardIndex]).
///
/// Only advances via the Next button (which gates on the current step's
/// validity), so the side-nav can never skip ahead — every step is mandatory.
/// Reset to 0 when a fresh project is started from the Hub.
@Riverpod(keepAlive: true)
class FurthestStep extends _$FurthestStep {
  @override
  int build() => 0;

  void reach(int wizardIndex) {
    if (wizardIndex > state) state = wizardIndex;
  }

  void reset() => state = 0;
}

/// Shared flag: true while the launch generation process is running.
/// Read by main_layout to disable the Back button during generation.
@Riverpod(keepAlive: true)
class IsGenerating extends _$IsGenerating {
  @override
  bool build() => false;

  // ignore: use_setters_to_change_properties
  void set(bool value) => state = value;
}
