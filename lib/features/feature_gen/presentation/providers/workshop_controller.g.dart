// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workshop_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Drives Workshop mode: open an existing NEAT project (via its `.neat.json`)
/// and generate features into it. The folder picker lives in the UI; this
/// controller takes a resolved path so it stays testable.

@ProviderFor(WorkshopController)
final workshopControllerProvider = WorkshopControllerProvider._();

/// Drives Workshop mode: open an existing NEAT project (via its `.neat.json`)
/// and generate features into it. The folder picker lives in the UI; this
/// controller takes a resolved path so it stays testable.
final class WorkshopControllerProvider
    extends $NotifierProvider<WorkshopController, WorkshopState> {
  /// Drives Workshop mode: open an existing NEAT project (via its `.neat.json`)
  /// and generate features into it. The folder picker lives in the UI; this
  /// controller takes a resolved path so it stays testable.
  WorkshopControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'workshopControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$workshopControllerHash();

  @$internal
  @override
  WorkshopController create() => WorkshopController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WorkshopState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WorkshopState>(value),
    );
  }
}

String _$workshopControllerHash() =>
    r'91416c615ee73aeefa4c9cc627980d5cbd6da3b7';

/// Drives Workshop mode: open an existing NEAT project (via its `.neat.json`)
/// and generate features into it. The folder picker lives in the UI; this
/// controller takes a resolved path so it stays testable.

abstract class _$WorkshopController extends $Notifier<WorkshopState> {
  WorkshopState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<WorkshopState, WorkshopState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<WorkshopState, WorkshopState>,
              WorkshopState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
