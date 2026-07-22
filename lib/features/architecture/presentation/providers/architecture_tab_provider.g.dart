// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'architecture_tab_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CurrentArchitectureTab)
final currentArchitectureTabProvider = CurrentArchitectureTabProvider._();

final class CurrentArchitectureTabProvider
    extends $NotifierProvider<CurrentArchitectureTab, ArchitectureTab> {
  CurrentArchitectureTabProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentArchitectureTabProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentArchitectureTabHash();

  @$internal
  @override
  CurrentArchitectureTab create() => CurrentArchitectureTab();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ArchitectureTab value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ArchitectureTab>(value),
    );
  }
}

String _$currentArchitectureTabHash() =>
    r'c015ffd46361a6c07577df4920dd178a15d778dd';

abstract class _$CurrentArchitectureTab extends $Notifier<ArchitectureTab> {
  ArchitectureTab build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ArchitectureTab, ArchitectureTab>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ArchitectureTab, ArchitectureTab>,
              ArchitectureTab,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
