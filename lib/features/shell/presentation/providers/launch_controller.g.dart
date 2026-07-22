// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'launch_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Drives project generation from the Launch step: calls
/// LaunchGenerationUsecase, streams logs, and registers the freshly generated
/// project in the Hub's recent list — mirrors WorkshopController's own
/// usecase-orchestration pattern so the View never calls a usecase directly.

@ProviderFor(LaunchController)
final launchControllerProvider = LaunchControllerProvider._();

/// Drives project generation from the Launch step: calls
/// LaunchGenerationUsecase, streams logs, and registers the freshly generated
/// project in the Hub's recent list — mirrors WorkshopController's own
/// usecase-orchestration pattern so the View never calls a usecase directly.
final class LaunchControllerProvider
    extends $NotifierProvider<LaunchController, LaunchState> {
  /// Drives project generation from the Launch step: calls
  /// LaunchGenerationUsecase, streams logs, and registers the freshly generated
  /// project in the Hub's recent list — mirrors WorkshopController's own
  /// usecase-orchestration pattern so the View never calls a usecase directly.
  LaunchControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'launchControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$launchControllerHash();

  @$internal
  @override
  LaunchController create() => LaunchController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LaunchState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LaunchState>(value),
    );
  }
}

String _$launchControllerHash() => r'64b90af7bfc831968a3efdc3d95e54ef7c67aa96';

/// Drives project generation from the Launch step: calls
/// LaunchGenerationUsecase, streams logs, and registers the freshly generated
/// project in the Hub's recent list — mirrors WorkshopController's own
/// usecase-orchestration pattern so the View never calls a usecase directly.

abstract class _$LaunchController extends $Notifier<LaunchState> {
  LaunchState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<LaunchState, LaunchState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<LaunchState, LaunchState>,
              LaunchState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
