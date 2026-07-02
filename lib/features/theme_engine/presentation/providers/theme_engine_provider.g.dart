// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme_engine_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Shared flag: true while the launch generation process is running.
/// Read by main_layout to disable the Back button during generation.

@ProviderFor(ExtractingImage)
final extractingImageProvider = ExtractingImageProvider._();

/// Shared flag: true while the launch generation process is running.
/// Read by main_layout to disable the Back button during generation.
final class ExtractingImageProvider
    extends $NotifierProvider<ExtractingImage, bool> {
  /// Shared flag: true while the launch generation process is running.
  /// Read by main_layout to disable the Back button during generation.
  ExtractingImageProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'extractingImageProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$extractingImageHash();

  @$internal
  @override
  ExtractingImage create() => ExtractingImage();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$extractingImageHash() => r'94c960154d055d7b6c91ac84fc464948b8f80ed6';

/// Shared flag: true while the launch generation process is running.
/// Read by main_layout to disable the Back button during generation.

abstract class _$ExtractingImage extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(ThemeEngine)
final themeEngineProvider = ThemeEngineProvider._();

final class ThemeEngineProvider
    extends $NotifierProvider<ThemeEngine, ThemeEngineState> {
  ThemeEngineProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'themeEngineProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$themeEngineHash();

  @$internal
  @override
  ThemeEngine create() => ThemeEngine();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ThemeEngineState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ThemeEngineState>(value),
    );
  }
}

String _$themeEngineHash() => r'a013ddecfe1520ea8475e9b1793287087c55a68b';

abstract class _$ThemeEngine extends $Notifier<ThemeEngineState> {
  ThemeEngineState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ThemeEngineState, ThemeEngineState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ThemeEngineState, ThemeEngineState>,
              ThemeEngineState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
