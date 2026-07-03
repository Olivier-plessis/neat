// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'infrastructure_tab_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CurrentInfrastructureTab)
final currentInfrastructureTabProvider = CurrentInfrastructureTabProvider._();

final class CurrentInfrastructureTabProvider
    extends $NotifierProvider<CurrentInfrastructureTab, InfrastructureTab> {
  CurrentInfrastructureTabProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentInfrastructureTabProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentInfrastructureTabHash();

  @$internal
  @override
  CurrentInfrastructureTab create() => CurrentInfrastructureTab();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(InfrastructureTab value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<InfrastructureTab>(value),
    );
  }
}

String _$currentInfrastructureTabHash() =>
    r'5f6328cb512ad40e21bd585bb95e1341b46e5b9d';

abstract class _$CurrentInfrastructureTab extends $Notifier<InfrastructureTab> {
  InfrastructureTab build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<InfrastructureTab, InfrastructureTab>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<InfrastructureTab, InfrastructureTab>,
              InfrastructureTab,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
