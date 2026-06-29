import 'dart:convert';
import 'dart:io';

import 'package:neat/features/hub/domain/models/recent_project.dart';
import 'package:path_provider/path_provider.dart';

/// Persists the Hub's recent-projects list as a JSON file in the app-support
/// directory. Entries whose `.neat.json` no longer exists (project moved or
/// deleted) are silently dropped on read.
class RecentProjectsStore {
  const RecentProjectsStore();

  static const _fileName = 'recent_projects.json';
  static const _max = 10;

  Future<File> _file() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/$_fileName');
  }

  /// Whether [path] still looks like a NEAT project (has a `.neat.json`).
  static bool _stillExists(RecentProject p) => File('${p.path}/.neat.json').existsSync();

  Future<List<RecentProject>> load() async {
    try {
      final file = await _file();
      if (!file.existsSync()) return const [];
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(RecentProject.fromJson)
          .where(_stillExists)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  /// Upserts [project] (most-recent first), capped at [_max] entries.
  Future<void> add(RecentProject project) async {
    final list = [...await load()]
      ..removeWhere((p) => p.path == project.path)
      ..insert(0, project);
    await _write(list.take(_max).toList());
  }

  Future<void> remove(String path) async {
    final list = [...await load()]..removeWhere((p) => p.path == path);
    await _write(list);
  }

  Future<void> _write(List<RecentProject> list) async {
    // Best-effort: persistence failures (no platform in tests, unwritable dir)
    // must never break a generation/open flow.
    try {
      final file = await _file();
      await file.create(recursive: true);
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(list.map((p) => p.toJson()).toList()),
      );
    } catch (_) {
      // ignore — the in-memory list still updates for the session.
    }
  }
}
