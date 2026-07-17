// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feature_form_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Scoped per [NeatContract] (family) and auto-disposed (default, no
/// keepAlive) — the Workshop can only be reached with a project already
/// loaded and closing it always routes back through the Hub first (see
/// hub_screen.dart's `_open`), so nothing ever watches this provider across
/// two different "add feature" sessions. Reopening any project therefore
/// always starts from a fresh form, matching the old useState-per-mount
/// behavior without any manual reset call.

@ProviderFor(FeatureFormController)
final featureFormControllerProvider = FeatureFormControllerFamily._();

/// Scoped per [NeatContract] (family) and auto-disposed (default, no
/// keepAlive) — the Workshop can only be reached with a project already
/// loaded and closing it always routes back through the Hub first (see
/// hub_screen.dart's `_open`), so nothing ever watches this provider across
/// two different "add feature" sessions. Reopening any project therefore
/// always starts from a fresh form, matching the old useState-per-mount
/// behavior without any manual reset call.
final class FeatureFormControllerProvider
    extends $NotifierProvider<FeatureFormController, FeatureFormState> {
  /// Scoped per [NeatContract] (family) and auto-disposed (default, no
  /// keepAlive) — the Workshop can only be reached with a project already
  /// loaded and closing it always routes back through the Hub first (see
  /// hub_screen.dart's `_open`), so nothing ever watches this provider across
  /// two different "add feature" sessions. Reopening any project therefore
  /// always starts from a fresh form, matching the old useState-per-mount
  /// behavior without any manual reset call.
  FeatureFormControllerProvider._({
    required FeatureFormControllerFamily super.from,
    required NeatContract super.argument,
  }) : super(
         retry: null,
         name: r'featureFormControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$featureFormControllerHash();

  @override
  String toString() {
    return r'featureFormControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  FeatureFormController create() => FeatureFormController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FeatureFormState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FeatureFormState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is FeatureFormControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$featureFormControllerHash() =>
    r'c4b4f51e3b32c11e2301cfb29cb7e769317cfd50';

/// Scoped per [NeatContract] (family) and auto-disposed (default, no
/// keepAlive) — the Workshop can only be reached with a project already
/// loaded and closing it always routes back through the Hub first (see
/// hub_screen.dart's `_open`), so nothing ever watches this provider across
/// two different "add feature" sessions. Reopening any project therefore
/// always starts from a fresh form, matching the old useState-per-mount
/// behavior without any manual reset call.

final class FeatureFormControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          FeatureFormController,
          FeatureFormState,
          FeatureFormState,
          FeatureFormState,
          NeatContract
        > {
  FeatureFormControllerFamily._()
    : super(
        retry: null,
        name: r'featureFormControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Scoped per [NeatContract] (family) and auto-disposed (default, no
  /// keepAlive) — the Workshop can only be reached with a project already
  /// loaded and closing it always routes back through the Hub first (see
  /// hub_screen.dart's `_open`), so nothing ever watches this provider across
  /// two different "add feature" sessions. Reopening any project therefore
  /// always starts from a fresh form, matching the old useState-per-mount
  /// behavior without any manual reset call.

  FeatureFormControllerProvider call(NeatContract contract) =>
      FeatureFormControllerProvider._(argument: contract, from: this);

  @override
  String toString() => r'featureFormControllerProvider';
}

/// Scoped per [NeatContract] (family) and auto-disposed (default, no
/// keepAlive) — the Workshop can only be reached with a project already
/// loaded and closing it always routes back through the Hub first (see
/// hub_screen.dart's `_open`), so nothing ever watches this provider across
/// two different "add feature" sessions. Reopening any project therefore
/// always starts from a fresh form, matching the old useState-per-mount
/// behavior without any manual reset call.

abstract class _$FeatureFormController extends $Notifier<FeatureFormState> {
  late final _$args = ref.$arg as NeatContract;
  NeatContract get contract => _$args;

  FeatureFormState build(NeatContract contract);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<FeatureFormState, FeatureFormState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<FeatureFormState, FeatureFormState>,
              FeatureFormState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
