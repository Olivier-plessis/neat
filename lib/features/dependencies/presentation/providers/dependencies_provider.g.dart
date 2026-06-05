// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dependencies_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SearchQuery)
final searchQueryProvider = SearchQueryProvider._();

final class SearchQueryProvider extends $NotifierProvider<SearchQuery, String> {
  SearchQueryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'searchQueryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$searchQueryHash();

  @$internal
  @override
  SearchQuery create() => SearchQuery();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$searchQueryHash() => r'6b84263fe2f4035d77f9deaafac53af4c900c25e';

abstract class _$SearchQuery extends $Notifier<String> {
  String build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<String, String>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String, String>,
              String,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(packageSearchResults)
final packageSearchResultsProvider = PackageSearchResultsProvider._();

final class PackageSearchResultsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PubPackage>>,
          List<PubPackage>,
          FutureOr<List<PubPackage>>
        >
    with $FutureModifier<List<PubPackage>>, $FutureProvider<List<PubPackage>> {
  PackageSearchResultsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'packageSearchResultsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$packageSearchResultsHash();

  @$internal
  @override
  $FutureProviderElement<List<PubPackage>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<PubPackage>> create(Ref ref) {
    return packageSearchResults(ref);
  }
}

String _$packageSearchResultsHash() =>
    r'86cc18b8253c1840beb9faff90576d062910a6ee';

@ProviderFor(PackageForDetail)
final packageForDetailProvider = PackageForDetailProvider._();

final class PackageForDetailProvider
    extends $NotifierProvider<PackageForDetail, PubPackage?> {
  PackageForDetailProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'packageForDetailProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$packageForDetailHash();

  @$internal
  @override
  PackageForDetail create() => PackageForDetail();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PubPackage? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PubPackage?>(value),
    );
  }
}

String _$packageForDetailHash() => r'c166bc334235670f0935f3b8241fe4023ddfafa5';

abstract class _$PackageForDetail extends $Notifier<PubPackage?> {
  PubPackage? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<PubPackage?, PubPackage?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PubPackage?, PubPackage?>,
              PubPackage?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(SelectedPackages)
final selectedPackagesProvider = SelectedPackagesProvider._();

final class SelectedPackagesProvider
    extends $NotifierProvider<SelectedPackages, List<PubPackage>> {
  SelectedPackagesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedPackagesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedPackagesHash();

  @$internal
  @override
  SelectedPackages create() => SelectedPackages();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<PubPackage> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<PubPackage>>(value),
    );
  }
}

String _$selectedPackagesHash() => r'30e175a9998a0155d2568d4a9a5621bd8550e700';

abstract class _$SelectedPackages extends $Notifier<List<PubPackage>> {
  List<PubPackage> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<List<PubPackage>, List<PubPackage>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<PubPackage>, List<PubPackage>>,
              List<PubPackage>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
