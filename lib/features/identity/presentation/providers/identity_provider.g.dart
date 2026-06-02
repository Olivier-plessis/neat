// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'identity_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(IdentityNotifier)
final identityProvider = IdentityNotifierProvider._();

final class IdentityNotifierProvider
    extends $NotifierProvider<IdentityNotifier, IdentityState> {
  IdentityNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'identityProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$identityNotifierHash();

  @$internal
  @override
  IdentityNotifier create() => IdentityNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IdentityState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IdentityState>(value),
    );
  }
}

String _$identityNotifierHash() => r'cc4cfd775e6d9d0990e8e18c7162396da23daaed';

abstract class _$IdentityNotifier extends $Notifier<IdentityState> {
  IdentityState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<IdentityState, IdentityState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<IdentityState, IdentityState>,
              IdentityState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
