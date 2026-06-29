// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recent_projects_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The Hub's recent-projects list, backed by [RecentProjectsStore]. Register a
/// project on generation (create) and on opening it in the Workshop.

@ProviderFor(RecentProjects)
final recentProjectsProvider = RecentProjectsProvider._();

/// The Hub's recent-projects list, backed by [RecentProjectsStore]. Register a
/// project on generation (create) and on opening it in the Workshop.
final class RecentProjectsProvider
    extends $AsyncNotifierProvider<RecentProjects, List<RecentProject>> {
  /// The Hub's recent-projects list, backed by [RecentProjectsStore]. Register a
  /// project on generation (create) and on opening it in the Workshop.
  RecentProjectsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recentProjectsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recentProjectsHash();

  @$internal
  @override
  RecentProjects create() => RecentProjects();
}

String _$recentProjectsHash() => r'8e47527c15d7f4f8bdd70463ce58590952049b85';

/// The Hub's recent-projects list, backed by [RecentProjectsStore]. Register a
/// project on generation (create) and on opening it in the Workshop.

abstract class _$RecentProjects extends $AsyncNotifier<List<RecentProject>> {
  FutureOr<List<RecentProject>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<RecentProject>>, List<RecentProject>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<RecentProject>>, List<RecentProject>>,
              AsyncValue<List<RecentProject>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
