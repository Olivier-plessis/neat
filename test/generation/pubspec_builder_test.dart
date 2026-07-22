import 'package:flutter_test/flutter_test.dart';
import 'package:neat/features/dependencies/domain/models/pub_package.dart';
import 'package:neat/features/generation/domain/usecases/writers/pubspec_writer.dart';
import 'package:yaml/yaml.dart';

/// A minimal `flutter create` pubspec, used as the [original] input to
/// [PubspecWriter.buildPubspecContent].
const _basePubspec = '''
name: my_app
description: "A new Flutter project."
publish_to: 'none'
version: 0.1.0+1

environment:
  sdk: ^3.12.0

dependencies:
  flutter:
    sdk: flutter

  cupertino_icons: ^1.0.8

dev_dependencies:
  flutter_test:
    sdk: flutter

  flutter_lints: ^6.0.0

flutter:
  uses-material-design: true
''';

PubPackage pkg(String name, String version, {bool isDev = false}) =>
    PubPackage(name: name, version: version, description: '', isDev: isDev);

/// Parses [content] as YAML and returns the merged dependency/dev_dependency
/// maps, failing the test with a readable message if the YAML is malformed.
({Map<dynamic, dynamic> deps, Map<dynamic, dynamic> devDeps}) parseDeps(String content) {
  late final YamlMap doc;
  try {
    doc = loadYaml(content) as YamlMap;
  } catch (e) {
    fail('Generated pubspec is not valid YAML:\n$e\n\n--- content ---\n$content');
  }
  return (
    deps: (doc['dependencies'] as YamlMap?) ?? YamlMap(),
    devDeps: (doc['dev_dependencies'] as YamlMap?) ?? YamlMap(),
  );
}

