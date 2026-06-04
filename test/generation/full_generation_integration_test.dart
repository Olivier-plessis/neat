@Tags(['integration'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:neat/features/architecture/domain/models/architecture_state.dart';
import 'package:neat/features/cicd/domain/models/cicd_state.dart';
import 'package:neat/features/dependencies/domain/models/pub_package.dart';
import 'package:neat/features/generation/domain/usecases/launch_generation_usecase.dart';
import 'package:neat/features/identity/domain/models/identity_state.dart';
import 'package:neat/features/theme_engine/domain/models/theme_engine_state.dart';

/// End-to-end generation guard (the Desktop equivalent of the extension's
/// `verify:gen`): generates a *real* Flutter project on disk with a heavy,
/// realistic dependency stack, then runs `flutter analyze` on the output and
/// asserts it produces **zero error-severity issues**.
///
/// Slow (pub get + build_runner + analyze) and network-dependent, so it is
/// excluded from the default suite. Run it on demand with:
///
///   flutter test --tags integration
///
/// or exclude it explicitly elsewhere with `--exclude-tags integration`.
void main() {
  // The exact set that resolves cleanly (mirrors a known-good generation):
  // riverpod + hooks + freezed + json + chopper/dio + go_router_builder + envied.
  final packages = <PubPackage>[
    _dep('hooks_riverpod', '3.3.1'),
    _dep('flutter_hooks', '0.21.3+1'),
    _dep('riverpod_annotation', '4.0.2'),
    _dep('json_annotation', '4.11.0'),
    _dep('freezed_annotation', '3.1.0'),
    _dep('dio', '5.9.2'),
    _dep('chopper', '8.6.0'),
    _dep('go_router', '17.2.3'),
    _dep('envied', '1.3.5'),
    _dev('riverpod_generator', '4.0.3'),
    _dev('envied_generator', '1.3.5'),
    _dev('riverpod_lint', '3.1.3'),
    _dev('json_serializable', '6.13.0'),
    _dev('build_runner', '2.15.0'),
    _dev('freezed', '3.2.5'),
    _dev('go_router_builder', '4.3.0'),
    _dev('chopper_generator', '8.6.2'),
  ];

  late Directory tempRoot;

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('neat_gen_');
  });

  tearDown(() async {
    if (tempRoot.existsSync()) {
      await tempRoot.delete(recursive: true);
    }
  });

  test(
    'generates a full project that passes flutter analyze (no errors)',
    () async {
      const projectName = 'neat_gen_test';
      final logs = <String>[];

      final identity = IdentityState(
        name: projectName,
        organization: 'com.neat.test',
        projectPath: tempRoot.path,
        description: 'NEAT generation integration test',
        // macOS-friendly target so analyze runs without mobile toolchains.
        targetPlatforms: const ['macos'],
      );

      const architecture = ArchitectureState(
        firstFeatureName: 'user_profile', // multi-word → camelCase stress case
      );

      const cicd = CicdState();

      const theme = ThemeEngineState(
        approach: ThemeApproach.customM3,
        components: {AppComponent.button, AppComponent.card, AppComponent.textField},
        generateWidgetbook: true,
      );

      try {
        await const LaunchGenerationUsecase().execute(
          identity: identity,
          packages: packages,
          architecture: architecture,
          cicd: cicd,
          theme: theme,
          onLog: logs.add,
        );
      } catch (e) {
        fail('Generation threw:\n$e\n\n--- logs ---\n${logs.join('\n')}');
      }

      final projectDir = Directory('${tempRoot.path}/$projectName');
      expect(projectDir.existsSync(), isTrue, reason: 'project dir was not created');

      // Prove the generation actually ran (guards against a vacuous pass where
      // analyze finds nothing because the project is empty/broken).
      for (final relPath in const [
        'pubspec.yaml',
        'lib/main.dart',
        'lib/app.dart',
        'lib/core/env/app_env.dart', // envied was selected
        'lib/features/user_profile/presentation/pages/user_profile_page.dart',
      ]) {
        expect(
          File('${projectDir.path}/$relPath').existsSync(),
          isTrue,
          reason: 'expected generated file missing: $relPath',
        );
      }

      // build_runner must have produced generated parts (riverpod/freezed/envied).
      final generatedParts = projectDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.g.dart') || f.path.endsWith('.freezed.dart'))
          .toList();
      expect(
        generatedParts,
        isNotEmpty,
        reason: 'build_runner produced no .g.dart/.freezed.dart parts — codegen failed',
      );

      // Full CRUD surface on the API source (chopper variant here).
      final apiSrc = File(
        '${projectDir.path}/lib/features/user_profile/data/sources/'
        'user_profile_api_source.dart',
      ).readAsStringSync();
      expect(apiSrc, contains('getAll()'));
      expect(apiSrc, contains('add('));
      expect(apiSrc, contains('update('));
      expect(apiSrc, contains('delete('));

      // Observability + networking bricks (chopper variant).
      for (final relPath in const [
        'lib/core/utils/app_logger.dart',
        'lib/core/observers/provider_observer.dart',
        'lib/core/observers/logger_interceptor.dart',
        'lib/core/network/chopper_client_provider.dart',
        'lib/core/bootstrap.dart',
        'lib/core/error/error_handler.dart',
      ]) {
        expect(
          File('${projectDir.path}/$relPath').existsSync(),
          isTrue,
          reason: 'expected observability file missing: $relPath',
        );
      }
      // main delegates to bootstrap; bootstrap guards the zone + wires the observer.
      final mainDart = File('${projectDir.path}/lib/main.dart').readAsStringSync();
      expect(mainDart, contains('bootstrap(DevEnv())'));
      final bootstrap = File('${projectDir.path}/lib/core/bootstrap.dart').readAsStringSync();
      expect(bootstrap, contains('runZonedGuarded'));
      expect(bootstrap, contains('observers: [RiverpodObserver()]'));

      // Run the analyzer on the generated project.
      final analyze = await Process.run(
        'flutter',
        ['analyze', '--no-pub'],
        workingDirectory: projectDir.path,
      );
      final out = '${analyze.stdout}\n${analyze.stderr}';

      // Sanity: analyze actually executed and produced its summary line. Without
      // this, a failure to launch the analyzer would masquerade as "no errors".
      expect(
        RegExp(r'(\d+ issues? found|No issues found)').hasMatch(out),
        isTrue,
        reason: 'flutter analyze did not run as expected:\n$out',
      );

      // Generated code may carry lints (info) or warnings; we only fail on
      // genuine compile-level errors — those mean the generation is broken.
      final errorLines = const LineSplitter()
          .convert(out)
          .where((l) => l.contains(' error •') || l.contains('error -'))
          .toList();

      expect(
        errorLines,
        isEmpty,
        reason: 'flutter analyze reported errors:\n${errorLines.join('\n')}\n\n'
            '--- full analyze output ---\n$out',
      );
    },
    timeout: const Timeout(Duration(minutes: 12)),
  );

  test(
    'offline-first generates a valid Dart workspace that analyzes cleanly',
    () async {
      const projectName = 'neat_ws_test';
      final logs = <String>[];

      // Riverpod (annotations) + dio + go_router. Enough to exercise the witness
      // feature; the focus here is the workspace wrapping, not the heavy codegen
      // stack already covered by the first test.
      final offlinePackages = <PubPackage>[
        _dep('hooks_riverpod', '3.3.1'),
        _dep('flutter_hooks', '0.21.3+1'),
        _dep('riverpod_annotation', '4.0.2'),
        _dep('dio', '5.9.2'),
        _dep('go_router', '17.2.3'),
        _dev('riverpod_generator', '4.0.3'),
        _dev('build_runner', '2.15.0'),
      ];

      final identity = IdentityState(
        name: projectName,
        organization: 'com.neat.test',
        projectPath: tempRoot.path,
        description: 'NEAT offline-first workspace integration test',
        targetPlatforms: const ['macos'],
      );

      const architecture = ArchitectureState(
        firstFeatureName: 'user_profile',
        storageStrategy: StorageStrategy.offlineFirstRead,
      );

      try {
        await const LaunchGenerationUsecase().execute(
          identity: identity,
          packages: offlinePackages,
          architecture: architecture,
          cicd: const CicdState(),
          theme: const ThemeEngineState(approach: ThemeApproach.customM3),
          onLog: logs.add,
        );
      } catch (e) {
        fail('Offline-first generation threw:\n$e\n\n--- logs ---\n${logs.join('\n')}');
      }

      final projectDir = Directory('${tempRoot.path}/$projectName');
      const pkg = '${projectName}_local_storage';

      // The workspace member package exists, is wired up, and its Drift
      // codegen ran (database.g.dart proves build_runner ran in the package).
      for (final relPath in [
        'pubspec.yaml',
        'packages/$pkg/pubspec.yaml',
        'packages/$pkg/lib/$pkg.dart',
        'packages/$pkg/lib/src/database.dart',
        'packages/$pkg/lib/src/database.g.dart',
      ]) {
        expect(
          File('${projectDir.path}/$relPath').existsSync(),
          isTrue,
          reason: 'expected workspace file missing: $relPath',
        );
      }

      // Offline-first bricks landed in the app.
      expect(
        File('${projectDir.path}/lib/core/network/network_info.dart').existsSync(),
        isTrue,
        reason: 'core/network/network_info.dart missing',
      );

      // Dio provider + logging interceptor (dio variant) make the API source wirable.
      final dioProvider =
          File('${projectDir.path}/lib/core/network/dio_provider.dart');
      expect(dioProvider.existsSync(), isTrue, reason: 'core/network/dio_provider.dart missing');
      expect(dioProvider.readAsStringSync(), contains('LoggerInterceptor()'));
      expect(
        File('${projectDir.path}/lib/core/observers/logger_interceptor.dart').existsSync(),
        isTrue,
        reason: 'logger_interceptor.dart missing',
      );

      // The witness repository is the offline-first variant (remote + cache).
      final repoImpl = File(
        '${projectDir.path}/lib/features/user_profile/data/repositories/'
        'user_profile_repository_impl.dart',
      ).readAsStringSync();
      expect(repoImpl, contains('NetworkInfo'));
      expect(repoImpl, contains('_local.cacheAll'));

      // The local source is Drift-backed (imports the workspace package).
      final localSrc = File(
        '${projectDir.path}/lib/features/user_profile/data/sources/'
        'user_profile_local_source.dart',
      ).readAsStringSync();
      expect(localSrc, contains('package:$pkg/$pkg.dart'));
      expect(localSrc, contains('AppDatabase'));

      // Root pubspec declares the workspace + connectivity_plus; member carries resolution.
      final rootPubspec = File('${projectDir.path}/pubspec.yaml').readAsStringSync();
      expect(rootPubspec, contains('workspace:'));
      expect(rootPubspec, contains('packages/$pkg'));
      expect(rootPubspec, contains('connectivity_plus'));
      final pkgPubspec =
          File('${projectDir.path}/packages/$pkg/pubspec.yaml').readAsStringSync();
      expect(pkgPubspec, contains('resolution: workspace'));

      // The whole workspace analyzes without errors.
      final analyze = await Process.run(
        'flutter',
        ['analyze', '--no-pub'],
        workingDirectory: projectDir.path,
      );
      final out = '${analyze.stdout}\n${analyze.stderr}';
      expect(
        RegExp(r'(\d+ issues? found|No issues found)').hasMatch(out),
        isTrue,
        reason: 'flutter analyze did not run as expected:\n$out',
      );
      final errorLines = const LineSplitter()
          .convert(out)
          .where((l) => l.contains(' error •') || l.contains('error -'))
          .toList();
      expect(
        errorLines,
        isEmpty,
        reason: 'workspace analyze reported errors:\n${errorLines.join('\n')}\n\n$out',
      );
    },
    timeout: const Timeout(Duration(minutes: 12)),
  );

  test(
    'offline + sync generates the Outbox + SyncService and analyzes cleanly',
    () async {
      const projectName = 'neat_sync_test';
      final logs = <String>[];

      final syncPackages = <PubPackage>[
        _dep('hooks_riverpod', '3.3.1'),
        _dep('flutter_hooks', '0.21.3+1'),
        _dep('riverpod_annotation', '4.0.2'),
        _dep('dio', '5.9.2'),
        _dep('go_router', '17.2.3'),
        _dev('riverpod_generator', '4.0.3'),
        _dev('build_runner', '2.15.0'),
      ];

      final identity = IdentityState(
        name: projectName,
        organization: 'com.neat.test',
        projectPath: tempRoot.path,
        description: 'NEAT offline + sync integration test',
        targetPlatforms: const ['macos'],
      );

      const architecture = ArchitectureState(
        firstFeatureName: 'user_profile',
        storageStrategy: StorageStrategy.offlineFirstSync,
      );

      try {
        await const LaunchGenerationUsecase().execute(
          identity: identity,
          packages: syncPackages,
          architecture: architecture,
          cicd: const CicdState(),
          theme: const ThemeEngineState(approach: ThemeApproach.customM3),
          onLog: logs.add,
        );
      } catch (e) {
        fail('Sync generation threw:\n$e\n\n--- logs ---\n${logs.join('\n')}');
      }

      final projectDir = Directory('${tempRoot.path}/$projectName');
      const pkg = '${projectName}_local_storage';

      // SyncService brick + Outbox table generated.
      expect(
        File('${projectDir.path}/lib/core/sync/sync_service.dart').existsSync(),
        isTrue,
        reason: 'core/sync/sync_service.dart missing',
      );
      final db = File('${projectDir.path}/packages/$pkg/lib/src/database.dart')
          .readAsStringSync();
      expect(db, contains('class OutboxEntries'));
      expect(db, contains('enqueueOutbox'));

      // Full CRUD write contract + Outbox-backed write path.
      final iRepo = File(
        '${projectDir.path}/lib/features/user_profile/domain/repositories/'
        'i_user_profile_repository.dart',
      ).readAsStringSync();
      expect(iRepo, contains('create(UserProfileEntity entity)'));
      expect(iRepo, contains('update(UserProfileEntity entity)'));
      expect(iRepo, contains('delete(String id)'));

      final repoImpl = File(
        '${projectDir.path}/lib/features/user_profile/data/repositories/'
        'user_profile_repository_impl.dart',
      ).readAsStringSync();
      expect(repoImpl, contains('enqueueWrite'));
      expect(repoImpl, contains("operation: 'create'"));
      expect(repoImpl, contains("operation: 'delete'"));

      // The whole workspace analyzes without errors.
      final analyze = await Process.run(
        'flutter',
        ['analyze', '--no-pub'],
        workingDirectory: projectDir.path,
      );
      final out = '${analyze.stdout}\n${analyze.stderr}';
      expect(
        RegExp(r'(\d+ issues? found|No issues found)').hasMatch(out),
        isTrue,
        reason: 'flutter analyze did not run as expected:\n$out',
      );
      final errorLines = const LineSplitter()
          .convert(out)
          .where((l) => l.contains(' error •') || l.contains('error -'))
          .toList();
      expect(
        errorLines,
        isEmpty,
        reason: 'sync workspace analyze reported errors:\n${errorLines.join('\n')}\n\n$out',
      );
    },
    timeout: const Timeout(Duration(minutes: 12)),
  );
}

PubPackage _dep(String name, String version) =>
    PubPackage(name: name, version: version, description: '');

PubPackage _dev(String name, String version) =>
    PubPackage(name: name, version: version, description: '', isDev: true);
