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

String _$currentStepHash() => r'b6695ac38d40847b845dd5922b82922e242026b8';

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

/// The furthest wizard step the user has unlocked (its [NeatStepX.wizardIndex]).
///
/// Only advances via the Next button (which gates on the current step's
/// validity), so the side-nav can never skip ahead — every step is mandatory.
/// Reset to 0 when a fresh project is started from the Hub.

@ProviderFor(FurthestStep)
final furthestStepProvider = FurthestStepProvider._();

/// The furthest wizard step the user has unlocked (its [NeatStepX.wizardIndex]).
///
/// Only advances via the Next button (which gates on the current step's
/// validity), so the side-nav can never skip ahead — every step is mandatory.
/// Reset to 0 when a fresh project is started from the Hub.
final class FurthestStepProvider extends $NotifierProvider<FurthestStep, int> {
  /// The furthest wizard step the user has unlocked (its [NeatStepX.wizardIndex]).
  ///
  /// Only advances via the Next button (which gates on the current step's
  /// validity), so the side-nav can never skip ahead — every step is mandatory.
  /// Reset to 0 when a fresh project is started from the Hub.
  FurthestStepProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'furthestStepProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$furthestStepHash();

  @$internal
  @override
  FurthestStep create() => FurthestStep();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$furthestStepHash() => r'412d6994e1ef0ac5dfa23350dbf8d9cd2ca352da';

/// The furthest wizard step the user has unlocked (its [NeatStepX.wizardIndex]).
///
/// Only advances via the Next button (which gates on the current step's
/// validity), so the side-nav can never skip ahead — every step is mandatory.
/// Reset to 0 when a fresh project is started from the Hub.

abstract class _$FurthestStep extends $Notifier<int> {
  int build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Shared flag: true while the launch generation process is running.
/// Read by main_layout to disable the Back button during generation.

@ProviderFor(IsGenerating)
final isGeneratingProvider = IsGeneratingProvider._();

/// Shared flag: true while the launch generation process is running.
/// Read by main_layout to disable the Back button during generation.
final class IsGeneratingProvider extends $NotifierProvider<IsGenerating, bool> {
  /// Shared flag: true while the launch generation process is running.
  /// Read by main_layout to disable the Back button during generation.
  IsGeneratingProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'isGeneratingProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$isGeneratingHash();

  @$internal
  @override
  IsGenerating create() => IsGenerating();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$isGeneratingHash() => r'e8f82f925336e086d75556f49ffb1b5ec4f9ac97';

/// Shared flag: true while the launch generation process is running.
/// Read by main_layout to disable the Back button during generation.

abstract class _$IsGenerating extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
