// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme_engine_tab_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CurrentThemeEngineTab)
final currentThemeEngineTabProvider = CurrentThemeEngineTabProvider._();

final class CurrentThemeEngineTabProvider
    extends $NotifierProvider<CurrentThemeEngineTab, ThemeEngineTab> {
  CurrentThemeEngineTabProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentThemeEngineTabProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentThemeEngineTabHash();

  @$internal
  @override
  CurrentThemeEngineTab create() => CurrentThemeEngineTab();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ThemeEngineTab value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ThemeEngineTab>(value),
    );
  }
}

String _$currentThemeEngineTabHash() =>
    r'1d767b6130e050f85a380df4685530c16be478dc';

abstract class _$CurrentThemeEngineTab extends $Notifier<ThemeEngineTab> {
  ThemeEngineTab build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ThemeEngineTab, ThemeEngineTab>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ThemeEngineTab, ThemeEngineTab>,
              ThemeEngineTab,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
