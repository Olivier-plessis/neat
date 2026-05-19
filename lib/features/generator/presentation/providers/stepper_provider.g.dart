// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stepper_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CurrentStep)
final currentStepProvider = CurrentStepProvider._();

final class CurrentStepProvider
    extends $NotifierProvider<CurrentStep, NeatStep> {
  CurrentStepProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentStepProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentStepHash();

  @$internal
  @override
  CurrentStep create() => CurrentStep();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NeatStep value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NeatStep>(value),
    );
  }
}

String _$currentStepHash() => r'851c9d43bbca937015060307704b3605c9de777f';

abstract class _$CurrentStep extends $Notifier<NeatStep> {
  NeatStep build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<NeatStep, NeatStep>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<NeatStep, NeatStep>,
              NeatStep,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
