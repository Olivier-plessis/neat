// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pub_dev_repository_impl.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(pubDevRepository)
final pubDevRepositoryProvider = PubDevRepositoryProvider._();

final class PubDevRepositoryProvider
    extends
        $FunctionalProvider<
          PubDevRepository,
          PubDevRepository,
          PubDevRepository
        >
    with $Provider<PubDevRepository> {
  PubDevRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pubDevRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pubDevRepositoryHash();

  @$internal
  @override
  $ProviderElement<PubDevRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PubDevRepository create(Ref ref) {
    return pubDevRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PubDevRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PubDevRepository>(value),
    );
  }
}

String _$pubDevRepositoryHash() => r'3ff621030fae71dde4b0505fe7a2be3df0f0d6d6';
