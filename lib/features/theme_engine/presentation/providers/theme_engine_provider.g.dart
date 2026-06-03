// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme_engine_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

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

String _$themeEngineHash() => r'6bb1ff8328e40c4ce9cc147933a1fe34465b54c9';

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
