import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'stepper_provider.g.dart';

enum NeatStep { identity, dependencies, cicd, launch, featureGen }

@Riverpod(keepAlive: true)
class CurrentStep extends _$CurrentStep {
  @override
  NeatStep build() => NeatStep.identity;

  void setStep(NeatStep step) => state = step;
}
