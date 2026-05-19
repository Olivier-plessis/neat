// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'flutter_sdk_versions_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(FlutterSdkVersions)
final flutterSdkVersionsProvider = FlutterSdkVersionsProvider._();

final class FlutterSdkVersionsProvider
    extends $AsyncNotifierProvider<FlutterSdkVersions, List<String>> {
  FlutterSdkVersionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'flutterSdkVersionsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$flutterSdkVersionsHash();

  @$internal
  @override
  FlutterSdkVersions create() => FlutterSdkVersions();
}

String _$flutterSdkVersionsHash() =>
    r'b0d4023eef3da86eac9ef905f1fcdc4122f70807';

abstract class _$FlutterSdkVersions extends $AsyncNotifier<List<String>> {
  FutureOr<List<String>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<String>>, List<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<String>>, List<String>>,
              AsyncValue<List<String>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
