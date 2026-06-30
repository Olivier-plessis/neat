// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'architecture_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ArchitectureNotifier)
final architectureProvider = ArchitectureNotifierProvider._();

final class ArchitectureNotifierProvider
    extends $NotifierProvider<ArchitectureNotifier, ArchitectureState> {
  ArchitectureNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'architectureProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$architectureNotifierHash();

  @$internal
  @override
  ArchitectureNotifier create() => ArchitectureNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ArchitectureState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ArchitectureState>(value),
    );
  }
}

String _$architectureNotifierHash() =>
    r'74b41c0cad7d287c5da814381580ad0092dd38e7';

abstract class _$ArchitectureNotifier extends $Notifier<ArchitectureState> {
  ArchitectureState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ArchitectureState, ArchitectureState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ArchitectureState, ArchitectureState>,
              ArchitectureState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
