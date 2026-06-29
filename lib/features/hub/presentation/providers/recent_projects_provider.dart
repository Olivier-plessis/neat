import 'package:neat/features/hub/data/recent_projects_store.dart';
import 'package:neat/features/hub/domain/models/recent_project.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'recent_projects_provider.g.dart';

/// The Hub's recent-projects list, backed by [RecentProjectsStore]. Register a
/// project on generation (create) and on opening it in the Workshop.
@Riverpod(keepAlive: true)
class RecentProjects extends _$RecentProjects {
  static const _store = RecentProjectsStore();

  @override
  Future<List<RecentProject>> build() => _store.load();

  /// Records [path] (with [name]) as just opened, moving it to the top.
  Future<void> register({required String path, required String name}) async {
    await _store.add(RecentProject(path: path, name: name, lastOpened: DateTime.now()));
    state = AsyncData(await _store.load());
  }

  /// Removes [path] from the list.
  Future<void> remove(String path) async {
    await _store.remove(path);
    state = AsyncData(await _store.load());
  }
}
