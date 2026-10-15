import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:neat/features/feature_gen/domain/services/stale_build_graph.dart';

/// Real bug, found building archy: a file moved from the `worksite` package to
/// `core` by hand left a stale entry in the root's build_runner cache, and the
/// Workshop's root pass then failed on every run. See StaleBuildGraph's doc.
void main() {
  group('StaleBuildGraph.isCausedBy', () {
    test('recognises the failure archy hit', () {
      const stderr = '''
Unhandled exception:
InvalidOutputException: worksite|lib/domain/entities/worksite_category.dart
Tried to delete from package not in the build. Packages in the build are: archy
#0      BuildPackages.pathFor (package:build_runner/src/build_plan/build_packages.dart:236)''';

      expect(StaleBuildGraph.isCausedBy(stderr), isTrue);
    });

    test('leaves any other failure alone', () {
      expect(StaleBuildGraph.isCausedBy(''), isFalse);
      expect(
        StaleBuildGraph.isCausedBy(
          "lib/a.dart:3:7: Error: Undefined name 'foo'.",
        ),
        isFalse,
      );
      expect(
        StaleBuildGraph.isCausedBy(
          'Could not find a file named "pubspec.yaml"',
        ),
        isFalse,
      );
    });
  });

  group('StaleBuildGraph.drop', () {
    late Directory project;

    setUp(() => project = Directory.systemTemp.createTempSync('neat_graph_'));
    tearDown(() {
      if (project.existsSync()) project.deleteSync(recursive: true);
    });

    File file(String relative) => File('${project.path}/$relative');

    test('deletes the asset graph and nothing else', () {
      file('.dart_tool/build/asset_graph.json').createSync(recursive: true);
      file('.dart_tool/build/generated/keep.txt').createSync(recursive: true);
      file('lib/main.dart').createSync(recursive: true);

      expect(StaleBuildGraph.drop(project.path), isTrue);

      expect(file('.dart_tool/build/asset_graph.json').existsSync(), isFalse);
      expect(file('.dart_tool/build/generated/keep.txt').existsSync(), isTrue);
      expect(file('lib/main.dart').existsSync(), isTrue);
    });

    test('says so when there was no graph, so a retry would be pointless', () {
      expect(StaleBuildGraph.drop(project.path), isFalse);

      file('.dart_tool/build/asset_graph.json').createSync(recursive: true);
      expect(StaleBuildGraph.drop(project.path), isTrue);
      expect(StaleBuildGraph.drop(project.path), isFalse);
    });
  });
}