void main() {
  group('buildPubspecContent — YAML validity', () {
    test('produces valid YAML for an empty package list', () {
      final out = PubspecWriter.buildPubspecContent(_basePubspec, const []);
      expect(() => parseDeps(out), returnsNormally);
    });

    test('produces valid YAML for a full realistic stack (the envied regression)', () {
      // Mirrors the package set that previously generated malformed YAML
      // (envied at the dependency boundary).
      final packages = [
        pkg('hooks_riverpod', '3.3.1'),
        pkg('flutter_hooks', '0.21.3+1'),
        pkg('riverpod_annotation', '4.0.2'),
        pkg('json_annotation', '4.11.0'),
        pkg('freezed_annotation', '3.1.0'),
        pkg('dio', '5.9.2'),
        pkg('chopper', '8.6.0'),
        pkg('go_router', '17.2.3'),
        pkg('envied', '1.3.5'),
        pkg('riverpod_generator', '4.0.3', isDev: true),
        pkg('envied_generator', '1.3.5', isDev: true),
        pkg('build_runner', '2.15.0', isDev: true),
        pkg('freezed', '3.2.5', isDev: true),
        pkg('go_router_builder', '4.3.0', isDev: true),
      ];

      final out = PubspecWriter.buildPubspecContent(_basePubspec, packages);
      final parsed = parseDeps(out);

      expect(parsed.deps['envied'], '^1.3.5');
      expect(parsed.deps['dio'], '^5.9.2');
      expect(parsed.devDeps['build_runner'], '^2.15.0');
      // Original cupertino_icons / flutter_lints survive the merge.
      expect(parsed.deps['cupertino_icons'], '^1.0.8');
      expect(parsed.devDeps['flutter_lints'], '^6.0.0');
    });
  });

  group('buildPubspecContent — dependency placement', () {
    test('runtime vs dev split honors isDev', () {
      final out = PubspecWriter.buildPubspecContent(_basePubspec, [
        pkg('dio', '5.9.2'),
        pkg('build_runner', '2.15.0', isDev: true),
      ]);
      final parsed = parseDeps(out);
      expect(parsed.deps.containsKey('dio'), isTrue);
      expect(parsed.deps.containsKey('build_runner'), isFalse);
      expect(parsed.devDeps.containsKey('build_runner'), isTrue);
    });

    test('selected versions are prefixed with a single caret', () {
      final out = PubspecWriter.buildPubspecContent(_basePubspec, [
        pkg('dio', '5.9.2'),
      ]);
      expect(parseDeps(out).deps['dio'], '^5.9.2');
    });
  });

  group('buildPubspecContent — deduplication (no side effects across runs)', () {
    test('duplicate package entries collapse to one', () {
      final out = PubspecWriter.buildPubspecContent(_basePubspec, [
        pkg('dio', '5.9.2'),
        pkg('dio', '5.9.2'),
        pkg('dio', '5.9.2'),
      ]);
      // A second caret-line would break YAML or duplicate the key; assert the
      // raw text only contains the dependency once.
      final occurrences = RegExp(r'^\s{2}dio:', multiLine: true).allMatches(out).length;
      expect(occurrences, 1);
      expect(() => parseDeps(out), returnsNormally);
    });
  });

  group('buildPubspecContent — auto-injection', () {
    test('google_fonts is always injected when absent', () {
      final out = PubspecWriter.buildPubspecContent(_basePubspec, const []);
      expect(parseDeps(out).deps.containsKey('google_fonts'), isTrue);
    });

    test('google_fonts is not duplicated when user already selected it', () {
      final out = PubspecWriter.buildPubspecContent(_basePubspec, [
        pkg('google_fonts', '7.0.0'),
      ]);
      final occurrences =
          RegExp(r'^\s{2}google_fonts:', multiLine: true).allMatches(out).length;
      expect(occurrences, 1);
      // The user's chosen version wins (no override).
      expect(parseDeps(out).deps['google_fonts'], '^7.0.0');
    });

    test('flutter_screenutil injected by default, skipped when addScreenUtil=false', () {
      final withSu =
          PubspecWriter.buildPubspecContent(_basePubspec, const []);
      expect(parseDeps(withSu).deps.containsKey('flutter_screenutil'), isTrue);

      final webOnly = PubspecWriter.buildPubspecContent(
        _basePubspec,
        const [],
        addScreenUtil: false,
      );
      expect(parseDeps(webOnly).deps.containsKey('flutter_screenutil'), isFalse);
    });

    test('go_router_builder pulls in go_router as a runtime dep', () {
      final out = PubspecWriter.buildPubspecContent(_basePubspec, [
        pkg('go_router_builder', '4.3.0', isDev: true),
      ]);
      final parsed = parseDeps(out);
      expect(parsed.devDeps.containsKey('go_router_builder'), isTrue);
      expect(parsed.deps.containsKey('go_router'), isTrue);
    });

    test('go_router not duplicated when explicitly selected alongside builder', () {
      final out = PubspecWriter.buildPubspecContent(_basePubspec, [
        pkg('go_router', '17.2.3'),
        pkg('go_router_builder', '4.3.0', isDev: true),
      ]);
      final occurrences =
          RegExp(r'^\s{2}go_router:', multiLine: true).allMatches(out).length;
      expect(occurrences, 1);
    });

    test('flutter_bloc injected when only the plain bloc package was selected', () {
      final out = PubspecWriter.buildPubspecContent(_basePubspec, [
        pkg('bloc', '9.0.1'),
      ]);
      expect(parseDeps(out).deps.containsKey('flutter_bloc'), isTrue);
    });

    test('flutter_bloc not duplicated when explicitly selected', () {
      final out = PubspecWriter.buildPubspecContent(_basePubspec, [
        pkg('flutter_bloc', '9.1.1'),
      ]);
      final occurrences =
          RegExp(r'^\s{2}flutter_bloc:', multiLine: true).allMatches(out).length;
      expect(occurrences, 1);
    });

    test('no flutter_bloc injected when no bloc-family package is present', () {
      final out = PubspecWriter.buildPubspecContent(_basePubspec, const []);
      expect(parseDeps(out).deps.containsKey('flutter_bloc'), isFalse);
    });

    test('widgetbook injected only when withWidgetbook=true', () {
      final off = PubspecWriter.buildPubspecContent(_basePubspec, const []);
      expect(parseDeps(off).devDeps.containsKey('widgetbook'), isFalse);

      final on = PubspecWriter.buildPubspecContent(
        _basePubspec,
        const [],
        withWidgetbook: true,
      );
      expect(parseDeps(on).devDeps.containsKey('widgetbook'), isTrue);
    });

    test('envied auto-injects envied_generator + build_runner', () {
      final out = PubspecWriter.buildPubspecContent(_basePubspec, [
        pkg('envied', '1.3.5'),
      ]);
      final parsed = parseDeps(out);
      expect(parsed.deps.containsKey('envied'), isTrue);
      expect(parsed.devDeps.containsKey('envied_generator'), isTrue);
      expect(parsed.devDeps.containsKey('build_runner'), isTrue);
    });

    test('envied does not duplicate generator/build_runner when present', () {
      final out = PubspecWriter.buildPubspecContent(_basePubspec, [
        pkg('envied', '1.3.5'),
        pkg('envied_generator', '1.3.5', isDev: true),
        pkg('build_runner', '2.15.0', isDev: true),
      ]);
      expect(
        RegExp(r'^\s{2}build_runner:', multiLine: true).allMatches(out).length,
        1,
      );
      expect(
        RegExp(r'^\s{2}envied_generator:', multiLine: true).allMatches(out).length,
        1,
      );
    });
  });

  group('buildPubspecContent — workspace', () {
    test('no workspace block when there are no members', () {
      final out = PubspecWriter.buildPubspecContent(_basePubspec, const []);
      expect(out.contains('workspace:'), isFalse);
      expect(() => parseDeps(out), returnsNormally);
    });

    test('path packages → workspace members + path deps + connectivity', () {
      final out = PubspecWriter.buildPubspecContent(
        _basePubspec,
        const [],
        pathPackages: ['my_app_local_storage'],
        addConnectivity: true,
      );
      final doc = loadYaml(out) as YamlMap;

      final workspace = doc['workspace'] as YamlList;
      expect(workspace, contains('packages/my_app_local_storage'));

      final deps = parseDeps(out).deps;
      expect((deps['my_app_local_storage'] as YamlMap)['path'], 'packages/my_app_local_storage');
      expect(deps.containsKey('connectivity_plus'), isTrue);

      // drift_dev 2.34.0's query analyzer calls a DartPlaceholder.when() method
      // sqlparser removed in 0.44.6 — pinned below it workspace-wide (a pub
      // workspace resolves one version of everything) until drift_dev's own
      // constraint moves past the break. See ROADMAP.md.
      final overrides = (doc['dependency_overrides'] as YamlMap?);
      expect(overrides, isNotNull, reason: 'offline-first must pin sqlparser below 0.44.6');
      expect(overrides!['sqlparser'], '>=0.44.0 <0.44.6');
    });

    test('no offline-first (addConnectivity=false) → no sqlparser override', () {
      final out = PubspecWriter.buildPubspecContent(
        _basePubspec,
        const [],
        pathPackages: ['my_app_ui'],
      );
      final doc = loadYaml(out) as YamlMap;
      expect(doc['dependency_overrides'], isNull);
    });

    test('multiple path packages + extra members (widgetbook)', () {
      final out = PubspecWriter.buildPubspecContent(
        _basePubspec,
        const [],
        pathPackages: ['my_app_ui', 'my_app_local_storage'],
        extraWorkspaceMembers: ['widgetbook'],
      );
      final workspace = (loadYaml(out) as YamlMap)['workspace'] as YamlList;
      expect(workspace, containsAll(<String>[
        'packages/my_app_ui',
        'packages/my_app_local_storage',
        'widgetbook',
      ]));
      final deps = parseDeps(out).deps;
      expect((deps['my_app_ui'] as YamlMap)['path'], 'packages/my_app_ui');
      // widgetbook is a member but NOT an app dependency.
      expect(deps.containsKey('widgetbook'), isFalse);
    });

    test('workspace block coexists with auto-injected deps (valid YAML)', () {
      final out = PubspecWriter.buildPubspecContent(
        _basePubspec,
        [pkg('envied', '1.3.5')],
        pathPackages: ['my_app_local_storage'],
        addConnectivity: true,
      );
      expect(() => parseDeps(out), returnsNormally);
      expect((loadYaml(out) as YamlMap)['workspace'], isA<YamlList>());
      expect(parseDeps(out).deps.containsKey('google_fonts'), isTrue);
      expect(parseDeps(out).devDeps.containsKey('envied_generator'), isTrue);
    });
  });

  group('buildPubspecContent — onboarding', () {
    test('addOnboarding injects shared_preferences', () {
      final out = PubspecWriter.buildPubspecContent(
        _basePubspec,
        const [],
        addOnboarding: true,
      );
      expect(parseDeps(out).deps.containsKey('shared_preferences'), isTrue);
    });

    test('no shared_preferences when onboarding is off', () {
      final out = PubspecWriter.buildPubspecContent(_basePubspec, const []);
      expect(parseDeps(out).deps.containsKey('shared_preferences'), isFalse);
    });

    test('addSlang + addOnboarding together: shared_preferences added once, not duplicated', () {
      final out = PubspecWriter.buildPubspecContent(
        _basePubspec,
        const [],
        addSlang: true,
        addOnboarding: true,
      );
      expect(() => parseDeps(out), returnsNormally);
      expect('shared_preferences:'.allMatches(out).length, 1);
    });
  });
}
