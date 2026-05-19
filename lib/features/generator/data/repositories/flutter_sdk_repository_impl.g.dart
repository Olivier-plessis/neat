// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'flutter_sdk_repository_impl.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(flutterSdkRepository)
final flutterSdkRepositoryProvider = FlutterSdkRepositoryProvider._();

final class FlutterSdkRepositoryProvider
    extends
        $FunctionalProvider<
          FlutterSdkRepository,
          FlutterSdkRepository,
          FlutterSdkRepository
        >
    with $Provider<FlutterSdkRepository> {
  FlutterSdkRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'flutterSdkRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$flutterSdkRepositoryHash();

  @$internal
  @override
  $ProviderElement<FlutterSdkRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FlutterSdkRepository create(Ref ref) {
    return flutterSdkRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FlutterSdkRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FlutterSdkRepository>(value),
    );
  }
}

String _$flutterSdkRepositoryHash() =>
    r'521afb0720d5f88301ff7fa25ef315ecc230f4c0';
