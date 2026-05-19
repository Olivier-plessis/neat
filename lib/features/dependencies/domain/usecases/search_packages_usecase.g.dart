// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_packages_usecase.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(searchPackagesUseCase)
final searchPackagesUseCaseProvider = SearchPackagesUseCaseProvider._();

final class SearchPackagesUseCaseProvider
    extends
        $FunctionalProvider<
          SearchPackagesUseCase,
          SearchPackagesUseCase,
          SearchPackagesUseCase
        >
    with $Provider<SearchPackagesUseCase> {
  SearchPackagesUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'searchPackagesUseCaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$searchPackagesUseCaseHash();

  @$internal
  @override
  $ProviderElement<SearchPackagesUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SearchPackagesUseCase create(Ref ref) {
    return searchPackagesUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SearchPackagesUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SearchPackagesUseCase>(value),
    );
  }
}

String _$searchPackagesUseCaseHash() =>
    r'b34d4e9ce844057fb771c9431c109f60e08fda20';
