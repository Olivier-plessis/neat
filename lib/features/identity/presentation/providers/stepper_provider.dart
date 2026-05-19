import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'stepper_provider.g.dart';

enum NeatStep { identity, dependencies, architecture, cicd, launch, featureGen }

extension NeatStepX on NeatStep {
  static const _wizardSteps = [
    NeatStep.identity,
    NeatStep.dependencies,
    NeatStep.architecture,
    NeatStep.cicd,
    NeatStep.launch,
  ];

  int get wizardIndex => _wizardSteps.indexOf(this);
  bool get isWizardStep => wizardIndex >= 0;
  static int get wizardTotal => _wizardSteps.length;
}

@Riverpod(keepAlive: true)
class CurrentStep extends _$CurrentStep {
  @override
  NeatStep build() => NeatStep.identity;

  void setStep(NeatStep step) => state = step;
}
