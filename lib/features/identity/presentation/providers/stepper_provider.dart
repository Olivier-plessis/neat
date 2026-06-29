import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'stepper_provider.g.dart';

/// [hub] is the landing screen (Create vs. Open). The middle six are the
/// creation wizard; [featureGen] is the Workshop (reached from the Hub).
enum NeatStep { hub, identity, themeEngine, dependencies, architecture, cicd, launch, featureGen }

extension NeatStepX on NeatStep {
  static const _wizardSteps = [
    NeatStep.identity,
    NeatStep.themeEngine,
    NeatStep.dependencies,
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
