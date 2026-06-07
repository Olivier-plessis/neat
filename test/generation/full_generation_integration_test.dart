@Tags(['integration'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:neat/features/architecture/domain/models/architecture_state.dart';
import 'package:neat/features/cicd/domain/models/cicd_state.dart';
import 'package:neat/features/dependencies/domain/models/pub_package.dart';
import 'package:neat/features/feature_gen/domain/models/feature_gen_options.dart';
import 'package:neat/features/feature_gen/domain/services/project_loader.dart';
import 'package:neat/features/feature_gen/domain/usecases/generate_feature_usecase.dart';
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
    'generates a full chopper + offline-sync project that analyzes cleanly',
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
        // Chopper + offline-sync: proves the chopper Outbox replay path.
        storageStrategy: StorageStrategy.offlineFirstSync,
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

      // The feature ships a real list screen with Skeletonizer loading states.
      final page = File(
        '${projectDir.path}/lib/features/user_profile/presentation/pages/'
        'user_profile_page.dart',
      ).readAsStringSync();
      expect(page, contains('Skeletonizer('));
      expect(page, contains('ListView.separated('));
      final provider = File(
        '${projectDir.path}/lib/features/user_profile/presentation/providers/'
        'user_profile_provider.dart',
      ).readAsStringSync();
      expect(provider, contains('Future<List<UserProfileEntity>> build()'));
      expect(provider, contains('getUserProfileUsecaseProvider'));
      expect(
        File('${projectDir.path}/pubspec.yaml').readAsStringSync(),
        contains('skeletonizer:'),
      );

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

      // Ready-to-use DI graph wires the chopper-backed API source + usecases.
      final di = File(
        '${projectDir.path}/lib/features/user_profile/presentation/providers/'
        'user_profile_providers.dart',
      ).readAsStringSync();
      expect(di, contains('UserProfileApiSource.create(ref.watch(chopperClientProvider))'));
      // Offline-sync: repository is the 3-arg variant + the sync engine is wired.
      expect(di, contains('ref.watch(networkInfoProvider)'));
      expect(di, contains('SyncService userProfileSync(Ref ref)'));
      expect(di, contains('api.add(UserProfileModel.fromJson(data))'));
      expect(di, contains('GetUserProfileUsecase'));
      expect(di, contains('CreateUserProfileUsecase'));

      // Workspace Contract (.neat.json) captures the stack for feature gen.
      final contractFile = File('${projectDir.path}/.neat.json');
      expect(contractFile.existsSync(), isTrue, reason: '.neat.json missing');
      final contract = jsonDecode(contractFile.readAsStringSync()) as Map<String, dynamic>;
      expect(contract['schemaVersion'], 1);
      expect(contract['projectName'], projectName);
      expect(contract['stateManagement'], 'riverpod');
      expect(contract['httpClient'], 'chopper');
      expect(contract['storageStrategy'], 'offlineFirstSync');
      expect(contract['architecture'], 'feature_first');

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

      // Generated code must be error- AND warning-free (infos are tolerated).
      final errorLines = const LineSplitter()
          .convert(out)
          .where((l) => l.contains(' error •') || l.contains(' warning •'))
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

      // Ready-to-use DI graph: dio-backed source + local source + repo. The
      // shared Drift db + NetworkInfo singletons live in core, not here, so the
      // feature DI references them instead of redeclaring them.
      final di = File(
        '${projectDir.path}/lib/features/user_profile/presentation/providers/'
        'user_profile_providers.dart',
      ).readAsStringSync();
      expect(di, contains('UserProfileApiSource(ref.watch(dioProvider))'));
      expect(di, contains('ref.watch(appDatabaseProvider)'));
      expect(di, contains('ref.watch(networkInfoProvider)'));
      expect(di, contains("import 'package:$projectName/core/providers/infrastructure_providers.dart'"));
      // The feature DI must NOT redeclare the shared singletons.
      expect(di, isNot(contains('AppDatabase appDatabase(Ref ref)')));
      expect(di, isNot(contains('NetworkInfo networkInfo(Ref ref)')));

      // Shared infrastructure providers exist once, in core.
      final infra = File(
        '${projectDir.path}/lib/core/providers/infrastructure_providers.dart',
      );
      expect(infra.existsSync(), isTrue, reason: 'core infrastructure_providers.dart missing');
      final infraSrc = infra.readAsStringSync();
      expect(infraSrc, contains('AppDatabase appDatabase(Ref ref)'));
      expect(infraSrc, contains('NetworkInfo networkInfo(Ref ref)'));

      // Offline usage guide ships with the project.
      expect(
        File('${projectDir.path}/docs/OFFLINE.md').existsSync(),
        isTrue,
        reason: 'docs/OFFLINE.md missing',
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
          .where((l) => l.contains(' error •') || l.contains(' warning •'))
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

      // SyncService is auto-wired in the DI graph (replay via the API source).
      final di = File(
        '${projectDir.path}/lib/features/user_profile/presentation/providers/'
        'user_profile_providers.dart',
      ).readAsStringSync();
      expect(di, contains('SyncService userProfileSync(Ref ref)'));
      expect(di, contains('..start()'));
      expect(di, contains('api.add(UserProfileModel.fromJson(data))'));

      // Outbox retry cap + offline usage guide.
      final syncSrc =
          File('${projectDir.path}/lib/core/sync/sync_service.dart').readAsStringSync();
      expect(syncSrc, contains('maxRetries'));
      final doc = File('${projectDir.path}/docs/OFFLINE.md');
      expect(doc.existsSync(), isTrue, reason: 'docs/OFFLINE.md missing');
      expect(doc.readAsStringSync(), contains('Outbox'));

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
          .where((l) => l.contains(' error •') || l.contains(' warning •'))
          .toList();
      expect(
        errorLines,
        isEmpty,
        reason: 'sync workspace analyze reported errors:\n${errorLines.join('\n')}\n\n$out',
      );
    },
    timeout: const Timeout(Duration(minutes: 12)),
  );

  test(
    'extracted UI package + Widgetbook form a clean workspace',
    () async {
      const projectName = 'neat_ui_test';
      final logs = <String>[];
      const uiPkg = '${projectName}_ui';

      final uiPackages = <PubPackage>[
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
        description: 'NEAT UI-package integration test',
        targetPlatforms: const ['macos'],
      );

      const architecture = ArchitectureState(firstFeatureName: 'user_profile');

      const theme = ThemeEngineState(
        approach: ThemeApproach.customM3,
        components: {AppComponent.button, AppComponent.card},
        generateWidgetbook: true,
        extractUiPackage: true,
      );

      try {
        await const LaunchGenerationUsecase().execute(
          identity: identity,
          packages: uiPackages,
          architecture: architecture,
          cicd: const CicdState(),
          theme: theme,
          onLog: logs.add,
        );
      } catch (e) {
        fail('UI-package generation threw:\n$e\n\n--- logs ---\n${logs.join('\n')}');
      }

      final projectDir = Directory('${tempRoot.path}/$projectName');

      // The <app>_ui package: pubspec, barrel, relocated theme + components.
      for (final relPath in [
        'packages/$uiPkg/pubspec.yaml',
        'packages/$uiPkg/lib/$uiPkg.dart',
        'packages/$uiPkg/lib/core/theme/app_theme.dart',
        'packages/$uiPkg/lib/components/app_button.dart',
        'packages/$uiPkg/lib/components/app_card.dart',
        'widgetbook/pubspec.yaml',
        'widgetbook/lib/main.dart',
      ]) {
        expect(
          File('${projectDir.path}/$relPath').existsSync(),
          isTrue,
          reason: 'expected file missing: $relPath',
        );
      }

      // Theme no longer in the app.
      expect(
        File('${projectDir.path}/lib/core/theme/app_theme.dart').existsSync(),
        isFalse,
        reason: 'app_theme.dart should have moved to the UI package',
      );
      // State stays in the app.
      expect(
        File('${projectDir.path}/lib/core/theme/theme_mode_controller.dart').existsSync(),
        isTrue,
        reason: 'theme_mode_controller stays in the app',
      );

      // Barrel exports + app imports the package.
      final barrel =
          File('${projectDir.path}/packages/$uiPkg/lib/$uiPkg.dart').readAsStringSync();
      expect(barrel, contains("export 'core/theme/app_theme.dart';"));
      expect(barrel, contains("export 'components/app_button.dart';"));
      expect(barrel, contains("export 'widgets/asset_images.dart';"));
      expect(barrel, contains("export 'gen/assets.dart';"));
      final appDart = File('${projectDir.path}/lib/app.dart').readAsStringSync();
      expect(appDart, contains("import 'package:$uiPkg/$uiPkg.dart';"));

      // spider: typed asset paths (config + generated Assets class).
      expect(File('${projectDir.path}/packages/$uiPkg/spider.yaml').existsSync(), isTrue);
      final assetsClass = File(
        '${projectDir.path}/packages/$uiPkg/lib/gen/assets.dart',
      ).readAsStringSync();
      expect(assetsClass, contains('class Assets'));

      // Shared SVG/image asset widgets ship in the UI package (flutter_svg dep +
      // a package-scoped assets folder).
      final assetWidgets = File(
        '${projectDir.path}/packages/$uiPkg/lib/widgets/asset_images.dart',
      ).readAsStringSync();
      expect(assetWidgets, contains('class SvgPictureCustom'));
      expect(assetWidgets, contains('class ImagePictureCustom'));
      expect(assetWidgets, contains("package: '$uiPkg'"));
      final uiPubspec =
          File('${projectDir.path}/packages/$uiPkg/pubspec.yaml').readAsStringSync();
      expect(uiPubspec, contains('flutter_svg'));
      expect(uiPubspec, contains('assets/'));
      expect(uiPubspec, contains('spider'));

      // Root workspace lists the UI package + widgetbook; widgetbook depends on it.
      final rootPubspec = File('${projectDir.path}/pubspec.yaml').readAsStringSync();
      expect(rootPubspec, contains('packages/$uiPkg'));
      expect(rootPubspec, contains('- widgetbook'));
      final wbPubspec = File('${projectDir.path}/widgetbook/pubspec.yaml').readAsStringSync();
      expect(wbPubspec, contains('path: ../packages/$uiPkg'));

      // Whole workspace analyzes without errors or warnings.
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
          .where((l) => l.contains(' error •') || l.contains(' warning •'))
          .toList();
      expect(
        errorLines,
        isEmpty,
        reason: 'UI-package workspace analyze reported issues:\n${errorLines.join('\n')}\n\n$out',
      );
    },
    timeout: const Timeout(Duration(minutes: 12)),
  );

  test(
    'FlexColorScheme + extracted UI package form a clean workspace',
    () async {
      const projectName = 'neat_flex_test';
      final logs = <String>[];
      const uiPkg = '${projectName}_ui';

      final flexPackages = <PubPackage>[
        _dep('hooks_riverpod', '3.3.1'),
        _dep('flutter_hooks', '0.21.3+1'),
        _dep('riverpod_annotation', '4.0.2'),
        _dep('flex_color_scheme', '8.4.0'),
        _dev('riverpod_generator', '4.0.3'),
        _dev('build_runner', '2.15.0'),
      ];

      final identity = IdentityState(
        name: projectName,
        organization: 'com.neat.test',
        projectPath: tempRoot.path,
        description: 'NEAT flex + UI-package integration test',
        targetPlatforms: const ['macos'],
      );

      const architecture = ArchitectureState(firstFeatureName: 'user_profile');

      // FlexColorScheme approach (default config, no pasted code) + UI extraction.
      const theme = ThemeEngineState(
        approach: ThemeApproach.flexColorScheme,
        extractUiPackage: true,
      );

      try {
        await const LaunchGenerationUsecase().execute(
          identity: identity,
          packages: flexPackages,
          architecture: architecture,
          cicd: const CicdState(),
          theme: theme,
          onLog: logs.add,
        );
      } catch (e) {
        fail('Flex + UI-package generation threw:\n$e\n\n--- logs ---\n${logs.join('\n')}');
      }

      final projectDir = Directory('${tempRoot.path}/$projectName');

      // Flex theme relocated into the UI package + flex dep in the package.
      final themeFile =
          File('${projectDir.path}/packages/$uiPkg/lib/core/theme/app_theme.dart');
      expect(themeFile.existsSync(), isTrue, reason: 'UI package app_theme.dart missing');
      expect(themeFile.readAsStringSync(), contains('FlexThemeData'));
      final uiPubspec =
          File('${projectDir.path}/packages/$uiPkg/pubspec.yaml').readAsStringSync();
      expect(uiPubspec, contains('flex_color_scheme'));

      // App imports the package; workspace lists it.
      expect(
        File('${projectDir.path}/lib/app.dart').readAsStringSync(),
        contains("import 'package:$uiPkg/$uiPkg.dart';"),
      );
      expect(
        File('${projectDir.path}/pubspec.yaml').readAsStringSync(),
        contains('packages/$uiPkg'),
      );

      // Whole workspace analyzes without errors or warnings.
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
          .where((l) => l.contains(' error •') || l.contains(' warning •'))
          .toList();
      expect(
        errorLines,
        isEmpty,
        reason: 'flex + UI-package workspace analyze reported issues:\n'
            '${errorLines.join('\n')}\n\n$out',
      );
    },
    timeout: const Timeout(Duration(minutes: 12)),
  );

  test(
    'feature generation adds a 2nd feature to an existing project, cleanly',
    () async {
      const projectName = 'neat_featgen_test';
      final logs = <String>[];

      final pkgs = <PubPackage>[
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
        description: 'NEAT feature-gen integration test',
        targetPlatforms: const ['macos'],
      );
      const architecture = ArchitectureState(); // firstFeatureName defaults to 'home'

      // 1. Generate the base project (writes .neat.json).
      try {
        await const LaunchGenerationUsecase().execute(
          identity: identity,
          packages: pkgs,
          architecture: architecture,
          cicd: const CicdState(),
          theme: const ThemeEngineState(approach: ThemeApproach.customM3),
          onLog: logs.add,
        );
      } catch (e) {
        fail('Base generation threw:\n$e');
      }

      final projectDir = Directory('${tempRoot.path}/$projectName');

      // 2. Re-open it via the contract (as the Hub would).
      final project = await const ProjectLoader().load(projectDir.path);
      expect(project, isNotNull, reason: '.neat.json should make the project loadable');
      expect(project!.features, ['home']);
      expect(project.contract.httpClient, 'dio');

      // 3. Add a 2nd feature, matching the stack derived from the contract.
      await const GenerateFeatureUsecase().execute(
        project: project,
        options: const FeatureGenOptions(name: 'orders'),
        onLog: logs.add,
      );

      // The new feature exists; the original is untouched.
      expect(
        File('${projectDir.path}/lib/features/orders/presentation/pages/orders_page.dart')
            .existsSync(),
        isTrue,
      );
      expect(
        File('${projectDir.path}/lib/features/orders/data/sources/orders_api_source.dart')
            .existsSync(),
        isTrue,
      );
      expect(
        File('${projectDir.path}/lib/features/home/presentation/pages/home_page.dart')
            .existsSync(),
        isTrue,
        reason: 'existing feature must be left intact',
      );

      // 3b. The new feature is wired into the router + AppRoutePath.
      final routesDart =
          File('${projectDir.path}/lib/core/router/routes.dart').readAsStringSync();
      expect(routesDart, contains('AppRoutePath.orders'));
      final routePath = File(
        '${projectDir.path}/lib/core/constants/app_route_path.dart',
      ).readAsStringSync();
      expect(routePath, contains("static const String orders = '/orders';"));

      // 4. Scanning now sees both features.
      expect(await const ProjectLoader().load(projectDir.path).then((p) => p!.features),
          ['home', 'orders']);

      // 5. Non-destructive guard: re-adding an existing feature throws.
      expect(
        () => const GenerateFeatureUsecase().execute(
          project: project,
          options: const FeatureGenOptions(name: 'home'),
          onLog: logs.add,
        ),
        throwsA(isA<Exception>()),
      );

      // 6. The whole project still analyzes without errors or warnings.
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
          .where((l) => l.contains(' error •') || l.contains(' warning •'))
          .toList();
      expect(
        errorLines,
        isEmpty,
        reason: 'feature-gen project analyze reported issues:\n${errorLines.join('\n')}\n\n$out',
      );
    },
    timeout: const Timeout(Duration(minutes: 12)),
  );

  test(
    'feature generation injects a Drift table into an offline-sync project',
    () async {
      const projectName = 'neat_featgen_offline';
      final logs = <String>[];

      final pkgs = <PubPackage>[
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
        description: 'NEAT offline feature-gen integration test',
        targetPlatforms: const ['macos'],
      );
      const architecture = ArchitectureState(
        storageStrategy: StorageStrategy.offlineFirstSync,
      );

      try {
        await const LaunchGenerationUsecase().execute(
          identity: identity,
          packages: pkgs,
          architecture: architecture,
          cicd: const CicdState(),
          theme: const ThemeEngineState(approach: ThemeApproach.customM3),
          onLog: logs.add,
        );
      } catch (e) {
        fail('Base offline generation threw:\n$e');
      }

      final projectDir = Directory('${tempRoot.path}/$projectName');
      const uiPkg = '${projectName}_local_storage';

      final project = await const ProjectLoader().load(projectDir.path);
      expect(project, isNotNull);
      expect(project!.contract.storageStrategy, 'offlineFirstSync');

      // Add a feature → its Drift table + DAO must be injected into the package.
      await const GenerateFeatureUsecase().execute(
        project: project,
        options: const FeatureGenOptions(name: 'orders'),
        onLog: logs.add,
      );

      final dbDart = File(
        '${projectDir.path}/packages/$uiPkg/lib/src/database.dart',
      ).readAsStringSync();
      expect(dbDart, contains('class OrdersRows extends Table'));
      expect(dbDart, contains('upsertOrders(OrdersRow row)')); // DAO injected
      expect(dbDart, contains('OrdersRows,')); // added to @DriftDatabase(tables:)

      // The whole offline workspace still analyzes cleanly.
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
          .where((l) => l.contains(' error •') || l.contains(' warning •'))
          .toList();
      expect(
        errorLines,
        isEmpty,
        reason: 'offline feature-gen analyze reported issues:\n${errorLines.join('\n')}\n\n$out',
      );
    },
    timeout: const Timeout(Duration(minutes: 12)),
  );

  test(
    'navigation-shell app boots into a bottom-nav shell and analyzes cleanly',
    () async {
      const projectName = 'neat_shell_test';
      final logs = <String>[];

      final pkgs = <PubPackage>[
        _dep('hooks_riverpod', '3.3.1'),
        _dep('flutter_hooks', '0.21.3+1'),
        _dep('riverpod_annotation', '4.0.2'),
        _dep('go_router', '17.2.3'),
        _dev('riverpod_generator', '4.0.3'),
        _dev('build_runner', '2.15.0'),
        _dev('go_router_builder', '4.3.0'),
      ];

      final identity = IdentityState(
        name: projectName,
        organization: 'com.neat.test',
        projectPath: tempRoot.path,
        description: 'NEAT navigation-shell integration test',
        targetPlatforms: const ['macos'],
      );

      // Bottom-nav shell from launch: the first feature ('home', the default) is
      // the first tab.
      const architecture = ArchitectureState(
        useNavigationShell: true,
        shellIcon: 'dashboard',
        shellLabel: 'Home',
      );

      try {
        await const LaunchGenerationUsecase().execute(
          identity: identity,
          packages: pkgs,
          architecture: architecture,
          cicd: const CicdState(),
          theme: const ThemeEngineState(approach: ThemeApproach.customM3),
          onLog: logs.add,
        );
      } catch (e) {
        fail('Navigation-shell generation threw:\n$e\n\n--- logs ---\n${logs.join('\n')}');
      }

      final projectDir = Directory('${tempRoot.path}/$projectName');

      // The shell scaffold + typed shell route exist.
      final scaffold = File('${projectDir.path}/lib/core/router/scaffold_with_nav_bar.dart');
      expect(scaffold.existsSync(), isTrue, reason: 'scaffold_with_nav_bar.dart missing');
      expect(scaffold.readAsStringSync(), contains('NavigationBar('));
      expect(
        scaffold.readAsStringSync(),
        contains("NavigationDestination(icon: Icon(Icons.dashboard), label: 'Home')"),
      );

      final shellRoute = File('${projectDir.path}/lib/core/router/app_shell_route.dart');
      expect(shellRoute.existsSync(), isTrue, reason: 'app_shell_route.dart missing');
      expect(shellRoute.readAsStringSync(), contains('@TypedStatefulShellRoute<AppShellRouteData>'));
      expect(shellRoute.readAsStringSync(), contains('TypedGoRoute<HomeRoute>(path: AppRoutePath.home)'));

      // routes.dart aggregates the shell (not a flat first-feature route).
      final routesDart =
          File('${projectDir.path}/lib/core/router/routes.dart').readAsStringSync();
      expect(routesDart, contains(r'...app_shell.$appRoutes'));

      // The first feature did NOT get its own standalone route file (it lives in
      // the shell), and the app boots into it (initialLocation = '/').
      expect(
        File('${projectDir.path}/lib/features/home/presentation/routes/home_routes.dart')
            .existsSync(),
        isFalse,
        reason: 'shell-branch feature must not emit a standalone route file',
      );
      final appRouter =
          File('${projectDir.path}/lib/core/router/app_router.dart').readAsStringSync();
      expect(appRouter, contains('initialLocation: AppRoutePath.home'));

      // Contract records the choice.
      final contract = jsonDecode(
        File('${projectDir.path}/.neat.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      expect(contract['useNavigationShell'], isTrue);

      // The whole project analyzes cleanly (build_runner generated the shell mixins).
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
          .where((l) => l.contains(' error •') || l.contains(' warning •'))
          .toList();
      expect(
        errorLines,
        isEmpty,
        reason: 'navigation-shell analyze reported issues:\n${errorLines.join('\n')}\n\n$out',
      );
    },
    timeout: const Timeout(Duration(minutes: 12)),
  );

  test(
    'Supabase backend: SDK-backed source + init + envied config, analyzes cleanly',
    () async {
      const projectName = 'neat_supabase_test';
      final logs = <String>[];

      final pkgs = <PubPackage>[
        _dep('hooks_riverpod', '3.3.1'),
        _dep('flutter_hooks', '0.21.3+1'),
        _dep('riverpod_annotation', '4.0.2'),
        _dep('supabase_flutter', '2.14.1'),
        _dep('go_router', '17.2.3'),
        _dep('json_annotation', '4.11.0'),
        _dep('freezed_annotation', '3.1.0'),
        _dep('envied', '1.3.5'),
        _dev('riverpod_generator', '4.0.3'),
        _dev('build_runner', '2.15.0'),
        _dev('freezed', '3.2.5'),
        _dev('json_serializable', '6.13.0'),
        _dev('envied_generator', '1.3.5'),
      ];

      final identity = IdentityState(
        name: projectName,
        organization: 'com.neat.test',
        projectPath: tempRoot.path,
        description: 'NEAT Supabase backend integration test',
        targetPlatforms: const ['macos'],
      );

      try {
        await const LaunchGenerationUsecase().execute(
          identity: identity,
          packages: pkgs,
          architecture: const ArchitectureState(firstFeatureName: 'todo'),
          cicd: const CicdState(),
          theme: const ThemeEngineState(approach: ThemeApproach.customM3),
          onLog: logs.add,
        );
      } catch (e) {
        fail('Supabase generation threw:\n$e\n\n--- logs ---\n${logs.join('\n')}');
      }

      final projectDir = Directory('${tempRoot.path}/$projectName');

      // Backend recorded as supabase.
      final contract = jsonDecode(
        File('${projectDir.path}/.neat.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      expect(contract['httpClient'], 'supabase');

      // Supabase client provider (not dio/chopper).
      expect(
        File('${projectDir.path}/lib/core/network/supabase_provider.dart').existsSync(),
        isTrue,
      );
      expect(
        File('${projectDir.path}/lib/core/network/dio_provider.dart').existsSync(),
        isFalse,
      );

      // The remote source talks to Supabase (same getAll/add/... contract).
      final src = File(
        '${projectDir.path}/lib/features/todo/data/sources/todo_api_source.dart',
      ).readAsStringSync();
      expect(src, contains('SupabaseClient'));
      expect(src, contains('.from(_table).select()'));
      expect(src, contains('Future<List<TodoModel>> getAll()'));
      expect(src, contains('Future<void> delete(String id)'));

      // DI wires the source from the supabase client provider.
      final di = File(
        '${projectDir.path}/lib/features/todo/presentation/providers/todo_providers.dart',
      ).readAsStringSync();
      expect(di, contains('TodoApiSource(ref.watch(supabaseClientProvider))'));

      // bootstrap initializes Supabase from the typed env.
      final bootstrap = File('${projectDir.path}/lib/core/bootstrap.dart').readAsStringSync();
      expect(bootstrap, contains('Supabase.initialize('));
      expect(bootstrap, contains('AppEnv.current.supabaseUrl'));
      // envied contract carries the supabase keys.
      expect(
        File('${projectDir.path}/lib/core/env/app_env.dart').readAsStringSync(),
        contains('supabaseAnonKey'),
      );
      expect(
        File('${projectDir.path}/.env.dev').readAsStringSync(),
        contains('SUPABASE_URL='),
      );

      // The whole project analyzes without errors or warnings.
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
          .where((l) => l.contains(' error •') || l.contains(' warning •'))
          .toList();
      expect(
        errorLines,
        isEmpty,
        reason: 'Supabase project analyze reported issues:\n${errorLines.join('\n')}\n\n$out',
      );
    },
    timeout: const Timeout(Duration(minutes: 12)),
  );

  test(
    'branding (logo) generates icon + splash config and still analyzes cleanly',
    () async {
      const projectName = 'neat_brand_test';
      final logs = <String>[];

      // A minimal valid 1x1 PNG to act as the uploaded logo.
      final logo = File('${tempRoot.path}/logo.png')
        ..writeAsBytesSync(base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
        ));

      final identity = IdentityState(
        name: projectName,
        organization: 'com.neat.test',
        projectPath: tempRoot.path,
        description: 'NEAT branding integration test',
        targetPlatforms: const ['macos'],
      );

      final theme = ThemeEngineState(approach: ThemeApproach.customM3, logoPath: logo.path);

      try {
        await const LaunchGenerationUsecase().execute(
          identity: identity,
          packages: <PubPackage>[
            _dep('hooks_riverpod', '3.3.1'),
            _dep('flutter_hooks', '0.21.3+1'),
            _dep('riverpod_annotation', '4.0.2'),
            _dev('riverpod_generator', '4.0.3'),
            _dev('build_runner', '2.15.0'),
          ],
          architecture: const ArchitectureState(),
          cicd: const CicdState(),
          theme: theme,
          onLog: logs.add,
        );
      } catch (e) {
        fail('Branding generation threw:\n$e\n\n--- logs ---\n${logs.join('\n')}');
      }

      final projectDir = Directory('${tempRoot.path}/$projectName');

      // Logo copied + both configs written.
      expect(
        File('${projectDir.path}/assets/branding/logo.png').existsSync(),
        isTrue,
        reason: 'logo not copied into the project',
      );
      expect(File('${projectDir.path}/flutter_launcher_icons.yaml').existsSync(), isTrue);
      expect(File('${projectDir.path}/flutter_native_splash.yaml').existsSync(), isTrue);
      // Dev deps resolved (pub get would have thrown otherwise).
      final pubspec = File('${projectDir.path}/pubspec.yaml').readAsStringSync();
      expect(pubspec, contains('flutter_launcher_icons:'));
      expect(pubspec, contains('flutter_native_splash:'));

      // Branding adds only config + assets → the project still analyzes clean.
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
          .where((l) => l.contains(' error •') || l.contains(' warning •'))
          .toList();
      expect(
        errorLines,
        isEmpty,
        reason: 'branding project analyze reported issues:\n${errorLines.join('\n')}\n\n$out',
      );
    },
    timeout: const Timeout(Duration(minutes: 12)),
  );
}

PubPackage _dep(String name, String version) =>
    PubPackage(name: name, version: version, description: '');

PubPackage _dev(String name, String version) =>
    PubPackage(name: name, version: version, description: '', isDev: true);
