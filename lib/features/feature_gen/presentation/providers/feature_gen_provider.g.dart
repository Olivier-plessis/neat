// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feature_gen_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(FeatureGenNotifier)
final featureGenProvider = FeatureGenNotifierProvider._();

final class FeatureGenNotifierProvider
    extends $NotifierProvider<FeatureGenNotifier, FeatureGenState> {
  FeatureGenNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'featureGenProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$featureGenNotifierHash();

  @$internal
  @override
  FeatureGenNotifier create() => FeatureGenNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FeatureGenState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FeatureGenState>(value),
    );
  }
}

String _$featureGenNotifierHash() =>
    r'63210825a8b1013f81554fcf451dcb204d94f253';

abstract class _$FeatureGenNotifier extends $Notifier<FeatureGenState> {
  FeatureGenState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<FeatureGenState, FeatureGenState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<FeatureGenState, FeatureGenState>,
              FeatureGenState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
