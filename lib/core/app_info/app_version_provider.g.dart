// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_version_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The app version label, read once from the platform bundle.
///
/// Returns "vX.Y.Z" (e.g. "v1.0.0"). Kept alive so the lookup runs only once.

@ProviderFor(appVersion)
final appVersionProvider = AppVersionProvider._();

/// The app version label, read once from the platform bundle.
///
/// Returns "vX.Y.Z" (e.g. "v1.0.0"). Kept alive so the lookup runs only once.

final class AppVersionProvider
    extends $FunctionalProvider<AsyncValue<String>, String, FutureOr<String>>
    with $FutureModifier<String>, $FutureProvider<String> {
  /// The app version label, read once from the platform bundle.
  ///
  /// Returns "vX.Y.Z" (e.g. "v1.0.0"). Kept alive so the lookup runs only once.
  AppVersionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appVersionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appVersionHash();

  @$internal
  @override
  $FutureProviderElement<String> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String> create(Ref ref) {
    return appVersion(ref);
  }
}

String _$appVersionHash() => r'f828c62d453bc5def96d4002a8a3793f42dd82b8';
