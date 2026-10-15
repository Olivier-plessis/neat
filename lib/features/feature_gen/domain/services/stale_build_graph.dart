import 'dart:io';

/// `build_runner` keeps a graph of every file it has seen in
/// `.dart_tool/build/asset_graph.json`. When a source file moves to another
/// package between two builds (a hand-made refactor), the graph still lists
/// the old path; the next run tries to delete that file's outputs in a package
/// that is not part of this build and stops with
/// `InvalidOutputException … Tried to delete from package not in the build`,
/// on every run, until the graph is dropped.
///
/// Real case, found building archy: `WorksiteCategory` moved from the
/// `worksite` package to `core`, and the next Workshop run failed on the
/// project's root pass (the packages' own passes were fine).
///
/// The graph is only a cache, so dropping it is safe — the next build starts
/// from scratch (NEAT already passes `--delete-conflicting-outputs`).
abstract final class StaleBuildGraph {
  static const _signature = 'Tried to delete from package not in the build';

  /// Whether a failed `build_runner build`'s stderr is this failure.
  static bool isCausedBy(String stderr) => stderr.contains(_signature);

  /// Deletes [projectDir]'s asset graph. False when there was none to delete
  /// (so a retry would fail the same way).
  static bool drop(String projectDir) {
    final graph = File('$projectDir/.dart_tool/build/asset_graph.json');
    if (!graph.existsSync()) return false;
    graph.deleteSync();
    return true;
  }
}
