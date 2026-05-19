// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fetch_stable_flutter_versions_usecase.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(fetchStableFlutterVersionsUseCase)
final fetchStableFlutterVersionsUseCaseProvider =
    FetchStableFlutterVersionsUseCaseProvider._();

final class FetchStableFlutterVersionsUseCaseProvider
    extends
        $FunctionalProvider<
          FetchStableFlutterVersionsUseCase,
          FetchStableFlutterVersionsUseCase,
          FetchStableFlutterVersionsUseCase
        >
    with $Provider<FetchStableFlutterVersionsUseCase> {
  FetchStableFlutterVersionsUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fetchStableFlutterVersionsUseCaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() =>
      _$fetchStableFlutterVersionsUseCaseHash();

  @$internal
  @override
  $ProviderElement<FetchStableFlutterVersionsUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FetchStableFlutterVersionsUseCase create(Ref ref) {
    return fetchStableFlutterVersionsUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FetchStableFlutterVersionsUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FetchStableFlutterVersionsUseCase>(
        value,
      ),
    );
  }
}

String _$fetchStableFlutterVersionsUseCaseHash() =>
    r'968da044c2fec25ac7a507ed7e1e59cb454cf228';
