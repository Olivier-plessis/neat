@Tags(['integration'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:neat/features/architecture/domain/models/architecture_state.dart';
import 'package:neat/features/architecture/domain/models/env_config.dart';
import 'package:neat/features/cicd/domain/models/cicd_state.dart';
import 'package:neat/features/dependencies/domain/models/pub_package.dart';
import 'package:neat/features/feature_gen/domain/models/feature_gen_options.dart';
import 'package:neat/features/feature_gen/domain/services/project_loader.dart';
import 'package:neat/features/feature_gen/domain/usecases/generate_feature_usecase.dart';
import 'package:neat/features/generation/domain/models/crud_endpoint_overrides.dart';
import 'package:neat/features/generation/domain/models/endpoint_spec.dart';
import 'package:neat/features/generation/domain/models/field_spec.dart';
import 'package:neat/features/generation/domain/services/json_entity_inferencer.dart';
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
        components: {
          AppComponent.button,
          AppComponent.card,
          AppComponent.textField,
        },
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
      expect(
        projectDir.existsSync(),
        isTrue,
        reason: 'project dir was not created',
      );

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
          .where(
            (f) =>
                f.path.endsWith('.g.dart') || f.path.endsWith('.freezed.dart'),
          )
          .toList();
      expect(
        generatedParts,
        isNotEmpty,
        reason:
            'build_runner produced no .g.dart/.freezed.dart parts — codegen failed',
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
      // ArchitectureState() defaults to a single `prod` env → collapses to the
      // unprefixed Env() (see the mono-env-by-default design).
      final mainDart = File(
        '${projectDir.path}/lib/main.dart',
      ).readAsStringSync();
      expect(mainDart, contains('bootstrap(Env())'));
      final bootstrap = File(
        '${projectDir.path}/lib/core/bootstrap.dart',
      ).readAsStringSync();
      expect(bootstrap, contains('runZonedGuarded'));
      expect(bootstrap, contains('observers: [RiverpodObserver()]'));

      // Repository-level DI (data/) wires the chopper-backed API source + sync.
      // Presentation never references a concrete Data class — only the
      // abstract-typed repository provider exposed here (wesioo-style split).
      final repoProviders = File(
        '${projectDir.path}/lib/features/user_profile/data/repositories/'
        'user_profile_repository_providers.dart',
      ).readAsStringSync();
      expect(
        repoProviders,
        contains(
          'UserProfileApiSource.create(ref.watch(chopperClientProvider))',
        ),
      );
      // Offline-sync: repository is the 3-arg variant + the sync engine is wired.
      expect(repoProviders, contains('ref.watch(networkInfoProvider)'));
      expect(repoProviders, contains('SyncService userProfileSync(Ref ref)'));
      expect(
        repoProviders,
        contains('api.add(UserProfileModel.fromJson(data))'),
      );

      // Usecase-level DI (presentation/) is built from the repository provider
      // above — its only import into data/ is the abstract-typed provider.
      final usecaseProviders = File(
        '${projectDir.path}/lib/features/user_profile/presentation/providers/'
        'user_profile_usecase_providers.dart',
      ).readAsStringSync();
      expect(usecaseProviders, contains('GetUserProfileUsecase'));
      expect(usecaseProviders, contains('CreateUserProfileUsecase'));
      expect(
        usecaseProviders,
        isNot(contains('UserProfileApiSource')),
        reason: 'presentation must never reference a concrete Data class',
      );
      expect(
        usecaseProviders,
        isNot(contains('UserProfileRepositoryImpl')),
        reason: 'presentation must never reference a concrete Data class',
      );

      // docs/REMOVE_FIRST_FEATURE.md: a feature isn't self-contained in its
      // own folder, so this guide should cover every shared file this exact
      // combo (chopper + offline-sync, no packageSplit, no shell) touched —
      // and only those.
      final removeDoc = File(
        '${projectDir.path}/docs/REMOVE_FIRST_FEATURE.md',
      ).readAsStringSync();
      expect(removeDoc, contains('lib/features/user_profile/'));
      expect(removeDoc, contains('// neat:route-imports'));
      expect(removeDoc, contains('chopper_model_converter.dart'));
      expect(removeDoc, contains('database.dart'));
      expect(
        removeDoc,
        contains('// neat:migrations'),
        reason: 'hasSync is on',
      );
      expect(
        removeDoc,
        isNot(contains('packageSplit)')),
        reason: 'not a packageSplit project',
      );
      expect(
        removeDoc,
        isNot(contains('Navigation shell')),
        reason: 'no shell branch here',
      );

      // Executable regression probe for Chopper's JsonConverter bug: the
      // built-in converter only decodes to Map/List — it never calls a custom
      // Model's fromJson — so `Response<List<XModel>>` throws
      // `FormatException: expected ... to be XModel, but got Map` at runtime.
      // `flutter analyze` can't catch this (the generated code compiles fine;
      // it only fails against a real decoded response). This drives the real
      // chopper pipeline: an http.Response → ModelJsonConverter.convertResponse.
      await File(
        '${projectDir.path}/test/_chopper_converter_probe_test.dart',
      ).writeAsString('''
import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:$projectName/core/network/chopper_model_converter.dart';
import 'package:$projectName/features/user_profile/data/models/user_profile_model.dart';

void main() {
  test('ModelJsonConverter decodes a list response into typed Models', () async {
    final httpResponse = http.Response(
      '[{"id": 1, "name": "Ada"}, {"id": 2, "name": "Grace"}]',
      200,
      headers: {'content-type': 'application/json'},
    );
    final response = chopper.Response<dynamic>(httpResponse, null);

    final converted = await const ModelJsonConverter()
        .convertResponse<List<UserProfileModel>, UserProfileModel>(response);

    expect(converted.body, isA<List<UserProfileModel>>());
    expect(converted.body!.length, 2);
    expect(converted.body!.first.id, '1');
    expect(converted.body!.first.name, 'Ada');
  });

  test('ModelJsonConverter decodes a single-object response', () async {
    final httpResponse = http.Response(
      '{"id": 7, "name": "Turing"}',
      200,
      headers: {'content-type': 'application/json'},
    );
    final response = chopper.Response<dynamic>(httpResponse, null);

    final converted = await const ModelJsonConverter()
        .convertResponse<UserProfileModel, UserProfileModel>(response);

    expect(converted.body, isA<UserProfileModel>());
    expect(converted.body!.id, '7');
  });
}
''');
      final probe = await Process.run('flutter', [
        'test',
        'test/_chopper_converter_probe_test.dart',
      ], workingDirectory: projectDir.path);
      expect(
        probe.exitCode,
        0,
        reason:
            'chopper-converter regression probe failed:\n${probe.stdout}\n${probe.stderr}',
      );

      // Workspace Contract (.neat.json) captures the stack for feature gen.
      final contractFile = File('${projectDir.path}/.neat.json');
      expect(contractFile.existsSync(), isTrue, reason: '.neat.json missing');
      final contract =
          jsonDecode(contractFile.readAsStringSync()) as Map<String, dynamic>;
      expect(contract['schemaVersion'], 1);
      expect(contract['projectName'], projectName);
      expect(contract['stateManagement'], 'riverpod');
      expect(contract['httpClient'], 'chopper');
      expect(contract['storageStrategy'], 'offlineFirstSync');
      expect(contract['architecture'], 'feature_first');

      // Run the analyzer on the generated project.
      final analyze = await Process.run('flutter', [
        'analyze',
        '--no-pub',
      ], workingDirectory: projectDir.path);
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
          .where(
            (l) =>
                (l.contains(' error •') || l.contains(' warning •')) &&
                !l.contains('• build/'),
          )
          .toList();

      expect(
        errorLines,
        isEmpty,
        reason:
            'flutter analyze reported errors:\n${errorLines.join('\n')}\n\n'
            '--- full analyze output ---\n$out',
      );
    },
    timeout: const Timeout(Duration(minutes: 12)),
  );

  test(
    'manual Riverpod (useRiverpodAnnotations: false): Notifier/NotifierProvider '
    'generated, not the legacy StateNotifier/StateNotifierProvider, analyzes cleanly',
    () async {
      const projectName = 'neat_manual_riverpod_test';
      final logs = <String>[];

      // No riverpod_annotation/riverpod_generator — manual mode needs neither.
      final manualPackages = <PubPackage>[
        _dep('hooks_riverpod', '3.3.1'),
        _dep('flutter_hooks', '0.21.3+1'),
        _dep('dio', '5.9.2'),
        _dep('go_router', '17.2.3'),
      ];

      final identity = IdentityState(
        name: projectName,
        organization: 'com.neat.test',
        projectPath: tempRoot.path,
        description: 'NEAT manual-Riverpod integration test',
        targetPlatforms: const ['macos'],
      );

      const architecture = ArchitectureState(
        firstFeatureName: 'user_profile',
        useRiverpodAnnotations: false,
      );

      try {
        await const LaunchGenerationUsecase().execute(
          identity: identity,
          packages: manualPackages,
          architecture: architecture,
          cicd: const CicdState(),
          theme: const ThemeEngineState(approach: ThemeApproach.customM3),
          onLog: logs.add,
        );
      } catch (e) {
        fail(
          'Manual-Riverpod generation threw:\n$e\n\n--- logs ---\n${logs.join('\n')}',
        );
      }

      final projectDir = Directory('${tempRoot.path}/$projectName');

      // The feature's provider uses the modern Notifier API.
      final provider = File(
        '${projectDir.path}/lib/features/user_profile/presentation/providers/'
        'user_profile_provider.dart',
      ).readAsStringSync();
      expect(
        provider,
        contains('NotifierProvider<UserProfileNotifier, AsyncValue<void>>'),
      );
      expect(
        provider,
        contains(
          'class UserProfileNotifier extends Notifier<AsyncValue<void>>',
        ),
      );
      expect(provider, isNot(contains('StateNotifier')));

      // theme_mode_controller.dart (also manual when annotations are off).
      final themeController = File(
        '${projectDir.path}/lib/core/theme/theme_mode_controller.dart',
      ).readAsStringSync();
      expect(
        themeController,
        contains('NotifierProvider<ThemeModeController, ThemeMode>'),
      );
      expect(
        themeController,
        contains('class ThemeModeController extends Notifier<ThemeMode>'),
      );
      expect(themeController, isNot(contains('StateNotifier')));

      // No riverpod_generator codegen is needed for state itself (no `part` in
      // either file above), but the workspace as a whole still must analyze
      // cleanly end to end.
      final analyze = await Process.run('flutter', [
        'analyze',
        '--no-pub',
      ], workingDirectory: projectDir.path);
      final out = '${analyze.stdout}\n${analyze.stderr}';
      expect(
        RegExp(r'(\d+ issues? found|No issues found)').hasMatch(out),
        isTrue,
        reason: 'flutter analyze did not run as expected:\n$out',
      );
      final errorLines = const LineSplitter()
          .convert(out)
          .where(
            (l) =>
                (l.contains(' error •') || l.contains(' warning •')) &&
                !l.contains('• build/'),
          )
          .toList();
      expect(
        errorLines,
        isEmpty,
        reason:
            'manual-Riverpod workspace analyze reported issues:\n'
            '${errorLines.join('\n')}\n\n$out',
      );
    },
    timeout: const Timeout(Duration(minutes: 12)),
  );

  test('Bloc (useCubit: false): full Bloc with Events/States generated, '
      'flutter_bloc auto-injected, analyzes cleanly', () async {
    const projectName = 'neat_bloc_test';
    final logs = <String>[];

    // 'bloc' alone (not flutter_bloc) — proves the auto-injection safety net.
    final blocPackages = <PubPackage>[
      _dep('bloc', '9.0.1'),
      _dep('dio', '5.9.2'),
      _dep('go_router', '17.2.3'),
    ];

    final identity = IdentityState(
      name: projectName,
      organization: 'com.neat.test',
      projectPath: tempRoot.path,
      description: 'NEAT Bloc integration test',
      targetPlatforms: const ['macos'],
    );

    const architecture = ArchitectureState(firstFeatureName: 'user_profile');

    try {
      await const LaunchGenerationUsecase().execute(
        identity: identity,
        packages: blocPackages,
        architecture: architecture,
        cicd: const CicdState(),
        theme: const ThemeEngineState(approach: ThemeApproach.customM3),
        onLog: logs.add,
      );
    } catch (e) {
      fail('Bloc generation threw:\n$e\n\n--- logs ---\n${logs.join('\n')}');
    }

    final projectDir = Directory('${tempRoot.path}/$projectName');

    // flutter_bloc auto-injected even though only 'bloc' was selected.
    expect(
      File('${projectDir.path}/pubspec.yaml').readAsStringSync(),
      contains('flutter_bloc:'),
    );

    // Full Bloc: bloc/event/state files, not cubit.
    final blocFile = File(
      '${projectDir.path}/lib/features/user_profile/presentation/bloc/user_profile_bloc.dart',
    ).readAsStringSync();
    expect(
      blocFile,
      contains(
        'class UserProfileBloc extends Bloc<UserProfileEvent, UserProfileState>',
      ),
    );
    final eventFile = File(
      '${projectDir.path}/lib/features/user_profile/presentation/bloc/user_profile_event.dart',
    ).readAsStringSync();
    expect(
      eventFile,
      contains('final class UserProfileLoadRequested extends UserProfileEvent'),
    );
    expect(
      Directory(
        '${projectDir.path}/lib/features/user_profile/presentation/cubit',
      ).existsSync(),
      isFalse,
      reason: 'useCubit is off — no cubit/ folder should exist',
    );

    // Theme toggle: BrightnessBloc, not BrightnessCubit.
    final appDart = File('${projectDir.path}/lib/app.dart').readAsStringSync();
    expect(appDart, contains('BrightnessBloc'));
    expect(appDart, isNot(contains('BrightnessCubit')));
    expect(
      File(
        '${projectDir.path}/lib/core/theme/brightness_theme/brightness_bloc.dart',
      ).existsSync(),
      isTrue,
    );

    // .neat.json carries the contract Workshop feature-gen will later read.
    final contract =
        jsonDecode(File('${projectDir.path}/.neat.json').readAsStringSync())
            as Map<String, dynamic>;
    expect(contract['stateManagement'], 'bloc');
    expect(contract['useCubit'], isFalse);

    final analyze = await Process.run('flutter', [
      'analyze',
      '--no-pub',
    ], workingDirectory: projectDir.path);
    final out = '${analyze.stdout}\n${analyze.stderr}';
    expect(
      RegExp(r'(\d+ issues? found|No issues found)').hasMatch(out),
      isTrue,
      reason: 'flutter analyze did not run as expected:\n$out',
    );
    final errorLines = const LineSplitter()
        .convert(out)
        .where(
          (l) =>
              (l.contains(' error •') || l.contains(' warning •')) &&
              !l.contains('• build/'),
        )
        .toList();
    expect(
      errorLines,
      isEmpty,
      reason:
          'Bloc workspace analyze reported issues:\n${errorLines.join('\n')}\n\n$out',
    );
  }, timeout: const Timeout(Duration(minutes: 12)));

  test('Bloc + chopper: chopper_model_converter.dart is generated regardless of '
      'state management (real bug reported from a real generated project — '
      'the repository_impl.dart it wires into is written for every stack, but '
      'the converter file itself used to be gated on hasRiverpod)', () async {
    const projectName = 'neat_bloc_chopper_test';
    final logs = <String>[];

    final blocPackages = <PubPackage>[
      _dep('flutter_bloc', '9.1.1'),
      _dep('chopper', '8.6.0'),
      _dep('go_router', '17.2.3'),
      _dev('chopper_generator', '8.6.2'),
      _dev('build_runner', '2.15.0'),
    ];

    final identity = IdentityState(
      name: projectName,
      organization: 'com.neat.test',
      projectPath: tempRoot.path,
      description: 'NEAT Bloc + chopper integration test',
      targetPlatforms: const ['macos'],
    );

    const architecture = ArchitectureState(firstFeatureName: 'product');

    try {
      await const LaunchGenerationUsecase().execute(
        identity: identity,
        packages: blocPackages,
        architecture: architecture,
        cicd: const CicdState(),
        theme: const ThemeEngineState(approach: ThemeApproach.customM3),
        onLog: logs.add,
      );
    } catch (e) {
      fail(
        'Bloc + chopper generation threw:\n$e\n\n--- logs ---\n${logs.join('\n')}',
      );
    }

    final projectDir = Directory('${tempRoot.path}/$projectName');

    // The file the repository_impl.dart actually imports for
    // unwrapChopperResponse/ModelJsonConverter — must exist regardless of
    // state management, unlike chopper_client_provider.dart (a Riverpod
    // provider, correctly still Riverpod-only since nothing else needs it
    // in Bloc/Cubit stub mode).
    final converter = File(
      '${projectDir.path}/lib/core/network/chopper_model_converter.dart',
    );
    expect(
      converter.existsSync(),
      isTrue,
      reason:
          'repository_impl.dart imports this regardless of state management',
    );
    expect(converter.readAsStringSync(), contains('class ModelJsonConverter'));
    expect(
      File(
        '${projectDir.path}/lib/core/network/chopper_client_provider.dart',
      ).existsSync(),
      isFalse,
      reason:
          'a Riverpod provider — correctly absent when nothing in Bloc/Cubit stub mode consumes it',
    );

    final repoImpl = File(
      '${projectDir.path}/lib/features/product/data/repositories/product_repository_impl.dart',
    ).readAsStringSync();
    expect(repoImpl, contains('unwrapChopperResponse'));

    // NetworkErrorHandler (UseCase.call()'s only catch site) must map
    // ChopperApiException too, in Bloc/Cubit projects just like Riverpod
    // ones — same root cause as the missing converter file above.
    final errorHandler = File(
      '${projectDir.path}/lib/core/network/network_error_handler.dart',
    ).readAsStringSync();
    expect(errorHandler, contains('ChopperApiException'));

    final analyze = await Process.run('flutter', [
      'analyze',
      '--no-pub',
    ], workingDirectory: projectDir.path);
    final out = '${analyze.stdout}\n${analyze.stderr}';
    final errorLines = const LineSplitter()
        .convert(out)
        .where(
          (l) =>
              (l.contains(' error •') || l.contains(' warning •')) &&
              !l.contains('• build/'),
        )
        .toList();
    expect(
      errorLines,
      isEmpty,
      reason:
          'Bloc + chopper workspace analyze reported issues:\n${errorLines.join('\n')}\n\n$out',
    );
  }, timeout: const Timeout(Duration(minutes: 12)));

  test(
    'Cubit (useCubit: true): Cubit (no Events) generated, analyzes cleanly',
    () async {
      const projectName = 'neat_cubit_test';
      final logs = <String>[];

      final cubitPackages = <PubPackage>[
        _dep('flutter_bloc', '9.1.1'),
        _dep('dio', '5.9.2'),
        _dep('go_router', '17.2.3'),
      ];

      final identity = IdentityState(
        name: projectName,
        organization: 'com.neat.test',
        projectPath: tempRoot.path,
        description: 'NEAT Cubit integration test',
        targetPlatforms: const ['macos'],
      );

      const architecture = ArchitectureState(
        firstFeatureName: 'user_profile',
        useCubit: true,
      );

      try {
        await const LaunchGenerationUsecase().execute(
          identity: identity,
          packages: cubitPackages,
          architecture: architecture,
          cicd: const CicdState(),
          theme: const ThemeEngineState(approach: ThemeApproach.customM3),
          onLog: logs.add,
        );
      } catch (e) {
        fail('Cubit generation threw:\n$e\n\n--- logs ---\n${logs.join('\n')}');
      }

      final projectDir = Directory('${tempRoot.path}/$projectName');

      final cubitFile = File(
        '${projectDir.path}/lib/features/user_profile/presentation/cubit/user_profile_cubit.dart',
      ).readAsStringSync();
      expect(
        cubitFile,
        contains('class UserProfileCubit extends Cubit<UserProfileState>'),
      );
      expect(
        Directory(
          '${projectDir.path}/lib/features/user_profile/presentation/bloc',
        ).existsSync(),
        isFalse,
        reason: 'useCubit is on — no bloc/ folder should exist',
      );

      final appDart = File(
        '${projectDir.path}/lib/app.dart',
      ).readAsStringSync();
      expect(appDart, contains('BrightnessCubit'));
      expect(appDart, isNot(contains('BrightnessBloc')));

      final contract =
          jsonDecode(File('${projectDir.path}/.neat.json').readAsStringSync())
              as Map<String, dynamic>;
      expect(contract['stateManagement'], 'bloc');
      expect(contract['useCubit'], isTrue);

      // AGENTS.md correctly names the Cubit path, not Bloc.
      final agentsMd = File('${projectDir.path}/AGENTS.md').readAsStringSync();
      expect(agentsMd, contains('Cubit (no Events)'));

      final analyze = await Process.run('flutter', [
        'analyze',
        '--no-pub',
      ], workingDirectory: projectDir.path);
      final out = '${analyze.stdout}\n${analyze.stderr}';
      expect(
        RegExp(r'(\d+ issues? found|No issues found)').hasMatch(out),
        isTrue,
        reason: 'flutter analyze did not run as expected:\n$out',
      );
      final errorLines = const LineSplitter()
          .convert(out)
          .where(
            (l) =>
                (l.contains(' error •') || l.contains(' warning •')) &&
                !l.contains('• build/'),
          )
          .toList();
      expect(
        errorLines,
        isEmpty,
        reason:
            'Cubit workspace analyze reported issues:\n${errorLines.join('\n')}\n\n$out',
      );
    },
    timeout: const Timeout(Duration(minutes: 12)),
  );

  test('Example feature preset (FakeStore Products): absolute apiPath override '
      'reaches the real API regardless of the project\'s own base URL', () async {
    const projectName = 'neat_gen_example_test';
    final logs = <String>[];

    final identity = IdentityState(
      name: projectName,
      organization: 'com.neat.test',
      projectPath: tempRoot.path,
      description: 'NEAT example-feature integration test',
      targetPlatforms: const ['macos'],
    );

    const architecture = ArchitectureState(
      firstFeatureName: 'product',
      firstFeatureFields: FieldSpec.fakeStoreProduct,
      firstFeatureApiPath: 'https://fakestoreapi.com/products',
    );

    const cicd = CicdState();
    const theme = ThemeEngineState(approach: ThemeApproach.customM3);

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
    expect(
      projectDir.existsSync(),
      isTrue,
      reason: 'project dir was not created',
    );

    // The preset targets fakestoreapi.com directly via an absolute apiPath
    // override — independent of the project's own (placeholder) API Base
    // URL — and drops the legacy `/add` suffix (confirmed against the real
    // API: fakestoreapi.com's create route is `POST /products`, no `/add`).
    final apiSrc = File(
      '${projectDir.path}/lib/features/product/data/sources/product_api_source.dart',
    ).readAsStringSync();
    expect(apiSrc, contains("baseUrl: 'https://fakestoreapi.com/products'"));
    expect(apiSrc, isNot(contains('/add')));

    // The nested `rating` object (Phase 1.5) survives through entity/model.
    // Nullable: fakestoreapi.com's create/update responses omit `rating`
    // entirely (only GET returns it) — a non-nullable field here would
    // crash the create-response JSON decode with a Null-is-not-Map cast.
    final entity = File(
      '${projectDir.path}/lib/features/product/domain/entities/product_entity.dart',
    ).readAsStringSync();
    expect(entity, contains('class ProductEntity'));
    expect(entity, contains('class RatingEntity'));
    expect(entity, contains('RatingEntity? rating'));

    // The simple CRUD-UI sheets (detail+delete, add) are scoped to this
    // preset — see FeatureScaffolder.writeFeature's includeCrudUi doc.
    final page = File(
      '${projectDir.path}/lib/features/product/presentation/pages/product_page.dart',
    ).readAsStringSync();
    expect(page, contains('_ProductDetailSheet'));
    expect(page, contains('_ProductCreateSheet'));
    expect(
      page,
      contains("import '../providers/product_usecase_providers.dart';"),
    );

    // Create/delete mutate the notifier's cached list directly (optimistic)
    // instead of `ref.invalidate` — FakeStore's writes are cosmetic (a
    // POST/DELETE returns 200 but never actually changes what a
    // subsequent GET returns), so invalidating would just re-fetch the
    // unchanged 20 products and make the write look like a no-op.
    final provider = File(
      '${projectDir.path}/lib/features/product/presentation/providers/product_provider.dart',
    ).readAsStringSync();
    expect(provider, contains('void addItem(ProductEntity item)'));
    expect(provider, contains('void removeItem(String id)'));
    expect(
      page,
      contains('ref.read(productProvider.notifier).addItem(created)'),
    );
    expect(
      page,
      contains('ref.read(productProvider.notifier).removeItem(item.id)'),
    );

    // build_runner must have produced generated parts (riverpod/freezed).
    final generatedParts = projectDir
        .listSync(recursive: true)
        .whereType<File>()
        .where(
          (f) => f.path.endsWith('.g.dart') || f.path.endsWith('.freezed.dart'),
        )
        .toList();
    expect(
      generatedParts,
      isNotEmpty,
      reason:
          'build_runner produced no .g.dart/.freezed.dart parts — codegen failed',
    );

    // Executable probe: the generated ApiSource really reaches
    // fakestoreapi.com and decodes real Products, even when the
    // ChopperClient it's handed is configured with a totally different
    // base URL — proving the absolute-URL override actually bypasses
    // Dio/Chopper's configured base (per Request.buildUri: "If [url]
    // starts with 'http://' or 'https://', baseUrl is ignored"), not just
    // that the generated source string looks right.
    await File(
      '${projectDir.path}/test/_example_feature_probe_test.dart',
    ).writeAsString('''
import 'package:chopper/chopper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:$projectName/core/network/chopper_model_converter.dart';
import 'package:$projectName/features/product/data/models/product_model.dart';
import 'package:$projectName/features/product/data/sources/product_api_source.dart';

void main() {
  final client = ChopperClient(
    baseUrl: Uri.parse('https://example.invalid'),
    converter: const ModelJsonConverter(),
  );
  final source = ProductApiSource.create(client);

  test(
    'ProductApiSource.getAll() reaches fakestoreapi.com even with an unrelated ChopperClient base URL',
    () async {
      final response = await source.getAll();
      expect(response.isSuccessful, isTrue, reason: response.error?.toString());
      expect(response.body, isNotNull);
      expect(response.body, isNotEmpty);
      expect(response.body!.first.title, isNotEmpty);
    },
  );

  test(
    'ProductApiSource.add() decodes the real create response, which omits `rating` entirely '
    '(regression: a non-nullable rating crashes fromJson with a Null-is-not-Map cast)',
    () async {
      const model = ProductModel(
        id: '000000',
        title: 'NEAT regression probe',
        price: 1,
        description: 'd',
        category: 'c',
        image: 'i',
        rating: null,
      );
      final response = await source.add(model);
      expect(response.isSuccessful, isTrue, reason: response.error?.toString());
      expect(response.body, isNotNull);
      expect(response.body!.title, 'NEAT regression probe');
      expect(response.body!.rating, isNull);
    },
  );
}
''');
    final probe = await Process.run('flutter', [
      'test',
      'test/_example_feature_probe_test.dart',
    ], workingDirectory: projectDir.path);
    expect(
      probe.exitCode,
      0,
      reason:
          'example-feature apiPath-override probe failed:\n${probe.stdout}\n${probe.stderr}',
    );

    // Executable probe for the optimistic-update fix: ProductNotifier's
    // addItem/removeItem must actually mutate the *cached* list — proving
    // the create/delete sheets don't rely on FakeStore's (fake) writes
    // surviving a refetch. `flutter analyze` can't catch this: the old
    // `ref.invalidate` code also compiled fine, it just silently discarded
    // the change against a non-persisting backend.
    await File(
      '${projectDir.path}/test/_optimistic_update_probe_test.dart',
    ).writeAsString('''
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:$projectName/core/env/app_env.dart';
import 'package:$projectName/core/env/envs/env.dart';
import 'package:$projectName/features/product/domain/entities/product_entity.dart';
import 'package:$projectName/features/product/presentation/providers/product_provider.dart';

void main() {
  test(
    'ProductNotifier.addItem/removeItem mutate the cached list locally, without a server round-trip',
    () async {
      // Providers reach AppEnv.current for the chopper base URL — normally
      // set by bootstrap() in main(), which this probe bypasses.
      AppEnv.setEnv(Env());
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Let the real initial fetch (fakestoreapi.com) complete first.
      await container.read(productProvider.future);

      const fake = ProductEntity(
        id: 'optimistic-test-id',
        title: 'Optimistic test product',
        price: 1,
        description: 'd',
        category: 'c',
        image: 'i',
        rating: RatingEntity(rate: 0, count: 0),
      );

      container.read(productProvider.notifier).addItem(fake);
      var list = container.read(productProvider).requireValue;
      expect(list.any((e) => e.id == 'optimistic-test-id'), isTrue);

      container.read(productProvider.notifier).removeItem('optimistic-test-id');
      list = container.read(productProvider).requireValue;
      expect(list.any((e) => e.id == 'optimistic-test-id'), isFalse);
    },
  );
}
''');
    final optimisticProbe = await Process.run('flutter', [
      'test',
      'test/_optimistic_update_probe_test.dart',
    ], workingDirectory: projectDir.path);
    expect(
      optimisticProbe.exitCode,
      0,
      reason:
          'optimistic-update probe failed:\n${optimisticProbe.stdout}\n${optimisticProbe.stderr}',
    );

    // Run the analyzer on the generated project.
    final analyze = await Process.run('flutter', [
      'analyze',
      '--no-pub',
    ], workingDirectory: projectDir.path);
    final out = '${analyze.stdout}\n${analyze.stderr}';

    expect(
      RegExp(r'(\d+ issues? found|No issues found)').hasMatch(out),
      isTrue,
      reason: 'flutter analyze did not run as expected:\n$out',
    );

    final errorLines = const LineSplitter()
        .convert(out)
        .where(
          (l) =>
              (l.contains(' error •') || l.contains(' warning •')) &&
              !l.contains('• build/'),
        )
        .toList();

    expect(
      errorLines,
      isEmpty,
      reason:
          'flutter analyze reported errors:\n${errorLines.join('\n')}\n\n'
          '--- full analyze output ---\n$out',
    );
  }, timeout: const Timeout(Duration(minutes: 12)));

  test('generateFirstFeature=false (plain go_router): boots to the welcome '
      'placeholder, zero features, analyzes cleanly', () async {
    const projectName = 'neat_gen_nofeature_test';
    final logs = <String>[];
    // Plain go_router (no go_router_builder) — isolates the manual routing
    // welcome-fallback path from the typed one (covered separately below).
    final noBuilderPackages = <PubPackage>[
      _dep('hooks_riverpod', '3.3.1'),
      _dep('flutter_hooks', '0.21.3+1'),
      _dep('riverpod_annotation', '4.0.2'),
      _dep('json_annotation', '4.11.0'),
      _dep('freezed_annotation', '3.1.0'),
      _dep('dio', '5.9.2'),
      _dep('go_router', '17.2.3'),
      _dev('riverpod_generator', '4.0.3'),
      _dev('riverpod_lint', '3.1.3'),
      _dev('json_serializable', '6.13.0'),
      _dev('build_runner', '2.15.0'),
      _dev('freezed', '3.2.5'),
    ];

    final identity = IdentityState(
      name: projectName,
      organization: 'com.neat.test',
      projectPath: tempRoot.path,
      description: 'NEAT no-first-feature integration test',
      targetPlatforms: const ['macos'],
    );

    const architecture = ArchitectureState(generateFirstFeature: false);
    const cicd = CicdState();
    const theme = ThemeEngineState(approach: ThemeApproach.customM3);

    try {
      await const LaunchGenerationUsecase().execute(
        identity: identity,
        packages: noBuilderPackages,
        architecture: architecture,
        cicd: cicd,
        theme: theme,
        onLog: logs.add,
      );
    } catch (e) {
      fail('Generation threw:\n$e\n\n--- logs ---\n${logs.join('\n')}');
    }

    final projectDir = Directory('${tempRoot.path}/$projectName');
    expect(
      projectDir.existsSync(),
      isTrue,
      reason: 'project dir was not created',
    );
    expect(
      Directory('${projectDir.path}/lib/features').existsSync(),
      isFalse,
      reason: 'no first feature was requested — lib/features/ should not exist',
    );

    final routePath = File(
      '${projectDir.path}/lib/core/constants/app_route_path.dart',
    ).readAsStringSync();
    expect(routePath, contains("static const String welcome = '/';"));

    // No first feature → nothing to write a removal guide for.
    expect(
      File('${projectDir.path}/docs/REMOVE_FIRST_FEATURE.md').existsSync(),
      isFalse,
    );

    final router = File(
      '${projectDir.path}/lib/core/router/app_router.dart',
    ).readAsStringSync();
    expect(router, contains('initialLocation: AppRoutePath.welcome'));

    final routes = File(
      '${projectDir.path}/lib/core/router/routes.dart',
    ).readAsStringSync();
    expect(routes, contains('AppRoutePath.welcome'));
    expect(routes, contains('WelcomePage'));

    expect(
      File('${projectDir.path}/lib/core/pages/welcome_page.dart').existsSync(),
      isTrue,
      reason: 'welcome placeholder page missing',
    );

    final analyze = await Process.run('flutter', [
      'analyze',
      '--no-pub',
    ], workingDirectory: projectDir.path);
    final out = '${analyze.stdout}\n${analyze.stderr}';
    expect(
      RegExp(r'(\d+ issues? found|No issues found)').hasMatch(out),
      isTrue,
      reason: 'flutter analyze did not run as expected:\n$out',
    );
    final errorLines = const LineSplitter()
        .convert(out)
        .where(
          (l) =>
              (l.contains(' error •') || l.contains(' warning •')) &&
              !l.contains('• build/'),
        )
        .toList();
    expect(
      errorLines,
      isEmpty,
      reason:
          'flutter analyze reported errors:\n${errorLines.join('\n')}\n\n'
          '--- full analyze output ---\n$out',
    );
  }, timeout: const Timeout(Duration(minutes: 12)));

  test('generateFirstFeature=false (go_router_builder + offline-first): typed '
      'welcome route + a zero-table Drift database analyze cleanly', () async {
    const projectName = 'neat_gen_nofeature_builder_test';
    final logs = <String>[];

    final identity = IdentityState(
      name: projectName,
      organization: 'com.neat.test',
      projectPath: tempRoot.path,
      description: 'NEAT no-first-feature (builder + offline) integration test',
      targetPlatforms: const ['macos'],
    );

    const architecture = ArchitectureState(
      generateFirstFeature: false,
      storageStrategy: StorageStrategy.offlineFirstRead,
    );
    const cicd = CicdState();
    const theme = ThemeEngineState(approach: ThemeApproach.customM3);

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
    expect(
      projectDir.existsSync(),
      isTrue,
      reason: 'project dir was not created',
    );
    expect(Directory('${projectDir.path}/lib/features').existsSync(), isFalse);

    final welcomeRoute = File(
      '${projectDir.path}/lib/core/router/welcome_route.dart',
    ).readAsStringSync();
    expect(
      welcomeRoute,
      contains('@TypedGoRoute<WelcomeRoute>(path: AppRoutePath.welcome)'),
    );

    final routes = File(
      '${projectDir.path}/lib/core/router/routes.dart',
    ).readAsStringSync();
    expect(routes, contains('welcome.\$appRoutes'));

    // The workspace + Drift database still get scaffolded (offline-first
    // was chosen), just with zero tables — the Workshop's existing
    // table-injection anchor adds the first one once a real feature exists.
    // Named exactly, not glob-scanned: ThemeEngineState.extractUiPackage
    // defaults to true, so packages/ also holds a `_ui` package with no
    // lib/src/ of its own — scanning every packages/*/lib/src/ is flaky
    // (filesystem listing order isn't guaranteed).
    final dbContent = File(
      '${projectDir.path}/packages/${projectName}_database/lib/src/database.dart',
    ).readAsStringSync();
    expect(dbContent, contains('tables: ['));
    expect(
      dbContent,
      isNot(contains('Rows,')),
      reason: 'no feature table should exist',
    );

    final analyze = await Process.run('flutter', [
      'analyze',
      '--no-pub',
    ], workingDirectory: projectDir.path);
    final out = '${analyze.stdout}\n${analyze.stderr}';
    expect(
      RegExp(r'(\d+ issues? found|No issues found)').hasMatch(out),
      isTrue,
      reason: 'flutter analyze did not run as expected:\n$out',
    );
    final errorLines = const LineSplitter()
        .convert(out)
        .where(
          (l) =>
              (l.contains(' error •') || l.contains(' warning •')) &&
              !l.contains('• build/'),
        )
        .toList();
    expect(
      errorLines,
      isEmpty,
      reason:
          'flutter analyze reported errors:\n${errorLines.join('\n')}\n\n'
          '--- full analyze output ---\n$out',
    );
  }, timeout: const Timeout(Duration(minutes: 12)));

  test(
    'packageSplit=true + generateFirstFeature=false: the shared core package '
    'still gets created with zero feature packages, and the Workshop can '
    'then add the real first feature as its own split package — the UI\'s '
    'own canPackageSplit requires a first feature, but the generator\'s '
    'packageSplitSupported never checks that, so this combo should already '
    'work end to end; proving it rather than trusting the reasoning',
    () async {
      const projectName = 'neat_gen_pkgsplit_nofeature_test';
      final logs = <String>[];
      final noBuilderPackages = <PubPackage>[
        _dep('hooks_riverpod', '3.3.1'),
        _dep('flutter_hooks', '0.21.3+1'),
        _dep('riverpod_annotation', '4.0.2'),
        _dep('json_annotation', '4.11.0'),
        _dep('freezed_annotation', '3.1.0'),
        _dep('dio', '5.9.2'),
        _dep('go_router', '17.2.3'),
        _dev('riverpod_generator', '4.0.3'),
        _dev('riverpod_lint', '3.1.3'),
        _dev('json_serializable', '6.13.0'),
        _dev('build_runner', '2.15.0'),
        _dev('freezed', '3.2.5'),
      ];

      final identity = IdentityState(
        name: projectName,
        organization: 'com.neat.test',
        projectPath: tempRoot.path,
        description: 'NEAT packageSplit + no-first-feature integration test',
        targetPlatforms: const ['macos'],
      );
      const architecture = ArchitectureState(
        packageSplit: true,
        generateFirstFeature: false,
      );

      try {
        await const LaunchGenerationUsecase().execute(
          identity: identity,
          packages: noBuilderPackages,
          architecture: architecture,
          cicd: const CicdState(),
          theme: const ThemeEngineState(approach: ThemeApproach.customM3),
          onLog: logs.add,
        );
      } catch (e) {
        fail('Generation threw:\n$e\n\n--- logs ---\n${logs.join('\n')}');
      }

      final projectDir = Directory('${tempRoot.path}/$projectName');
      final coreRoot = '${projectDir.path}/packages/core';
      String read(String p) => File(p).readAsStringSync();

      // The shared core package exists — this doesn't depend on a first
      // feature (see _writeCorePackage's own gate: `if (corePackageName !=
      // null)`, computed purely from packageSplitSupported).
      expect(
        Directory(coreRoot).existsSync(),
        isTrue,
        reason: 'packages/core missing',
      );
      expect(read('$coreRoot/pubspec.yaml'), contains('name: core'));
      expect(
        File('$coreRoot/lib/core/error/failure.dart').existsSync(),
        isTrue,
      );
      expect(
        File('$coreRoot/lib/core/usecases/use_case.dart').existsSync(),
        isTrue,
      );

      // No feature package at all — lib/features/ never existed either (the
      // no-first-feature precedent), and packages/ has nothing beyond core.
      expect(
        Directory('${projectDir.path}/lib/features').existsSync(),
        isFalse,
      );
      // core + the extracted UI package (theme.extractUiPackage defaults to
      // true, independent of packageSplit/generateFirstFeature) — but no
      // feature package, since none was requested yet.
      final packageDirs = Directory('${projectDir.path}/packages')
          .listSync()
          .whereType<Directory>()
          .map((d) => d.path.split(Platform.pathSeparator).last)
          .toList();
      expect(packageDirs, containsAll(['core', '${projectName}_ui']));
      expect(
        packageDirs,
        hasLength(2),
        reason: 'no feature package should exist yet',
      );

      // Welcome placeholder, same as the non-split no-first-feature case.
      expect(
        File(
          '${projectDir.path}/lib/core/pages/welcome_page.dart',
        ).existsSync(),
        isTrue,
      );
      final routes = read('${projectDir.path}/lib/core/router/routes.dart');
      expect(routes, contains('WelcomePage'));

      // Root workspace wires only core in — no feature member/path dependency.
      final rootPubspec = read('${projectDir.path}/pubspec.yaml');
      expect(rootPubspec, contains('workspace:'));
      expect(rootPubspec, contains('- packages/core'));
      expect(rootPubspec, contains('core:\n    path: packages/core'));

      // Reload sees packageSplit + zero features — ready for the Workshop.
      final loaded = await const ProjectLoader().load(projectDir.path);
      expect(loaded!.contract.packageSplit, isTrue);
      expect(loaded.features, isEmpty);

      // ── The Workshop adds the *real* first feature ──────────────────────
      // GenerateFeatureUsecase never distinguishes "1st feature" from "5th
      // feature" — every packageSplit feature-add creates its own package
      // the same way, so this should already work without any special-casing.
      await const GenerateFeatureUsecase().execute(
        project: loaded,
        options: const FeatureGenOptions(name: 'home'),
        onLog: logs.add,
      );

      final homeRoot = '${projectDir.path}/packages/home';
      expect(
        Directory(homeRoot).existsSync(),
        isTrue,
        reason: 'packages/home missing',
      );
      expect(read('$homeRoot/pubspec.yaml'), contains('name: home'));
      expect(
        read('$homeRoot/pubspec.yaml'),
        contains('core:\n    path: ../core'),
        reason:
            'the Workshop-added feature depends on core via a sibling path dep',
      );
      expect(
        File('$homeRoot/lib/presentation/pages/home_page.dart').existsSync(),
        isTrue,
      );
      expect(
        read('${projectDir.path}/pubspec.yaml'),
        contains('home:\n    path: packages/home'),
      );
      expect(
        read('${projectDir.path}/lib/core/router/routes.dart'),
        contains("import 'package:home/presentation/pages/home_page.dart';"),
      );

      final reloaded = await const ProjectLoader().load(projectDir.path);
      expect(reloaded!.features, ['home']);

      final analyze = await Process.run('flutter', [
        'analyze',
        '--no-pub',
      ], workingDirectory: projectDir.path);
      final out = '${analyze.stdout}\n${analyze.stderr}';
      final errorLines = const LineSplitter()
          .convert(out)
          .where(
            (l) =>
                (l.contains(' error •') || l.contains(' warning •')) &&
                !l.contains('• build/'),
          )
          .toList();
      expect(
        errorLines,
        isEmpty,
        reason:
            'flutter analyze reported errors:\n${errorLines.join('\n')}\n\n'
            '--- full analyze output ---\n$out',
      );
    },
    timeout: const Timeout(Duration(minutes: 12)),
  );

  test(
    'FeatureGenOptions.setAsHomePage (real bug from a real generated project '
    '— the "welcome" placeholder\'s own doc comment promised removal but '
    'nothing ever delivered it): the Workshop\'s first feature repoints '
    'every AppRoutePath.welcome reference and deletes the placeholder\'s '
    'own files',
    () async {
      const projectName = 'neat_gen_home_page_test';
      final logs = <String>[];

      final identity = IdentityState(
        name: projectName,
        organization: 'com.neat.test',
        projectPath: tempRoot.path,
        description: 'NEAT setAsHomePage integration test',
        targetPlatforms: const ['macos'],
      );
      const architecture = ArchitectureState(generateFirstFeature: false);

      try {
        await const LaunchGenerationUsecase().execute(
          identity: identity,
          packages: packages,
          architecture: architecture,
          cicd: const CicdState(),
          theme: const ThemeEngineState(approach: ThemeApproach.customM3),
          onLog: logs.add,
        );
      } catch (e) {
        fail('Base generation threw:\n$e\n\n--- logs ---\n${logs.join('\n')}');
      }

      final projectDir = Directory('${tempRoot.path}/$projectName');
      String read(String p) => File(p).readAsStringSync();

      // Sanity: the welcome placeholder really is there pre-add, same as
      // the other no-first-feature tests.
      expect(
        File('${projectDir.path}/lib/core/router/welcome_route.dart').existsSync(),
        isTrue,
      );
      expect(
        read('${projectDir.path}/lib/core/router/app_router.dart'),
        contains('AppRoutePath.welcome'),
      );
      expect(
        read('${projectDir.path}/lib/core/constants/app_route_path.dart'),
        contains("static const String welcome = '/';"),
      );

      final loaded = await const ProjectLoader().load(projectDir.path);
      expect(loaded!.features, isEmpty);

      // ── The Workshop adds the real first feature, as the home page ──────
      // setAsHomePage defaults to true, so this alone already exercises it.
      try {
        await const GenerateFeatureUsecase().execute(
          project: loaded,
          options: const FeatureGenOptions(name: 'recipes'),
          onLog: logs.add,
        );
      } catch (e) {
        fail('Feature generation threw:\n$e\n\n--- logs ---\n${logs.join('\n')}');
      }

      // The placeholder's own files are gone.
      expect(
        File('${projectDir.path}/lib/core/router/welcome_route.dart').existsSync(),
        isFalse,
      );
      expect(
        File('${projectDir.path}/lib/core/router/welcome_route.g.dart').existsSync(),
        isFalse,
      );
      expect(
        File('${projectDir.path}/lib/core/pages/welcome_page.dart').existsSync(),
        isFalse,
      );

      // routes.dart: no trace of the placeholder, the new feature wired in.
      final routes = read('${projectDir.path}/lib/core/router/routes.dart');
      expect(routes, isNot(contains('welcome')));
      expect(routes, isNot(contains('Welcome')));
      expect(routes, contains('recipes.\$appRoutes'));

      // app_router.dart: initialLocation (and any redirect target) now
      // points at the new feature, not the placeholder.
      final router = read('${projectDir.path}/lib/core/router/app_router.dart');
      expect(router, isNot(contains('AppRoutePath.welcome')));
      expect(router, contains('AppRoutePath.recipes'));

      // AppRoutePath: the dead constant is gone, the real one is there.
      final routePath = read('${projectDir.path}/lib/core/constants/app_route_path.dart');
      expect(routePath, isNot(contains('welcome')));
      expect(routePath, contains("static const String recipes = '/recipes';"));

      final reloaded = await const ProjectLoader().load(projectDir.path);
      expect(reloaded!.features, ['recipes']);

      final analyze = await Process.run('flutter', [
        'analyze',
        '--no-pub',
      ], workingDirectory: projectDir.path);
      final out = '${analyze.stdout}\n${analyze.stderr}';
      final errorLines = const LineSplitter()
          .convert(out)
          .where(
            (l) =>
                (l.contains(' error •') || l.contains(' warning •')) &&
                !l.contains('• build/'),
          )
          .toList();
      expect(
        errorLines,
        isEmpty,
        reason:
            'flutter analyze reported errors:\n${errorLines.join('\n')}\n\n'
            '--- full analyze output ---\n$out',
      );
    },
    timeout: const Timeout(Duration(minutes: 12)),
  );

  test(
    'FeatureGenOptions.setAsHomePage: false (opt-out) — the welcome '
    'placeholder stays untouched, coexisting with the new feature exactly '
    'like before this option existed',
    () async {
      const projectName = 'neat_gen_home_page_optout_test';
      final logs = <String>[];

      final identity = IdentityState(
        name: projectName,
        organization: 'com.neat.test',
        projectPath: tempRoot.path,
        description: 'NEAT setAsHomePage opt-out integration test',
        targetPlatforms: const ['macos'],
      );
      const architecture = ArchitectureState(generateFirstFeature: false);

      try {
        await const LaunchGenerationUsecase().execute(
          identity: identity,
          packages: packages,
          architecture: architecture,
          cicd: const CicdState(),
          theme: const ThemeEngineState(approach: ThemeApproach.customM3),
          onLog: logs.add,
        );
      } catch (e) {
        fail('Base generation threw:\n$e\n\n--- logs ---\n${logs.join('\n')}');
      }

      final projectDir = Directory('${tempRoot.path}/$projectName');
      final loaded = await const ProjectLoader().load(projectDir.path);

      try {
        await const GenerateFeatureUsecase().execute(
          project: loaded!,
          options: const FeatureGenOptions(name: 'recipes', setAsHomePage: false),
          onLog: logs.add,
        );
      } catch (e) {
        fail('Feature generation threw:\n$e\n\n--- logs ---\n${logs.join('\n')}');
      }

      expect(
        File('${projectDir.path}/lib/core/router/welcome_route.dart').existsSync(),
        isTrue,
        reason: 'opted out — the placeholder must be left alone',
      );
      final routes = File(
        '${projectDir.path}/lib/core/router/routes.dart',
      ).readAsStringSync();
      expect(routes, contains('welcome.\$appRoutes'));
      expect(routes, contains('recipes.\$appRoutes'));
    },
    timeout: const Timeout(Duration(minutes: 12)),
  );

  test(
    'packageSplit=true (Phase 1): shared <app>_core workspace package plus a '
    'split first feature package are generated, wired, and analyze cleanly',
    () async {
      const projectName = 'neat_gen_core_pkg_test';
      final logs = <String>[];
      // Phase 1 combo: dio, plain go_router, remote-only (no Drift — a 3rd
      // package, later — see the "offline-first" combo elsewhere in Phase 2).
      final noBuilderPackages = <PubPackage>[
        _dep('hooks_riverpod', '3.3.1'),
        _dep('flutter_hooks', '0.21.3+1'),
        _dep('riverpod_annotation', '4.0.2'),
        _dep('json_annotation', '4.11.0'),
        _dep('freezed_annotation', '3.1.0'),
        _dep('dio', '5.9.2'),
        _dep('go_router', '17.2.3'),
        _dev('riverpod_generator', '4.0.3'),
        _dev('riverpod_lint', '3.1.3'),
        _dev('json_serializable', '6.13.0'),
        _dev('build_runner', '2.15.0'),
        _dev('freezed', '3.2.5'),
      ];

      final identity = IdentityState(
        name: projectName,
        organization: 'com.neat.test',
        projectPath: tempRoot.path,
        description: 'NEAT packageSplit core-package integration test',
        targetPlatforms: const ['macos'],
      );

      const architecture = ArchitectureState(packageSplit: true);
      const cicd = CicdState();
      const theme = ThemeEngineState(approach: ThemeApproach.customM3);

      try {
        await const LaunchGenerationUsecase().execute(
          identity: identity,
          packages: noBuilderPackages,
          architecture: architecture,
          cicd: cicd,
          theme: theme,
          onLog: logs.add,
        );
      } catch (e) {
        fail('Generation threw:\n$e\n\n--- logs ---\n${logs.join('\n')}');
      }

      final projectDir = Directory('${tempRoot.path}/$projectName');
      final coreRoot = '${projectDir.path}/packages/core';
      String read(String p) => File(p).readAsStringSync();

      final corePubspec = read('$coreRoot/pubspec.yaml');
      expect(corePubspec, contains('name: core'));
      expect(corePubspec, contains('resolution: workspace'));

      final failure = read('$coreRoot/lib/core/error/failure.dart');
      expect(failure, contains('class Failure'));

      final result = read('$coreRoot/lib/core/result/result.dart');
      expect(result, contains('sealed class Result<T>'));
      expect(
        result,
        contains("import 'package:core/core/error/failure.dart';"),
      );

      final useCase = read('$coreRoot/lib/core/usecases/use_case.dart');
      expect(useCase, contains('abstract class UseCase<Params, T>'));
      expect(
        useCase,
        contains(
          "import 'package:core/core/network/network_error_handler.dart';",
        ),
      );

      final errorHandler = read(
        '$coreRoot/lib/core/network/network_error_handler.dart',
      );
      expect(errorHandler, contains('DioException'));
      expect(
        errorHandler,
        isNot(contains('ChopperApiException')),
        reason: 'Phase 1 core package is dio-only',
      );

      // No envied in Phase 1 — the plain (no AppEnv) dioProvider branch.
      final dioProviderFile = read(
        '$coreRoot/lib/core/network/dio_provider.dart',
      );
      expect(dioProviderFile, isNot(contains('AppEnv')));

      final futureExt = read('$coreRoot/lib/core/utils/future_extensions.dart');
      expect(futureExt, contains('void fire() => unawaited(this);'));

      expect(
        File('$coreRoot/lib/core/constants/app_route_path.dart').existsSync(),
        isTrue,
      );

      // ── Split first feature (Step 2a): packages/<app>_home/ ──────────────
      // architecture.generateFirstFeature defaults true, so packageSplit
      // also splits the default first feature ('home') into its own package.
      final featureRoot = '${projectDir.path}/packages/home';

      final featurePubspec = read('$featureRoot/pubspec.yaml');
      expect(featurePubspec, contains('name: home'));
      expect(featurePubspec, contains('resolution: workspace'));
      expect(
        featurePubspec,
        contains('core:\n    path: ../core'),
        reason:
            'the feature package depends on core via a sibling path dep, never on the app',
      );

      // domain/data/presentation live at the package root — no features/home/
      // nesting, since the package root IS the feature.
      expect(
        File('$featureRoot/lib/domain/entities/home_entity.dart').existsSync(),
        isTrue,
      );
      expect(
        File(
          '$featureRoot/lib/domain/repositories/i_home_repository.dart',
        ).existsSync(),
        isTrue,
      );
      expect(
        File('$featureRoot/lib/data/models/home_model.dart').existsSync(),
        isTrue,
      );
      expect(
        File('$featureRoot/lib/presentation/pages/home_page.dart').existsSync(),
        isTrue,
      );

      // The usecase crosses into core, not the app — Result/Failure/UseCase
      // live in the shared package, never duplicated per feature.
      final getUsecase = read(
        '$featureRoot/lib/domain/usecases/get_home_usecase.dart',
      );
      expect(
        getUsecase,
        contains("import 'package:core/core/usecases/use_case.dart';"),
      );
      expect(
        getUsecase,
        isNot(contains('package:$projectName/')),
        reason:
            'a split feature package must never import from the app — that would be a cycle',
      );

      // The list page's Failure/theme toggle also cross into core, for the
      // same single-source-of-truth reason as the usecase above.
      final homePage = read(
        '$featureRoot/lib/presentation/pages/home_page.dart',
      );
      expect(
        homePage,
        contains("import 'package:core/core/error/failure.dart';"),
      );
      expect(
        homePage,
        contains(
          "import 'package:core/core/theme/theme_mode_controller.dart';",
        ),
      );
      expect(homePage, isNot(contains('package:$projectName/')));

      // theme_mode_controller is single-sourced from core (not duplicated in
      // the app) — otherwise the app shell and the feature page's dark-mode
      // toggle would watch two different provider instances.
      expect(
        File(
          '$coreRoot/lib/core/theme/theme_mode_controller.dart',
        ).existsSync(),
        isTrue,
      );
      expect(
        File(
          '${projectDir.path}/lib/core/theme/theme_mode_controller.dart',
        ).existsSync(),
        isFalse,
      );

      // The root app's router crosses into the split feature package to
      // register the route — the one legitimate app→feature-package import.
      final routes = read('${projectDir.path}/lib/core/router/routes.dart');
      expect(
        routes,
        contains("import 'package:home/presentation/pages/home_page.dart';"),
      );

      // Root pubspec wires both packages into the workspace.
      final rootPubspec = read('${projectDir.path}/pubspec.yaml');
      expect(rootPubspec, contains('workspace:'));
      expect(rootPubspec, contains('- packages/core'));
      expect(rootPubspec, contains('- packages/home'));
      expect(rootPubspec, contains('core:\n    path: packages/core'));
      expect(rootPubspec, contains('home:\n    path: packages/home'));

      // The whole workspace (app + core + split feature) analyzes cleanly.
      final analyze = await Process.run('flutter', [
        'analyze',
        '--no-pub',
      ], workingDirectory: projectDir.path);
      final out = '${analyze.stdout}\n${analyze.stderr}';
      expect(
        RegExp(r'(\d+ issues? found|No issues found)').hasMatch(out),
        isTrue,
        reason: 'flutter analyze did not run as expected:\n$out',
      );
      final errorLines = const LineSplitter()
          .convert(out)
          .where(
            (l) =>
                (l.contains(' error •') || l.contains(' warning •')) &&
                !l.contains('• build/'),
          )
          .toList();
      expect(
        errorLines,
        isEmpty,
        reason:
            'flutter analyze reported errors:\n${errorLines.join('\n')}\n\n'
            '--- full analyze output ---\n$out',
      );
    },
    timeout: const Timeout(Duration(minutes: 12)),
  );

  test('packageSplit=true + chopper: the split feature self-registers its decoder '
      'into core\'s registry, and the workspace analyzes cleanly', () async {
    const projectName = 'neat_gen_pkgsplit_chopper_test';
    final logs = <String>[];
    // Same combo as the dio packageSplit test, but chopper instead of dio —
    // chopper's decoder registry (chopperModelDecoders) can't be populated
    // by core importing every feature's Model (that would recreate the
    // very app←feature cycle packageSplit avoids), so the split feature
    // registers itself at runtime instead (see
    // DataTemplates.featureRepositoryProviders/AppTemplates.bootstrap).
    final chopperPackages = <PubPackage>[
      _dep('hooks_riverpod', '3.3.1'),
      _dep('flutter_hooks', '0.21.3+1'),
      _dep('riverpod_annotation', '4.0.2'),
      _dep('json_annotation', '4.11.0'),
      _dep('freezed_annotation', '3.1.0'),
      _dep('chopper', '8.6.0'),
      _dep('go_router', '17.2.3'),
      _dev('riverpod_generator', '4.0.3'),
      _dev('riverpod_lint', '3.1.3'),
      _dev('json_serializable', '6.13.0'),
      _dev('build_runner', '2.15.0'),
      _dev('freezed', '3.2.5'),
      _dev('chopper_generator', '8.6.2'),
    ];

    final identity = IdentityState(
      name: projectName,
      organization: 'com.neat.test',
      projectPath: tempRoot.path,
      description: 'NEAT packageSplit + chopper integration test',
      targetPlatforms: const ['macos'],
    );

    const architecture = ArchitectureState(packageSplit: true);
    const cicd = CicdState();
    const theme = ThemeEngineState(approach: ThemeApproach.customM3);

    try {
      await const LaunchGenerationUsecase().execute(
        identity: identity,
        packages: chopperPackages,
        architecture: architecture,
        cicd: cicd,
        theme: theme,
        onLog: logs.add,
      );
    } catch (e) {
      fail('Generation threw:\n$e\n\n--- logs ---\n${logs.join('\n')}');
    }

    final projectDir = Directory('${tempRoot.path}/$projectName');
    final coreRoot = '${projectDir.path}/packages/core';
    final featureRoot = '${projectDir.path}/packages/home';
    String read(String p) => File(p).readAsStringSync();

    // Core's NetworkErrorHandler matches the actual client (chopper), not
    // a hardcoded dio — this is what widening packageSplitSupported fixed.
    final errorHandler = read(
      '$coreRoot/lib/core/network/network_error_handler.dart',
    );
    expect(errorHandler, contains('ChopperApiException'));

    // Core ships chopper's client + a witness-free decoder registry —
    // never dio_provider.dart (this project has no dio dependency at all).
    expect(
      File(
        '$coreRoot/lib/core/network/chopper_client_provider.dart',
      ).existsSync(),
      isTrue,
    );
    expect(
      File('$coreRoot/lib/core/network/dio_provider.dart').existsSync(),
      isFalse,
    );
    final coreConverter = read(
      '$coreRoot/lib/core/network/chopper_model_converter.dart',
    );
    expect(
      coreConverter,
      contains('final Map<Type, JsonDecoder> chopperModelDecoders = {'),
    );
    expect(
      coreConverter,
      isNot(contains('HomeModel')),
      reason:
          'core cannot import a feature package\'s Model — the registry starts empty, '
          'populated at runtime by each split feature registering itself',
    );

    final corePubspec = read('$coreRoot/pubspec.yaml');
    expect(corePubspec, contains('chopper: ^8.6.0'));
    expect(corePubspec, isNot(contains('dio:')));

    // The feature package depends on chopper (+ its generator) and core.
    final featurePubspec = read('$featureRoot/pubspec.yaml');
    expect(featurePubspec, contains('chopper: ^8.6.0'));
    expect(featurePubspec, contains('chopper_generator: ^8.6.2'));
    expect(featurePubspec, contains('core:\n    path: ../core'));

    // The feature registers its own decoder — imports core's registry +
    // its own Model, never the app.
    final repoProviders = read(
      '$featureRoot/lib/data/repositories/home_repository_providers.dart',
    );
    expect(repoProviders, contains('void registerHomeChopperDecoders() {'));
    expect(
      repoProviders,
      contains('chopperModelDecoders[HomeModel] = HomeModel.fromJson;'),
    );
    expect(
      repoProviders,
      contains(
        "import 'package:core/core/network/chopper_model_converter.dart';",
      ),
    );
    expect(
      repoProviders,
      contains(
        "import 'package:core/core/network/chopper_client_provider.dart';",
      ),
    );
    expect(
      repoProviders,
      isNot(contains('package:$projectName/')),
      reason:
          'a split feature package must never import from the app — that would be a cycle',
    );

    // The app calls the registration before runApp — and its own local
    // chopper_model_converter.dart copy (unused dead code once split, same
    // fate as dio_provider.dart's app-local copy in Phase 1) stays witness-
    // free too, since the witness feature's Model no longer lives at the
    // app-relative path this template assumes.
    final bootstrap = read('${projectDir.path}/lib/core/bootstrap.dart');
    expect(
      bootstrap,
      contains(
        "import 'package:home/data/repositories/home_repository_providers.dart';",
      ),
    );
    expect(bootstrap, contains('registerHomeChopperDecoders();'));
    expect(bootstrap, contains('// neat:chopper-register-calls'));
    // The app no longer writes its own chopper_model_converter.dart/
    // chopper_client_provider.dart/dio_provider.dart at all when split —
    // nothing in the app reads them (features import core's copies
    // instead), so they'd just be dead code (see ROADMAP.md §6a's "clean
    // up the duplicated core/" note).
    expect(
      File(
        '${projectDir.path}/lib/core/network/chopper_model_converter.dart',
      ).existsSync(),
      isFalse,
    );

    // Root pubspec wires both packages into the workspace.
    final chopperRootPubspec = read('${projectDir.path}/pubspec.yaml');
    expect(chopperRootPubspec, contains('- packages/core'));
    expect(chopperRootPubspec, contains('- packages/home'));

    // The whole workspace (app + core + split feature) analyzes cleanly.
    final chopperAnalyze = await Process.run('flutter', [
      'analyze',
      '--no-pub',
    ], workingDirectory: projectDir.path);
    final chopperOut = '${chopperAnalyze.stdout}\n${chopperAnalyze.stderr}';
    expect(
      RegExp(r'(\d+ issues? found|No issues found)').hasMatch(chopperOut),
      isTrue,
      reason: 'flutter analyze did not run as expected:\n$chopperOut',
    );
    final chopperErrorLines = const LineSplitter()
        .convert(chopperOut)
        .where(
          (l) =>
              (l.contains(' error •') || l.contains(' warning •')) &&
              !l.contains('• build/'),
        )
        .toList();
    expect(
      chopperErrorLines,
      isEmpty,
      reason:
          'flutter analyze reported errors:\n${chopperErrorLines.join('\n')}\n\n'
          '--- full analyze output ---\n$chopperOut',
    );
  }, timeout: const Timeout(Duration(minutes: 12)));

  test('packageSplit=true + chopper + envied: the core package bridges '
      'AppEnv.apiBaseUrl via ApiConfig (real bug: core cannot import AppEnv '
      'itself), and the workspace analyzes cleanly', () async {
    const projectName = 'neat_gen_pkgsplit_chopper_envied_test';
    final logs = <String>[];
    // Same combo as the plain packageSplit+chopper test, plus envied — the
    // combo that actually exercises the core package's client provider,
    // which used to hardcode useEnvied: false unconditionally (found via a
    // real project: every split feature's remote call hit an empty
    // baseUrl, "Invalid argument(s): No host specified in URI ...").
    final packages = <PubPackage>[
      _dep('hooks_riverpod', '3.3.1'),
      _dep('flutter_hooks', '0.21.3+1'),
      _dep('riverpod_annotation', '4.0.2'),
      _dep('json_annotation', '4.11.0'),
      _dep('freezed_annotation', '3.1.0'),
      _dep('chopper', '8.6.0'),
      _dep('go_router', '17.2.3'),
      _dep('envied', '1.3.5'),
      _dev('riverpod_generator', '4.0.3'),
      _dev('envied_generator', '1.3.5'),
      _dev('riverpod_lint', '3.1.3'),
      _dev('json_serializable', '6.13.0'),
      _dev('build_runner', '2.15.0'),
      _dev('freezed', '3.2.5'),
      _dev('chopper_generator', '8.6.2'),
    ];

    final identity = IdentityState(
      name: projectName,
      organization: 'com.neat.test',
      projectPath: tempRoot.path,
      description: 'NEAT packageSplit + chopper + envied integration test',
      targetPlatforms: const ['macos'],
    );

    const architecture = ArchitectureState(packageSplit: true);
    const cicd = CicdState();
    const theme = ThemeEngineState(approach: ThemeApproach.customM3);

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
    final coreRoot = '${projectDir.path}/packages/core';
    String read(String p) => File(p).readAsStringSync();

    // Core ships the ApiConfig bridge, and its chopper client reads it
    // instead of trying (and failing) to import AppEnv.
    final apiConfig = read('$coreRoot/lib/core/network/api_config.dart');
    expect(apiConfig, contains('class ApiConfig'));
    expect(apiConfig, contains("static String baseUrl = '';"));

    final chopperClientProvider = read(
      '$coreRoot/lib/core/network/chopper_client_provider.dart',
    );
    expect(
      chopperClientProvider,
      contains('baseUrl: Uri.parse(ApiConfig.baseUrl)'),
    );
    expect(
      chopperClientProvider,
      contains("import 'package:core/core/network/api_config.dart';"),
    );
    expect(
      chopperClientProvider,
      isNot(contains('AppEnv')),
      reason:
          'core cannot import the app\'s AppEnv — that would recreate the cycle '
          'packageSplit exists to avoid',
    );

    // bootstrap.dart bridges env.apiBaseUrl into core's ApiConfig once,
    // before runApp — the same "set a static value from the composition
    // root" shape AppEnv.setEnv(env) itself already uses.
    final bootstrap = read('${projectDir.path}/lib/core/bootstrap.dart');
    expect(
      bootstrap,
      contains("import 'package:core/core/network/api_config.dart';"),
    );
    expect(bootstrap, contains('ApiConfig.baseUrl = env.apiBaseUrl;'));

    // The whole workspace (app + core + split feature) analyzes cleanly.
    final analyze = await Process.run('flutter', [
      'analyze',
      '--no-pub',
    ], workingDirectory: projectDir.path);
    final out = '${analyze.stdout}\n${analyze.stderr}';
    expect(
      RegExp(r'(\d+ issues? found|No issues found)').hasMatch(out),
      isTrue,
      reason: 'flutter analyze did not run as expected:\n$out',
    );
    final errorLines = const LineSplitter()
        .convert(out)
        .where(
          (l) =>
              (l.contains(' error •') || l.contains(' warning •')) &&
              !l.contains('• build/'),
        )
        .toList();
    expect(
      errorLines,
      isEmpty,
      reason:
          'flutter analyze reported errors:\n${errorLines.join('\n')}\n\n'
          '--- full analyze output ---\n$out',
    );
  }, timeout: const Timeout(Duration(minutes: 12)));

  test(
    'packageSplit=true + go_router_builder: the split feature\'s typed routes '
    'cross into core for AppRoutePath, and the workspace analyzes cleanly',
    () async {
      const projectName = 'neat_gen_pkgsplit_builder_test';
      final logs = <String>[];
      // Same Phase 1-ish combo as the manual packageSplit test, but
      // go_router_builder instead of plain go_router — routesAggregator()/
      // featureRoutes() needed the same package-aware redirect as
      // routesManual()/featureRoute() got in Step 2a.
      final builderPackages = <PubPackage>[
        _dep('hooks_riverpod', '3.3.1'),
        _dep('flutter_hooks', '0.21.3+1'),
        _dep('riverpod_annotation', '4.0.2'),
        _dep('json_annotation', '4.11.0'),
        _dep('freezed_annotation', '3.1.0'),
        _dep('dio', '5.9.2'),
        _dep('go_router', '17.2.3'),
        _dev('go_router_builder', '4.3.0'),
        _dev('riverpod_generator', '4.0.3'),
        _dev('riverpod_lint', '3.1.3'),
        _dev('json_serializable', '6.13.0'),
        _dev('build_runner', '2.15.0'),
        _dev('freezed', '3.2.5'),
      ];

      final identity = IdentityState(
        name: projectName,
        organization: 'com.neat.test',
        projectPath: tempRoot.path,
        description: 'NEAT packageSplit + go_router_builder integration test',
        targetPlatforms: const ['macos'],
      );

      const architecture = ArchitectureState(packageSplit: true);
      const cicd = CicdState();
      const theme = ThemeEngineState(approach: ThemeApproach.customM3);

      try {
        await const LaunchGenerationUsecase().execute(
          identity: identity,
          packages: builderPackages,
          architecture: architecture,
          cicd: cicd,
          theme: theme,
          onLog: logs.add,
        );
      } catch (e) {
        fail('Generation threw:\n$e\n\n--- logs ---\n${logs.join('\n')}');
      }

      final projectDir = Directory('${tempRoot.path}/$projectName');
      final coreRoot = '${projectDir.path}/packages/core';
      final featureRoot = '${projectDir.path}/packages/home';
      String read(String p) => File(p).readAsStringSync();

      // The feature package's typed route class crosses into core for
      // AppRoutePath (the one legitimate boundary crossing — the app's own
      // copy would be the forbidden feature→app cycle), and stays relative
      // for its own page (same package).
      final featureRoutes = read(
        '$featureRoot/lib/presentation/routes/home_routes.dart',
      );
      expect(
        featureRoutes,
        contains("import 'package:core/core/constants/app_route_path.dart';"),
      );
      expect(featureRoutes, contains("import '../pages/home_page.dart';"));
      expect(featureRoutes, contains('@TypedGoRoute<HomeRoute>'));
      expect(
        featureRoutes,
        isNot(contains('package:$projectName/')),
        reason:
            'a split feature package must never import from the app — that would be a cycle',
      );

      // The app's routes aggregator crosses into the split feature package
      // for the typed routes file — the one legitimate app→feature import.
      final routes = read('${projectDir.path}/lib/core/router/routes.dart');
      expect(
        routes,
        contains(
          "import 'package:home/presentation/routes/home_routes.dart' as home;",
        ),
      );

      // go_router_builder's codegen ran in the feature package's own
      // build_runner pass (same as freezed/riverpod_generator already do).
      expect(
        File(
          '$featureRoot/lib/presentation/routes/home_routes.g.dart',
        ).existsSync(),
        isTrue,
        reason:
            'go_router_builder codegen did not run for the split feature package',
      );
      final featurePubspec = read('$featureRoot/pubspec.yaml');
      expect(featurePubspec, contains('go_router_builder: ^4.3.0'));

      // Core still ships its own AppRoutePath copy (written unconditionally
      // by _writeCorePackage), independent of the routing style.
      expect(
        File('$coreRoot/lib/core/constants/app_route_path.dart').existsSync(),
        isTrue,
      );

      final analyze = await Process.run('flutter', [
        'analyze',
        '--no-pub',
      ], workingDirectory: projectDir.path);
      final out = '${analyze.stdout}\n${analyze.stderr}';
      expect(
        RegExp(r'(\d+ issues? found|No issues found)').hasMatch(out),
        isTrue,
        reason: 'flutter analyze did not run as expected:\n$out',
      );
      final errorLines = const LineSplitter()
          .convert(out)
          .where(
            (l) =>
                (l.contains(' error •') || l.contains(' warning •')) &&
                !l.contains('• build/'),
          )
          .toList();
      expect(
        errorLines,
        isEmpty,
        reason:
            'flutter analyze reported errors:\n${errorLines.join('\n')}\n\n'
            '--- full analyze output ---\n$out',
      );
    },
    timeout: const Timeout(Duration(minutes: 12)),
  );

  test('packageSplit=true + go_router_builder + child route (§6a Phase 3): the '
      'Workshop adds a feature nested under an existing split feature — a '
      'genuine cross-feature-package dependency (parent package -> child '
      'package), previously rejected outright, now wired with a path: '
      'dependency + the parent package\'s own build_runner re-run', () async {
    const projectName = 'neat_pkgsplit_childroute_builder_test';
    final logs = <String>[];
    final builderPackages = <PubPackage>[
      _dep('hooks_riverpod', '3.3.1'),
      _dep('flutter_hooks', '0.21.3+1'),
      _dep('riverpod_annotation', '4.0.2'),
      _dep('json_annotation', '4.11.0'),
      _dep('freezed_annotation', '3.1.0'),
      _dep('dio', '5.9.2'),
      _dep('go_router', '17.2.3'),
      _dev('go_router_builder', '4.3.0'),
      _dev('riverpod_generator', '4.0.3'),
      _dev('riverpod_lint', '3.1.3'),
      _dev('json_serializable', '6.13.0'),
      _dev('build_runner', '2.15.0'),
      _dev('freezed', '3.2.5'),
    ];

    final identity = IdentityState(
      name: projectName,
      organization: 'com.neat.test',
      projectPath: tempRoot.path,
      description:
          'NEAT packageSplit + go_router_builder + child route integration test',
      targetPlatforms: const ['macos'],
    );
    const architecture = ArchitectureState(packageSplit: true); // splits 'home'

    try {
      await const LaunchGenerationUsecase().execute(
        identity: identity,
        packages: builderPackages,
        architecture: architecture,
        cicd: const CicdState(),
        theme: const ThemeEngineState(approach: ThemeApproach.customM3),
        onLog: logs.add,
      );
    } catch (e) {
      fail('Base generation threw:\n$e\n\n--- logs ---\n${logs.join('\n')}');
    }

    final projectDir = Directory('${tempRoot.path}/$projectName');
    final project = await const ProjectLoader().load(projectDir.path);
    expect(project!.contract.packageSplit, isTrue);

    // Add "reviews" as a child of "home" — the case that used to throw.
    await const GenerateFeatureUsecase().execute(
      project: project,
      options: const FeatureGenOptions(
        name: 'reviews',
        routing: FeatureRouting.child,
        parentFeature: 'home',
      ),
      onLog: logs.add,
    );

    String read(String p) => File(p).readAsStringSync();
    final homeRoot = '${projectDir.path}/packages/home';
    final reviewsRoot = '${projectDir.path}/packages/reviews';

    // The parent package's own routes file crosses into the child package
    // directly — the one legitimate feature-to-feature import (a one-way
    // edge matching the nesting the user explicitly asked for).
    final parentRoutes = read(
      '$homeRoot/lib/presentation/routes/home_routes.dart',
    );
    expect(
      parentRoutes,
      contains(
        "import 'package:reviews/presentation/pages/reviews_page.dart';",
      ),
    );
    expect(
      parentRoutes,
      contains("TypedGoRoute<ReviewsRoute>(path: 'reviews')"),
    );
    expect(
      parentRoutes,
      contains(r'class ReviewsRoute extends GoRouteData with $ReviewsRoute'),
    );

    // The parent package's pubspec declares the new path: dependency.
    final parentPubspec = read('$homeRoot/pubspec.yaml');
    expect(parentPubspec, contains('reviews:\n    path: ../reviews'));

    // The parent package's own build_runner pass re-ran: $ReviewsRoute
    // (the mixin the nested class needs) must exist in the regenerated file.
    expect(
      read('$homeRoot/lib/presentation/routes/home_routes.g.dart'),
      contains(r'mixin $ReviewsRoute'),
    );

    // AppRoutePath gained the nested '/home/reviews' constant. Single-sourced
    // in core (packageSplit) — the app keeps no copy of its own at all.
    expect(
      File(
        '${projectDir.path}/lib/core/constants/app_route_path.dart',
      ).existsSync(),
      isFalse,
    );
    expect(
      read(
        '${projectDir.path}/packages/core/lib/core/constants/app_route_path.dart',
      ),
      contains("static const String reviews = '/home/reviews';"),
    );

    // The child package itself is a normal split feature otherwise.
    expect(
      File(
        '$reviewsRoot/lib/presentation/pages/reviews_page.dart',
      ).existsSync(),
      isTrue,
    );

    // The whole (now 4-package) workspace analyzes cleanly.
    final analyze = await Process.run('flutter', [
      'analyze',
      '--no-pub',
    ], workingDirectory: projectDir.path);
    final out = '${analyze.stdout}\n${analyze.stderr}';
    expect(
      RegExp(r'(\d+ issues? found|No issues found)').hasMatch(out),
      isTrue,
      reason: 'flutter analyze did not run as expected:\n$out',
    );
    final errorLines = const LineSplitter()
        .convert(out)
        .where(
          (l) =>
              (l.contains(' error •') || l.contains(' warning •')) &&
              !l.contains('• build/'),
        )
        .toList();
    expect(
      errorLines,
      isEmpty,
      reason:
          'flutter analyze reported errors:\n${errorLines.join('\n')}\n\n'
          '--- full analyze output ---\n$out',
    );
  }, timeout: const Timeout(Duration(minutes: 12)));

  test('packageSplit=true + go_router_builder + chopper + child route + '
      'mergeIntoParent: the new feature gets its own entity/repository/'
      'datasource but nests them under a reviews/ subfolder inside the '
      'parent\'s own package instead of a separate one — no new package, '
      'workspace member, or path: dependency, and the parent\'s routes file '
      'imports the child page with a plain relative import (same package '
      'now) — chopper specifically, since its own decoder registration (real '
      'bug: crashed on a null featurePackageName! when merged) needs it', () async {
    const projectName = 'neat_pkgsplit_childroute_merge_test';
    final logs = <String>[];
    // chopper, not dio (mirrors the "packageSplit + chopper" test above) —
    // exercises the decoder-registration path this test is really about.
    final builderPackages = <PubPackage>[
      _dep('hooks_riverpod', '3.3.1'),
      _dep('flutter_hooks', '0.21.3+1'),
      _dep('riverpod_annotation', '4.0.2'),
      _dep('json_annotation', '4.11.0'),
      _dep('freezed_annotation', '3.1.0'),
      _dep('chopper', '8.6.0'),
      _dep('go_router', '17.2.3'),
      _dev('go_router_builder', '4.3.0'),
      _dev('riverpod_generator', '4.0.3'),
      _dev('riverpod_lint', '3.1.3'),
      _dev('json_serializable', '6.13.0'),
      _dev('build_runner', '2.15.0'),
      _dev('freezed', '3.2.5'),
      _dev('chopper_generator', '8.6.2'),
    ];

    final identity = IdentityState(
      name: projectName,
      organization: 'com.neat.test',
      projectPath: tempRoot.path,
      description:
          'NEAT packageSplit + go_router_builder + mergeIntoParent integration test',
      targetPlatforms: const ['macos'],
    );
    const architecture = ArchitectureState(packageSplit: true); // splits 'home'

    try {
      await const LaunchGenerationUsecase().execute(
        identity: identity,
        packages: builderPackages,
        architecture: architecture,
        cicd: const CicdState(),
        theme: const ThemeEngineState(approach: ThemeApproach.customM3),
        onLog: logs.add,
      );
    } catch (e) {
      fail('Base generation threw:\n$e\n\n--- logs ---\n${logs.join('\n')}');
    }

    final projectDir = Directory('${tempRoot.path}/$projectName');
    final project = await const ProjectLoader().load(projectDir.path);
    expect(project!.contract.packageSplit, isTrue);

    // Add "reviews" as a child of "home", merged into home's own package.
    await const GenerateFeatureUsecase().execute(
      project: project,
      options: const FeatureGenOptions(
        name: 'reviews',
        routing: FeatureRouting.child,
        parentFeature: 'home',
        mergeIntoParent: true,
      ),
      onLog: logs.add,
    );

    String read(String p) => File(p).readAsStringSync();
    final homeRoot = '${projectDir.path}/packages/home';

    // No separate 'reviews' package was created at all.
    expect(
      Directory('${projectDir.path}/packages/reviews').existsSync(),
      isFalse,
    );

    // Own entity/repository/datasource, nested under a reviews/ subfolder
    // per layer inside home's own package.
    expect(
      File(
        '$homeRoot/lib/domain/reviews/entities/reviews_entity.dart',
      ).existsSync(),
      isTrue,
    );
    expect(
      File(
        '$homeRoot/lib/domain/reviews/repositories/i_reviews_repository.dart',
      ).existsSync(),
      isTrue,
    );
    expect(
      File(
        '$homeRoot/lib/data/reviews/repositories/reviews_repository_impl.dart',
      ).existsSync(),
      isTrue,
    );
    expect(
      File(
        '$homeRoot/lib/presentation/reviews/pages/reviews_page.dart',
      ).existsSync(),
      isTrue,
    );
    // home's own (pre-existing) files are untouched, still at the
    // non-nested location.
    expect(
      File('$homeRoot/lib/domain/entities/home_entity.dart').existsSync(),
      isTrue,
    );

    // The parent package's own routes file gains a plain relative import —
    // no cross-package dependency was introduced by merging.
    final parentRoutes = read(
      '$homeRoot/lib/presentation/routes/home_routes.dart',
    );
    expect(
      parentRoutes,
      contains("import '../reviews/pages/reviews_page.dart';"),
    );
    expect(parentRoutes, isNot(contains('package:reviews')));
    expect(
      parentRoutes,
      contains("TypedGoRoute<ReviewsRoute>(path: 'reviews')"),
    );

    // No new path: dependency and no new workspace member.
    expect(read('$homeRoot/pubspec.yaml'), isNot(contains('reviews:')));
    expect(
      read('${projectDir.path}/pubspec.yaml'),
      isNot(contains('packages/reviews')),
    );

    // AppRoutePath still gains the nested '/home/reviews' constant, single
    // -sourced in core exactly as for a non-merged child.
    expect(
      read(
        '${projectDir.path}/packages/core/lib/core/constants/app_route_path.dart',
      ),
      contains("static const String reviews = '/home/reviews';"),
    );

    // Chopper decoder registration: bootstrap.dart imports the merged
    // child's repository providers from *home's* package, nested under
    // data/reviews/ — not a (nonexistent) 'reviews' package (real bug:
    // this used to crash on featurePackageName! being null when merged).
    final bootstrap = read('${projectDir.path}/lib/core/bootstrap.dart');
    expect(
      bootstrap,
      contains(
        "import 'package:home/data/reviews/repositories/reviews_repository_providers.dart';",
      ),
    );
    expect(bootstrap, contains('registerReviewsChopperDecoders();'));

    // The workspace still analyzes cleanly (no 4th package this time).
    final analyze = await Process.run('flutter', [
      'analyze',
      '--no-pub',
    ], workingDirectory: projectDir.path);
    final out = '${analyze.stdout}\n${analyze.stderr}';
    expect(
      RegExp(r'(\d+ issues? found|No issues found)').hasMatch(out),
      isTrue,
      reason: 'flutter analyze did not run as expected:\n$out',
    );
    final errorLines = const LineSplitter()
        .convert(out)
        .where(
          (l) =>
              (l.contains(' error •') || l.contains(' warning •')) &&
              !l.contains('• build/'),
        )
        .toList();
    expect(
      errorLines,
      isEmpty,
      reason:
          'flutter analyze reported errors:\n${errorLines.join('\n')}\n\n'
          '--- full analyze output ---\n$out',
    );
  }, timeout: const Timeout(Duration(minutes: 12)));

  test('non-split (feature-first) + plain go_router + child route + '
      'mergeIntoParent: the new feature nests under the parent\'s own '
      'lib/features/<parent>/ tree (own entity/repository/datasource, in a '
      'reviews/ subfolder per layer) instead of getting its own '
      'lib/features/reviews/ — the app\'s shared routes.dart import points at '
      'the new nested location', () async {
    const projectName = 'neat_gen_childroute_merge_nonsplit_test';
    final logs = <String>[];
    // Plain go_router (no go_router_builder), dio, no chopper — same combo
    // as the Phase 1 packageSplit core-package test's noBuilderPackages.
    final plainPackages = <PubPackage>[
      _dep('hooks_riverpod', '3.3.1'),
      _dep('flutter_hooks', '0.21.3+1'),
      _dep('riverpod_annotation', '4.0.2'),
      _dep('json_annotation', '4.11.0'),
      _dep('freezed_annotation', '3.1.0'),
      _dep('dio', '5.9.2'),
      _dep('go_router', '17.2.3'),
      _dev('riverpod_generator', '4.0.3'),
      _dev('riverpod_lint', '3.1.3'),
      _dev('json_serializable', '6.13.0'),
      _dev('build_runner', '2.15.0'),
      _dev('freezed', '3.2.5'),
    ];

    final identity = IdentityState(
      name: projectName,
      organization: 'com.neat.test',
      projectPath: tempRoot.path,
      description: 'NEAT non-split + mergeIntoParent integration test',
      targetPlatforms: const ['macos'],
    );
    const architecture =
        ArchitectureState(); // non-split, feature-first, plain go_router

    try {
      await const LaunchGenerationUsecase().execute(
        identity: identity,
        packages: plainPackages,
        architecture: architecture,
        cicd: const CicdState(),
        theme: const ThemeEngineState(approach: ThemeApproach.customM3),
        onLog: logs.add,
      );
    } catch (e) {
      fail('Base generation threw:\n$e\n\n--- logs ---\n${logs.join('\n')}');
    }

    final projectDir = Directory('${tempRoot.path}/$projectName');
    final project = await const ProjectLoader().load(projectDir.path);
    expect(project!.contract.packageSplit, isFalse);

    // Add "reviews" as a child of "home", merged into home's own tree.
    await const GenerateFeatureUsecase().execute(
      project: project,
      options: const FeatureGenOptions(
        name: 'reviews',
        routing: FeatureRouting.child,
        parentFeature: 'home',
        mergeIntoParent: true,
      ),
      onLog: logs.add,
    );

    String read(String p) => File(p).readAsStringSync();
    final homeRoot = '${projectDir.path}/lib/features/home';

    // No separate lib/features/reviews/ was created at all.
    expect(
      Directory('${projectDir.path}/lib/features/reviews').existsSync(),
      isFalse,
    );

    // Own entity/repository/datasource, nested under a reviews/ subfolder
    // per layer inside home's own feature-first tree.
    expect(
      File(
        '$homeRoot/domain/reviews/entities/reviews_entity.dart',
      ).existsSync(),
      isTrue,
    );
    expect(
      File(
        '$homeRoot/data/reviews/repositories/reviews_repository_impl.dart',
      ).existsSync(),
      isTrue,
    );
    expect(
      File(
        '$homeRoot/presentation/reviews/pages/reviews_page.dart',
      ).existsSync(),
      isTrue,
    );
    // home's own (pre-existing) files are untouched.
    expect(
      File('$homeRoot/domain/entities/home_entity.dart').existsSync(),
      isTrue,
    );

    // The app's shared routes.dart nests the child under home's GoRoute,
    // importing straight into the new merged location (a package: import —
    // routes.dart lives in a different folder than the parent's own tree).
    final routes = read('${projectDir.path}/lib/core/router/routes.dart');
    expect(
      routes,
      contains(
        "import 'package:$projectName/features/home/presentation/reviews/pages/reviews_page.dart';",
      ),
    );
    expect(routes, contains("path: 'reviews',"));
    expect(routes, contains('// neat:children:home'));

    // AppRoutePath gains the nested '/home/reviews' constant, exactly as
    // for a non-merged child (single app-level copy, no packageSplit here).
    expect(
      read('${projectDir.path}/lib/core/constants/app_route_path.dart'),
      contains("static const String reviews = '/home/reviews';"),
    );

    final analyze = await Process.run('flutter', [
      'analyze',
      '--no-pub',
    ], workingDirectory: projectDir.path);
    final out = '${analyze.stdout}\n${analyze.stderr}';
    expect(
      RegExp(r'(\d+ issues? found|No issues found)').hasMatch(out),
      isTrue,
      reason: 'flutter analyze did not run as expected:\n$out',
    );
    final errorLines = const LineSplitter()
        .convert(out)
        .where(
          (l) =>
              (l.contains(' error •') || l.contains(' warning •')) &&
              !l.contains('• build/'),
        )
        .toList();
    expect(
      errorLines,
      isEmpty,
      reason:
          'flutter analyze reported errors:\n${errorLines.join('\n')}\n\n'
          '--- full analyze output ---\n$out',
    );
  }, timeout: const Timeout(Duration(minutes: 12)));

  test('packageSplit=true + go_router_builder + shell branches + a nested child '
      '(§7): the app never imports a branch/child page directly — every '
      'shell-owned page routes through core\'s shell page registry instead — '
      'and a child can be nested under a shell branch at all (real bug: the '
      'old child-route wiring silently no-op\'d for a shell-branch parent)', () async {
    const projectName = 'neat_pkgsplit_shell_registry_test';
    final logs = <String>[];
    final builderPackages = <PubPackage>[
      _dep('hooks_riverpod', '3.3.1'),
      _dep('flutter_hooks', '0.21.3+1'),
      _dep('riverpod_annotation', '4.0.2'),
      _dep('json_annotation', '4.11.0'),
      _dep('freezed_annotation', '3.1.0'),
      _dep('dio', '5.9.2'),
      _dep('go_router', '17.2.3'),
      _dev('go_router_builder', '4.3.0'),
      _dev('riverpod_generator', '4.0.3'),
      _dev('riverpod_lint', '3.1.3'),
      _dev('json_serializable', '6.13.0'),
      _dev('build_runner', '2.15.0'),
      _dev('freezed', '3.2.5'),
    ];

    final identity = IdentityState(
      name: projectName,
      organization: 'com.neat.test',
      projectPath: tempRoot.path,
      description: 'NEAT packageSplit + shell page registry integration test',
      targetPlatforms: const ['macos'],
    );
    // packageSplit + shell: the wizard's own first feature ('product')
    // becomes the shell's first branch.
    const architecture = ArchitectureState(
      packageSplit: true,
      firstFeatureName: 'product',
      useNavigationShell: true,
      shellIcon: 'shopping_bag',
      shellLabel: 'Product',
    );

    try {
      await const LaunchGenerationUsecase().execute(
        identity: identity,
        packages: builderPackages,
        architecture: architecture,
        cicd: const CicdState(),
        theme: const ThemeEngineState(approach: ThemeApproach.customM3),
        onLog: logs.add,
      );
    } catch (e) {
      fail('Base generation threw:\n$e\n\n--- logs ---\n${logs.join('\n')}');
    }

    final projectDir = Directory('${tempRoot.path}/$projectName');
    String read(String p) => File(p).readAsStringSync();

    // The core package already ships the registry after the wizard's own
    // first shell branch — seeded with 'product' as a witness.
    final registryPath =
        '${projectDir.path}/packages/core/lib/core/router/shell_page_registry.dart';
    expect(
      File(registryPath).existsSync(),
      isTrue,
      reason: 'shell_page_registry.dart missing',
    );
    expect(
      read(registryPath),
      contains('final Map<String, ShellPageBuilder> shellPageBuilders = {'),
    );
    expect(
      read(registryPath),
      contains('ShellPageBuilder lookupShellPage(String key)'),
    );

    final shellRoutePath =
        '${projectDir.path}/lib/core/router/app_shell_route.dart';
    expect(
      read(shellRoutePath),
      contains("import 'package:core/core/router/shell_page_registry.dart';"),
    );
    expect(
      read(shellRoutePath),
      contains("lookupShellPage('product')(context, state)"),
    );
    expect(
      read(shellRoutePath),
      isNot(
        contains(
          "import 'package:product/presentation/pages/product_page.dart';",
        ),
      ),
      reason:
          'the app must never import a packageSplit shell branch\'s page directly',
    );

    // docs/REMOVE_FIRST_FEATURE.md: packageSplit + shell sections should be
    // present (dio here, not chopper, and no offline-first — so neither of
    // those sections should appear).
    final removeDoc = read('${projectDir.path}/docs/REMOVE_FIRST_FEATURE.md');
    expect(removeDoc, contains('packages/product/'));
    expect(removeDoc, contains('Workspace wiring (packageSplit)'));
    expect(removeDoc, contains('- packages/product'));
    expect(removeDoc, contains('Navigation shell'));
    expect(removeDoc, contains('shell_page_registry.dart'));
    expect(removeDoc, isNot(contains('chopper_model_converter.dart')));
    expect(removeDoc, isNot(contains('Drift database')));

    // 'product' (the first branch) self-registers, and bootstrap.dart calls it.
    final productRegPath =
        '${projectDir.path}/packages/product/lib/presentation/routes/product_shell_registration.dart';
    expect(File(productRegPath).existsSync(), isTrue);
    expect(read(productRegPath), contains('void registerProductShellPage()'));
    expect(read(productRegPath), contains("shellPageBuilders['product'] = "));
    final bootstrapPath = '${projectDir.path}/lib/core/bootstrap.dart';
    expect(
      read(bootstrapPath),
      contains(
        "import 'package:product/presentation/routes/product_shell_registration.dart';",
      ),
    );
    expect(read(bootstrapPath), contains('registerProductShellPage();'));

    // ── Add 'users' as a second shell branch via the Workshop ──────────────
    var project = await const ProjectLoader().load(projectDir.path);
    expect(project!.contract.packageSplit, isTrue);
    await const GenerateFeatureUsecase().execute(
      project: project,
      options: const FeatureGenOptions(
        name: 'users',
        routing: FeatureRouting.shell,
        shellIcon: 'people',
        shellLabel: 'Users',
      ),
      onLog: logs.add,
    );

    expect(
      read(shellRoutePath),
      contains("lookupShellPage('users')(context, state)"),
    );
    expect(
      read(shellRoutePath),
      isNot(
        contains("import 'package:users/presentation/pages/users_page.dart';"),
      ),
    );
    final usersRegPath =
        '${projectDir.path}/packages/users/lib/presentation/routes/users_shell_registration.dart';
    expect(File(usersRegPath).existsSync(), isTrue);
    expect(read(bootstrapPath), contains('registerUsersShellPage();'));
    // Both branches carry their own proactive children anchor, ready for a
    // sub-route to be nested under either one later.
    expect(read(shellRoutePath), contains('// neat:typed-children:product'));
    expect(read(shellRoutePath), contains('// neat:typed-children:users'));

    // ── Nest 'reviews' as a child under the 'product' shell branch ──────────
    // The real bug this closes: the pre-fix child-route wiring assumed
    // every parent had its own <parent>_routes.dart — a shell branch never
    // does (its route lives in app_shell_route.dart instead), so this
    // silently no-op'd, generating 'reviews' without ever wiring its route.
    project = await const ProjectLoader().load(projectDir.path);
    await const GenerateFeatureUsecase().execute(
      project: project!,
      options: const FeatureGenOptions(
        name: 'reviews',
        routing: FeatureRouting.child,
        parentFeature: 'product',
      ),
      onLog: logs.add,
    );

    final shellRouteContent = read(shellRoutePath);
    expect(
      shellRouteContent,
      contains("TypedGoRoute<ReviewsRoute>(path: 'reviews')"),
    );
    expect(
      shellRouteContent,
      contains(r'class ReviewsRoute extends GoRouteData with $ReviewsRoute'),
    );
    expect(
      shellRouteContent,
      contains("lookupShellPage('reviews')(context, state)"),
    );
    expect(
      shellRouteContent,
      isNot(
        contains(
          "import 'package:reviews/presentation/pages/reviews_page.dart';",
        ),
      ),
    );
    // The child sits under 'product's own anchor, not 'users'.
    final anchorIdx = shellRouteContent.indexOf(
      '// neat:typed-children:product',
    );
    final childIdx = shellRouteContent.indexOf(
      "TypedGoRoute<ReviewsRoute>(path: 'reviews')",
    );
    expect(childIdx, lessThan(anchorIdx));

    final reviewsRegPath =
        '${projectDir.path}/packages/reviews/lib/presentation/routes/reviews_shell_registration.dart';
    expect(File(reviewsRegPath).existsSync(), isTrue);
    expect(read(bootstrapPath), contains('registerReviewsShellPage();'));

    // The child never gets its own standalone routes file (its route
    // lives in the shell's tree, like any other shell branch/child).
    expect(
      File(
        '${projectDir.path}/packages/reviews/lib/presentation/routes/reviews_routes.dart',
      ).existsSync(),
      isFalse,
    );

    // AppRoutePath gained the nested '/product/reviews' constant. Single-sourced
    // in core (packageSplit) — the app keeps no copy of its own at all.
    expect(
      File(
        '${projectDir.path}/lib/core/constants/app_route_path.dart',
      ).existsSync(),
      isFalse,
    );
    expect(
      read(
        '${projectDir.path}/packages/core/lib/core/constants/app_route_path.dart',
      ),
      contains("static const String reviews = '/product/reviews';"),
    );

    // No cross-feature-package dependency needed: the child was never
    // imported by 'product's own package, only registered — so 'product'
    // never gains a path: dependency on 'reviews' (unlike the normal
    // top-level-parent child-route case, see the packageSplit + child
    // route test above).
    expect(
      read('${projectDir.path}/packages/product/pubspec.yaml'),
      isNot(contains('reviews:')),
    );
    // The root workspace still wires 'reviews' in, same as any new feature.
    expect(
      read('${projectDir.path}/pubspec.yaml'),
      contains('- packages/reviews'),
    );

    // The whole (now 5-package) workspace analyzes cleanly — proves the
    // $ReviewsRoute mixin generated correctly from app_shell_route.dart's
    // own build_runner pass (a cross-package codegen dependency direction
    // not exercised before this feature).
    final analyze = await Process.run('flutter', [
      'analyze',
      '--no-pub',
    ], workingDirectory: projectDir.path);
    final out = '${analyze.stdout}\n${analyze.stderr}';
    expect(
      RegExp(r'(\d+ issues? found|No issues found)').hasMatch(out),
      isTrue,
      reason: 'flutter analyze did not run as expected:\n$out',
    );
    final errorLines = const LineSplitter()
        .convert(out)
        .where(
          (l) =>
              (l.contains(' error •') || l.contains(' warning •')) &&
              !l.contains('• build/'),
        )
        .toList();
    expect(
      errorLines,
      isEmpty,
      reason:
          'flutter analyze reported errors:\n${errorLines.join('\n')}\n\n'
          '--- full analyze output ---\n$out',
    );
  }, timeout: const Timeout(Duration(minutes: 12)));

  test('packageSplit=true + go_router_builder + chopper + shell branch + child + '
      'mergeIntoParent (real project: a "recepies" shell branch merging in an '
      '"ingredient" child): the merged child skips the shell page registry '
      'entirely — app_shell_route.dart imports its page directly from the '
      'parent\'s own nested package location, and chopper decoder registration '
      'points there too', () async {
    const projectName = 'neat_pkgsplit_shell_merge_test';
    final logs = <String>[];
    final builderPackages = <PubPackage>[
      _dep('hooks_riverpod', '3.3.1'),
      _dep('flutter_hooks', '0.21.3+1'),
      _dep('riverpod_annotation', '4.0.2'),
      _dep('json_annotation', '4.11.0'),
      _dep('freezed_annotation', '3.1.0'),
      _dep('chopper', '8.6.0'),
      _dep('go_router', '17.2.3'),
      _dev('go_router_builder', '4.3.0'),
      _dev('riverpod_generator', '4.0.3'),
      _dev('riverpod_lint', '3.1.3'),
      _dev('json_serializable', '6.13.0'),
      _dev('build_runner', '2.15.0'),
      _dev('freezed', '3.2.5'),
      _dev('chopper_generator', '8.6.2'),
    ];

    final identity = IdentityState(
      name: projectName,
      organization: 'com.neat.test',
      projectPath: tempRoot.path,
      description:
          'NEAT packageSplit + shell + mergeIntoParent integration test',
      targetPlatforms: const ['macos'],
    );
    const architecture = ArchitectureState(
      packageSplit: true,
      firstFeatureName: 'recepies',
      useNavigationShell: true,
      shellIcon: 'restaurant',
      shellLabel: 'Recepies',
    );

    try {
      await const LaunchGenerationUsecase().execute(
        identity: identity,
        packages: builderPackages,
        architecture: architecture,
        cicd: const CicdState(),
        theme: const ThemeEngineState(approach: ThemeApproach.customM3),
        onLog: logs.add,
      );
    } catch (e) {
      fail('Base generation threw:\n$e\n\n--- logs ---\n${logs.join('\n')}');
    }

    final projectDir = Directory('${tempRoot.path}/$projectName');
    final project = await const ProjectLoader().load(projectDir.path);
    expect(project!.contract.packageSplit, isTrue);

    // Merge "ingredient" into the "recepies" shell branch.
    await const GenerateFeatureUsecase().execute(
      project: project,
      options: const FeatureGenOptions(
        name: 'ingredient',
        routing: FeatureRouting.child,
        parentFeature: 'recepies',
        mergeIntoParent: true,
      ),
      onLog: logs.add,
    );

    String read(String p) => File(p).readAsStringSync();
    final recepiesRoot = '${projectDir.path}/packages/recepies';

    // No separate 'ingredient' package was created at all.
    expect(
      Directory('${projectDir.path}/packages/ingredient').existsSync(),
      isFalse,
    );

    // Own entity/repository/datasource, nested under an ingredient/
    // subfolder per layer inside recepies' own package.
    expect(
      File(
        '$recepiesRoot/lib/domain/ingredient/entities/ingredient_entity.dart',
      ).existsSync(),
      isTrue,
    );
    expect(
      File(
        '$recepiesRoot/lib/presentation/ingredient/pages/ingredient_page.dart',
      ).existsSync(),
      isTrue,
    );

    // app_shell_route.dart imports the merged child's page directly — no
    // registry lookup at all for it (unlike a non-merged shell child).
    final shellRoutePath =
        '${projectDir.path}/lib/core/router/app_shell_route.dart';
    final shellRouteContent = read(shellRoutePath);
    expect(
      shellRouteContent,
      contains(
        "import 'package:recepies/presentation/ingredient/pages/ingredient_page.dart';",
      ),
    );
    expect(
      shellRouteContent,
      contains("TypedGoRoute<IngredientRoute>(path: 'ingredient')"),
    );
    expect(shellRouteContent, contains('const IngredientPage()'));
    expect(shellRouteContent, isNot(contains("lookupShellPage('ingredient')")));

    // No <f>_shell_registration.dart file, and bootstrap.dart never
    // references one for the merged child.
    expect(
      File(
        '$recepiesRoot/lib/presentation/ingredient/routes/ingredient_shell_registration.dart',
      ).existsSync(),
      isFalse,
    );
    final bootstrap = read('${projectDir.path}/lib/core/bootstrap.dart');
    expect(bootstrap, isNot(contains('registerIngredientShellPage();')));

    // Chopper decoder registration: bootstrap.dart imports the merged
    // child's repository providers from *recepies'* package, nested under
    // data/ingredient/ — the exact crash this scenario originally hit
    // (featurePackageName! was null when merged).
    expect(
      bootstrap,
      contains(
        "import 'package:recepies/data/ingredient/repositories/"
        "ingredient_repository_providers.dart';",
      ),
    );
    expect(bootstrap, contains('registerIngredientChopperDecoders();'));

    // No new path: dependency and no new workspace member.
    expect(read('$recepiesRoot/pubspec.yaml'), isNot(contains('ingredient:')));
    expect(
      read('${projectDir.path}/pubspec.yaml'),
      isNot(contains('packages/ingredient')),
    );

    // AppRoutePath still gains the nested '/recepies/ingredient' constant.
    expect(
      read(
        '${projectDir.path}/packages/core/lib/core/constants/app_route_path.dart',
      ),
      contains("static const String ingredient = '/recepies/ingredient';"),
    );

    final analyze = await Process.run('flutter', [
      'analyze',
      '--no-pub',
    ], workingDirectory: projectDir.path);
    final out = '${analyze.stdout}\n${analyze.stderr}';
    expect(
      RegExp(r'(\d+ issues? found|No issues found)').hasMatch(out),
      isTrue,
      reason: 'flutter analyze did not run as expected:\n$out',
    );
    final errorLines = const LineSplitter()
        .convert(out)
        .where(
          (l) =>
              (l.contains(' error •') || l.contains(' warning •')) &&
              !l.contains('• build/'),
        )
        .toList();
    expect(
      errorLines,
      isEmpty,
      reason:
          'flutter analyze reported errors:\n${errorLines.join('\n')}\n\n'
          '--- full analyze output ---\n$out',
    );
  }, timeout: const Timeout(Duration(minutes: 12)));

  test('packageSplit=true + plain go_router (not builder) + shell branch + a '
      'nested child (§7): same registry decoupling + sub-route support as the '
      'go_router_builder case above, via routes.dart\'s embedded '
      'StatefulShellRoute instead of a typed app_shell_route.dart', () async {
    const projectName = 'neat_pkgsplit_shell_registry_plain_test';
    final logs = <String>[];
    final plainPackages = <PubPackage>[
      _dep('hooks_riverpod', '3.3.1'),
      _dep('flutter_hooks', '0.21.3+1'),
      _dep('riverpod_annotation', '4.0.2'),
      _dep('json_annotation', '4.11.0'),
      _dep('freezed_annotation', '3.1.0'),
      _dep('dio', '5.9.2'),
      _dep('go_router', '17.2.3'),
      _dev('riverpod_generator', '4.0.3'),
      _dev('riverpod_lint', '3.1.3'),
      _dev('json_serializable', '6.13.0'),
      _dev('build_runner', '2.15.0'),
      _dev('freezed', '3.2.5'),
    ];

    final identity = IdentityState(
      name: projectName,
      organization: 'com.neat.test',
      projectPath: tempRoot.path,
      description:
          'NEAT packageSplit + plain shell page registry integration test',
      targetPlatforms: const ['macos'],
    );
    const architecture = ArchitectureState(
      packageSplit: true,
      firstFeatureName: 'product',
      useNavigationShell: true,
      shellIcon: 'shopping_bag',
      shellLabel: 'Product',
    );

    try {
      await const LaunchGenerationUsecase().execute(
        identity: identity,
        packages: plainPackages,
        architecture: architecture,
        cicd: const CicdState(),
        theme: const ThemeEngineState(approach: ThemeApproach.customM3),
        onLog: logs.add,
      );
    } catch (e) {
      fail('Base generation threw:\n$e\n\n--- logs ---\n${logs.join('\n')}');
    }

    final projectDir = Directory('${tempRoot.path}/$projectName');
    String read(String p) => File(p).readAsStringSync();
    final routesPath = '${projectDir.path}/lib/core/router/routes.dart';

    expect(
      read(routesPath),
      contains("lookupShellPage('product')(context, state)"),
    );
    expect(
      read(routesPath),
      isNot(
        contains(
          "import 'package:product/presentation/pages/product_page.dart';",
        ),
      ),
    );
    expect(read(routesPath), contains('// neat:children:product'));

    // Add 'reviews' as a child of the 'product' shell branch.
    final project = await const ProjectLoader().load(projectDir.path);
    expect(project!.contract.packageSplit, isTrue);
    await const GenerateFeatureUsecase().execute(
      project: project,
      options: const FeatureGenOptions(
        name: 'reviews',
        routing: FeatureRouting.child,
        parentFeature: 'product',
      ),
      onLog: logs.add,
    );

    final routesContent = read(routesPath);
    expect(routesContent, contains("path: 'reviews',"));
    expect(
      routesContent,
      contains("lookupShellPage('reviews')(context, state)"),
    );
    expect(
      routesContent,
      isNot(
        contains(
          "import 'package:reviews/presentation/pages/reviews_page.dart';",
        ),
      ),
    );
    final reviewsRegPath =
        '${projectDir.path}/packages/reviews/lib/presentation/routes/reviews_shell_registration.dart';
    expect(File(reviewsRegPath).existsSync(), isTrue);
    expect(
      read('${projectDir.path}/lib/core/bootstrap.dart'),
      contains('registerReviewsShellPage();'),
    );

    final analyze = await Process.run('flutter', [
      'analyze',
      '--no-pub',
    ], workingDirectory: projectDir.path);
    final out = '${analyze.stdout}\n${analyze.stderr}';
    expect(
      RegExp(r'(\d+ issues? found|No issues found)').hasMatch(out),
      isTrue,
      reason: 'flutter analyze did not run as expected:\n$out',
    );
    final errorLines = const LineSplitter()
        .convert(out)
        .where(
          (l) =>
              (l.contains(' error •') || l.contains(' warning •')) &&
              !l.contains('• build/'),
        )
        .toList();
    expect(
      errorLines,
      isEmpty,
      reason:
          'flutter analyze reported errors:\n${errorLines.join('\n')}\n\n'
          '--- full analyze output ---\n$out',
    );
  }, timeout: const Timeout(Duration(minutes: 12)));

  test('packageSplit=true + offline-first: the split feature shares core\'s '
      'Drift db + connectivity, and the workspace analyzes cleanly', () async {
    const projectName = 'neat_gen_pkgsplit_offline_test';
    final logs = <String>[];
    // Offline-first *read* only (no sync/Outbox yet — see ROADMAP.md §6a):
    // infrastructure_providers.dart/network_info.dart move to core, so
    // every offline-first feature package shares the same Drift db +
    // connectivity singletons instead of each getting its own.
    final offlinePackages = <PubPackage>[
      _dep('hooks_riverpod', '3.3.1'),
      _dep('flutter_hooks', '0.21.3+1'),
      _dep('riverpod_annotation', '4.0.2'),
      _dep('json_annotation', '4.11.0'),
      _dep('freezed_annotation', '3.1.0'),
      _dep('dio', '5.9.2'),
      _dep('go_router', '17.2.3'),
      _dev('riverpod_generator', '4.0.3'),
      _dev('riverpod_lint', '3.1.3'),
      _dev('json_serializable', '6.13.0'),
      _dev('build_runner', '2.15.0'),
      _dev('freezed', '3.2.5'),
    ];

    final identity = IdentityState(
      name: projectName,
      organization: 'com.neat.test',
      projectPath: tempRoot.path,
      description: 'NEAT packageSplit + offline-first integration test',
      targetPlatforms: const ['macos'],
    );

    const architecture = ArchitectureState(
      packageSplit: true,
      storageStrategy: StorageStrategy.offlineFirstRead,
    );
    const cicd = CicdState();
    const theme = ThemeEngineState(approach: ThemeApproach.customM3);

    try {
      await const LaunchGenerationUsecase().execute(
        identity: identity,
        packages: offlinePackages,
        architecture: architecture,
        cicd: cicd,
        theme: theme,
        onLog: logs.add,
      );
    } catch (e) {
      fail('Generation threw:\n$e\n\n--- logs ---\n${logs.join('\n')}');
    }

    final projectDir = Directory('${tempRoot.path}/$projectName');
    final coreRoot = '${projectDir.path}/packages/core';
    final featureRoot = '${projectDir.path}/packages/home';
    final dbPkg = '${projectName}_database';
    final storageRoot = '${projectDir.path}/packages/$dbPkg';
    String read(String p) => File(p).readAsStringSync();

    // Core ships NetworkInfo + the shared appDatabaseProvider/
    // networkInfoProvider — the single instances every offline-first
    // feature package reuses, instead of each getting its own.
    expect(
      File('$coreRoot/lib/core/network/network_info.dart').existsSync(),
      isTrue,
    );
    final infraProviders = read(
      '$coreRoot/lib/core/providers/infrastructure_providers.dart',
    );
    expect(infraProviders, contains('AppDatabase appDatabase(Ref ref)'));
    expect(infraProviders, contains('NetworkInfo networkInfo(Ref ref)'));
    expect(
      infraProviders,
      contains("import 'package:core/core/network/network_info.dart';"),
    );
    expect(infraProviders, contains("import 'package:$dbPkg/"));

    // Core's own pubspec depends on the Drift package + connectivity_plus.
    final corePubspec = read('$coreRoot/pubspec.yaml');
    expect(corePubspec, contains('connectivity_plus:'));
    expect(corePubspec, contains('$dbPkg:\n    path: ../$dbPkg'));

    // The feature package's repository crosses into core for
    // Failure/NetworkInfo/Result/AppLogger, and depends on the Drift
    // package directly for its local source — never on the app.
    final repoImpl = read(
      '$featureRoot/lib/data/repositories/home_repository_impl.dart',
    );
    expect(
      repoImpl,
      contains("import 'package:core/core/error/failure.dart';"),
    );
    expect(
      repoImpl,
      contains("import 'package:core/core/network/network_info.dart';"),
    );
    expect(
      repoImpl,
      isNot(contains('package:$projectName/')),
      reason:
          'a split feature package must never import from the app — that would be a cycle',
    );

    final repoProviders = read(
      '$featureRoot/lib/data/repositories/home_repository_providers.dart',
    );
    expect(
      repoProviders,
      contains(
        "import 'package:core/core/providers/infrastructure_providers.dart';",
      ),
    );

    final localSource = read(
      '$featureRoot/lib/data/sources/home_local_source.dart',
    );
    expect(
      localSource,
      contains("import 'package:$dbPkg/$dbPkg.dart';"),
    );

    // The feature package's own pubspec depends on the Drift package too.
    final featurePubspec = read('$featureRoot/pubspec.yaml');
    expect(
      featurePubspec,
      contains('$dbPkg:\n    path: ../$dbPkg'),
    );

    // Root pubspec wires all three packages into the workspace.
    final rootPubspec = read('${projectDir.path}/pubspec.yaml');
    expect(rootPubspec, contains('- packages/core'));
    expect(rootPubspec, contains('- packages/home'));
    expect(rootPubspec, contains('- packages/$dbPkg'));

    expect(Directory(storageRoot).existsSync(), isTrue);

    final analyze = await Process.run('flutter', [
      'analyze',
      '--no-pub',
    ], workingDirectory: projectDir.path);
    final out = '${analyze.stdout}\n${analyze.stderr}';
    expect(
      RegExp(r'(\d+ issues? found|No issues found)').hasMatch(out),
      isTrue,
      reason: 'flutter analyze did not run as expected:\n$out',
    );
    final errorLines = const LineSplitter()
        .convert(out)
        .where(
          (l) =>
              (l.contains(' error •') || l.contains(' warning •')) &&
              !l.contains('• build/'),
        )
        .toList();
    expect(
      errorLines,
      isEmpty,
      reason:
          'flutter analyze reported errors:\n${errorLines.join('\n')}\n\n'
          '--- full analyze output ---\n$out',
    );
  }, timeout: const Timeout(Duration(minutes: 12)));

  test('Step 2b: the Workshop adds a 2nd feature package to an already-split '
      'project, wired and analyzing cleanly', () async {
    const projectName = 'neat_pkgsplit_2b_test';
    final logs = <String>[];
    final pkgs = <PubPackage>[
      _dep('hooks_riverpod', '3.3.1'),
      _dep('flutter_hooks', '0.21.3+1'),
      _dep('riverpod_annotation', '4.0.2'),
      _dep('json_annotation', '4.11.0'),
      _dep('freezed_annotation', '3.1.0'),
      _dep('dio', '5.9.2'),
      _dep('go_router', '17.2.3'),
      _dev('riverpod_generator', '4.0.3'),
      _dev('riverpod_lint', '3.1.3'),
      _dev('json_serializable', '6.13.0'),
      _dev('build_runner', '2.15.0'),
      _dev('freezed', '3.2.5'),
    ];

    final identity = IdentityState(
      name: projectName,
      organization: 'com.neat.test',
      projectPath: tempRoot.path,
      description: 'NEAT packageSplit Step 2b integration test',
      targetPlatforms: const ['macos'],
    );
    const architecture = ArchitectureState(packageSplit: true); // splits 'home'

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
      fail('Base generation threw:\n$e\n\n--- logs ---\n${logs.join('\n')}');
    }

    final projectDir = Directory('${tempRoot.path}/$projectName');

    // Re-open via the contract, as the Hub would — the contract must carry
    // packageSplit, and feature discovery must scan packages/, not
    // lib/features/ (empty there for a split project).
    final project = await const ProjectLoader().load(projectDir.path);
    expect(project, isNotNull);
    expect(project!.contract.packageSplit, isTrue);
    expect(project.features, ['home']);

    // Add a 2nd feature — must land in its own package, never lib/features/
    // under the app (the bug this Step 2b fixes).
    await const GenerateFeatureUsecase().execute(
      project: project,
      options: const FeatureGenOptions(name: 'orders'),
      onLog: logs.add,
    );

    final orderRoot = '${projectDir.path}/packages/orders';
    String read(String p) => File(p).readAsStringSync();

    expect(
      File('${projectDir.path}/lib/features/orders').existsSync(),
      isFalse,
      reason: 'a packageSplit project must never grow a lib/features/ folder',
    );
    expect(
      File('$orderRoot/lib/presentation/pages/orders_page.dart').existsSync(),
      isTrue,
    );
    expect(
      File('$orderRoot/lib/domain/entities/orders_entity.dart').existsSync(),
      isTrue,
    );

    final orderPubspec = read('$orderRoot/pubspec.yaml');
    expect(orderPubspec, contains('name: orders'));
    expect(orderPubspec, contains('core:\n    path: ../core'));

    // The usecase crosses into core, never the app — same discipline as the
    // wizard's own split first feature.
    final getUsecase = read(
      '$orderRoot/lib/domain/usecases/get_orders_usecase.dart',
    );
    expect(
      getUsecase,
      contains("import 'package:core/core/usecases/use_case.dart';"),
    );
    expect(getUsecase, isNot(contains('package:$projectName/')));

    // Root pubspec: new workspace member + path dependency (routes.dart
    // imports the new package directly).
    final rootPubspec = read('${projectDir.path}/pubspec.yaml');
    expect(rootPubspec, contains('- packages/orders'));
    expect(rootPubspec, contains('orders:\n    path: packages/orders'));

    // routes.dart crosses into the new package; AppRoutePath is
    // single-sourced in the core package's copy (packageSplit) — the app
    // keeps no copy of its own, and routes.dart's own import already
    // redirects there (see CoreTemplates.routesManual's corePackageName doc).
    final routes = read('${projectDir.path}/lib/core/router/routes.dart');
    expect(
      routes,
      contains("import 'package:orders/presentation/pages/orders_page.dart';"),
    );
    expect(routes, contains('AppRoutePath.orders'));
    expect(
      File(
        '${projectDir.path}/lib/core/constants/app_route_path.dart',
      ).existsSync(),
      isFalse,
    );
    expect(
      read(
        '${projectDir.path}/packages/core/lib/core/constants/app_route_path.dart',
      ),
      contains("static const String orders = '/orders';"),
      reason:
          'the split feature imports AppRoutePath from core, not the app — core\'s '
          'single copy must gain the constant too',
    );

    // Reload sees both features; non-destructive guard still holds.
    final reloaded = await const ProjectLoader().load(projectDir.path);
    expect(reloaded!.features, ['home', 'orders']);
    expect(
      () => const GenerateFeatureUsecase().execute(
        project: reloaded,
        options: const FeatureGenOptions(name: 'home'),
        onLog: logs.add,
      ),
      throwsA(isA<Exception>()),
    );

    // §6a Phase 3: child routes under packageSplit now work for plain
    // go_router — nesting happens inside the app's own shared routes.dart
    // (which already depends on every feature package for their top-level
    // routes), so no new cross-feature-package dependency is needed here.
    await const GenerateFeatureUsecase().execute(
      project: reloaded,
      options: const FeatureGenOptions(
        name: 'reviews',
        routing: FeatureRouting.child,
        parentFeature: 'home',
      ),
      onLog: logs.add,
    );
    final routesAfterChild = read(
      '${projectDir.path}/lib/core/router/routes.dart',
    );
    expect(
      routesAfterChild,
      contains(
        "import 'package:reviews/presentation/pages/reviews_page.dart';",
      ),
    );
    expect(routesAfterChild, isNot(contains('features/reviews/')));
    expect(routesAfterChild, contains("path: 'reviews',"));
    expect(routesAfterChild, contains('// neat:children:home'));
    expect(
      read(
        '${projectDir.path}/packages/core/lib/core/constants/app_route_path.dart',
      ),
      contains("static const String reviews = '/home/reviews';"),
    );

    // The whole (now 3-package) workspace analyzes cleanly.
    final analyze = await Process.run('flutter', [
      'analyze',
      '--no-pub',
    ], workingDirectory: projectDir.path);
    final out = '${analyze.stdout}\n${analyze.stderr}';
    expect(
      RegExp(r'(\d+ issues? found|No issues found)').hasMatch(out),
      isTrue,
      reason: 'flutter analyze did not run as expected:\n$out',
    );
    final errorLines = const LineSplitter()
        .convert(out)
        .where(
          (l) =>
              (l.contains(' error •') || l.contains(' warning •')) &&
              !l.contains('• build/'),
        )
        .toList();
    expect(
      errorLines,
      isEmpty,
      reason:
          'flutter analyze reported errors:\n${errorLines.join('\n')}\n\n'
          '--- full analyze output ---\n$out',
    );
  }, timeout: const Timeout(Duration(minutes: 12)));

  test('Step 2b + chopper: the Workshop-added feature package self-registers via '
      'bootstrap.dart\'s anchors', () async {
    const projectName = 'neat_pkgsplit_2b_chopper_test';
    final logs = <String>[];
    final pkgs = <PubPackage>[
      _dep('hooks_riverpod', '3.3.1'),
      _dep('flutter_hooks', '0.21.3+1'),
      _dep('riverpod_annotation', '4.0.2'),
      _dep('json_annotation', '4.11.0'),
      _dep('freezed_annotation', '3.1.0'),
      _dep('chopper', '8.6.0'),
      _dep('go_router', '17.2.3'),
      _dev('riverpod_generator', '4.0.3'),
      _dev('riverpod_lint', '3.1.3'),
      _dev('json_serializable', '6.13.0'),
      _dev('build_runner', '2.15.0'),
      _dev('freezed', '3.2.5'),
      _dev('chopper_generator', '8.6.2'),
    ];

    final identity = IdentityState(
      name: projectName,
      organization: 'com.neat.test',
      projectPath: tempRoot.path,
      description: 'NEAT packageSplit Step 2b + chopper integration test',
      targetPlatforms: const ['macos'],
    );
    const architecture = ArchitectureState(packageSplit: true);

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
      fail('Base generation threw:\n$e\n\n--- logs ---\n${logs.join('\n')}');
    }

    final projectDir = Directory('${tempRoot.path}/$projectName');
    final project = await const ProjectLoader().load(projectDir.path);
    expect(project!.contract.httpClient, 'chopper');

    await const GenerateFeatureUsecase().execute(
      project: project,
      options: const FeatureGenOptions(name: 'orders'),
      onLog: logs.add,
    );

    String read(String p) => File(p).readAsStringSync();
    final orderRoot = '${projectDir.path}/packages/orders';

    // The new feature package generated its own registration function...
    final repoProviders = read(
      '$orderRoot/lib/data/repositories/orders_repository_providers.dart',
    );
    expect(repoProviders, contains('void registerOrdersChopperDecoders() {'));
    expect(
      repoProviders,
      contains(
        "import 'package:core/core/network/chopper_model_converter.dart';",
      ),
    );

    // ...and bootstrap.dart calls it (alongside the wizard's own first
    // feature's registration — both anchors stack cleanly).
    final bootstrap = read('${projectDir.path}/lib/core/bootstrap.dart');
    expect(bootstrap, contains('registerHomeChopperDecoders();'));
    expect(
      bootstrap,
      contains(
        "import 'package:orders/data/repositories/orders_repository_providers.dart';",
      ),
    );
    expect(bootstrap, contains('registerOrdersChopperDecoders();'));

    final analyze = await Process.run('flutter', [
      'analyze',
      '--no-pub',
    ], workingDirectory: projectDir.path);
    final out = '${analyze.stdout}\n${analyze.stderr}';
    final errorLines = const LineSplitter()
        .convert(out)
        .where(
          (l) =>
              (l.contains(' error •') || l.contains(' warning •')) &&
              !l.contains('• build/'),
        )
        .toList();
    expect(
      errorLines,
      isEmpty,
      reason:
          'flutter analyze reported errors:\n${errorLines.join('\n')}\n\n'
          '--- full analyze output ---\n$out',
    );
  }, timeout: const Timeout(Duration(minutes: 12)));

  test(
    'packageSplit=true + chopper + generateFirstFeature=false (real bug, found '
    'via a real generated project: dummyjson.com/users threw a chopper '
    'FormatException on every call, not just getAll() — the decoder registration '
    'function was generated but never called): the Workshop\'s very first '
    'feature must self-heal bootstrap.dart\'s chopper-register anchors, since '
    '`AppTemplates.bootstrap` only seeds them when the wizard\'s own first '
    'feature already uses chopper',
    () async {
      const projectName = 'neat_pkgsplit_chopper_nofirst_test';
      final logs = <String>[];
      final pkgs = <PubPackage>[
        _dep('hooks_riverpod', '3.3.1'),
        _dep('flutter_hooks', '0.21.3+1'),
        _dep('riverpod_annotation', '4.0.2'),
        _dep('json_annotation', '4.11.0'),
        _dep('freezed_annotation', '3.1.0'),
        _dep('chopper', '8.6.0'),
        _dep('go_router', '17.2.3'),
        _dev('riverpod_generator', '4.0.3'),
        _dev('riverpod_lint', '3.1.3'),
        _dev('json_serializable', '6.13.0'),
        _dev('build_runner', '2.15.0'),
        _dev('freezed', '3.2.5'),
        _dev('chopper_generator', '8.6.2'),
      ];

      final identity = IdentityState(
        name: projectName,
        organization: 'com.neat.test',
        projectPath: tempRoot.path,
        description: 'NEAT packageSplit + chopper, no first feature, integration test',
        targetPlatforms: const ['macos'],
      );
      // The exact combo that exposed this: no first feature at launch — chopper
      // is still the project's chosen httpClient, but nothing seeds bootstrap
      // .dart's chopper-register anchors until a real feature exists.
      const architecture = ArchitectureState(
        packageSplit: true,
        generateFirstFeature: false,
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
        fail('Base generation threw:\n$e\n\n--- logs ---\n${logs.join('\n')}');
      }

      final projectDir = Directory('${tempRoot.path}/$projectName');
      final project = await const ProjectLoader().load(projectDir.path);
      expect(project, isNotNull);
      expect(project!.contract.httpClient, 'chopper');

      // bootstrap.dart has no chopper-register anchors yet — nothing has ever
      // used them (no first feature at launch).
      final bootstrapPath = '${projectDir.path}/lib/core/bootstrap.dart';
      expect(
        File(bootstrapPath).readAsStringSync(),
        isNot(contains('// neat:chopper-register-imports')),
      );

      try {
        await const GenerateFeatureUsecase().execute(
          project: project,
          options: const FeatureGenOptions(name: 'users'),
          onLog: logs.add,
        );
      } catch (e) {
        fail(
          'Feature generation threw:\n$e\n\n--- logs ---\n${logs.join('\n')}',
        );
      }

      // The feature generated its own registration function...
      final repoProviders = File(
        '${projectDir.path}/packages/users/lib/data/repositories/users_repository_providers.dart',
      ).readAsStringSync();
      expect(repoProviders, contains('void registerUsersChopperDecoders() {'));
      expect(
        repoProviders,
        contains('chopperModelDecoders[UsersModel] = UsersModel.fromJson;'),
      );

      // ...and bootstrap.dart both gained the anchors (self-healed) and
      // actually calls it — the exact real-world gap: without the self-heal,
      // the anchors — and therefore this import/call — would be entirely
      // absent, leaving the registration function dead code and
      // chopperModelDecoders permanently empty.
      final bootstrap = File(bootstrapPath).readAsStringSync();
      expect(bootstrap, contains('// neat:chopper-register-imports'));
      expect(bootstrap, contains('// neat:chopper-register-calls'));
      expect(
        bootstrap,
        contains(
          "import 'package:users/data/repositories/users_repository_providers.dart';",
        ),
      );
      expect(bootstrap, contains('registerUsersChopperDecoders();'));

      final analyze = await Process.run('flutter', [
        'analyze',
        '--no-pub',
      ], workingDirectory: projectDir.path);
      final out = '${analyze.stdout}\n${analyze.stderr}';
      final errorLines = const LineSplitter()
          .convert(out)
          .where(
            (l) =>
                (l.contains(' error •') || l.contains(' warning •')) &&
                !l.contains('• build/'),
          )
          .toList();
      expect(
        errorLines,
        isEmpty,
        reason:
            'packageSplit + chopper, no first feature, workspace analyze '
            'reported issues:\n${errorLines.join('\n')}\n\n$out',
      );
    },
    timeout: const Timeout(Duration(minutes: 12)),
  );

  test('packageSplit=true + i18n: the whole slang setup is single-sourced in '
      'core, never duplicated in the app', () async {
    const projectName = 'neat_pkgsplit_i18n_test';
    final logs = <String>[];
    final pkgs = <PubPackage>[
      _dep('hooks_riverpod', '3.3.1'),
      _dep('flutter_hooks', '0.21.3+1'),
      _dep('riverpod_annotation', '4.0.2'),
      _dep('json_annotation', '4.11.0'),
      _dep('freezed_annotation', '3.1.0'),
      _dep('dio', '5.9.2'),
      _dep('go_router', '17.2.3'),
      _dev('riverpod_generator', '4.0.3'),
      _dev('riverpod_lint', '3.1.3'),
      _dev('json_serializable', '6.13.0'),
      _dev('build_runner', '2.15.0'),
      _dev('freezed', '3.2.5'),
    ];

    final identity = IdentityState(
      name: projectName,
      organization: 'com.neat.test',
      projectPath: tempRoot.path,
      description: 'NEAT packageSplit + i18n integration test',
      targetPlatforms: const ['macos'],
    );
    const architecture = ArchitectureState(
      packageSplit: true,
      generateI18n: true,
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
      fail('Generation threw:\n$e\n\n--- logs ---\n${logs.join('\n')}');
    }

    final projectDir = Directory('${tempRoot.path}/$projectName');
    final coreRoot = '${projectDir.path}/packages/core';
    final featureRoot = '${projectDir.path}/packages/home';
    String read(String p) => File(p).readAsStringSync();

    // The whole i18n setup lives in core...
    expect(read('$coreRoot/slang.yaml'), contains('base_locale: en'));
    expect(File('$coreRoot/lib/i18n/en.i18n.json').existsSync(), isTrue);
    expect(File('$coreRoot/lib/i18n/fr.i18n.json').existsSync(), isTrue);
    expect(File('$coreRoot/lib/i18n/strings.g.dart').existsSync(), isTrue);
    expect(
      read('$coreRoot/lib/core/i18n/language_switcher.dart'),
      contains('LanguageSwitcher'),
    );
    expect(
      read('$coreRoot/lib/core/i18n/locale_store.dart'),
      contains('SharedPreferences'),
    );
    final corePubspec = read('$coreRoot/pubspec.yaml');
    expect(corePubspec, contains('slang:'));
    expect(corePubspec, contains('slang_flutter:'));
    expect(corePubspec, contains('shared_preferences:'));

    // ...never duplicated in the app.
    expect(File('${projectDir.path}/slang.yaml').existsSync(), isFalse);
    expect(File('${projectDir.path}/lib/i18n').existsSync(), isFalse);
    expect(
      File('${projectDir.path}/lib/core/i18n/locale_store.dart').existsSync(),
      isFalse,
    );
    expect(
      File(
        '${projectDir.path}/lib/core/i18n/language_switcher.dart',
      ).existsSync(),
      isFalse,
    );

    // The app's own files cross into core for i18n.
    final bootstrap = read('${projectDir.path}/lib/core/bootstrap.dart');
    expect(
      bootstrap,
      contains("import 'package:core/core/i18n/locale_store.dart';"),
    );
    expect(bootstrap, contains("import 'package:core/i18n/strings.g.dart';"));
    expect(bootstrap, contains('LocaleStore.init()'));
    final app = read('${projectDir.path}/lib/app.dart');
    expect(app, contains("import 'package:core/i18n/strings.g.dart';"));

    // The split feature's page also crosses into core — never the app.
    final homePage = read('$featureRoot/lib/presentation/pages/home_page.dart');
    expect(homePage, contains("import 'package:core/i18n/strings.g.dart';"));
    expect(
      homePage,
      contains("import 'package:core/core/i18n/language_switcher.dart';"),
    );
    expect(homePage, contains('context.t.home.title'));
    expect(
      homePage,
      isNot(contains('package:$projectName/')),
      reason: 'a split feature package must never import from the app',
    );

    // The whole workspace analyzes cleanly.
    final analyze = await Process.run('flutter', [
      'analyze',
      '--no-pub',
    ], workingDirectory: projectDir.path);
    final out = '${analyze.stdout}\n${analyze.stderr}';
    final errorLines = const LineSplitter()
        .convert(out)
        .where(
          (l) =>
              (l.contains(' error •') || l.contains(' warning •')) &&
              !l.contains('• build/'),
        )
        .toList();
    expect(
      errorLines,
      isEmpty,
      reason:
          'flutter analyze reported errors:\n${errorLines.join('\n')}\n\n'
          '--- full analyze output ---\n$out',
    );
  }, timeout: const Timeout(Duration(minutes: 12)));

  test('packageSplit=true + offline+sync: the split feature\'s SyncService '
      'crosses into core, and the workspace analyzes cleanly', () async {
    const projectName = 'neat_pkgsplit_sync_test';
    final logs = <String>[];
    final pkgs = <PubPackage>[
      _dep('hooks_riverpod', '3.3.1'),
      _dep('flutter_hooks', '0.21.3+1'),
      _dep('riverpod_annotation', '4.0.2'),
      _dep('json_annotation', '4.11.0'),
      _dep('freezed_annotation', '3.1.0'),
      _dep('dio', '5.9.2'),
      _dep('go_router', '17.2.3'),
      _dev('riverpod_generator', '4.0.3'),
      _dev('riverpod_lint', '3.1.3'),
      _dev('json_serializable', '6.13.0'),
      _dev('build_runner', '2.15.0'),
      _dev('freezed', '3.2.5'),
    ];

    final identity = IdentityState(
      name: projectName,
      organization: 'com.neat.test',
      projectPath: tempRoot.path,
      description: 'NEAT packageSplit + offline-sync integration test',
      targetPlatforms: const ['macos'],
    );
    const architecture = ArchitectureState(
      packageSplit: true,
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
      fail('Generation threw:\n$e\n\n--- logs ---\n${logs.join('\n')}');
    }

    final projectDir = Directory('${tempRoot.path}/$projectName');
    final coreRoot = '${projectDir.path}/packages/core';
    final featureRoot = '${projectDir.path}/packages/home';
    String read(String p) => File(p).readAsStringSync();

    // sync_service.dart lives in core, importing core's own network_info.dart...
    final coreSync = read('$coreRoot/lib/core/sync/sync_service.dart');
    expect(coreSync, contains('class SyncService'));
    expect(
      coreSync,
      contains("import 'package:core/core/network/network_info.dart';"),
    );

    // ...never duplicated in the app.
    expect(
      File('${projectDir.path}/lib/core/sync/sync_service.dart').existsSync(),
      isFalse,
    );

    // The split feature's repository-providers DI graph crosses into core
    // for SyncService, never the app.
    final di = read(
      '$featureRoot/lib/data/repositories/home_repository_providers.dart',
    );
    expect(di, contains('SyncService homeSync(Ref ref)'));
    expect(di, contains("import 'package:core/core/sync/sync_service.dart';"));
    expect(
      di,
      isNot(contains('package:$projectName/')),
      reason: 'a split feature package must never import from the app',
    );

    // Full CRUD write contract + Outbox-backed write path still generated.
    final repoImpl = read(
      '$featureRoot/lib/data/repositories/home_repository_impl.dart',
    );
    expect(repoImpl, contains('enqueueWrite'));
    expect(repoImpl, contains("operation: 'create'"));

    // The whole workspace analyzes cleanly.
    final analyze = await Process.run('flutter', [
      'analyze',
      '--no-pub',
    ], workingDirectory: projectDir.path);
    final out = '${analyze.stdout}\n${analyze.stderr}';
    final errorLines = const LineSplitter()
        .convert(out)
        .where(
          (l) =>
              (l.contains(' error •') || l.contains(' warning •')) &&
              !l.contains('• build/'),
        )
        .toList();
    expect(
      errorLines,
      isEmpty,
      reason:
          'flutter analyze reported errors:\n${errorLines.join('\n')}\n\n'
          '--- full analyze output ---\n$out',
    );
  }, timeout: const Timeout(Duration(minutes: 12)));

  test('packageSplit=true + Supabase + auth: Auth becomes its own package too, '
      "and both it and the split feature cross into core for Supabase's client, "
      'and the workspace analyzes cleanly', () async {
    const projectName = 'neat_pkgsplit_supabase_test';
    final logs = <String>[];
    final pkgs = <PubPackage>[
      _dep('hooks_riverpod', '3.3.1'),
      _dep('flutter_hooks', '0.21.3+1'),
      _dep('riverpod_annotation', '4.0.2'),
      _dep('json_annotation', '4.11.0'),
      _dep('freezed_annotation', '3.1.0'),
      _dep('supabase_flutter', '2.14.1'),
      _dep('go_router', '17.2.3'),
      _dev('riverpod_generator', '4.0.3'),
      _dev('riverpod_lint', '3.1.3'),
      _dev('json_serializable', '6.13.0'),
      _dev('build_runner', '2.15.0'),
      _dev('freezed', '3.2.5'),
      _dev('go_router_builder', '4.3.0'), // required by generateAuth
    ];

    final identity = IdentityState(
      name: projectName,
      organization: 'com.neat.test',
      projectPath: tempRoot.path,
      description: 'NEAT packageSplit + Supabase + auth integration test',
      targetPlatforms: const ['macos'],
    );
    const architecture = ArchitectureState(
      packageSplit: true,
      generateAuth: true,
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
      fail('Generation threw:\n$e\n\n--- logs ---\n${logs.join('\n')}');
    }

    final projectDir = Directory('${tempRoot.path}/$projectName');
    final coreRoot = '${projectDir.path}/packages/core';
    final featureRoot = '${projectDir.path}/packages/home';
    final authRoot = '${projectDir.path}/packages/auth';
    String read(String p) => File(p).readAsStringSync();

    // supabase_provider.dart lives in core...
    expect(
      read('$coreRoot/lib/core/network/supabase_provider.dart'),
      contains('SupabaseClient supabaseClient(Ref ref)'),
    );
    // ...never duplicated in the app.
    expect(
      File(
        '${projectDir.path}/lib/core/network/supabase_provider.dart',
      ).existsSync(),
      isFalse,
    );

    // Auth is its own package now (screens included) — nothing left under
    // lib/features/auth/.
    expect(File('${projectDir.path}/lib/features/auth').existsSync(), isFalse);
    final authImpl = read(
      '$authRoot/lib/data/repositories/auth_repository_impl.dart',
    );
    expect(
      authImpl,
      contains("import '../../domain/repositories/i_auth_repository.dart';"),
      reason:
          'same-package self-reference — a plain relative import, like any other split feature',
    );
    // ...and its Result/Failure imports redirect to core, same as any
    // other split feature (not duplicated the way wesioo's standalone
    // authentication package does).
    expect(
      authImpl,
      contains("import 'package:core/core/error/failure.dart';"),
    );
    expect(
      authImpl,
      contains("import 'package:core/core/result/result.dart';"),
    );
    final authProvider = read(
      '$authRoot/lib/presentation/providers/auth_provider.dart',
    );
    expect(
      authProvider,
      contains("import 'package:core/core/network/supabase_provider.dart';"),
    );
    final authPubspec = read('$authRoot/pubspec.yaml');
    expect(authPubspec, contains('core:\n    path: ../core'));

    // router_notifier.dart (app-level) crosses into the auth package for
    // AuthController, never the reverse.
    final routerNotifier = read(
      '${projectDir.path}/lib/core/router/router_notifier.dart',
    );
    expect(
      routerNotifier,
      contains(
        "import 'package:auth/presentation/providers/auth_provider.dart';",
      ),
    );

    // The split feature's own repository-providers DI graph crosses into
    // core for the same client, never the app.
    final di = read(
      '$featureRoot/lib/data/repositories/home_repository_providers.dart',
    );
    expect(
      di,
      contains("import 'package:core/core/network/supabase_provider.dart';"),
    );
    expect(
      di,
      isNot(contains('package:$projectName/')),
      reason: 'a split feature package must never import from the app',
    );

    // The whole workspace analyzes cleanly.
    final analyze = await Process.run('flutter', [
      'analyze',
      '--no-pub',
    ], workingDirectory: projectDir.path);
    final out = '${analyze.stdout}\n${analyze.stderr}';
    final errorLines = const LineSplitter()
        .convert(out)
        .where(
          (l) =>
              (l.contains(' error •') || l.contains(' warning •')) &&
              !l.contains('• build/'),
        )
        .toList();
    expect(
      errorLines,
      isEmpty,
      reason:
          'flutter analyze reported errors:\n${errorLines.join('\n')}\n\n'
          '--- full analyze output ---\n$out',
    );
  }, timeout: const Timeout(Duration(minutes: 12)));

  test(
    'packageSplit=true + Firebase + auth + realtime + storage: everything '
    'crosses into core for the client, and the workspace analyzes cleanly',
    () async {
      const projectName = 'neat_pkgsplit_firebase_test';
      final logs = <String>[];

      final config = File('${tempRoot.path}/pkgsplit_firebase_config.json')
        ..writeAsStringSync('''{
  "apiKey": "AIzaTestKey123",
  "appId": "1:1234567890:web:abcdef",
  "messagingSenderId": "1234567890",
  "projectId": "neat-demo",
  "authDomain": "neat-demo.firebaseapp.com",
  "storageBucket": "neat-demo.appspot.com"
}''');

      final pkgs = <PubPackage>[
        _dep('hooks_riverpod', '3.3.1'),
        _dep('flutter_hooks', '0.21.3+1'),
        _dep('riverpod_annotation', '4.0.2'),
        _dep('json_annotation', '4.11.0'),
        _dep('freezed_annotation', '3.1.0'),
        _dep('cloud_firestore', '5.6.0'),
        _dep('go_router', '17.2.3'),
        _dev('riverpod_generator', '4.0.3'),
        _dev('riverpod_lint', '3.1.3'),
        _dev('json_serializable', '6.13.0'),
        _dev('build_runner', '2.15.0'),
        _dev('freezed', '3.2.5'),
        _dev('go_router_builder', '4.3.0'), // required by generateAuth
      ];

      final identity = IdentityState(
        name: projectName,
        organization: 'com.neat.test',
        projectPath: tempRoot.path,
        description:
            'NEAT packageSplit + Firebase + auth/realtime/storage integration test',
        targetPlatforms: const ['macos'],
      );
      final architecture = ArchitectureState(
        packageSplit: true,
        generateAuth: true,
        generateRealtime: true,
        generateStorage: true,
        firebaseConfigPath: config.path,
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
        fail('Generation threw:\n$e\n\n--- logs ---\n${logs.join('\n')}');
      }

      final projectDir = Directory('${tempRoot.path}/$projectName');
      final coreRoot = '${projectDir.path}/packages/core';
      final featureRoot = '${projectDir.path}/packages/home';
      final authRoot = '${projectDir.path}/packages/auth';
      String read(String p) => File(p).readAsStringSync();

      // firebase_provider.dart lives in core, with auth + storage singletons
      // (hasAuth/hasStorage threaded through)...
      final coreFp = read('$coreRoot/lib/core/network/firebase_provider.dart');
      expect(coreFp, contains('FirebaseFirestore firestore(Ref ref)'));
      expect(coreFp, contains('FirebaseAuth firebaseAuth(Ref ref)'));
      expect(coreFp, contains('FirebaseStorage firebaseStorage(Ref ref)'));
      // ...never duplicated in the app.
      expect(
        File(
          '${projectDir.path}/lib/core/network/firebase_provider.dart',
        ).existsSync(),
        isFalse,
      );

      // Auth is its own package now (screens included), redirecting to core
      // for Result/Failure/the client.
      expect(
        File('${projectDir.path}/lib/features/auth').existsSync(),
        isFalse,
      );
      final authImpl = read(
        '$authRoot/lib/data/repositories/auth_repository_impl.dart',
      );
      expect(
        authImpl,
        contains("import 'package:core/core/result/result.dart';"),
      );
      final authProvider = read(
        '$authRoot/lib/presentation/providers/auth_provider.dart',
      );
      expect(
        authProvider,
        contains("import 'package:core/core/network/firebase_provider.dart';"),
      );

      // Storage stays app-level too (nothing NEAT generates imports it
      // cross-package), but its client-provider import redirects to core.
      final storage = read(
        '${projectDir.path}/lib/core/storage/storage_service.dart',
      );
      expect(
        storage,
        contains("import 'package:core/core/network/firebase_provider.dart';"),
      );

      // The split feature crosses into core for Firestore + realtime works.
      final src = read('$featureRoot/lib/data/sources/home_api_source.dart');
      expect(src, contains('Stream<List<HomeModel>> watchAll()'));
      final di = read(
        '$featureRoot/lib/data/repositories/home_repository_providers.dart',
      );
      expect(
        di,
        contains("import 'package:core/core/network/firebase_provider.dart';"),
      );
      expect(
        di,
        isNot(contains('package:$projectName/')),
        reason: 'a split feature package must never import from the app',
      );

      // The whole workspace analyzes cleanly.
      final analyze = await Process.run('flutter', [
        'analyze',
        '--no-pub',
      ], workingDirectory: projectDir.path);
      final out = '${analyze.stdout}\n${analyze.stderr}';
      final errorLines = const LineSplitter()
          .convert(out)
          .where(
            (l) =>
                (l.contains(' error •') || l.contains(' warning •')) &&
                !l.contains('• build/'),
          )
          .toList();
      expect(
        errorLines,
        isEmpty,
        reason:
            'flutter analyze reported errors:\n${errorLines.join('\n')}\n\n'
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
        fail(
          'Offline-first generation threw:\n$e\n\n--- logs ---\n${logs.join('\n')}',
        );
      }

      final projectDir = Directory('${tempRoot.path}/$projectName');
      final pkg = '${projectName}_database';

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

      // Not a web target — the web-only DriftWebOptions branch and its setup
      // doc shouldn't appear (see the dedicated web test below).
      final dbSource = File(
        '${projectDir.path}/packages/$pkg/lib/src/database.dart',
      ).readAsStringSync();
      expect(dbSource, isNot(contains('kIsWeb')));
      expect(dbSource, isNot(contains('DriftWebOptions')));
      expect(
        File('${projectDir.path}/docs/DRIFT_WEB_SETUP.md').existsSync(),
        isFalse,
      );

      // Offline-first bricks landed in the app.
      expect(
        File(
          '${projectDir.path}/lib/core/network/network_info.dart',
        ).existsSync(),
        isTrue,
        reason: 'core/network/network_info.dart missing',
      );

      // Dio provider + logging interceptor (dio variant) make the API source wirable.
      final dioProvider = File(
        '${projectDir.path}/lib/core/network/dio_provider.dart',
      );
      expect(
        dioProvider.existsSync(),
        isTrue,
        reason: 'core/network/dio_provider.dart missing',
      );
      expect(dioProvider.readAsStringSync(), contains('LoggerInterceptor()'));
      expect(
        File(
          '${projectDir.path}/lib/core/observers/logger_interceptor.dart',
        ).existsSync(),
        isTrue,
        reason: 'logger_interceptor.dart missing',
      );

      // Repository-level DI (data/): dio-backed source + local source + repo.
      // The shared Drift db + NetworkInfo singletons live in core, not here, so
      // the feature DI references them instead of redeclaring them.
      final di = File(
        '${projectDir.path}/lib/features/user_profile/data/repositories/'
        'user_profile_repository_providers.dart',
      ).readAsStringSync();
      expect(di, contains('UserProfileApiSource(ref.watch(dioProvider))'));
      expect(di, contains('ref.watch(appDatabaseProvider)'));
      expect(di, contains('ref.watch(networkInfoProvider)'));
      expect(
        di,
        contains(
          "import 'package:$projectName/core/providers/infrastructure_providers.dart'",
        ),
      );
      // The feature DI must NOT redeclare the shared singletons.
      expect(di, isNot(contains('AppDatabase appDatabase(Ref ref)')));
      expect(di, isNot(contains('NetworkInfo networkInfo(Ref ref)')));

      // Shared infrastructure providers exist once, in core.
      final infra = File(
        '${projectDir.path}/lib/core/providers/infrastructure_providers.dart',
      );
      expect(
        infra.existsSync(),
        isTrue,
        reason: 'core infrastructure_providers.dart missing',
      );
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
      final rootPubspec = File(
        '${projectDir.path}/pubspec.yaml',
      ).readAsStringSync();
      expect(rootPubspec, contains('workspace:'));
      expect(rootPubspec, contains('packages/$pkg'));
      expect(rootPubspec, contains('connectivity_plus'));
      final pkgPubspec = File(
        '${projectDir.path}/packages/$pkg/pubspec.yaml',
      ).readAsStringSync();
      expect(pkgPubspec, contains('resolution: workspace'));

      // The whole workspace analyzes without errors.
      final analyze = await Process.run('flutter', [
        'analyze',
        '--no-pub',
      ], workingDirectory: projectDir.path);
      final out = '${analyze.stdout}\n${analyze.stderr}';
      expect(
        RegExp(r'(\d+ issues? found|No issues found)').hasMatch(out),
        isTrue,
        reason: 'flutter analyze did not run as expected:\n$out',
      );
      final errorLines = const LineSplitter()
          .convert(out)
          .where(
            (l) =>
                (l.contains(' error •') || l.contains(' warning •')) &&
                !l.contains('• build/'),
          )
          .toList();
      expect(
        errorLines,
        isEmpty,
        reason:
            'workspace analyze reported errors:\n${errorLines.join('\n')}\n\n$out',
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
      final pkg = '${projectName}_database';

      // SyncService brick + Outbox table generated.
      expect(
        File('${projectDir.path}/lib/core/sync/sync_service.dart').existsSync(),
        isTrue,
        reason: 'core/sync/sync_service.dart missing',
      );
      final db = File(
        '${projectDir.path}/packages/$pkg/lib/src/database.dart',
      ).readAsStringSync();
      expect(
        db,
        isNot(contains('class OutboxEntries')),
        reason: 'the table definition lives in its own file, not database.dart',
      );
      expect(db, contains('OutboxDao'));
      expect(
        db,
        isNot(contains('enqueueOutbox')),
        reason: 'Outbox DAO methods live in their own file, not database.dart',
      );

      // Outbox's own dedicated table file (see LocalStorageTemplates.outboxTableFile).
      final outboxTable = File(
        '${projectDir.path}/packages/$pkg/lib/src/table/outbox_table.dart',
      ).readAsStringSync();
      expect(outboxTable, contains('class OutboxEntries extends Table'));

      // Outbox's own dedicated DAO file (see LocalStorageTemplates.outboxDaoFile).
      final outboxDao = File(
        '${projectDir.path}/packages/$pkg/lib/src/dao/outbox_dao.dart',
      ).readAsStringSync();
      expect(
        outboxDao,
        contains('class OutboxDao extends DatabaseAccessor<AppDatabase>'),
      );
      expect(outboxDao, contains('enqueueOutbox'));

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

      // SyncService is auto-wired in the repository-level DI graph (data/),
      // replaying via the API source.
      final di = File(
        '${projectDir.path}/lib/features/user_profile/data/repositories/'
        'user_profile_repository_providers.dart',
      ).readAsStringSync();
      expect(di, contains('SyncService userProfileSync(Ref ref)'));
      expect(di, contains('..start()'));
      expect(di, contains('api.add(UserProfileModel.fromJson(data))'));

      // Outbox retry cap + offline usage guide.
      final syncSrc = File(
        '${projectDir.path}/lib/core/sync/sync_service.dart',
      ).readAsStringSync();
      expect(syncSrc, contains('maxRetries'));
      final doc = File('${projectDir.path}/docs/OFFLINE.md');
      expect(doc.existsSync(), isTrue, reason: 'docs/OFFLINE.md missing');
      expect(doc.readAsStringSync(), contains('Outbox'));

      // The whole workspace analyzes without errors.
      final analyze = await Process.run('flutter', [
        'analyze',
        '--no-pub',
      ], workingDirectory: projectDir.path);
      final out = '${analyze.stdout}\n${analyze.stderr}';
      expect(
        RegExp(r'(\d+ issues? found|No issues found)').hasMatch(out),
        isTrue,
        reason: 'flutter analyze did not run as expected:\n$out',
      );
      final errorLines = const LineSplitter()
          .convert(out)
          .where(
            (l) =>
                (l.contains(' error •') || l.contains(' warning •')) &&
                !l.contains('• build/'),
          )
          .toList();
      expect(
        errorLines,
        isEmpty,
        reason:
            'sync workspace analyze reported errors:\n${errorLines.join('\n')}\n\n$out',
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
        fail(
          'UI-package generation threw:\n$e\n\n--- logs ---\n${logs.join('\n')}',
        );
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
        File(
          '${projectDir.path}/lib/core/theme/theme_mode_controller.dart',
        ).existsSync(),
        isTrue,
        reason: 'theme_mode_controller stays in the app',
      );

      // Barrel exports + app imports the package.
      final barrel = File(
        '${projectDir.path}/packages/$uiPkg/lib/$uiPkg.dart',
      ).readAsStringSync();
      expect(barrel, contains("export 'core/theme/app_theme.dart';"));
      expect(barrel, contains("export 'components/app_button.dart';"));
      expect(barrel, contains("export 'widgets/asset_images.dart';"));
      expect(barrel, contains("export 'gen/assets.dart';"));
      final appDart = File(
        '${projectDir.path}/lib/app.dart',
      ).readAsStringSync();
      expect(appDart, contains("import 'package:$uiPkg/$uiPkg.dart';"));

      // spider: typed asset paths (config + generated Assets class).
      expect(
        File('${projectDir.path}/packages/$uiPkg/spider.yaml').existsSync(),
        isTrue,
      );
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
      final uiPubspec = File(
        '${projectDir.path}/packages/$uiPkg/pubspec.yaml',
      ).readAsStringSync();
      expect(uiPubspec, contains('flutter_svg'));
      expect(uiPubspec, contains('assets/'));
      expect(uiPubspec, contains('spider'));

      // Root workspace lists the UI package + widgetbook; widgetbook depends on it.
      final rootPubspec = File(
        '${projectDir.path}/pubspec.yaml',
      ).readAsStringSync();
      expect(rootPubspec, contains('packages/$uiPkg'));
      expect(rootPubspec, contains('- widgetbook'));
      final wbPubspec = File(
        '${projectDir.path}/widgetbook/pubspec.yaml',
      ).readAsStringSync();
      expect(wbPubspec, contains('path: ../packages/$uiPkg'));

      // Whole workspace analyzes without errors or warnings.
      final analyze = await Process.run('flutter', [
        'analyze',
        '--no-pub',
      ], workingDirectory: projectDir.path);
      final out = '${analyze.stdout}\n${analyze.stderr}';
      expect(
        RegExp(r'(\d+ issues? found|No issues found)').hasMatch(out),
        isTrue,
        reason: 'flutter analyze did not run as expected:\n$out',
      );
      final errorLines = const LineSplitter()
          .convert(out)
          .where(
            (l) =>
                (l.contains(' error •') || l.contains(' warning •')) &&
                !l.contains('• build/'),
          )
          .toList();
      expect(
        errorLines,
        isEmpty,
        reason:
            'UI-package workspace analyze reported issues:\n${errorLines.join('\n')}\n\n$out',
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
      const theme = ThemeEngineState(approach: ThemeApproach.flexColorScheme);

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
        fail(
          'Flex + UI-package generation threw:\n$e\n\n--- logs ---\n${logs.join('\n')}',
        );
      }

      final projectDir = Directory('${tempRoot.path}/$projectName');

      // Flex theme relocated into the UI package + flex dep in the package.
      final themeFile = File(
        '${projectDir.path}/packages/$uiPkg/lib/core/theme/app_theme.dart',
      );
      expect(
        themeFile.existsSync(),
        isTrue,
        reason: 'UI package app_theme.dart missing',
      );
      expect(themeFile.readAsStringSync(), contains('FlexThemeData'));
      final uiPubspec = File(
        '${projectDir.path}/packages/$uiPkg/pubspec.yaml',
      ).readAsStringSync();
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
      final analyze = await Process.run('flutter', [
        'analyze',
        '--no-pub',
      ], workingDirectory: projectDir.path);
      final out = '${analyze.stdout}\n${analyze.stderr}';
      expect(
        RegExp(r'(\d+ issues? found|No issues found)').hasMatch(out),
        isTrue,
        reason: 'flutter analyze did not run as expected:\n$out',
      );
      final errorLines = const LineSplitter()
          .convert(out)
          .where(
            (l) =>
                (l.contains(' error •') || l.contains(' warning •')) &&
                !l.contains('• build/'),
          )
          .toList();
      expect(
        errorLines,
        isEmpty,
        reason:
            'flex + UI-package workspace analyze reported issues:\n'
            '${errorLines.join('\n')}\n\n$out',
      );
    },
    timeout: const Timeout(Duration(minutes: 12)),
  );

  test(
    'FlexColorScheme playground paste: a full file with an unrelated wrapper '
    'class/field shape still extracts AppTheme.light/.dark correctly',
    () async {
      const projectName = 'neat_flex_paste_test';
      final logs = <String>[];

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
        description: 'NEAT FlexColorScheme playground-paste integration test',
        targetPlatforms: const ['macos'],
      );

      const architecture = ArchitectureState(firstFeatureName: 'user_profile');

      // A realistic playground paste: a full file, its own (irrelevant) import
      // list, and a wrapper class/field naming that has nothing to do with
      // NEAT's own `AppTheme.light`/`.dark` contract — proving extraction is
      // shape-agnostic (only the FlexThemeData.light(...)/.dark(...) call
      // expressions themselves are pulled out; everything else is ignored).
      const pastedCode = '''
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';

abstract final class Palette {
  static ThemeData light = FlexThemeData.light(
    scheme: FlexScheme.mandyRed,
    subThemesData: const FlexSubThemesData(
      interactionEffects: true,
      blendOnLevel: 20,
    ),
    visualDensity: FlexColorScheme.comfortablePlatformDensity,
    useMaterial3: true,
  );

  static ThemeData dark = FlexThemeData.dark(
    scheme: FlexScheme.mandyRed,
    subThemesData: const FlexSubThemesData(
      interactionEffects: true,
      blendOnLevel: 30,
    ),
    visualDensity: FlexColorScheme.comfortablePlatformDensity,
    useMaterial3: true,
  );
}
''';

      const theme = ThemeEngineState(
        approach: ThemeApproach.flexColorScheme,
        flexColorSchemeCode: pastedCode,
        extractUiPackage: false,
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
        fail(
          'Flex playground-paste generation threw:\n$e\n\n--- logs ---\n${logs.join('\n')}',
        );
      }

      final projectDir = Directory('${tempRoot.path}/$projectName');
      final themeSrc = File(
        '${projectDir.path}/lib/core/theme/app_theme.dart',
      ).readAsStringSync();

      // NEAT's own AppTheme class shape, not the pasted wrapper's — this is
      // what app.dart actually references (AppTheme.light / AppTheme.dark).
      expect(themeSrc, contains('class AppTheme {'));
      expect(themeSrc, isNot(contains('class Palette')));
      expect(themeSrc, contains('static ThemeData get light =>'));
      expect(themeSrc, contains('static ThemeData get dark =>'));

      // Both extracted calls carry NEAT's own extension + text theme wiring.
      expect(themeSrc, contains('FlexThemeData.light('));
      expect(themeSrc, contains('FlexThemeData.dark('));
      expect(themeSrc, contains('scheme: FlexScheme.mandyRed'));
      expect(
        'AppColors.light'.allMatches(themeSrc).length,
        greaterThanOrEqualTo(2),
        reason:
            'both light and dark configs should carry the AppColors extension',
      );

      // The whole workspace analyzes without errors or warnings.
      final analyze = await Process.run('flutter', [
        'analyze',
        '--no-pub',
      ], workingDirectory: projectDir.path);
      final out = '${analyze.stdout}\n${analyze.stderr}';
      expect(
        RegExp(r'(\d+ issues? found|No issues found)').hasMatch(out),
        isTrue,
        reason: 'flutter analyze did not run as expected:\n$out',
      );
      final errorLines = const LineSplitter()
          .convert(out)
          .where(
            (l) =>
                (l.contains(' error •') || l.contains(' warning •')) &&
                !l.contains('• build/'),
          )
          .toList();
      expect(
        errorLines,
        isEmpty,
        reason:
            'flex playground-paste workspace analyze reported issues:\n'
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
      const architecture =
          ArchitectureState(); // firstFeatureName defaults to 'home'

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
      expect(
        project,
        isNotNull,
        reason: '.neat.json should make the project loadable',
      );
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
        File(
          '${projectDir.path}/lib/features/orders/presentation/pages/orders_page.dart',
        ).existsSync(),
        isTrue,
      );
      expect(
        File(
          '${projectDir.path}/lib/features/orders/data/sources/orders_api_source.dart',
        ).existsSync(),
        isTrue,
      );
      expect(
        File(
          '${projectDir.path}/lib/features/home/presentation/pages/home_page.dart',
        ).existsSync(),
        isTrue,
        reason: 'existing feature must be left intact',
      );

      // 3b. The new feature is wired into the router + AppRoutePath.
      final routesDart = File(
        '${projectDir.path}/lib/core/router/routes.dart',
      ).readAsStringSync();
      expect(routesDart, contains('AppRoutePath.orders'));
      final routePath = File(
        '${projectDir.path}/lib/core/constants/app_route_path.dart',
      ).readAsStringSync();
      expect(routePath, contains("static const String orders = '/orders';"));

      // 4. Scanning now sees both features.
      expect(
        await const ProjectLoader()
            .load(projectDir.path)
            .then((p) => p!.features),
        ['home', 'orders'],
      );

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
      final analyze = await Process.run('flutter', [
        'analyze',
        '--no-pub',
      ], workingDirectory: projectDir.path);
      final out = '${analyze.stdout}\n${analyze.stderr}';
      expect(
        RegExp(r'(\d+ issues? found|No issues found)').hasMatch(out),
        isTrue,
        reason: 'flutter analyze did not run as expected:\n$out',
      );
      final errorLines = const LineSplitter()
          .convert(out)
          .where(
            (l) =>
                (l.contains(' error •') || l.contains(' warning •')) &&
                !l.contains('• build/'),
          )
          .toList();
      expect(
        errorLines,
        isEmpty,
        reason:
            'feature-gen project analyze reported issues:\n${errorLines.join('\n')}\n\n$out',
      );
    },
    timeout: const Timeout(Duration(minutes: 12)),
  );

  test(
    'feature generation on a Cubit project: the Workshop reads useCubit from '
    'the contract, not a hardcoded false — the 2nd feature is a Cubit too',
    () async {
      const projectName = 'neat_featgen_cubit';
      final logs = <String>[];

      final pkgs = <PubPackage>[
        _dep('flutter_bloc', '9.1.1'),
        _dep('dio', '5.9.2'),
        _dep('go_router', '17.2.3'),
      ];

      final identity = IdentityState(
        name: projectName,
        organization: 'com.neat.test',
        projectPath: tempRoot.path,
        description: 'NEAT Cubit feature-gen integration test',
        targetPlatforms: const ['macos'],
      );
      const architecture = ArchitectureState(useCubit: true);

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
        fail('Base Cubit generation threw:\n$e');
      }

      final projectDir = Directory('${tempRoot.path}/$projectName');
      final project = await const ProjectLoader().load(projectDir.path);
      expect(project!.contract.useCubit, isTrue);

      await const GenerateFeatureUsecase().execute(
        project: project,
        options: const FeatureGenOptions(name: 'orders'),
        onLog: logs.add,
      );

      expect(
        File(
          '${projectDir.path}/lib/features/orders/presentation/cubit/orders_cubit.dart',
        ).existsSync(),
        isTrue,
        reason:
            'the 2nd feature must match the project\'s Cubit choice, not default to full Bloc',
      );
      expect(
        Directory(
          '${projectDir.path}/lib/features/orders/presentation/bloc',
        ).existsSync(),
        isFalse,
      );

      final analyze = await Process.run('flutter', [
        'analyze',
        '--no-pub',
      ], workingDirectory: projectDir.path);
      final out = '${analyze.stdout}\n${analyze.stderr}';
      final errorLines = const LineSplitter()
          .convert(out)
          .where(
            (l) =>
                (l.contains(' error •') || l.contains(' warning •')) &&
                !l.contains('• build/'),
          )
          .toList();
      expect(
        errorLines,
        isEmpty,
        reason:
            'Cubit feature-gen project analyze reported issues:\n${errorLines.join('\n')}\n\n$out',
      );
    },
    timeout: const Timeout(Duration(minutes: 12)),
  );

  test('Custom Endpoints (§7 Phase 2): a feature with a request+response '
      'endpoint, a response-only endpoint, and a bodyless endpoint — typed '
      'chopper methods, per-endpoint Models/UseCases, no entity/repository, '
      'decoder registry entries, analyzes cleanly', () async {
    const projectName = 'neat_custom_endpoints_test';
    final logs = <String>[];

    final pkgs = <PubPackage>[
      _dep('hooks_riverpod', '3.3.1'),
      _dep('flutter_hooks', '0.21.3+1'),
      _dep('riverpod_annotation', '4.0.2'),
      _dep('chopper', '8.6.0'),
      _dep('go_router', '17.2.3'),
      _dev('riverpod_generator', '4.0.3'),
      _dev('chopper_generator', '8.6.2'),
      _dev('build_runner', '2.15.0'),
    ];

    final identity = IdentityState(
      name: projectName,
      organization: 'com.neat.test',
      projectPath: tempRoot.path,
      description: 'NEAT Custom Endpoints integration test',
      targetPlatforms: const ['macos'],
    );
    // No first feature — this test adds the custom-endpoints feature via
    // the Workshop, same as a real user would.
    const architecture = ArchitectureState(generateFirstFeature: false);

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
      fail('Base generation threw:\n$e\n\n--- logs ---\n${logs.join('\n')}');
    }

    final projectDir = Directory('${tempRoot.path}/$projectName');
    final project = await const ProjectLoader().load(projectDir.path);
    expect(project, isNotNull);
    expect(project!.contract.httpClient, 'chopper');

    const inferencer = JsonEntityInferencer();
    final loginReq = inferencer.infer(
      '{"email": "a@b.com", "password": "secret"}',
      requireId: false,
    );
    final loginRes = inferencer.infer(
      '{"token": "abc", "expiresAt": "2024-01-31T10:00:00Z"}',
      requireId: false,
    );
    final meRes = inferencer.infer(
      '{"name": "Ada", "email": "a@b.com"}',
      requireId: false,
    );

    final options = FeatureGenOptions(
      name: 'auth',
      useCustomEndpoints: true,
      endpoints: [
        EndpointSpec(
          name: 'login',
          method: HttpMethod.post,
          path: '/auth/login',
          requestFields: loginReq.fields,
          responseFields: loginRes.fields,
        ),
        EndpointSpec(
          name: 'me',
          path: '/auth/me',
          responseFields: meRes.fields,
        ),
        const EndpointSpec(
          name: 'logout',
          method: HttpMethod.post,
          path: '/auth/logout',
        ),
      ],
    );

    try {
      await const GenerateFeatureUsecase().execute(
        project: project,
        options: options,
        onLog: logs.add,
      );
    } catch (e) {
      fail(
        'Custom Endpoints generation threw:\n$e\n\n--- logs ---\n${logs.join('\n')}',
      );
    }

    String read(String p) => File(p).readAsStringSync();
    final featureRoot = '${projectDir.path}/lib/features/auth';

    // No entity, no repository interface, no local source — there's no
    // single entity to abstract over.
    expect(Directory('$featureRoot/domain/entities').existsSync(), isFalse);
    expect(Directory('$featureRoot/domain/repositories').existsSync(), isFalse);
    expect(
      File('$featureRoot/data/sources/auth_local_source.dart').existsSync(),
      isFalse,
    );

    // One UseCase per endpoint.
    expect(
      File('$featureRoot/domain/usecases/login_usecase.dart').existsSync(),
      isTrue,
    );
    expect(
      File('$featureRoot/domain/usecases/me_usecase.dart').existsSync(),
      isTrue,
    );
    expect(
      File('$featureRoot/domain/usecases/logout_usecase.dart').existsSync(),
      isTrue,
    );
    final loginUsecase = read(
      '$featureRoot/domain/usecases/login_usecase.dart',
    );
    expect(
      loginUsecase,
      contains(
        'class LoginUsecase extends UseCase<LoginRequestModel, LoginResponseModel>',
      ),
    );
    expect(loginUsecase, contains('unwrapChopperResponse'));
    final logoutUsecase = read(
      '$featureRoot/domain/usecases/logout_usecase.dart',
    );
    expect(
      logoutUsecase,
      contains('class LogoutUsecase extends NoParamsUseCase<Unit>'),
    );
    final meUsecase = read('$featureRoot/domain/usecases/me_usecase.dart');
    expect(
      meUsecase,
      contains('class MeUsecase extends NoParamsUseCase<MeResponseModel>'),
    );

    // Models: login has both request+response, me has response-only, logout has neither.
    expect(
      File('$featureRoot/data/models/login_model.dart').existsSync(),
      isTrue,
    );
    final loginModel = read('$featureRoot/data/models/login_model.dart');
    expect(loginModel, contains('class LoginRequestModel'));
    expect(loginModel, contains('class LoginResponseModel'));
    expect(File('$featureRoot/data/models/me_model.dart').existsSync(), isTrue);
    final meModel = read('$featureRoot/data/models/me_model.dart');
    expect(meModel, isNot(contains('class MeRequestModel')));
    expect(meModel, contains('class MeResponseModel'));
    expect(
      File('$featureRoot/data/models/logout_model.dart').existsSync(),
      isFalse,
    );

    // One shared API source, N typed methods, each with its own full path
    // (no shared @ChopperApi baseUrl — arbitrary endpoints share no prefix).
    final apiSource = read('$featureRoot/data/sources/auth_api_source.dart');
    expect(apiSource, contains("@ChopperApi(baseUrl: '')"));
    expect(apiSource, contains("@POST(path: '/auth/login')"));
    expect(
      apiSource,
      contains(
        'Future<Response<LoginResponseModel>> login(@Body() LoginRequestModel body);',
      ),
    );
    expect(apiSource, contains("@GET(path: '/auth/me')"));
    expect(apiSource, contains('Future<Response<MeResponseModel>> me();'));
    expect(apiSource, contains("@POST(path: '/auth/logout')"));
    expect(apiSource, contains('Future<Response<dynamic>> logout();'));

    // Decoder registry: response models only (login + me), not logout
    // (no response body) and not request models (never decoded).
    final converter = read(
      '${projectDir.path}/lib/core/network/chopper_model_converter.dart',
    );
    expect(
      converter,
      contains(
        'LoginResponseModel: (json) => LoginResponseModel.fromJson(json)',
      ),
    );
    expect(
      converter,
      contains('MeResponseModel: (json) => MeResponseModel.fromJson(json)'),
    );
    expect(converter, isNot(contains('LogoutResponseModel')));

    // Presentation still gets exactly one placeholder page (no CRUD DI
    // graph — dataList is always false here).
    expect(
      File('$featureRoot/presentation/pages/auth_page.dart').existsSync(),
      isTrue,
    );
    expect(
      Directory('$featureRoot/presentation/providers').existsSync() ||
          Directory('$featureRoot/presentation/cubit').existsSync() ||
          Directory('$featureRoot/presentation/bloc').existsSync(),
      isTrue,
    );
    expect(
      File(
        '$featureRoot/presentation/providers/auth_usecase_providers.dart',
      ).existsSync(),
      isFalse,
      reason: 'no repository exists for a usecase-level DI graph to wire',
    );

    // The whole workspace analyzes cleanly (chopper_generator's codegen
    // for auth_api_source.chopper.dart included).
    final analyze = await Process.run('flutter', [
      'analyze',
      '--no-pub',
    ], workingDirectory: projectDir.path);
    final out = '${analyze.stdout}\n${analyze.stderr}';
    expect(
      RegExp(r'(\d+ issues? found|No issues found)').hasMatch(out),
      isTrue,
      reason: 'flutter analyze did not run as expected:\n$out',
    );
    final errorLines = const LineSplitter()
        .convert(out)
        .where(
          (l) =>
              (l.contains(' error •') || l.contains(' warning •')) &&
              !l.contains('• build/'),
        )
        .toList();
    expect(
      errorLines,
      isEmpty,
      reason:
          'Custom Endpoints workspace analyze reported issues:\n${errorLines.join('\n')}\n\n$out',
    );
  }, timeout: const Timeout(Duration(minutes: 12)));

  test(
    'Customize endpoints (Entity + CRUD, chopper): each of the 5 fixed '
    'operations gets its own method + path instead of sharing one derived '
    'base (dummyjson-style: POST /recipes/add to create), and the workspace '
    'analyzes cleanly',
    () async {
      const projectName = 'neat_customize_endpoints_test';
      final logs = <String>[];

      final pkgs = <PubPackage>[
        _dep('hooks_riverpod', '3.3.1'),
        _dep('flutter_hooks', '0.21.3+1'),
        _dep('riverpod_annotation', '4.0.2'),
        _dep('json_annotation', '4.11.0'),
        _dep('freezed_annotation', '3.1.0'),
        _dep('chopper', '8.6.0'),
        _dep('go_router', '17.2.3'),
        _dev('riverpod_generator', '4.0.3'),
        _dev('riverpod_lint', '3.1.3'),
        _dev('json_serializable', '6.13.0'),
        _dev('build_runner', '2.15.0'),
        _dev('freezed', '3.2.5'),
        _dev('chopper_generator', '8.6.2'),
      ];

      final identity = IdentityState(
        name: projectName,
        organization: 'com.neat.test',
        projectPath: tempRoot.path,
        description: 'NEAT customize endpoints integration test',
        targetPlatforms: const ['macos'],
      );
      // No first feature — added via the Workshop, same as a real user would.
      const architecture = ArchitectureState(generateFirstFeature: false);

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
        fail('Base generation threw:\n$e\n\n--- logs ---\n${logs.join('\n')}');
      }

      final projectDir = Directory('${tempRoot.path}/$projectName');
      final project = await const ProjectLoader().load(projectDir.path);
      expect(project, isNotNull);
      expect(project!.contract.httpClient, 'chopper');

      final options = FeatureGenOptions(
        name: 'recipe',
        apiPath: '/recipes',
        customizeEndpoints: true,
        endpointOverrides: CrudEndpointOverrides.defaultsFor('/recipes').copyWith(
          createPath: '/recipes/add',
          createName: 'createRecipe',
          updateMethod: HttpMethod.patch,
        ),
      );

      try {
        await const GenerateFeatureUsecase().execute(
          project: project,
          options: options,
          onLog: logs.add,
        );
      } catch (e) {
        fail(
          'Customize endpoints generation threw:\n$e\n\n--- logs ---\n${logs.join('\n')}',
        );
      }

      final apiSource = File(
        '${projectDir.path}/lib/features/recipe/data/sources/recipe_api_source.dart',
      ).readAsStringSync();
      expect(apiSource, contains("@ChopperApi(baseUrl: '')"));
      expect(apiSource, contains("@GET(path: '/recipes')"));
      expect(apiSource, contains("@GET(path: '/recipes/{id}')"));
      expect(apiSource, contains("@POST(path: '/recipes/add')"));
      expect(apiSource, contains("@PATCH(path: '/recipes/{id}')"));
      expect(apiSource, contains("@DELETE(path: '/recipes/{id}')"));
      // The one overridden method name replaces the fixed 'add' — the other
      // 4 stay their fixed default names since only createName was set.
      expect(apiSource, contains('Future<Response<RecipeModel>> createRecipe('));
      expect(apiSource, isNot(contains('Future<Response<RecipeModel>> add(')));
      expect(apiSource, contains('Future<Response<List<RecipeModel>>> getAll('));
      // The repository call site follows the renamed method, not the old
      // fixed one — this is what makes the rename load-bearing rather than
      // cosmetic.
      final repositoryImpl = File(
        '${projectDir.path}/lib/features/recipe/data/repositories/recipe_repository_impl.dart',
      ).readAsStringSync();
      expect(repositoryImpl, contains('.createRecipe(model)'));
      expect(repositoryImpl, isNot(contains('.add(model)')));
      // Still one shared entity/model — not one per operation (the whole
      // point vs Custom Endpoints' per-endpoint models).
      expect(
        File(
          '${projectDir.path}/lib/features/recipe/data/models/recipe_model.dart',
        ).existsSync(),
        isTrue,
      );
      expect(
        File(
          '${projectDir.path}/lib/features/recipe/domain/entities/recipe_entity.dart',
        ).existsSync(),
        isTrue,
      );

      final analyze = await Process.run('flutter', [
        'analyze',
        '--no-pub',
      ], workingDirectory: projectDir.path);
      final out = '${analyze.stdout}\n${analyze.stderr}';
      final errorLines = const LineSplitter()
          .convert(out)
          .where(
            (l) =>
                (l.contains(' error •') || l.contains(' warning •')) &&
                !l.contains('• build/'),
          )
          .toList();
      expect(
        errorLines,
        isEmpty,
        reason:
            'Customize endpoints workspace analyze reported issues:\n'
            '${errorLines.join('\n')}\n\n$out',
      );
    },
    timeout: const Timeout(Duration(minutes: 12)),
  );

  test(
    'FeatureGenOptions.listEnvelopeKey (real bug from a real generated project: '
    'dummyjson-style paginated envelopes broke getAll() at runtime with '
    '"FormatException: JsonConverter expected response body to be Iterable<Model>, '
    'but got Map"): getAll() decodes into a typed <Feature>ListModel wrapper '
    'instead of a bare array',
    () async {
      const projectName = 'neat_envelope_test';
      final logs = <String>[];

      final pkgs = <PubPackage>[
        _dep('hooks_riverpod', '3.3.1'),
        _dep('flutter_hooks', '0.21.3+1'),
        _dep('riverpod_annotation', '4.0.2'),
        _dep('json_annotation', '4.11.0'),
        _dep('freezed_annotation', '3.1.0'),
        _dep('chopper', '8.6.0'),
        _dep('go_router', '17.2.3'),
        _dev('riverpod_generator', '4.0.3'),
        _dev('riverpod_lint', '3.1.3'),
        _dev('json_serializable', '6.13.0'),
        _dev('build_runner', '2.15.0'),
        _dev('freezed', '3.2.5'),
        _dev('chopper_generator', '8.6.2'),
      ];

      final identity = IdentityState(
        name: projectName,
        organization: 'com.neat.test',
        projectPath: tempRoot.path,
        description: 'NEAT paginated-envelope integration test',
        targetPlatforms: const ['macos'],
      );
      // No first feature — added via the Workshop, same as a real user would.
      const architecture = ArchitectureState(generateFirstFeature: false);

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
        fail('Base generation threw:\n$e\n\n--- logs ---\n${logs.join('\n')}');
      }

      final projectDir = Directory('${tempRoot.path}/$projectName');
      final project = await const ProjectLoader().load(projectDir.path);
      expect(project, isNotNull);
      expect(project!.contract.httpClient, 'chopper');

      // dummyjson.com/recipes' real shape — the exact JSON that exposed this
      // bug — run through JsonEntityInferencer exactly like the Workshop's
      // Entity Fields step does, so the envelope key comes from real
      // inference, not a hand-picked constant.
      const sampleJson = '''
{
  "recipes": [
    {"id": 1, "name": "Kimchi", "cuisine": "Korean"}
  ],
  "total": 50,
  "skip": 0,
  "limit": 30
}
''';
      final inferred = const JsonEntityInferencer().infer(sampleJson);
      expect(inferred.envelopeKey, 'recipes');

      final options = FeatureGenOptions(
        name: 'recipe',
        apiPath: '/recipes',
        json: sampleJson,
        fields: inferred.fields,
        fieldWarnings: inferred.warnings,
        listEnvelopeKey: inferred.envelopeKey ?? '',
        envelopeFields: inferred.envelopeFields,
      );

      try {
        await const GenerateFeatureUsecase().execute(
          project: project,
          options: options,
          onLog: logs.add,
        );
      } catch (e) {
        fail(
          'Feature generation threw:\n$e\n\n--- logs ---\n${logs.join('\n')}',
        );
      }

      // The ApiSource: a List<Model>-typed return can't decode a wrapper
      // object — getAll() decodes into the generated RecipeListModel wrapper
      // instead (see DataTemplates.featureModel's own doc), fully typed.
      final apiSource = File(
        '${projectDir.path}/lib/features/recipe/data/sources/recipe_api_source.dart',
      ).readAsStringSync();
      expect(apiSource, contains('Future<Response<RecipeListModel>> getAll();'));
      expect(
        apiSource,
        isNot(contains('Future<Response<List<RecipeModel>>> getAll();')),
      );

      // The model file: the wrapper class carries the list field + its
      // sibling pagination metadata, typed — not discarded.
      final modelFile = File(
        '${projectDir.path}/lib/features/recipe/data/models/recipe_model.dart',
      ).readAsStringSync();
      expect(modelFile, contains('abstract class RecipeListModel'));
      expect(modelFile, contains('required List<RecipeModel> recipes,'));
      expect(modelFile, contains('required int total,'));
      expect(modelFile, contains('required int skip,'));
      expect(modelFile, contains('required int limit,'));

      // The repository: accesses the wrapper's list field directly — no
      // manual Map casting.
      final repositoryImpl = File(
        '${projectDir.path}/lib/features/recipe/data/repositories/recipe_repository_impl.dart',
      ).readAsStringSync();
      expect(repositoryImpl, contains('unwrapChopperResponse(await _remote.getAll()).recipes'));
      expect(repositoryImpl, isNot(contains('as Map<String, dynamic>')));

      // The decoder registry: both the entity Model and the wrapper
      // ListModel are registered — getAll() decodes into the latter.
      final converter = File(
        '${projectDir.path}/lib/core/network/chopper_model_converter.dart',
      ).readAsStringSync();
      expect(converter, contains('RecipeModel: (json) => RecipeModel.fromJson(json),'));
      expect(converter, contains('RecipeListModel: (json) => RecipeListModel.fromJson(json),'));

      // Executable regression probe: proves the actual runtime bug (a
      // `FormatException` chopper throws mid-decode, which `flutter analyze`
      // can't catch — the generated code compiles fine either way) is gone.
      // Drives the real pipeline end to end: a real HTTP response carrying
      // the envelope body, through ModelJsonConverter.convertResponse with
      // the actual registered RecipeListModel decoder — exactly what
      // getAll()'s new typed declaration triggers at runtime.
      await File(
        '${projectDir.path}/test/_envelope_probe_test.dart',
      ).writeAsString('''
import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:$projectName/core/network/chopper_model_converter.dart';
import 'package:$projectName/features/recipe/data/models/recipe_model.dart';

void main() {
  test('ModelJsonConverter decodes an envelope body into a typed '
      'RecipeListModel (no Iterable<Model> vs Map mismatch)', () async {
    final httpResponse = http.Response(
      '{"recipes": [{"id": 1, "name": "Kimchi", "cuisine": "Korean"}], '
      '"total": 50, "skip": 0, "limit": 30}',
      200,
      headers: {'content-type': 'application/json'},
    );
    final response = chopper.Response<dynamic>(httpResponse, null);

    final converted = await const ModelJsonConverter()
        .convertResponse<RecipeListModel, RecipeListModel>(response);

    expect(converted.body, isA<RecipeListModel>());
    final wrapper = converted.body!;
    expect(wrapper.total, 50);
    expect(wrapper.recipes, hasLength(1));
    expect(wrapper.recipes.first.id, '1');
    expect(wrapper.recipes.first.name, 'Kimchi');
  });
}
''');
      final probe = await Process.run('flutter', [
        'test',
        'test/_envelope_probe_test.dart',
      ], workingDirectory: projectDir.path);
      expect(
        probe.exitCode,
        0,
        reason: 'envelope regression probe failed:\n${probe.stdout}\n${probe.stderr}',
      );

      final analyze = await Process.run('flutter', [
        'analyze',
        '--no-pub',
      ], workingDirectory: projectDir.path);
      final out = '${analyze.stdout}\n${analyze.stderr}';
      final errorLines = const LineSplitter()
          .convert(out)
          .where(
            (l) =>
                (l.contains(' error •') || l.contains(' warning •')) &&
                !l.contains('• build/'),
          )
          .toList();
      expect(
        errorLines,
        isEmpty,
        reason:
            'Paginated-envelope workspace analyze reported issues:\n'
            '${errorLines.join('\n')}\n\n$out',
      );
    },
    timeout: const Timeout(Duration(minutes: 12)),
  );

  test(
    'feature generation (chopper) registers the new feature in the decoder registry',
    () async {
      const projectName = 'neat_featgen_chopper';
      final logs = <String>[];

      final pkgs = <PubPackage>[
        _dep('hooks_riverpod', '3.3.1'),
        _dep('flutter_hooks', '0.21.3+1'),
        _dep('riverpod_annotation', '4.0.2'),
        _dep('chopper', '8.6.0'),
        _dep('go_router', '17.2.3'),
        _dev('riverpod_generator', '4.0.3'),
        _dev('build_runner', '2.15.0'),
        _dev('chopper_generator', '8.6.2'),
      ];

      final identity = IdentityState(
        name: projectName,
        organization: 'com.neat.test',
        projectPath: tempRoot.path,
        description: 'NEAT chopper feature-gen integration test',
        targetPlatforms: const ['macos'],
      );
      const architecture =
          ArchitectureState(); // firstFeatureName defaults to 'home'

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
        fail('Base chopper generation threw:\n$e');
      }

      final projectDir = Directory('${tempRoot.path}/$projectName');
      final project = await const ProjectLoader().load(projectDir.path);
      expect(project!.contract.httpClient, 'chopper');

      // Witness feature ("home") is already registered at generation time.
      final converterBefore = File(
        '${projectDir.path}/lib/core/network/chopper_model_converter.dart',
      ).readAsStringSync();
      expect(
        converterBefore,
        contains('HomeModel: (json) => HomeModel.fromJson(json)'),
      );

      // Add a 2nd chopper-backed feature via the Workshop.
      await const GenerateFeatureUsecase().execute(
        project: project,
        options: const FeatureGenOptions(name: 'orders'),
        onLog: logs.add,
      );

      final converterAfter = File(
        '${projectDir.path}/lib/core/network/chopper_model_converter.dart',
      ).readAsStringSync();
      expect(
        converterAfter,
        contains('OrdersModel: (json) => OrdersModel.fromJson(json)'),
      );
      expect(
        converterAfter,
        contains(
          "import 'package:$projectName/features/orders/data/models/orders_model.dart';",
        ),
      );
      // The witness feature's own entry survives the insertion untouched.
      expect(
        converterAfter,
        contains('HomeModel: (json) => HomeModel.fromJson(json)'),
      );

      // Executable probe: the newly Workshop-added feature's Model actually
      // decodes through the shared converter — not just present as text.
      await File(
        '${projectDir.path}/test/_chopper_converter_probe_test.dart',
      ).writeAsString('''
import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:$projectName/core/network/chopper_model_converter.dart';
import 'package:$projectName/features/orders/data/models/orders_model.dart';

void main() {
  test('Workshop-added feature Model decodes through ModelJsonConverter', () async {
    final httpResponse = http.Response(
      '[{"id": 1, "name": "First order"}]',
      200,
      headers: {'content-type': 'application/json'},
    );
    final response = chopper.Response<dynamic>(httpResponse, null);

    final converted = await const ModelJsonConverter()
        .convertResponse<List<OrdersModel>, OrdersModel>(response);

    expect(converted.body, isA<List<OrdersModel>>());
    expect(converted.body!.single.id, '1');
    expect(converted.body!.single.name, 'First order');
  });
}
''');
      final probe = await Process.run('flutter', [
        'test',
        'test/_chopper_converter_probe_test.dart',
      ], workingDirectory: projectDir.path);
      expect(
        probe.exitCode,
        0,
        reason:
            'Workshop chopper-decoder regression probe failed:\n${probe.stdout}\n${probe.stderr}',
      );

      // The whole project still analyzes without errors or warnings.
      final analyze = await Process.run('flutter', [
        'analyze',
        '--no-pub',
      ], workingDirectory: projectDir.path);
      final out = '${analyze.stdout}\n${analyze.stderr}';
      final errorLines = const LineSplitter()
          .convert(out)
          .where(
            (l) =>
                (l.contains(' error •') || l.contains(' warning •')) &&
                !l.contains('• build/'),
          )
          .toList();
      expect(
        errorLines,
        isEmpty,
        reason:
            'chopper feature-gen project analyze reported issues:\n${errorLines.join('\n')}\n\n$out',
      );
    },
    timeout: const Timeout(Duration(minutes: 12)),
  );

  test('feature generation (chopper) with Domain UseCase off never wires a '
      'register<Feature>ChopperDecoders() call that was never generated', () async {
    const projectName = 'neat_featgen_chopper_no_usecase';
    final logs = <String>[];

    final pkgs = <PubPackage>[
      _dep('hooks_riverpod', '3.3.1'),
      _dep('flutter_hooks', '0.21.3+1'),
      _dep('riverpod_annotation', '4.0.2'),
      _dep('chopper', '8.6.0'),
      _dep('go_router', '17.2.3'),
      _dev('riverpod_generator', '4.0.3'),
      _dev('build_runner', '2.15.0'),
      _dev('chopper_generator', '8.6.2'),
    ];

    final identity = IdentityState(
      name: projectName,
      organization: 'com.neat.test',
      projectPath: tempRoot.path,
      description:
          'NEAT chopper feature-gen (no Domain UseCase) integration test',
      targetPlatforms: const ['macos'],
    );
    const architecture =
        ArchitectureState(); // firstFeatureName defaults to 'home'

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
      fail('Base chopper generation threw:\n$e');
    }

    final projectDir = Directory('${tempRoot.path}/$projectName');
    final project = await const ProjectLoader().load(projectDir.path);

    // Remote Data Source stays on (so the ApiSource/RepositoryImpl/Model
    // still get generated), but Domain UseCase is off — the exact real-world
    // combo that shipped a broken bootstrap.dart before this fix: it wires
    // a register<Feature>ChopperDecoders() call unconditionally on
    // `httpClient == 'chopper'` alone, but that function only exists inside
    // <feature>_repository_providers.dart, which FeatureScaffolder only
    // writes when `useAnnotations && hasHttpClient && includeUseCases` are
    // ALL true (see feature_scaffolder.dart).
    await const GenerateFeatureUsecase().execute(
      project: project!,
      options: const FeatureGenOptions(name: 'orders', includeUseCase: false),
      onLog: logs.add,
    );

    // The file that would define registerOrdersChopperDecoders() was never
    // written...
    expect(
      File(
        '${projectDir.path}/lib/features/orders/data/repositories/orders_repository_providers.dart',
      ).existsSync(),
      isFalse,
    );
    // ...so bootstrap.dart must not import or call it. (The non-split
    // witness feature never calls a register function at all — its decoder
    // is anchor-inserted straight into chopper_model_converter.dart — so
    // there's nothing else to assert stays present here.)
    final bootstrap = File(
      '${projectDir.path}/lib/core/bootstrap.dart',
    ).readAsStringSync();
    expect(bootstrap, isNot(contains('orders_repository_providers.dart')));
    expect(bootstrap, isNot(contains('registerOrdersChopperDecoders')));

    // The whole project still analyzes without errors or warnings.
    final analyze = await Process.run('flutter', [
      'analyze',
      '--no-pub',
    ], workingDirectory: projectDir.path);
    final out = '${analyze.stdout}\n${analyze.stderr}';
    final errorLines = const LineSplitter()
        .convert(out)
        .where(
          (l) =>
              (l.contains(' error •') || l.contains(' warning •')) &&
              !l.contains('• build/'),
        )
        .toList();
    expect(
      errorLines,
      isEmpty,
      reason:
          'chopper (no Domain UseCase) feature-gen project analyze reported issues:\n'
          '${errorLines.join('\n')}\n\n$out',
    );
  }, timeout: const Timeout(Duration(minutes: 12)));

  test('feature generation with zero data sources: pure entity + presentation, '
      'no data/ layer at all', () async {
    const projectName = 'neat_featgen_no_datasource';
    final logs = <String>[];

    final pkgs = <PubPackage>[
      _dep('hooks_riverpod', '3.3.1'),
      _dep('flutter_hooks', '0.21.3+1'),
      _dep('riverpod_annotation', '4.0.2'),
      _dep('chopper', '8.6.0'),
      _dep('go_router', '17.2.3'),
      _dev('riverpod_generator', '4.0.3'),
      _dev('build_runner', '2.15.0'),
      _dev('chopper_generator', '8.6.2'),
    ];

    final identity = IdentityState(
      name: projectName,
      organization: 'com.neat.test',
      projectPath: tempRoot.path,
      description: 'NEAT zero-data-source feature-gen integration test',
      targetPlatforms: const ['macos'],
    );
    const architecture =
        ArchitectureState(); // firstFeatureName defaults to 'home'

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
    final project = await const ProjectLoader().load(projectDir.path);

    // Remote, Local, and Domain UseCase all off — previously blocked by
    // FeatureGenOptions.hasAnyDataSource; now allowed as a deliberate
    // "pure entity + presentation, no data layer" feature.
    await const GenerateFeatureUsecase().execute(
      project: project!,
      options: const FeatureGenOptions(
        name: 'settings',
        includeRemoteDataSource: false,
        includeLocalDataSource: false,
        includeUseCase: false,
      ),
      onLog: logs.add,
    );

    final f = '${projectDir.path}/lib/features/settings';
    // No data/ layer at all — no model, no repository (impl or interface),
    // no sources, no usecases.
    expect(Directory('$f/data').existsSync(), isFalse);
    expect(
      File('$f/domain/repositories/i_settings_repository.dart').existsSync(),
      isFalse,
    );
    expect(Directory('$f/domain/usecases').existsSync(), isFalse);
    // But the entity + presentation layer are still generated.
    expect(
      File('$f/domain/entities/settings_entity.dart').existsSync(),
      isTrue,
    );
    expect(
      File('$f/presentation/pages/settings_page.dart').existsSync(),
      isTrue,
    );
    expect(
      File('$f/presentation/providers/settings_provider.dart').existsSync(),
      isTrue,
    );

    // The whole project still analyzes without errors or warnings.
    final analyze = await Process.run('flutter', [
      'analyze',
      '--no-pub',
    ], workingDirectory: projectDir.path);
    final out = '${analyze.stdout}\n${analyze.stderr}';
    final errorLines = const LineSplitter()
        .convert(out)
        .where(
          (l) =>
              (l.contains(' error •') || l.contains(' warning •')) &&
              !l.contains('• build/'),
        )
        .toList();
    expect(
      errorLines,
      isEmpty,
      reason:
          'zero-data-source feature-gen project analyze reported issues:\n'
          '${errorLines.join('\n')}\n\n$out',
    );
  }, timeout: const Timeout(Duration(minutes: 12)));

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
      final uiPkg = '${projectName}_database';

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
      expect(
        dbDart,
        isNot(contains('class OrdersRows extends Table')),
        reason: 'the table definition lives in its own file, not database.dart',
      );
      expect(
        dbDart,
        isNot(contains('upsertOrders(OrdersRow row)')),
        reason: 'DAO methods live in their own file, not database.dart',
      );
      expect(
        dbDart,
        contains('OrdersRows,'),
      ); // added to @DriftDatabase(tables:)
      expect(dbDart, contains('OrdersDao,')); // added to @DriftDatabase(daos:)
      expect(dbDart, contains("import 'table/orders_table.dart';"));
      expect(dbDart, contains("import 'dao/orders_dao.dart';"));

      // The feature's own dedicated table file (see
      // LocalStorageTemplates.featureTableFile) — created by the Workshop, not
      // inserted into database.dart.
      final ordersTable = File(
        '${projectDir.path}/packages/$uiPkg/lib/src/table/orders_table.dart',
      ).readAsStringSync();
      expect(ordersTable, contains('class OrdersRows extends Table'));

      // The feature's own dedicated DAO file (see
      // LocalStorageTemplates.featureDaoFile) — created by the Workshop, not
      // inserted into database.dart.
      final ordersDao = File(
        '${projectDir.path}/packages/$uiPkg/lib/src/dao/orders_dao.dart',
      ).readAsStringSync();
      expect(
        ordersDao,
        contains('class OrdersDao extends DatabaseAccessor<AppDatabase>'),
      );
      expect(ordersDao, contains('upsertOrders(OrdersRow row)'));

      // Schema version bumped + a migration step added — otherwise a device
      // that already has the app installed (schemaVersion still 1) would
      // never get the new table (Drift only runs onCreate on a fresh db).
      expect(dbDart, contains('int get schemaVersion => 2;'));
      expect(dbDart, contains('MigrationStrategy get migration'));
      expect(
        dbDart,
        contains('if (from < 2) await m.createTable(ordersRows);'),
      );

      // The whole offline workspace still analyzes cleanly.
      final analyze = await Process.run('flutter', [
        'analyze',
        '--no-pub',
      ], workingDirectory: projectDir.path);
      final out = '${analyze.stdout}\n${analyze.stderr}';
      expect(
        RegExp(r'(\d+ issues? found|No issues found)').hasMatch(out),
        isTrue,
        reason: 'flutter analyze did not run as expected:\n$out',
      );
      final errorLines = const LineSplitter()
          .convert(out)
          .where(
            (l) =>
                (l.contains(' error •') || l.contains(' warning •')) &&
                !l.contains('• build/'),
          )
          .toList();
      expect(
        errorLines,
        isEmpty,
        reason:
            'offline feature-gen analyze reported issues:\n${errorLines.join('\n')}\n\n$out',
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
        fail(
          'Navigation-shell generation threw:\n$e\n\n--- logs ---\n${logs.join('\n')}',
        );
      }

      final projectDir = Directory('${tempRoot.path}/$projectName');

      // The shell scaffold + typed shell route exist.
      final scaffold = File(
        '${projectDir.path}/lib/core/navigation/scaffold_with_nav_bar.dart',
      );
      expect(
        scaffold.existsSync(),
        isTrue,
        reason: 'scaffold_with_nav_bar.dart missing',
      );
      expect(scaffold.readAsStringSync(), contains('NavigationBar('));
      expect(
        scaffold.readAsStringSync(),
        contains(
          "NavigationDestination(icon: Icon(Icons.dashboard), label: 'Home')",
        ),
      );

      final shellRoute = File(
        '${projectDir.path}/lib/core/router/app_shell_route.dart',
      );
      expect(
        shellRoute.existsSync(),
        isTrue,
        reason: 'app_shell_route.dart missing',
      );
      final shellRouteContent = shellRoute.readAsStringSync();
      expect(
        shellRouteContent,
        contains('@TypedStatefulShellRoute<AppShellRouteData>'),
      );
      expect(shellRouteContent, contains('TypedGoRoute<HomeRoute>('));
      expect(shellRouteContent, contains('path: AppRoutePath.home'));
      // Proactive children anchor (§7 sub-routes): present even though no
      // child was ever added — lets the Workshop nest one later.
      expect(shellRouteContent, contains('// neat:typed-children:home'));
      // Non-split: the branch's page is imported/constructed directly, never
      // through the shell page registry (that's packageSplit-only — see the
      // packageSplit+shell+chopper test below).
      expect(shellRouteContent, contains('const HomePage()'));
      expect(shellRouteContent, isNot(contains('lookupShellPage')));

      // routes.dart aggregates the shell (not a flat first-feature route).
      final routesDart = File(
        '${projectDir.path}/lib/core/router/routes.dart',
      ).readAsStringSync();
      expect(routesDart, contains(r'...app_shell.$appRoutes'));

      // The first feature did NOT get its own standalone route file (it lives in
      // the shell), and the app boots into it (initialLocation = '/').
      expect(
        File(
          '${projectDir.path}/lib/features/home/presentation/routes/home_routes.dart',
        ).existsSync(),
        isFalse,
        reason: 'shell-branch feature must not emit a standalone route file',
      );
      final appRouter = File(
        '${projectDir.path}/lib/core/router/app_router.dart',
      ).readAsStringSync();
      expect(appRouter, contains('initialLocation: AppRoutePath.home'));

      // Contract records the choice.
      final contract =
          jsonDecode(File('${projectDir.path}/.neat.json').readAsStringSync())
              as Map<String, dynamic>;
      expect(contract['useNavigationShell'], isTrue);

      // The whole project analyzes cleanly (build_runner generated the shell mixins).
      final analyze = await Process.run('flutter', [
        'analyze',
        '--no-pub',
      ], workingDirectory: projectDir.path);
      final out = '${analyze.stdout}\n${analyze.stderr}';
      expect(
        RegExp(r'(\d+ issues? found|No issues found)').hasMatch(out),
        isTrue,
        reason: 'flutter analyze did not run as expected:\n$out',
      );
      final errorLines = const LineSplitter()
          .convert(out)
          .where(
            (l) =>
                (l.contains(' error •') || l.contains(' warning •')) &&
                !l.contains('• build/'),
          )
          .toList();
      expect(
        errorLines,
        isEmpty,
        reason:
            'navigation-shell analyze reported issues:\n${errorLines.join('\n')}\n\n$out',
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
          architecture: const ArchitectureState(
            firstFeatureName: 'todo',
            // Per-env Supabase credentials → pre-filled into .env.<flavor>.
            environments: [
              EnvConfig(
                name: 'dev',
                supabaseUrl: 'https://dev.supabase.co',
                supabaseAnonKey: 'dev-anon-key',
              ),
              EnvConfig(name: 'staging'),
              EnvConfig(name: 'prod'),
            ],
          ),
          cicd: const CicdState(),
          theme: const ThemeEngineState(approach: ThemeApproach.customM3),
          onLog: logs.add,
        );
      } catch (e) {
        fail(
          'Supabase generation threw:\n$e\n\n--- logs ---\n${logs.join('\n')}',
        );
      }

      final projectDir = Directory('${tempRoot.path}/$projectName');

      // Backend recorded as supabase.
      final contract =
          jsonDecode(File('${projectDir.path}/.neat.json').readAsStringSync())
              as Map<String, dynamic>;
      expect(contract['httpClient'], 'supabase');

      // Supabase client provider (not dio/chopper).
      expect(
        File(
          '${projectDir.path}/lib/core/network/supabase_provider.dart',
        ).existsSync(),
        isTrue,
      );
      expect(
        File(
          '${projectDir.path}/lib/core/network/dio_provider.dart',
        ).existsSync(),
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

      // Repository-level DI (data/) wires the source from the supabase client provider.
      final di = File(
        '${projectDir.path}/lib/features/todo/data/repositories/todo_repository_providers.dart',
      ).readAsStringSync();
      expect(di, contains('TodoApiSource(ref.watch(supabaseClientProvider))'));

      // bootstrap initializes Supabase from the typed env (modern publishableKey).
      final bootstrap = File(
        '${projectDir.path}/lib/core/bootstrap.dart',
      ).readAsStringSync();
      expect(bootstrap, contains('Supabase.initialize('));
      expect(
        bootstrap,
        contains('publishableKey: AppEnv.current.supabasePublishableKey'),
      );
      // envied contract carries the supabase keys — and NOT the REST apiBaseUrl.
      final appEnv = File(
        '${projectDir.path}/lib/core/env/app_env.dart',
      ).readAsStringSync();
      expect(appEnv, contains('supabasePublishableKey'));
      expect(
        appEnv,
        isNot(contains('apiBaseUrl')),
        reason: 'REST leftover in a Supabase project',
      );
      final envDev = File('${projectDir.path}/.env.dev').readAsStringSync();
      expect(envDev, contains('SUPABASE_URL=https://dev.supabase.co'));
      expect(envDev, contains('SUPABASE_PUBLISHABLE_KEY=dev-anon-key'));
      expect(envDev, isNot(contains('API_BASE_URL')));

      // ≥2 environments → per-env entry points are emitted on every platform
      // (here macOS), but WITHOUT native flavors (no --flavor, no productFlavors),
      // so a plain `flutter run` still works.
      expect(
        File('${projectDir.path}/lib/main_staging.dart').existsSync(),
        isTrue,
      );
      final launch = File(
        '${projectDir.path}/.vscode/launch.json',
      ).readAsStringSync();
      expect(launch, contains('lib/main_staging.dart'));
      expect(
        launch,
        isNot(contains('--flavor')),
        reason: 'macOS has no native flavors',
      );

      // The whole project analyzes without errors or warnings.
      final analyze = await Process.run('flutter', [
        'analyze',
        '--no-pub',
      ], workingDirectory: projectDir.path);
      final out = '${analyze.stdout}\n${analyze.stderr}';
      expect(
        RegExp(r'(\d+ issues? found|No issues found)').hasMatch(out),
        isTrue,
        reason: 'flutter analyze did not run as expected:\n$out',
      );
      final errorLines = const LineSplitter()
          .convert(out)
          .where(
            (l) =>
                (l.contains(' error •') || l.contains(' warning •')) &&
                !l.contains('• build/'),
          )
          .toList();
      expect(
        errorLines,
        isEmpty,
        reason:
            'Supabase project analyze reported issues:\n${errorLines.join('\n')}\n\n$out',
      );
    },
    timeout: const Timeout(Duration(minutes: 12)),
  );

  test(
    'Supabase auth: login/signup/forgot + go_router guard, analyzes cleanly',
    () async {
      const projectName = 'neat_auth_test';
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
        _dev('go_router_builder', '4.3.0'),
      ];

      final identity = IdentityState(
        name: projectName,
        organization: 'com.neat.test',
        projectPath: tempRoot.path,
        description: 'NEAT Supabase auth integration test',
        targetPlatforms: const ['macos'],
      );

      try {
        await const LaunchGenerationUsecase().execute(
          identity: identity,
          packages: pkgs,
          architecture: const ArchitectureState(generateAuth: true),
          cicd: const CicdState(),
          theme: const ThemeEngineState(approach: ThemeApproach.customM3),
          onLog: logs.add,
        );
      } catch (e) {
        fail('Auth generation threw:\n$e\n\n--- logs ---\n${logs.join('\n')}');
      }

      final projectDir = Directory('${tempRoot.path}/$projectName');

      // Contract records auth.
      final contract =
          jsonDecode(File('${projectDir.path}/.neat.json').readAsStringSync())
              as Map<String, dynamic>;
      expect(contract['generateAuth'], isTrue);

      // The auth feature + the three screens + repository + guard exist.
      for (final relPath in const [
        'lib/features/auth/domain/repositories/i_auth_repository.dart',
        'lib/features/auth/data/repositories/auth_repository_impl.dart',
        'lib/features/auth/presentation/providers/auth_provider.dart',
        'lib/features/auth/data/repositories/auth_repository_providers.dart',
        'lib/features/auth/presentation/screens/login_screen.dart',
        'lib/features/auth/presentation/screens/signup_screen.dart',
        'lib/features/auth/presentation/screens/forgot_password_screen.dart',
        'lib/features/auth/presentation/routes/auth_routes.dart',
        'lib/core/router/router_notifier.dart',
      ]) {
        expect(
          File('${projectDir.path}/$relPath').existsSync(),
          isTrue,
          reason: 'expected auth file missing: $relPath',
        );
      }

      // Repository talks to Supabase auth.
      final repo = File(
        '${projectDir.path}/lib/features/auth/data/repositories/auth_repository_impl.dart',
      ).readAsStringSync();
      expect(repo, contains('signInWithPassword'));
      expect(repo, contains('_client.auth.signUp'));

      // Path constants + the router guard are wired.
      final routePath = File(
        '${projectDir.path}/lib/core/constants/app_route_path.dart',
      ).readAsStringSync();
      expect(routePath, contains("static const String login = '/login';"));
      final appRouter = File(
        '${projectDir.path}/lib/core/router/app_router.dart',
      ).readAsStringSync();
      expect(appRouter, contains('refreshListenable: guard'));
      expect(appRouter, contains('redirect: guard.redirect'));
      final routes = File(
        '${projectDir.path}/lib/core/router/routes.dart',
      ).readAsStringSync();
      expect(routes, contains(r'...auth.$appRoutes'));

      // The whole project analyzes without errors or warnings.
      final analyze = await Process.run('flutter', [
        'analyze',
        '--no-pub',
      ], workingDirectory: projectDir.path);
      final out = '${analyze.stdout}\n${analyze.stderr}';
      expect(
        RegExp(r'(\d+ issues? found|No issues found)').hasMatch(out),
        isTrue,
        reason: 'flutter analyze did not run as expected:\n$out',
      );
      final errorLines = const LineSplitter()
          .convert(out)
          .where(
            (l) =>
                (l.contains(' error •') || l.contains(' warning •')) &&
                !l.contains('• build/'),
          )
          .toList();
      expect(
        errorLines,
        isEmpty,
        reason:
            'auth project analyze reported issues:\n${errorLines.join('\n')}\n\n$out',
      );
    },
    timeout: const Timeout(Duration(minutes: 12)),
  );

  test(
    'Supabase realtime + storage: live list + StorageService + avatar widget, analyzes cleanly',
    () async {
      const projectName = 'neat_realtime_test';
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
        description: 'NEAT Supabase realtime + storage integration test',
        targetPlatforms: const ['macos'],
      );

      try {
        await const LaunchGenerationUsecase().execute(
          identity: identity,
          packages: pkgs,
          architecture: const ArchitectureState(
            firstFeatureName: 'todo',
            generateRealtime: true,
            generateStorage: true,
          ),
          cicd: const CicdState(),
          theme: const ThemeEngineState(approach: ThemeApproach.customM3),
          onLog: logs.add,
        );
      } catch (e) {
        fail(
          'Realtime/storage generation threw:\n$e\n\n--- logs ---\n${logs.join('\n')}',
        );
      }

      final projectDir = Directory('${tempRoot.path}/$projectName');

      // Contract records both opt-ins.
      final contract =
          jsonDecode(File('${projectDir.path}/.neat.json').readAsStringSync())
              as Map<String, dynamic>;
      expect(contract['generateRealtime'], isTrue);
      expect(contract['generateStorage'], isTrue);

      // ── Realtime ────────────────────────────────────────────────────────────
      // The api source exposes a live stream.
      final src = File(
        '${projectDir.path}/lib/features/todo/data/sources/todo_api_source.dart',
      ).readAsStringSync();
      expect(src, contains('Stream<List<TodoModel>> watchAll()'));
      expect(src, contains(".stream(primaryKey: ['id'])"));

      // The repository interface + impl carry watchAll().
      final iRepo = File(
        '${projectDir.path}/lib/features/todo/domain/repositories/i_todo_repository.dart',
      ).readAsStringSync();
      expect(iRepo, contains('Stream<List<TodoEntity>> watchAll();'));

      // The list notifier became a StreamNotifier over the repository stream.
      final notifier = File(
        '${projectDir.path}/lib/features/todo/presentation/providers/todo_provider.dart',
      ).readAsStringSync();
      expect(notifier, contains('Stream<List<TodoEntity>> build()'));
      expect(notifier, contains('todoRepositoryProvider).watchAll()'));

      // ── Storage ─────────────────────────────────────────────────────────────
      final storage = File(
        '${projectDir.path}/lib/core/storage/storage_service.dart',
      ).readAsStringSync();
      expect(storage, contains('class StorageService'));
      expect(storage, contains('uploadBinary'));
      // riverpod_generator turns this into `storageServiceProvider`.
      expect(storage, contains('StorageService storageService(Ref ref)'));

      // The sample widget consumes the generated provider + uploads.
      final avatar = File(
        '${projectDir.path}/lib/core/storage/avatar_upload_field.dart',
      ).readAsStringSync();
      expect(avatar, contains('ref.read(storageServiceProvider)'));
      expect(avatar, contains('ImagePicker()'));

      // image_picker was injected.
      final pubspec = File(
        '${projectDir.path}/pubspec.yaml',
      ).readAsStringSync();
      expect(pubspec, contains('image_picker:'));

      // The whole project analyzes without errors or warnings.
      final analyze = await Process.run('flutter', [
        'analyze',
        '--no-pub',
      ], workingDirectory: projectDir.path);
      final out = '${analyze.stdout}\n${analyze.stderr}';
      expect(
        RegExp(r'(\d+ issues? found|No issues found)').hasMatch(out),
        isTrue,
        reason: 'flutter analyze did not run as expected:\n$out',
      );
      final errorLines = const LineSplitter()
          .convert(out)
          .where(
            (l) =>
                (l.contains(' error •') || l.contains(' warning •')) &&
                !l.contains('• build/'),
          )
          .toList();
      expect(
        errorLines,
        isEmpty,
        reason:
            'realtime/storage project analyze reported issues:\n${errorLines.join('\n')}\n\n$out',
      );
    },
    timeout: const Timeout(Duration(minutes: 12)),
  );

  test(
    'Firebase backend: Firestore source + auth + realtime + storage, analyzes cleanly',
    () async {
      const projectName = 'neat_firebase_test';
      final logs = <String>[];

      // A web app config JSON (what users copy from the Firebase console).
      final config = File('${tempRoot.path}/firebase_config.json')
        ..writeAsStringSync('''{
  "apiKey": "AIzaTestKey123",
  "appId": "1:1234567890:web:abcdef",
  "messagingSenderId": "1234567890",
  "projectId": "neat-demo",
  "authDomain": "neat-demo.firebaseapp.com",
  "storageBucket": "neat-demo.appspot.com"
}''');

      final pkgs = <PubPackage>[
        _dep('hooks_riverpod', '3.3.1'),
        _dep('flutter_hooks', '0.21.3+1'),
        _dep('riverpod_annotation', '4.0.2'),
        _dep('cloud_firestore', '5.6.0'),
        _dep('go_router', '17.2.3'),
        _dep('json_annotation', '4.11.0'),
        _dep('freezed_annotation', '3.1.0'),
        _dev('riverpod_generator', '4.0.3'),
        _dev('build_runner', '2.15.0'),
        _dev('freezed', '3.2.5'),
        _dev('json_serializable', '6.13.0'),
        _dev('go_router_builder', '4.3.0'),
      ];

      final identity = IdentityState(
        name: projectName,
        organization: 'com.neat.test',
        projectPath: tempRoot.path,
        description: 'NEAT Firebase backend integration test',
        targetPlatforms: const ['macos'],
      );

      try {
        await const LaunchGenerationUsecase().execute(
          identity: identity,
          packages: pkgs,
          architecture: ArchitectureState(
            firstFeatureName: 'todo',
            generateAuth: true,
            generateRealtime: true,
            generateStorage: true,
            generateOAuth: true,
            firebaseConfigPath: config.path,
          ),
          cicd: const CicdState(),
          theme: const ThemeEngineState(approach: ThemeApproach.customM3),
          onLog: logs.add,
        );
      } catch (e) {
        fail(
          'Firebase generation threw:\n$e\n\n--- logs ---\n${logs.join('\n')}',
        );
      }

      final projectDir = Directory('${tempRoot.path}/$projectName');

      // Backend recorded as firebase.
      final contract =
          jsonDecode(File('${projectDir.path}/.neat.json').readAsStringSync())
              as Map<String, dynamic>;
      expect(contract['httpClient'], 'firebase');
      expect(contract['generateRealtime'], isTrue);
      expect(contract['generateStorage'], isTrue);
      expect(contract['generateAuth'], isTrue);

      // firebase_options.dart generated from the uploaded config.
      final options = File(
        '${projectDir.path}/lib/firebase_options.dart',
      ).readAsStringSync();
      expect(options, contains("projectId: 'neat-demo'"));
      expect(options, contains("storageBucket: 'neat-demo.appspot.com'"));

      // Firebase providers (firestore + auth + storage).
      final fp = File(
        '${projectDir.path}/lib/core/network/firebase_provider.dart',
      ).readAsStringSync();
      expect(fp, contains('FirebaseFirestore firestore(Ref ref)'));
      expect(fp, contains('FirebaseAuth firebaseAuth(Ref ref)'));
      expect(fp, contains('FirebaseStorage firebaseStorage(Ref ref)'));

      // Remote source talks to Firestore + a realtime snapshots stream.
      final src = File(
        '${projectDir.path}/lib/features/todo/data/sources/todo_api_source.dart',
      ).readAsStringSync();
      expect(src, contains('FirebaseFirestore'));
      expect(src, contains('_db.collection(_collection)'));
      expect(src, contains('Stream<List<TodoModel>> watchAll()'));
      expect(src, contains('.snapshots()'));

      // Repository-level DI (data/) wires the source from the firestore provider.
      final di = File(
        '${projectDir.path}/lib/features/todo/data/repositories/todo_repository_providers.dart',
      ).readAsStringSync();
      expect(di, contains('TodoApiSource(ref.watch(firestoreProvider))'));

      // Auth uses FirebaseAuth + OAuth via signInWithProvider.
      final authImpl = File(
        '${projectDir.path}/lib/features/auth/data/repositories/auth_repository_impl.dart',
      ).readAsStringSync();
      expect(authImpl, contains('FirebaseAuth'));
      expect(authImpl, contains('signInWithEmailAndPassword'));
      expect(contract['generateOAuth'], isTrue);
      expect(authImpl, contains('signInWithProvider(GoogleAuthProvider())'));
      expect(authImpl, contains('signInWithProvider(AppleAuthProvider())'));
      final iAuth = File(
        '${projectDir.path}/lib/features/auth/domain/repositories/i_auth_repository.dart',
      ).readAsStringSync();
      expect(iAuth, contains('Future<Result<bool>> signInWithGoogle();'));
      final login = File(
        '${projectDir.path}/lib/features/auth/presentation/screens/login_screen.dart',
      ).readAsStringSync();
      expect(login, contains('Continue with Google'));
      expect(login, contains('Continue with Apple'));

      // Firestore Security Rules scaffold (auth-aware) + CLI wiring.
      final rules = File(
        '${projectDir.path}/firestore.rules',
      ).readAsStringSync();
      expect(rules, contains('match /todos/{id}'));
      expect(rules, contains('request.auth != null'));
      expect(File('${projectDir.path}/firebase.json').existsSync(), isTrue);
      expect(
        File('${projectDir.path}/firestore.indexes.json').existsSync(),
        isTrue,
      );

      // Storage uses FirebaseStorage.
      final storage = File(
        '${projectDir.path}/lib/core/storage/storage_service.dart',
      ).readAsStringSync();
      expect(storage, contains('FirebaseStorage'));
      expect(storage, contains('getDownloadURL'));

      // bootstrap initializes Firebase + enables Firestore persistence.
      final bootstrap = File(
        '${projectDir.path}/lib/core/bootstrap.dart',
      ).readAsStringSync();
      expect(bootstrap, contains('Firebase.initializeApp('));
      expect(bootstrap, contains('DefaultFirebaseOptions.currentPlatform'));
      expect(bootstrap, contains('persistenceEnabled: true'));

      // Firebase deps injected; no Drift workspace package (Firestore offline).
      // ThemeEngineState.extractUiPackage defaults to true, so packages/ still
      // exists (holding the _ui package) — the actual guarantee is no
      // _database package alongside it.
      final pubspec = File(
        '${projectDir.path}/pubspec.yaml',
      ).readAsStringSync();
      expect(pubspec, contains('firebase_core:'));
      expect(pubspec, contains('firebase_auth:'));
      expect(pubspec, contains('firebase_storage:'));
      expect(
        Directory(
          '${projectDir.path}/packages/${projectName}_database',
        ).existsSync(),
        isFalse,
        reason:
            'Firebase backend should not generate a Drift workspace package',
      );

      // The whole project analyzes without errors or warnings.
      final analyze = await Process.run('flutter', [
        'analyze',
        '--no-pub',
      ], workingDirectory: projectDir.path);
      final out = '${analyze.stdout}\n${analyze.stderr}';
      expect(
        RegExp(r'(\d+ issues? found|No issues found)').hasMatch(out),
        isTrue,
        reason: 'flutter analyze did not run as expected:\n$out',
      );
      final errorLines = const LineSplitter()
          .convert(out)
          .where(
            (l) =>
                (l.contains(' error •') || l.contains(' warning •')) &&
                !l.contains('• build/'),
          )
          .toList();
      expect(
        errorLines,
        isEmpty,
        reason:
            'Firebase project analyze reported issues:\n${errorLines.join('\n')}\n\n$out',
      );
    },
    timeout: const Timeout(Duration(minutes: 12)),
  );

  test(
    'i18n (slang): setup + sample page consumption + switcher, analyzes cleanly',
    () async {
      const projectName = 'neat_i18n_test';
      final logs = <String>[];

      final pkgs = <PubPackage>[
        _dep('hooks_riverpod', '3.3.1'),
        _dep('flutter_hooks', '0.21.3+1'),
        _dep('riverpod_annotation', '4.0.2'),
        _dep('go_router', '17.2.3'),
        // freezed + json_serializable bring source_gen builders: this is the
        // combo that made slang_build_runner throw InvalidOutputException, so
        // the test guards that the slang-CLI codegen path stays clean.
        _dep('json_annotation', '4.11.0'),
        _dep('freezed_annotation', '3.1.0'),
        _dev('riverpod_generator', '4.0.3'),
        _dev('build_runner', '2.15.0'),
        _dev('freezed', '3.2.5'),
        _dev('json_serializable', '6.13.0'),
      ];

      final identity = IdentityState(
        name: projectName,
        organization: 'com.neat.test',
        projectPath: tempRoot.path,
        description: 'NEAT i18n (slang) integration test',
        targetPlatforms: const ['macos'],
      );

      try {
        await const LaunchGenerationUsecase().execute(
          identity: identity,
          packages: pkgs,
          // firstFeatureName defaults to 'home'.
          architecture: const ArchitectureState(generateI18n: true),
          cicd: const CicdState(),
          theme: const ThemeEngineState(approach: ThemeApproach.customM3),
          onLog: logs.add,
        );
      } catch (e) {
        fail('i18n generation threw:\n$e\n\n--- logs ---\n${logs.join('\n')}');
      }

      final projectDir = Directory('${tempRoot.path}/$projectName');

      final contract =
          jsonDecode(File('${projectDir.path}/.neat.json').readAsStringSync())
              as Map<String, dynamic>;
      expect(contract['generateI18n'], isTrue);

      // slang config + translation files.
      final slang = File('${projectDir.path}/slang.yaml').readAsStringSync();
      expect(slang, contains('base_locale: en'));
      expect(
        File('${projectDir.path}/lib/i18n/en.i18n.json').existsSync(),
        isTrue,
      );
      final fr = File(
        '${projectDir.path}/lib/i18n/fr.i18n.json',
      ).readAsStringSync();
      expect(fr, contains('Accueil'));

      // build_runner produced the slang codegen.
      expect(
        File('${projectDir.path}/lib/i18n/strings.g.dart').existsSync(),
        isTrue,
        reason: 'slang_build_runner did not generate strings.g.dart',
      );

      // Language switcher widget persists via LocaleStore.
      final switcher = File(
        '${projectDir.path}/lib/core/i18n/language_switcher.dart',
      ).readAsStringSync();
      expect(switcher, contains('PopupMenuButton<AppLocale>'));
      expect(switcher, contains('LocaleStore.setLocale'));

      // Locale persistence store (shared_preferences).
      final store = File(
        '${projectDir.path}/lib/core/i18n/locale_store.dart',
      ).readAsStringSync();
      expect(store, contains('SharedPreferences'));
      expect(store, contains('setLocaleRaw'));

      // bootstrap restores the persisted locale on start-up.
      final bootstrap = File(
        '${projectDir.path}/lib/core/bootstrap.dart',
      ).readAsStringSync();
      expect(bootstrap, contains('TranslationProvider('));
      expect(bootstrap, contains('LocaleStore.init()'));

      // MaterialApp is wired to the slang locale.
      final app = File('${projectDir.path}/lib/app.dart').readAsStringSync();
      expect(app, contains('AppLocaleUtils.supportedLocales'));
      expect(app, contains('GlobalMaterialLocalizations.delegates'));

      // The feature page consumes context.t + shows the switcher.
      final page = File(
        '${projectDir.path}/lib/features/home/presentation/pages/home_page.dart',
      ).readAsStringSync();
      expect(page, contains('context.t.home.title'));
      expect(page, contains('LanguageSwitcher()'));

      // Deps injected.
      final pubspec = File(
        '${projectDir.path}/pubspec.yaml',
      ).readAsStringSync();
      expect(pubspec, contains('slang:'));
      expect(pubspec, contains('slang_flutter:'));
      expect(pubspec, contains('flutter_localizations:'));
      expect(pubspec, contains('shared_preferences:'));

      // Analyze 0/0.
      final analyze = await Process.run('flutter', [
        'analyze',
        '--no-pub',
      ], workingDirectory: projectDir.path);
      final out = '${analyze.stdout}\n${analyze.stderr}';
      expect(
        RegExp(r'(\d+ issues? found|No issues found)').hasMatch(out),
        isTrue,
        reason: 'flutter analyze did not run as expected:\n$out',
      );
      final errorLines = const LineSplitter()
          .convert(out)
          .where(
            (l) =>
                (l.contains(' error •') || l.contains(' warning •')) &&
                !l.contains('• build/'),
          )
          .toList();
      expect(
        errorLines,
        isEmpty,
        reason:
            'i18n project analyze reported issues:\n${errorLines.join('\n')}\n\n$out',
      );
    },
    timeout: const Timeout(Duration(minutes: 12)),
  );

  test(
    'i18n locale selection: French-only skips the English scaffold and rebases slang',
    () async {
      const projectName = 'neat_i18n_single_locale_test';
      final logs = <String>[];

      final pkgs = <PubPackage>[
        _dep('hooks_riverpod', '3.3.1'),
        _dep('flutter_hooks', '0.21.3+1'),
        _dep('riverpod_annotation', '4.0.2'),
        _dep('go_router', '17.2.3'),
        _dep('json_annotation', '4.11.0'),
        _dep('freezed_annotation', '3.1.0'),
        _dev('riverpod_generator', '4.0.3'),
        _dev('build_runner', '2.15.0'),
        _dev('freezed', '3.2.5'),
        _dev('json_serializable', '6.13.0'),
      ];

      final identity = IdentityState(
        name: projectName,
        organization: 'com.neat.test',
        projectPath: tempRoot.path,
        description: 'NEAT i18n single-locale integration test',
        targetPlatforms: const ['macos'],
      );

      try {
        await const LaunchGenerationUsecase().execute(
          identity: identity,
          packages: pkgs,
          architecture: const ArchitectureState(
            generateI18n: true,
            // Infrastructure > Localization: only French selected — English
            // deselected via ArchitectureNotifier.toggleI18nLocale.
            i18nLocales: {'fr'},
          ),
          cicd: const CicdState(),
          theme: const ThemeEngineState(approach: ThemeApproach.customM3),
          onLog: logs.add,
        );
      } catch (e) {
        fail(
          'i18n single-locale generation threw:\n$e\n\n--- logs ---\n${logs.join('\n')}',
        );
      }

      final projectDir = Directory('${tempRoot.path}/$projectName');

      // Base locale rebased to fr — English wasn't picked, so it can't stay
      // the slang base_locale (and its scaffold file must not exist at all).
      final slang = File('${projectDir.path}/slang.yaml').readAsStringSync();
      expect(slang, contains('base_locale: fr'));
      expect(
        File('${projectDir.path}/lib/i18n/en.i18n.json').existsSync(),
        isFalse,
      );
      final fr = File(
        '${projectDir.path}/lib/i18n/fr.i18n.json',
      ).readAsStringSync();
      expect(fr, contains('Accueil'));

      expect(
        File('${projectDir.path}/lib/i18n/strings.g.dart').existsSync(),
        isTrue,
        reason: 'slang codegen did not run for the fr-only scaffold',
      );

      final analyze = await Process.run('flutter', [
        'analyze',
        '--no-pub',
      ], workingDirectory: projectDir.path);
      final out = '${analyze.stdout}\n${analyze.stderr}';
      final errorLines = const LineSplitter()
          .convert(out)
          .where(
            (l) =>
                (l.contains(' error •') || l.contains(' warning •')) &&
                !l.contains('• build/'),
          )
          .toList();
      expect(
        errorLines,
        isEmpty,
        reason:
            'fr-only i18n project analyze reported issues:\n${errorLines.join('\n')}\n\n$out',
      );
    },
    timeout: const Timeout(Duration(minutes: 12)),
  );

  test('i18n: all 5 locales each write a filename matching their own locale code '
      '(real bug: Italian used to write to pt.i18n.json, breaking slang codegen '
      'for it), analyzes cleanly', () async {
    const projectName = 'neat_i18n_all_locales_test';
    final logs = <String>[];

    final pkgs = <PubPackage>[
      _dep('hooks_riverpod', '3.3.1'),
      _dep('flutter_hooks', '0.21.3+1'),
      _dep('riverpod_annotation', '4.0.2'),
      _dep('go_router', '17.2.3'),
      _dep('json_annotation', '4.11.0'),
      _dep('freezed_annotation', '3.1.0'),
      _dev('riverpod_generator', '4.0.3'),
      _dev('build_runner', '2.15.0'),
      _dev('freezed', '3.2.5'),
      _dev('json_serializable', '6.13.0'),
    ];

    final identity = IdentityState(
      name: projectName,
      organization: 'com.neat.test',
      projectPath: tempRoot.path,
      description: 'NEAT i18n all-locales integration test',
      targetPlatforms: const ['macos'],
    );

    try {
      await const LaunchGenerationUsecase().execute(
        identity: identity,
        packages: pkgs,
        architecture: const ArchitectureState(
          generateI18n: true,
          i18nLocales: {'en', 'fr', 'de', 'es', 'it'},
        ),
        cicd: const CicdState(),
        theme: const ThemeEngineState(approach: ThemeApproach.customM3),
        onLog: logs.add,
      );
    } catch (e) {
      fail(
        'i18n all-locales generation threw:\n$e\n\n--- logs ---\n${logs.join('\n')}',
      );
    }

    final projectDir = Directory('${tempRoot.path}/$projectName');
    final i18nDir = '${projectDir.path}/lib/i18n';

    for (final code in ['en', 'fr', 'de', 'es', 'it']) {
      expect(
        File('$i18nDir/$code.i18n.json').existsSync(),
        isTrue,
        reason:
            '$code.i18n.json missing — a locale must write to its own matching filename',
      );
    }
    // The old bug's filename must never be written.
    expect(File('$i18nDir/pt.i18n.json').existsSync(), isFalse);

    expect(
      File('$i18nDir/strings.g.dart').existsSync(),
      isTrue,
      reason:
          'slang codegen did not run — a mismatched filename (the old pt/it bug) would '
          'make slang silently ignore the declared it locale instead',
    );

    final analyze = await Process.run('flutter', [
      'analyze',
      '--no-pub',
    ], workingDirectory: projectDir.path);
    final out = '${analyze.stdout}\n${analyze.stderr}';
    final errorLines = const LineSplitter()
        .convert(out)
        .where(
          (l) =>
              (l.contains(' error •') || l.contains(' warning •')) &&
              !l.contains('• build/'),
        )
        .toList();
    expect(
      errorLines,
      isEmpty,
      reason:
          'all-locales i18n project analyze reported issues:\n${errorLines.join('\n')}\n\n$out',
    );
  }, timeout: const Timeout(Duration(minutes: 12)));

  test(
    'i18n CSV upload: compact CSV becomes the slang source, analyzes cleanly',
    () async {
      const projectName = 'neat_i18n_csv_test';
      final logs = <String>[];

      // A compact CSV with three locales (es is the base = first column).
      final csv = File('${tempRoot.path}/translations.csv')
        ..writeAsStringSync(
          'key,es,en,fr\n'
          'appName,Mi app,My app,Mon app\n'
          'greeting,Hola,Hello,Bonjour\n',
        );

      final pkgs = <PubPackage>[
        _dep('hooks_riverpod', '3.3.1'),
        _dep('flutter_hooks', '0.21.3+1'),
        _dep('riverpod_annotation', '4.0.2'),
        _dep('go_router', '17.2.3'),
        _dep('json_annotation', '4.11.0'),
        _dep('freezed_annotation', '3.1.0'),
        _dev('riverpod_generator', '4.0.3'),
        _dev('build_runner', '2.15.0'),
        _dev('freezed', '3.2.5'),
        _dev('json_serializable', '6.13.0'),
      ];

      try {
        await const LaunchGenerationUsecase().execute(
          identity: IdentityState(
            name: projectName,
            organization: 'com.neat.test',
            projectPath: tempRoot.path,
            description: 'NEAT i18n CSV upload integration test',
            targetPlatforms: const ['macos'],
          ),
          packages: pkgs,
          architecture: ArchitectureState(
            generateI18n: true,
            i18nCsvPath: csv.path,
          ),
          cicd: const CicdState(),
          theme: const ThemeEngineState(approach: ThemeApproach.customM3),
          onLog: logs.add,
        );
      } catch (e) {
        fail(
          'i18n CSV generation threw:\n$e\n\n--- logs ---\n${logs.join('\n')}',
        );
      }

      final projectDir = Directory('${tempRoot.path}/$projectName');

      // The CSV is the source; the default JSON scaffold is NOT written.
      expect(
        File('${projectDir.path}/lib/i18n/strings.i18n.csv').existsSync(),
        isTrue,
      );
      expect(
        File('${projectDir.path}/lib/i18n/en.i18n.json').existsSync(),
        isFalse,
      );
      // slang.yaml points at the CSV with the first column as base locale.
      final slang = File('${projectDir.path}/slang.yaml').readAsStringSync();
      expect(slang, contains('input_file_pattern: .i18n.csv'));
      expect(slang, contains('base_locale: es'));
      // Codegen ran from the CSV.
      expect(
        File('${projectDir.path}/lib/i18n/strings.g.dart').existsSync(),
        isTrue,
      );
      // With a custom CSV we don't know the keys → the page is NOT woven.
      final page = File(
        '${projectDir.path}/lib/features/home/presentation/pages/home_page.dart',
      ).readAsStringSync();
      expect(page, isNot(contains('context.t')));

      final analyze = await Process.run('flutter', [
        'analyze',
        '--no-pub',
      ], workingDirectory: projectDir.path);
      final out = '${analyze.stdout}\n${analyze.stderr}';
      expect(
        RegExp(r'(\d+ issues? found|No issues found)').hasMatch(out),
        isTrue,
        reason: 'flutter analyze did not run as expected:\n$out',
      );
      final errorLines = const LineSplitter()
          .convert(out)
          .where(
            (l) =>
                (l.contains(' error •') || l.contains(' warning •')) &&
                !l.contains('• build/'),
          )
          .toList();
      expect(
        errorLines,
        isEmpty,
        reason:
            'i18n CSV project analyze reported issues:\n${errorLines.join('\n')}\n\n$out',
      );
    },
    timeout: const Timeout(Duration(minutes: 12)),
  );

  test(
    'flavors + fastlane: envied → 3 entry points, productFlavors, fastlane under android/ios',
    () async {
      const projectName = 'neat_flavors_test';
      final logs = <String>[];

      final pkgs = <PubPackage>[
        _dep('hooks_riverpod', '3.3.1'),
        _dep('flutter_hooks', '0.21.3+1'),
        _dep('riverpod_annotation', '4.0.2'),
        _dep('dio', '5.9.2'),
        _dep('envied', '1.3.5'),
        _dev('riverpod_generator', '4.0.3'),
        _dev('build_runner', '2.15.0'),
        _dev('envied_generator', '1.3.5'),
      ];

      try {
        await const LaunchGenerationUsecase().execute(
          identity: IdentityState(
            name: 'neat_flavors_test',
            organization: 'com.neat.test',
            projectPath: tempRoot.path,
            description: 'NEAT flavors + fastlane integration test',
          ),
          packages: pkgs,
          // Opt-in flavors + a renamed "production" env (the last = base) + a
          // pre-filled API URL on dev.
          architecture: const ArchitectureState(
            generateFlavors: true,
            // production (index 2) is the explicit base — no appId suffix there.
            baseEnvIndex: 2,
            environments: [
              EnvConfig(name: 'dev', apiBaseUrl: 'https://api.dev.test'),
              EnvConfig(name: 'staging'),
              EnvConfig(name: 'production'),
            ],
          ),
          cicd: const CicdState(selectedTools: {CiTool.fastlane}),
          theme: const ThemeEngineState(approach: ThemeApproach.customM3),
          onLog: logs.add,
        );
      } catch (e) {
        fail(
          'flavors generation threw:\n$e\n\n--- logs ---\n${logs.join('\n')}',
        );
      }

      final projectDir = Directory('${tempRoot.path}/$projectName');
      String read(String p) => File('${projectDir.path}/$p').readAsStringSync();
      bool exists(String p) => File('${projectDir.path}/$p').existsSync();

      // Entry points wire the (custom-named) envied env classes.
      expect(read('lib/main_dev.dart'), contains('bootstrap(DevEnv())'));
      expect(
        read('lib/main_staging.dart'),
        contains('bootstrap(StagingEnv())'),
      );
      expect(
        read('lib/main_production.dart'),
        contains('bootstrap(ProductionEnv())'),
      );

      // Per-env API URL pre-filled in the matching .env.
      expect(read('.env.dev'), contains('API_BASE_URL=https://api.dev.test'));
      expect(read('.env.production'), contains('API_BASE_URL=\n'));
      // The logger keys on the production (last) env.
      expect(
        read('lib/core/utils/app_logger.dart'),
        contains('is ProductionEnv'),
      );

      // VS Code run configs + the how-to.
      expect(read('.vscode/launch.json'), contains('lib/main_dev.dart'));
      expect(read('.vscode/launch.json'), contains('"--flavor", "dev"'));
      expect(exists('docs/FLAVORS.md'), isTrue);

      // Android productFlavors: dev gets a suffix, the base (production) does not.
      final gradle = read('android/app/build.gradle.kts');
      expect(gradle, contains('productFlavors'));
      expect(gradle, contains('create("dev")'));
      expect(gradle, contains('applicationIdSuffix = ".dev"'));
      expect(gradle, contains('create("production")'));
      expect(gradle, isNot(contains('applicationIdSuffix = ".production"')));
      // AGP 8+ needs resValues enabled for the per-flavor app_name (else the
      // build fails with "custom resource values, but the feature is disabled").
      expect(gradle, contains('resValues = true'));
      final manifest = read('android/app/src/main/AndroidManifest.xml');
      expect(manifest, contains('android:label="@string/app_name"'));

      // Fastlane is under android/ and ios/ — never the project root.
      expect(exists('android/fastlane/Fastfile'), isTrue);
      expect(exists('ios/fastlane/Fastfile'), isTrue);
      expect(exists('android/key.properties.example'), isTrue);
      expect(exists('fastlane/Fastfile'), isFalse);
      // The android lane is flavor-aware (envied is on).
      expect(
        read('android/fastlane/Fastfile'),
        contains('lib/main_#{flavor}.dart'),
      );
      // Secrets git-ignored.
      expect(read('.gitignore'), contains('fastlane/.env'));

      // Still analyzes cleanly (the Dart entry points compile).
      final analyze = await Process.run('flutter', [
        'analyze',
        '--no-pub',
      ], workingDirectory: projectDir.path);
      final out = '${analyze.stdout}\n${analyze.stderr}';
      expect(
        RegExp(r'(\d+ issues? found|No issues found)').hasMatch(out),
        isTrue,
        reason: 'flutter analyze did not run as expected:\n$out',
      );
      final errorLines = const LineSplitter()
          .convert(out)
          .where(
            (l) =>
                (l.contains(' error •') || l.contains(' warning •')) &&
                !l.contains('• build/'),
          )
          .toList();
      expect(
        errorLines,
        isEmpty,
        reason:
            'flavors project analyze reported issues:\n${errorLines.join('\n')}\n\n$out',
      );
    },
    timeout: const Timeout(Duration(minutes: 12)),
  );

  test(
    'single environment: collapses to one .env + Env class + main.dart (no flavors)',
    () async {
      const projectName = 'neat_single_env_test';
      final logs = <String>[];

      final pkgs = <PubPackage>[
        _dep('hooks_riverpod', '3.3.1'),
        _dep('flutter_hooks', '0.21.3+1'),
        _dep('riverpod_annotation', '4.0.2'),
        _dep('chopper', '8.6.0'),
        _dep('envied', '1.3.5'),
        _dev('riverpod_generator', '4.0.3'),
        _dev('build_runner', '2.15.0'),
        _dev('envied_generator', '1.3.5'),
        _dev('chopper_generator', '8.6.2'),
      ];

      try {
        await const LaunchGenerationUsecase().execute(
          identity: IdentityState(
            name: projectName,
            organization: 'com.neat.test',
            projectPath: tempRoot.path,
            description: 'NEAT single-env integration test',
            targetPlatforms: const ['macos'],
          ),
          packages: pkgs,
          // A single environment → no flavors, no entry points, a plain `.env`.
          // generateFlavors is irrelevant here (one env can't be flavored).
          architecture: const ArchitectureState(
            generateFlavors: true,
            environments: [
              EnvConfig(name: 'dev', apiBaseUrl: 'https://api.test'),
            ],
          ),
          cicd: const CicdState(),
          theme: const ThemeEngineState(approach: ThemeApproach.customM3),
          onLog: logs.add,
        );
      } catch (e) {
        fail(
          'single-env generation threw:\n$e\n\n--- logs ---\n${logs.join('\n')}',
        );
      }

      final projectDir = Directory('${tempRoot.path}/$projectName');
      String read(String p) => File('${projectDir.path}/$p').readAsStringSync();
      bool exists(String p) => File('${projectDir.path}/$p').existsSync();

      // Plain `.env` — never the flavored `.env.dev`.
      expect(read('.env'), contains('API_BASE_URL=https://api.test'));
      expect(exists('.env.dev'), isFalse);

      // A single `Env`/`EnvVars` reading `.env` (no <Flavor> prefix).
      expect(exists('lib/core/env/envs/env.dart'), isTrue);
      expect(exists('lib/core/env/envs/dev_env.dart'), isFalse);
      final envFile = read('lib/core/env/envs/env.dart');
      expect(envFile, contains("@Envied(path: '.env'"));
      expect(envFile, contains("part 'env.g.dart';"));
      expect(envFile, contains('abstract class EnvVars'));
      expect(envFile, contains('class Env implements AppEnv'));

      // One main.dart loading Env(); no per-env entry points / launch.json / doc.
      final mainDart = read('lib/main.dart');
      expect(mainDart, contains('bootstrap(Env())'));
      expect(mainDart, contains("import 'core/env/envs/env.dart';"));
      expect(exists('lib/main_dev.dart'), isFalse);
      expect(exists('.vscode/launch.json'), isFalse);
      expect(exists('docs/FLAVORS.md'), isFalse);

      // The whole project (incl. the envied-generated _EnvVars) analyzes clean.
      final analyze = await Process.run('flutter', [
        'analyze',
        '--no-pub',
      ], workingDirectory: projectDir.path);
      final out = '${analyze.stdout}\n${analyze.stderr}';
      final errorLines = const LineSplitter()
          .convert(out)
          .where(
            (l) =>
                (l.contains(' error •') || l.contains(' warning •')) &&
                !l.contains('• build/'),
          )
          .toList();
      expect(
        errorLines,
        isEmpty,
        reason:
            'single-env project analyze reported issues:\n${errorLines.join('\n')}\n\n$out',
      );
    },
    timeout: const Timeout(Duration(minutes: 12)),
  );

  test(
    'Sentry (CI/CD screen, opt-in): sentry_flutter dependency, DSN in .env (never a literal in '
    'bootstrap.dart), SentryFlutter.init wraps runApp, analyzes cleanly',
    () async {
      const projectName = 'neat_sentry_test';
      final logs = <String>[];

      final pkgs = <PubPackage>[
        _dep('hooks_riverpod', '3.3.1'),
        _dep('flutter_hooks', '0.21.3+1'),
        _dep('riverpod_annotation', '4.0.2'),
        _dep('chopper', '8.6.0'),
        _dep('envied', '1.3.5'),
        _dev('riverpod_generator', '4.0.3'),
        _dev('build_runner', '2.15.0'),
        _dev('envied_generator', '1.3.5'),
        _dev('chopper_generator', '8.6.2'),
      ];

      try {
        await const LaunchGenerationUsecase().execute(
          identity: IdentityState(
            name: projectName,
            organization: 'com.neat.test',
            projectPath: tempRoot.path,
            description: 'NEAT Sentry integration test',
            targetPlatforms: const ['macos'],
          ),
          packages: pkgs,
          architecture: const ArchitectureState(),
          cicd: const CicdState(
            selectedTools: {CiTool.sentry},
            sentryDsn: 'https://examplePublicKey@o0.ingest.sentry.io/0',
          ),
          theme: const ThemeEngineState(approach: ThemeApproach.customM3),
          onLog: logs.add,
        );
      } catch (e) {
        fail(
          'Sentry generation threw:\n$e\n\n--- logs ---\n${logs.join('\n')}',
        );
      }

      final projectDir = Directory('${tempRoot.path}/$projectName');
      String read(String p) => File('${projectDir.path}/$p').readAsStringSync();

      // pubspec: sentry_flutter injected (not from the packages list — it's
      // driven by the CI/CD screen's toggle, see buildPubspecContent's
      // addSentry).
      expect(read('pubspec.yaml'), contains('sentry_flutter: ^'));

      // The DSN lives in .env (single env, no flavors here), never as a
      // literal in checked-in source.
      expect(
        read('.env'),
        contains('SENTRY_DSN=https://examplePublicKey@o0.ingest.sentry.io/0'),
      );
      expect(
        read('lib/core/env/app_env.dart'),
        contains('abstract final String sentryDsn;'),
      );

      // bootstrap.dart: SentryFlutter.init wraps runApp, reads the DSN from
      // AppEnv (never the literal DSN itself), and the existing zone-guard/
      // registerErrorHandler stay in place (chained onto, not replaced).
      final bootstrap = read('lib/core/bootstrap.dart');
      expect(bootstrap, contains("import 'package:flutter/foundation.dart';"));
      expect(
        bootstrap,
        contains("import 'package:sentry_flutter/sentry_flutter.dart';"),
      );
      expect(bootstrap, contains('await SentryFlutter.init('));
      // Disabled in debug mode (kDebugMode) — local dev iteration shouldn't
      // spam a real Sentry project or burn its quota.
      expect(
        bootstrap,
        contains("options.dsn = kDebugMode ? '' : AppEnv.current.sentryDsn"),
      );
      expect(bootstrap, isNot(contains('examplePublicKey')));
      expect(bootstrap, contains('appRunner: () => runApp('));
      expect(bootstrap, contains('registerErrorHandler();'));
      expect(bootstrap, contains('runZonedGuarded'));
      expect(
        bootstrap.indexOf('registerErrorHandler();'),
        lessThan(bootstrap.indexOf('SentryFlutter.init(')),
      );

      final analyze = await Process.run('flutter', [
        'analyze',
        '--no-pub',
      ], workingDirectory: projectDir.path);
      final out = '${analyze.stdout}\n${analyze.stderr}';
      final errorLines = const LineSplitter()
          .convert(out)
          .where(
            (l) =>
                (l.contains(' error •') || l.contains(' warning •')) &&
                !l.contains('• build/'),
          )
          .toList();
      expect(
        errorLines,
        isEmpty,
        reason:
            'Sentry project analyze reported issues:\n${errorLines.join('\n')}\n\n$out',
      );
    },
    timeout: const Timeout(Duration(minutes: 12)),
  );

  test(
    'JSON-driven entity: inferred fields flow into entity/model/Drift/list, analyzes cleanly',
    () async {
      const projectName = 'neat_json_entity_test';
      final logs = <String>[];

      // A realistic Response JSON (FakeStore-ish product): mixed scalar types,
      // an int id (→ coerced String), snake_case keys (→ @JsonKey), an ISO date.
      const json = '''
        {
          "id": 7,
          "title": "Classic Tee",
          "price": 19.99,
          "in_stock": true,
          "created_at": "2024-01-31T10:00:00Z"
        }
      ''';
      final inferred = const JsonEntityInferencer().infer(json);
      expect(
        inferred.fields.map((f) => f.dartName),
        containsAll(['id', 'title', 'price', 'inStock', 'createdAt']),
      );

      final architecture = ArchitectureState(
        firstFeatureName: 'product',
        firstFeatureFields: inferred.fields,
        // Offline-first → exercises the Drift table columns from the fields.
        storageStrategy: StorageStrategy.offlineFirstRead,
      );

      try {
        await const LaunchGenerationUsecase().execute(
          identity: IdentityState(
            name: projectName,
            organization: 'com.neat.test',
            projectPath: tempRoot.path,
            description: 'NEAT JSON-driven entity test',
            targetPlatforms: const ['macos'],
          ),
          packages: packages,
          architecture: architecture,
          cicd: const CicdState(),
          theme: const ThemeEngineState(approach: ThemeApproach.customM3),
          onLog: logs.add,
        );
      } catch (e) {
        fail(
          'JSON-entity generation threw:\n$e\n\n--- logs ---\n${logs.join('\n')}',
        );
      }

      final projectDir = Directory('${tempRoot.path}/$projectName');
      String read(String p) => File('${projectDir.path}/$p').readAsStringSync();

      // Entity carries the inferred fields (id coerced to String).
      final entity = read(
        'lib/features/product/domain/entities/product_entity.dart',
      );
      expect(entity, contains('String id'));
      expect(entity, contains('double price'));
      expect(entity, contains('bool inStock'));
      expect(entity, contains('DateTime createdAt'));

      // Model maps snake_case keys with @JsonKey.
      final model = read('lib/features/product/data/models/product_model.dart');
      expect(model, contains("@JsonKey(name: 'in_stock')"));
      expect(model, contains("@JsonKey(name: 'created_at')"));

      // Drift table columns are typed per field; id stays the TextColumn PK.
      final db = read(
        'packages/${projectName}_database/lib/src/table/product_table.dart',
      );
      expect(db, contains('TextColumn get id => text()();'));
      expect(db, contains('RealColumn get price => real()();'));
      expect(db, contains('BoolColumn get inStock => boolean()();'));
      expect(db, contains('DateTimeColumn get createdAt => dateTime()();'));
      expect(db, contains('primaryKey => {id}'));

      // The list tile shows the inferred title field.
      final page = read(
        'lib/features/product/presentation/pages/product_page.dart',
      );
      expect(page, contains('Text(item.title)'));

      // The id must convert leniently, never `as String` (a real API — this one
      // included — sends an int id; a bare cast throws at runtime, and the
      // offline-first repository's broad try/catch swallows it silently,
      // surfacing as an empty list with no visible error). Static check first:
      expect(model, contains('fromJson: _idFromJson'));
      expect(model, isNot(contains("id: json['id'] as String")));

      // Then an *executable* regression probe: actually call Model.fromJson with
      // an int id and assert it doesn't throw. `flutter analyze` alone can't
      // catch this class of bug — the unsafe cast is valid Dart, it only fails
      // at runtime against a real payload.
      await File(
        '${projectDir.path}/test/_id_coercion_probe_test.dart',
      ).writeAsString('''
import 'package:flutter_test/flutter_test.dart';
import 'package:$projectName/features/product/data/models/product_model.dart';

void main() {
  test('ProductModel.fromJson coerces an int id to String', () {
    final model = ProductModel.fromJson(const {
      'id': 7,
      'title': 'Classic Tee',
      'price': 19.99,
      'in_stock': true,
      'created_at': '2024-01-31T10:00:00Z',
    });
    expect(model.id, '7');
  });
}
''');
      final probe = await Process.run('flutter', [
        'test',
        'test/_id_coercion_probe_test.dart',
      ], workingDirectory: projectDir.path);
      expect(
        probe.exitCode,
        0,
        reason:
            'id-coercion regression probe failed:\n${probe.stdout}\n${probe.stderr}',
      );

      // Whole project analyzes with zero errors/warnings (codegen included).
      final analyze = await Process.run('flutter', [
        'analyze',
        '--no-pub',
      ], workingDirectory: projectDir.path);
      final out = '${analyze.stdout}\n${analyze.stderr}';
      final errorLines = const LineSplitter()
          .convert(out)
          .where(
            (l) =>
                (l.contains(' error •') || l.contains(' warning •')) &&
                !l.contains('• build/'),
          )
          .toList();
      expect(
        errorLines,
        isEmpty,
        reason:
            'JSON-entity project analyze reported issues:\n${errorLines.join('\n')}\n\n$out',
      );
    },
    timeout: const Timeout(Duration(minutes: 12)),
  );

  test(
    'nested JSON entity: sub-classes + list + Drift JSON columns, analyzes cleanly',
    () async {
      const projectName = 'neat_nested_entity_test';
      final logs = <String>[];

      // A product with a nested object (rating) and a list of scalars (tags).
      const json = '''
        {
          "id": 7,
          "title": "Classic Tee",
          "price": 19.99,
          "rating": { "rate": 4.5, "count": 120 },
          "tags": ["summer", "cotton"]
        }
      ''';
      final inferred = const JsonEntityInferencer().infer(json);
      final rating = inferred.fields.firstWhere((f) => f.dartName == 'rating');
      expect(rating.kind, FieldKind.object);
      expect(rating.objectName, 'Rating');

      final architecture = ArchitectureState(
        firstFeatureName: 'product',
        firstFeatureFields: inferred.fields,
        // Offline-first → exercises the Drift JSON columns for nested/list fields.
        storageStrategy: StorageStrategy.offlineFirstRead,
      );

      try {
        await const LaunchGenerationUsecase().execute(
          identity: IdentityState(
            name: projectName,
            organization: 'com.neat.test',
            projectPath: tempRoot.path,
            description: 'NEAT nested JSON entity test',
            targetPlatforms: const ['macos'],
          ),
          packages: packages,
          architecture: architecture,
          cicd: const CicdState(),
          theme: const ThemeEngineState(approach: ThemeApproach.customM3),
          onLog: logs.add,
        );
      } catch (e) {
        fail(
          'nested-entity generation threw:\n$e\n\n--- logs ---\n${logs.join('\n')}',
        );
      }

      final projectDir = Directory('${tempRoot.path}/$projectName');
      String read(String p) => File('${projectDir.path}/$p').readAsStringSync();

      // Entity file carries the parent + a generated RatingEntity sub-class.
      final entity = read(
        'lib/features/product/domain/entities/product_entity.dart',
      );
      expect(entity, contains('RatingEntity rating'));
      expect(entity, contains('List<String> tags'));

      // Model file has a RatingModel with fromEntity/toEntity + the nested field.
      final model = read('lib/features/product/data/models/product_model.dart');
      expect(model, contains('RatingModel'));
      expect(model, contains('RatingModel.fromEntity'));

      // Drift stores complex fields as JSON TextColumns; local source (de)serialises.
      final db = read(
        'packages/${projectName}_database/lib/src/table/product_table.dart',
      );
      expect(db, contains('TextColumn get rating => text()();'));
      expect(db, contains('TextColumn get tags => text()();'));
      final local = read(
        'lib/features/product/data/sources/product_local_source.dart',
      );
      expect(local, contains("import 'dart:convert';"));
      expect(local, contains('jsonEncode('));
      expect(local, contains('jsonDecode('));

      // Whole project (incl. freezed + json_serializable codegen for the nested
      // model) analyzes with zero errors/warnings.
      final analyze = await Process.run('flutter', [
        'analyze',
        '--no-pub',
      ], workingDirectory: projectDir.path);
      final out = '${analyze.stdout}\n${analyze.stderr}';
      final errorLines = const LineSplitter()
          .convert(out)
          .where(
            (l) =>
                (l.contains(' error •') || l.contains(' warning •')) &&
                !l.contains('• build/'),
          )
          .toList();
      expect(
        errorLines,
        isEmpty,
        reason:
            'nested-entity project analyze reported issues:\n${errorLines.join('\n')}\n\n$out',
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
        ..writeAsBytesSync(
          base64Decode(
            'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
          ),
        );

      final identity = IdentityState(
        name: projectName,
        organization: 'com.neat.test',
        projectPath: tempRoot.path,
        description: 'NEAT branding integration test',
        targetPlatforms: const ['macos'],
      );

      final theme = ThemeEngineState(
        approach: ThemeApproach.customM3,
        logoPath: logo.path,
      );

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
        fail(
          'Branding generation threw:\n$e\n\n--- logs ---\n${logs.join('\n')}',
        );
      }

      final projectDir = Directory('${tempRoot.path}/$projectName');

      // Logo copied + both configs written.
      expect(
        File('${projectDir.path}/assets/branding/logo.png').existsSync(),
        isTrue,
        reason: 'logo not copied into the project',
      );
      expect(
        File('${projectDir.path}/flutter_launcher_icons.yaml').existsSync(),
        isTrue,
      );
      expect(
        File('${projectDir.path}/flutter_native_splash.yaml').existsSync(),
        isTrue,
      );
      // Dev deps resolved (pub get would have thrown otherwise).
      final pubspec = File(
        '${projectDir.path}/pubspec.yaml',
      ).readAsStringSync();
      expect(pubspec, contains('flutter_launcher_icons:'));
      expect(pubspec, contains('flutter_native_splash:'));

      // Branding adds only config + assets → the project still analyzes clean.
      final analyze = await Process.run('flutter', [
        'analyze',
        '--no-pub',
      ], workingDirectory: projectDir.path);
      final out = '${analyze.stdout}\n${analyze.stderr}';
      expect(
        RegExp(r'(\d+ issues? found|No issues found)').hasMatch(out),
        isTrue,
        reason: 'flutter analyze did not run as expected:\n$out',
      );
      final errorLines = const LineSplitter()
          .convert(out)
          .where(
            (l) =>
                (l.contains(' error •') || l.contains(' warning •')) &&
                !l.contains('• build/'),
          )
          .toList();
      expect(
        errorLines,
        isEmpty,
        reason:
            'branding project analyze reported issues:\n${errorLines.join('\n')}\n\n$out',
      );
    },
    timeout: const Timeout(Duration(minutes: 12)),
  );

  test('onboarding (plain go_router, no builder): generates the seen provider + page skeleton, '
      'stays unwired, analyzes cleanly', () async {
    const projectName = 'neat_onboarding_test';
    final logs = <String>[];

    final pkgs = <PubPackage>[
      _dep('hooks_riverpod', '3.3.1'),
      _dep('flutter_hooks', '0.21.3+1'),
      _dep('riverpod_annotation', '4.0.2'),
      _dep('go_router', '17.2.3'),
      _dep('json_annotation', '4.11.0'),
      _dep('freezed_annotation', '3.1.0'),
      _dev('riverpod_generator', '4.0.3'),
      _dev('build_runner', '2.15.0'),
      _dev('freezed', '3.2.5'),
      _dev('json_serializable', '6.13.0'),
    ];

    final identity = IdentityState(
      name: projectName,
      organization: 'com.neat.test',
      projectPath: tempRoot.path,
      description: 'NEAT onboarding integration test',
      targetPlatforms: const ['macos'],
    );

    try {
      await const LaunchGenerationUsecase().execute(
        identity: identity,
        packages: pkgs,
        architecture: const ArchitectureState(generateOnboarding: true),
        cicd: const CicdState(),
        theme: const ThemeEngineState(approach: ThemeApproach.customM3),
        onLog: logs.add,
      );
    } catch (e) {
      fail(
        'Onboarding generation threw:\n$e\n\n--- logs ---\n${logs.join('\n')}',
      );
    }

    final projectDir = Directory('${tempRoot.path}/$projectName');

    final contract =
        jsonDecode(File('${projectDir.path}/.neat.json').readAsStringSync())
            as Map<String, dynamic>;
    expect(contract['generateOnboarding'], isTrue);

    // The seen-flag provider.
    final provider = File(
      '${projectDir.path}/lib/core/onboarding/onboarding_seen_provider.dart',
    ).readAsStringSync();
    expect(provider, contains('@Riverpod(keepAlive: true)'));
    expect(
      provider,
      contains('class OnboardingSeen extends _\$OnboardingSeen'),
    );
    expect(provider, contains('SharedPreferences'));

    // The page skeleton.
    final page = File(
      '${projectDir.path}/lib/core/onboarding/onboarding_page.dart',
    ).readAsStringSync();
    expect(page, contains('class OnboardingPage extends HookConsumerWidget'));
    expect(page, contains('usePageController()'));
    expect(page, contains('PageView('));
    // NEAT deliberately does not wire routing — bootstrap/app_router stay
    // untouched, only the doc comment mentions the redirect example.
    expect(page, contains('redirect: (context, state) {'));

    // Not auto-wired into bootstrap or the router.
    final bootstrap = File(
      '${projectDir.path}/lib/core/bootstrap.dart',
    ).readAsStringSync();
    expect(bootstrap, isNot(contains('OnboardingSeen')));
    expect(bootstrap, isNot(contains('onboardingSeenProvider')));

    // Dep injected.
    final pubspec = File('${projectDir.path}/pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('shared_preferences:'));

    // Analyze 0/0 — the un-wired skeleton must still compile on its own.
    final analyze = await Process.run('flutter', [
      'analyze',
      '--no-pub',
    ], workingDirectory: projectDir.path);
    final out = '${analyze.stdout}\n${analyze.stderr}';
    expect(
      RegExp(r'(\d+ issues? found|No issues found)').hasMatch(out),
      isTrue,
      reason: 'flutter analyze did not run as expected:\n$out',
    );
    final errorLines = const LineSplitter()
        .convert(out)
        .where(
          (l) =>
              (l.contains(' error •') || l.contains(' warning •')) &&
              !l.contains('• build/'),
        )
        .toList();
    expect(
      errorLines,
      isEmpty,
      reason:
          'onboarding project analyze reported issues:\n${errorLines.join('\n')}\n\n$out',
    );
  }, timeout: const Timeout(Duration(minutes: 12)));

  test(
    'onboarding (go_router_builder, no Auth, shell): redirect auto-wired, analyzes cleanly',
    () async {
      const projectName = 'neat_onboarding_autowired_test';
      final logs = <String>[];

      final pkgs = <PubPackage>[
        _dep('hooks_riverpod', '3.3.1'),
        _dep('flutter_hooks', '0.21.3+1'),
        _dep('riverpod_annotation', '4.0.2'),
        _dep('go_router', '17.2.3'),
        _dep('json_annotation', '4.11.0'),
        _dep('freezed_annotation', '3.1.0'),
        _dev('riverpod_generator', '4.0.3'),
        _dev('build_runner', '2.15.0'),
        _dev('freezed', '3.2.5'),
        _dev('json_serializable', '6.13.0'),
        _dev('go_router_builder', '4.3.0'),
      ];

      final identity = IdentityState(
        name: projectName,
        organization: 'com.neat.test',
        projectPath: tempRoot.path,
        description: 'NEAT onboarding auto-wired integration test',
        targetPlatforms: const ['macos'],
      );

      try {
        await const LaunchGenerationUsecase().execute(
          identity: identity,
          packages: pkgs,
          // useNavigationShell mirrors the reported case (nexus: no Auth,
          // go_router_builder, a shell) — the onboarding route is a top-level
          // sibling of the shell, so it shouldn't interact with its branches.
          architecture: const ArchitectureState(
            generateOnboarding: true,
            useNavigationShell: true,
          ),
          cicd: const CicdState(),
          theme: const ThemeEngineState(approach: ThemeApproach.customM3),
          onLog: logs.add,
        );
      } catch (e) {
        fail(
          'Onboarding (auto-wired) generation threw:\n$e\n\n--- logs ---\n${logs.join('\n')}',
        );
      }

      final projectDir = Directory('${tempRoot.path}/$projectName');

      // Route registered.
      final routePath = File(
        '${projectDir.path}/lib/core/constants/app_route_path.dart',
      ).readAsStringSync();
      expect(
        routePath,
        contains("static const String onboarding = '/onboarding';"),
      );

      final routes = File(
        '${projectDir.path}/lib/core/onboarding/onboarding_routes.dart',
      ).readAsStringSync();
      expect(
        routes,
        contains(
          '@TypedGoRoute<OnboardingRoute>(path: AppRoutePath.onboarding)',
        ),
      );

      // routes.dart aggregates it (no separate RouterNotifier — no Auth here).
      // dart format may wrap the long import line — check substrings, not the
      // exact single-line form.
      final routesDart = File(
        '${projectDir.path}/lib/core/router/routes.dart',
      ).readAsStringSync();
      expect(routesDart, contains('core/onboarding/onboarding_routes.dart'));
      expect(routesDart, contains('as onboarding;'));
      expect(routesDart, contains(r'...onboarding.$appRoutes,'));
      expect(
        File(
          '${projectDir.path}/lib/core/router/router_notifier.dart',
        ).existsSync(),
        isFalse,
        reason:
            'no Auth in this scenario — there should be no RouterNotifier at all',
      );

      // Standalone guard wired directly in app_router.dart.
      final appRouter = File(
        '${projectDir.path}/lib/core/router/app_router.dart',
      ).readAsStringSync();
      expect(appRouter, contains('onboarding_seen_provider.dart'));
      expect(appRouter, contains('refreshListenable: seen'));
      expect(appRouter, contains('AppRoutePath.onboarding'));

      // bootstrap pre-loads the persisted flag before runApp.
      final bootstrap = File(
        '${projectDir.path}/lib/core/bootstrap.dart',
      ).readAsStringSync();
      expect(bootstrap, contains('ProviderContainer'));
      expect(bootstrap, contains('onboardingSeenProvider.notifier).load()'));
      expect(bootstrap, contains('UncontrolledProviderScope'));

      // The doc comment reflects reality — already wired, not "wire it yourself".
      final page = File(
        '${projectDir.path}/lib/core/onboarding/onboarding_page.dart',
      ).readAsStringSync();
      expect(page, contains('NEAT already wired the routing gate'));

      // AGENTS.md reflects the auto-wired case too.
      final agents = File('${projectDir.path}/AGENTS.md').readAsStringSync();
      expect(agents, contains('The routing gate is already wired'));

      // Analyze 0/0 — the real, hard part: does the generated redirect
      // actually compile (shell branches included)?
      final analyze = await Process.run('flutter', [
        'analyze',
        '--no-pub',
      ], workingDirectory: projectDir.path);
      final out = '${analyze.stdout}\n${analyze.stderr}';
      expect(
        RegExp(r'(\d+ issues? found|No issues found)').hasMatch(out),
        isTrue,
        reason: 'flutter analyze did not run as expected:\n$out',
      );
      final errorLines = const LineSplitter()
          .convert(out)
          .where(
            (l) =>
                (l.contains(' error •') || l.contains(' warning •')) &&
                !l.contains('• build/'),
          )
          .toList();
      expect(
        errorLines,
        isEmpty,
        reason:
            'onboarding (auto-wired) project analyze reported issues:\n${errorLines.join('\n')}\n\n$out',
      );
    },
    timeout: const Timeout(Duration(minutes: 12)),
  );

  test(
    'onboarding + Auth (go_router_builder): merged into RouterNotifier, one refreshListenable, analyzes cleanly',
    () async {
      const projectName = 'neat_onboarding_auth_test';
      final logs = <String>[];

      final pkgs = <PubPackage>[
        _dep('hooks_riverpod', '3.3.1'),
        _dep('flutter_hooks', '0.21.3+1'),
        _dep('riverpod_annotation', '4.0.2'),
        _dep('supabase_flutter', '2.14.1'),
        _dep('go_router', '17.2.3'),
        _dep('json_annotation', '4.11.0'),
        _dep('freezed_annotation', '3.1.0'),
        _dev('riverpod_generator', '4.0.3'),
        _dev('build_runner', '2.15.0'),
        _dev('freezed', '3.2.5'),
        _dev('json_serializable', '6.13.0'),
        _dev('go_router_builder', '4.3.0'),
      ];

      final identity = IdentityState(
        name: projectName,
        organization: 'com.neat.test',
        projectPath: tempRoot.path,
        description: 'NEAT onboarding + auth integration test',
        targetPlatforms: const ['macos'],
      );

      try {
        await const LaunchGenerationUsecase().execute(
          identity: identity,
          packages: pkgs,
          architecture: const ArchitectureState(
            generateAuth: true,
            generateOnboarding: true,
          ),
          cicd: const CicdState(),
          theme: const ThemeEngineState(approach: ThemeApproach.customM3),
          onLog: logs.add,
        );
      } catch (e) {
        fail(
          'Onboarding + Auth generation threw:\n$e\n\n--- logs ---\n${logs.join('\n')}',
        );
      }

      final projectDir = Directory('${tempRoot.path}/$projectName');

      // Merged into the existing RouterNotifier — not a second Listenable.
      final notifier = File(
        '${projectDir.path}/lib/core/router/router_notifier.dart',
      ).readAsStringSync();
      expect(notifier, contains('onboarding_seen_provider.dart'));
      expect(notifier, contains('ref.listen(onboardingSeenProvider,'));
      expect(notifier, contains('AppRoutePath.onboarding'));
      expect('implements Listenable'.allMatches(notifier).length, 1);

      // app_router.dart uses the Auth guard's shape — no standalone onboarding guard.
      final appRouter = File(
        '${projectDir.path}/lib/core/router/app_router.dart',
      ).readAsStringSync();
      expect(appRouter, contains('refreshListenable: guard'));
      expect(appRouter, isNot(contains('onboarding_seen_provider.dart')));

      // Route registered + aggregated.
      final routesDart = File(
        '${projectDir.path}/lib/core/router/routes.dart',
      ).readAsStringSync();
      expect(routesDart, contains(r'...onboarding.$appRoutes,'));
      expect(routesDart, contains(r'...auth.$appRoutes,'));

      // Analyze 0/0 — the real proof that merging into RouterNotifier compiles.
      final analyze = await Process.run('flutter', [
        'analyze',
        '--no-pub',
      ], workingDirectory: projectDir.path);
      final out = '${analyze.stdout}\n${analyze.stderr}';
      expect(
        RegExp(r'(\d+ issues? found|No issues found)').hasMatch(out),
        isTrue,
        reason: 'flutter analyze did not run as expected:\n$out',
      );
      final errorLines = const LineSplitter()
          .convert(out)
          .where(
            (l) =>
                (l.contains(' error •') || l.contains(' warning •')) &&
                !l.contains('• build/'),
          )
          .toList();
      expect(
        errorLines,
        isEmpty,
        reason:
            'onboarding+auth project analyze reported issues:\n${errorLines.join('\n')}\n\n$out',
      );
    },
    timeout: const Timeout(Duration(minutes: 12)),
  );

  test(
    'onboarding + Auth + generateFirstFeature=false (real bug: both the '
    "onboarding onDone redirect and the auth guard's post-login redirect "
    'hardcoded AppRoutePath.<the leftover wizard default firstFeatureName> '
    "instead of AppRoutePath.welcome — found in a real user's generated "
    'project via a routing reference to the unused default feature name)',
    () async {
      const projectName = 'neat_onboarding_auth_nofeature_test';
      final logs = <String>[];

      final pkgs = <PubPackage>[
        _dep('hooks_riverpod', '3.3.1'),
        _dep('flutter_hooks', '0.21.3+1'),
        _dep('riverpod_annotation', '4.0.2'),
        _dep('supabase_flutter', '2.14.1'),
        _dep('go_router', '17.2.3'),
        _dep('json_annotation', '4.11.0'),
        _dep('freezed_annotation', '3.1.0'),
        _dev('riverpod_generator', '4.0.3'),
        _dev('build_runner', '2.15.0'),
        _dev('freezed', '3.2.5'),
        _dev('json_serializable', '6.13.0'),
        _dev('go_router_builder', '4.3.0'),
      ];

      final identity = IdentityState(
        name: projectName,
        organization: 'com.neat.test',
        projectPath: tempRoot.path,
        description:
            'NEAT onboarding + auth + no-first-feature integration test',
        targetPlatforms: const ['macos'],
      );

      try {
        await const LaunchGenerationUsecase().execute(
          identity: identity,
          packages: pkgs,
          architecture: const ArchitectureState(
            generateAuth: true,
            generateOnboarding: true,
            generateFirstFeature: false,
          ),
          cicd: const CicdState(),
          theme: const ThemeEngineState(approach: ThemeApproach.customM3),
          onLog: logs.add,
        );
      } catch (e) {
        fail(
          'Onboarding + Auth + no-first-feature generation threw:\n$e\n\n--- logs ---\n${logs.join('\n')}',
        );
      }

      final projectDir = Directory('${tempRoot.path}/$projectName');

      // onboarding's "done" redirect targets the welcome placeholder, not a
      // nonexistent AppRoutePath.<default firstFeatureName> getter.
      final routes = File(
        '${projectDir.path}/lib/core/onboarding/onboarding_routes.dart',
      ).readAsStringSync();
      expect(routes, contains('context.go(AppRoutePath.welcome)'));

      // The post-login auth guard redirects there too.
      final notifier = File(
        '${projectDir.path}/lib/core/router/router_notifier.dart',
      ).readAsStringSync();
      expect(notifier, contains('AppRoutePath.welcome'));

      // app.dart's MaterialApp title is the project's own package name, never
      // the wizard's leftover default first-feature name.
      final app = File('${projectDir.path}/lib/app.dart').readAsStringSync();
      expect(app, contains("title: '$projectName'"));

      final analyze = await Process.run('flutter', [
        'analyze',
        '--no-pub',
      ], workingDirectory: projectDir.path);
      final out = '${analyze.stdout}\n${analyze.stderr}';
      expect(
        RegExp(r'(\d+ issues? found|No issues found)').hasMatch(out),
        isTrue,
        reason: 'flutter analyze did not run as expected:\n$out',
      );
      final errorLines = const LineSplitter()
          .convert(out)
          .where(
            (l) =>
                (l.contains(' error •') || l.contains(' warning •')) &&
                !l.contains('• build/'),
          )
          .toList();
      expect(
        errorLines,
        isEmpty,
        reason:
            'onboarding+auth+no-first-feature project analyze reported issues:\n'
            '${errorLines.join('\n')}\n\n$out',
      );
    },
    timeout: const Timeout(Duration(minutes: 12)),
  );

  test('onboarding + packageSplit (go_router_builder, shell, no Auth): AppRoutePath.onboarding is '
      'mirrored into the core package too, analyzes cleanly', () async {
    const projectName = 'neat_onboarding_pkgsplit_test';
    final logs = <String>[];

    final pkgs = <PubPackage>[
      _dep('hooks_riverpod', '3.3.1'),
      _dep('flutter_hooks', '0.21.3+1'),
      _dep('riverpod_annotation', '4.0.2'),
      _dep('dio', '5.9.2'),
      _dep('go_router', '17.2.3'),
      _dep('json_annotation', '4.11.0'),
      _dep('freezed_annotation', '3.1.0'),
      _dev('riverpod_generator', '4.0.3'),
      _dev('build_runner', '2.15.0'),
      _dev('freezed', '3.2.5'),
      _dev('json_serializable', '6.13.0'),
      _dev('go_router_builder', '4.3.0'),
    ];

    final identity = IdentityState(
      name: projectName,
      organization: 'com.neat.test',
      projectPath: tempRoot.path,
      description: 'NEAT onboarding + packageSplit integration test',
      targetPlatforms: const ['macos'],
    );

    try {
      await const LaunchGenerationUsecase().execute(
        identity: identity,
        packages: pkgs,
        // Mirrors the reported case (nexus_pac): packageSplit + onboarding
        // + shell, no Auth.
        architecture: const ArchitectureState(
          packageSplit: true,
          generateOnboarding: true,
          useNavigationShell: true,
        ),
        cicd: const CicdState(),
        theme: const ThemeEngineState(approach: ThemeApproach.customM3),
        onLog: logs.add,
      );
    } catch (e) {
      fail(
        'Onboarding + packageSplit generation threw:\n$e\n\n--- logs ---\n${logs.join('\n')}',
      );
    }

    final projectDir = Directory('${tempRoot.path}/$projectName');

    // AppRoutePath is single-sourced in packages/core — the app no longer
    // keeps its own (driftable, duplicate) copy at all.
    expect(
      File(
        '${projectDir.path}/lib/core/constants/app_route_path.dart',
      ).existsSync(),
      isFalse,
      reason:
          'the app should no longer write its own AppRoutePath copy when packageSplit is on '
          '— everything redirects to packages/core instead',
    );

    final coreCopy = File(
      '${projectDir.path}/packages/core/lib/core/constants/app_route_path.dart',
    ).readAsStringSync();
    expect(
      coreCopy,
      contains("static const String onboarding = '/onboarding';"),
      reason:
          'the single core copy must have onboarding — any split feature referencing it '
          '(e.g. one added later via the Workshop) would otherwise fail to compile',
    );

    // Every app-level consumer redirects its import there instead of
    // keeping/expecting a local copy.
    for (final relPath in [
      'lib/core/router/app_router.dart',
      'lib/core/router/app_shell_route.dart',
      'lib/core/onboarding/onboarding_routes.dart',
    ]) {
      final content = File('${projectDir.path}/$relPath').readAsStringSync();
      expect(
        content,
        contains("import 'package:core/core/constants/app_route_path.dart';"),
        reason:
            '$relPath should import AppRoutePath from packages/core, not a local app copy',
      );
    }

    final analyze = await Process.run('flutter', [
      'analyze',
      '--no-pub',
    ], workingDirectory: projectDir.path);
    final out = '${analyze.stdout}\n${analyze.stderr}';
    expect(
      RegExp(r'(\d+ issues? found|No issues found)').hasMatch(out),
      isTrue,
      reason: 'flutter analyze did not run as expected:\n$out',
    );
    final errorLines = const LineSplitter()
        .convert(out)
        .where(
          (l) =>
              (l.contains(' error •') || l.contains(' warning •')) &&
              !l.contains('• build/'),
        )
        .toList();
    expect(
      errorLines,
      isEmpty,
      reason:
          'onboarding+packageSplit project analyze reported issues:\n${errorLines.join('\n')}\n\n$out',
    );
  }, timeout: const Timeout(Duration(minutes: 12)));

  test(
    'offline-first + web target: driftDatabase gets a DriftWebOptions branch '
    'and docs/DRIFT_WEB_SETUP.md, and the workspace still analyzes cleanly '
    '(real bug: drift_flutter throws "the `web` parameter needs to be set" '
    'without it — found running a real generated project in Chrome)',
    () async {
      const projectName = 'neat_web_drift_test';
      final logs = <String>[];

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
        description: 'NEAT offline-first + web integration test',
        targetPlatforms: const ['web'],
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
        fail(
          'Offline-first + web generation threw:\n$e\n\n--- logs ---\n${logs.join('\n')}',
        );
      }

      final projectDir = Directory('${tempRoot.path}/$projectName');
      final pkg = '${projectName}_database';

      final dbSource = File(
        '${projectDir.path}/packages/$pkg/lib/src/database.dart',
      ).readAsStringSync();
      expect(
        dbSource,
        contains("import 'package:flutter/foundation.dart' show kIsWeb;"),
      );
      expect(dbSource, contains('if (kIsWeb) {'));
      expect(dbSource, contains('web: DriftWebOptions('));
      expect(dbSource, contains("sqlite3Wasm: Uri.parse('sqlite3.wasm')"));
      expect(
        dbSource,
        contains("driftWorker: Uri.parse('drift_worker.dart.js')"),
      );
      // Native fallback stays intact for platforms other than web.
      expect(dbSource, contains("return driftDatabase(name: 'app_db');"));

      // The one manual step left (prebuilt release binaries, not
      // template-generatable) is documented, not silently missing.
      final setupDoc = File(
        '${projectDir.path}/docs/DRIFT_WEB_SETUP.md',
      ).readAsStringSync();
      expect(setupDoc, contains('sqlite3.wasm'));
      expect(setupDoc, contains('drift_worker.dart.js'));
      expect(setupDoc, contains('packages/$pkg/pubspec.yaml'));

      final analyze = await Process.run('flutter', [
        'analyze',
        '--no-pub',
      ], workingDirectory: projectDir.path);
      final out = '${analyze.stdout}\n${analyze.stderr}';
      expect(
        RegExp(r'(\d+ issues? found|No issues found)').hasMatch(out),
        isTrue,
        reason: 'flutter analyze did not run as expected:\n$out',
      );
      final errorLines = const LineSplitter()
          .convert(out)
          .where(
            (l) =>
                (l.contains(' error •') || l.contains(' warning •')) &&
                !l.contains('• build/'),
          )
          .toList();
      expect(
        errorLines,
        isEmpty,
        reason:
            'offline-first + web project analyze reported issues:\n${errorLines.join('\n')}\n\n$out',
      );
    },
    timeout: const Timeout(Duration(minutes: 12)),
  );
}

PubPackage _dep(String name, String version) =>
    PubPackage(name: name, version: version, description: '');

PubPackage _dev(String name, String version) =>
    PubPackage(name: name, version: version, description: '', isDev: true);
