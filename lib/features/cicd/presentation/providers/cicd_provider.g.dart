// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cicd_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CicdNotifier)
final cicdProvider = CicdNotifierProvider._();

final class CicdNotifierProvider
    extends $NotifierProvider<CicdNotifier, CicdState> {
  CicdNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cicdProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cicdNotifierHash();

  @$internal
  @override
  CicdNotifier create() => CicdNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CicdState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CicdState>(value),
    );
  }
}

String _$cicdNotifierHash() => r'f8282fb28e871e6cbae221df9a088b23ae3a1192';

abstract class _$CicdNotifier extends $Notifier<CicdState> {
  CicdState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<CicdState, CicdState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CicdState, CicdState>,
              CicdState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
