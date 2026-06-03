import 'dart:io';

import 'package:neat/features/architecture/presentation/providers/architecture_provider.dart';
import 'package:neat/features/cicd/domain/usecases/generate_yaml_usecase.dart';
import 'package:neat/features/cicd/presentation/providers/cicd_provider.dart';
import 'package:neat/features/dependencies/domain/models/pub_package.dart';
import 'package:neat/features/identity/domain/services/templates/config_templates.dart';
import 'package:neat/features/identity/domain/services/templates/core_templates.dart';
import 'package:neat/features/identity/domain/services/templates/dart/app_templates.dart';
import 'package:neat/features/identity/domain/services/templates/dart/core_dart_templates.dart';
import 'package:neat/features/identity/domain/services/templates/dart/data_templates.dart';
import 'package:neat/features/identity/domain/services/templates/dart/domain_templates.dart';
import 'package:neat/features/identity/domain/services/templates/dart/presentation_templates.dart';
import 'package:neat/features/identity/domain/services/templates/dart/state_templates.dart';
import 'package:neat/features/identity/domain/services/templates/theme_templates.dart';
import 'package:neat/features/identity/presentation/providers/identity_provider.dart';
import 'package:neat/features/theme_engine/presentation/providers/theme_engine_provider.dart';

class LaunchGenerationUsecase {
  const LaunchGenerationUsecase();

  Future<void> execute({
    required IdentityState identity,
    required List<PubPackage> packages,
    required ArchitectureState architecture,
    required CicdState cicd,
    required ThemeEngineState theme,
    required void Function(String) onLog,
  }) async {
    final projectDir = Directory('${identity.projectPath}/${identity.name}');
    final flutter = await _resolveFlutter();
    onLog('[▶] Using Flutter: $flutter');

    // 1. flutter create
    onLog("[▶] Running 'flutter create ${identity.name}'...");
    final createResult = await Process.run(flutter, [
      'create',
      '--project-name',
      identity.name,
      '-e',
      '--org',
      identity.organization,
      '--description',
      identity.description,
      '--platforms',
      identity.targetPlatforms.join(','),
      projectDir.path,
    ]);

    if (createResult.exitCode != 0) {
      throw Exception(createResult.stderr.toString().trim());
    }
    onLog('[✓] Flutter project created.');

    // 1b. .fvmrc — pin the Flutter SDK version for FVM users
    await _write(
      '${projectDir.path}/.fvmrc',
      ConfigTemplates.fvmrc(flutterVersion: identity.flutterVersion),
    );
    onLog('[✓] .fvmrc written (Flutter ${identity.flutterVersion}).');

    // Resolve feature flags from selected packages
    final hasRiverpod = packages.any((p) => p.name.contains('riverpod'));
    final hasBloc = packages.any((p) => p.name.contains('bloc'));
    final useCubit = architecture.useCubit && hasBloc;
    final useAnnotations = architecture.useRiverpodAnnotations && hasRiverpod;
    final hasGoRouterBuilder = packages.any((p) => p.name == 'go_router_builder');
    // go_router_builder requires go_router — treat it as selected even if the
    // user didn't explicitly add go_router as a standalone package.
    final hasGoRouter = packages.any((p) => p.name == 'go_router') || hasGoRouterBuilder;
    final hasFlexColorScheme = packages.any((p) => p.name == 'flex_color_scheme');
    final hasFreezed = packages.any((p) => p.name == 'freezed');
    final hasJsonSerializable = packages.any((p) => p.name == 'json_serializable');
    final hasRetrofit = packages.any((p) => p.name == 'retrofit');
    final hasChopper = packages.any((p) => p.name == 'chopper');
    final hasDio = packages.any((p) => p.name == 'dio');
    final hasHttpClient = hasRetrofit || hasChopper || hasDio;
    final httpClient = hasRetrofit
        ? 'retrofit'
        : hasChopper
        ? 'chopper'
        : hasDio
        ? 'dio'
        : '';
    final featureName = identity.name;
    final packageName = identity.name;

    // 2. Scaffold Clean Architecture directories + files
    onLog('[▶] Scaffolding Clean Architecture...');
    await _buildScaffold(
      projectDir: projectDir,
      architecture: architecture,
      packages: packages,
      featureName: featureName,
      packageName: packageName,
      hasRiverpod: hasRiverpod,
      hasBloc: hasBloc,
      useCubit: useCubit,
      useAnnotations: useAnnotations,
      hasGoRouter: hasGoRouter,
      hasGoRouterBuilder: hasGoRouterBuilder,
      hasFlexColorScheme: hasFlexColorScheme,
      hasHttpClient: hasHttpClient,
      httpClient: httpClient,
      hasFreezed: hasFreezed,
      hasJsonSerializable: hasJsonSerializable,
      theme: theme,
    );
    onLog('[✓] Scaffold created.');

    // 3. pubspec.yaml
    onLog('[▶] Configuring pubspec.yaml...');
    await _writePubspec(projectDir, packages);
    onLog('[✓] Dependencies added to pubspec.yaml.');

    // 4. CI/CD files
    if (cicd.selectedTools.isNotEmpty) {
      onLog('[▶] Generating CI/CD configuration files...');
      await _writeCicdFiles(projectDir, cicd);
      onLog('[✓] CI/CD files written.');
    }

    // 5. flutter pub get — with automatic conflict recovery
    onLog("[▶] Running 'flutter pub get'...");
    await _pubGet(projectDir, flutter, onLog);

    // 6. build_runner — only if code-gen packages are present
    final hasBuildRunner = packages.any((p) => p.name == 'build_runner');
    if (hasBuildRunner) {
      onLog(
        "[▶] Running 'dart run build_runner build' (may fail on first run due to version resolution)...",
      );
      await _runBuildRunner(projectDir, onLog);
    }

    onLog('');
    onLog('[✓✓] Project successfully generated at ${projectDir.path}');
  }

  // ── Scaffold ──────────────────────────────────────────────────────────────

  Future<void> _buildScaffold({
    required Directory projectDir,
    required ArchitectureState architecture,
    required List<PubPackage> packages,
    required String featureName,
    required String packageName,
    required bool hasRiverpod,
    required bool hasBloc,
    required bool useCubit,
    required bool useAnnotations,
    required bool hasGoRouter,
    required bool hasGoRouterBuilder,
    required bool hasFlexColorScheme,
    required bool hasHttpClient,
    required String httpClient,
    required bool hasFreezed,
    required bool hasJsonSerializable,
    required ThemeEngineState theme,
  }) async {
    final lib = '${projectDir.path}/lib';

    // ── main.dart ─────────────────────────────────────────────────────────
    await _write('$lib/main.dart', AppTemplates.mainDart(packages));

    // ── app.dart ──────────────────────────────────────────────────────────
    await _write(
      '$lib/app.dart',
      AppTemplates.appDart(
        name: featureName,
        hasGoRouter: hasGoRouter,
        hasRiverpod: hasRiverpod,
        useAnnotations: useAnnotations,
        hasBloc: hasBloc,
        useCubit: useCubit,
      ),
    );

    // ── core/result ───────────────────────────────────────────────────────
    await _write('$lib/core/result/result.dart', CoreDartTemplates.coreResultDart());
    await _write('$lib/core/usecases/use_case.dart', CoreDartTemplates.coreUsecaseDart());

    // ── core/constants ────────────────────────────────────────────────────
    await _write('$lib/core/constants/app_route_path.dart', CoreTemplates.appRoutePath());

    // ── core/error ────────────────────────────────────────────────────────
    await _write('$lib/core/error/failure.dart', CoreTemplates.failure());

    // ── core/utils ────────────────────────────────────────────────────────
    await _write('$lib/core/utils/extensions.dart', CoreTemplates.extensions());

    // ── core/theme ────────────────────────────────────────────────────────
    await _writeTheme(
      lib: lib,
      packageName: packageName,
      hasRiverpod: hasRiverpod,
      useAnnotations: useAnnotations,
      hasBloc: hasBloc,
      useCubit: useCubit,
      hasFlexColorScheme: hasFlexColorScheme,
      theme: theme,
    );

    // ── core/router ───────────────────────────────────────────────────────
    if (hasGoRouter) {
      await _writeRouter(
        lib: lib,
        packageName: packageName,
        featureName: featureName,
        hasGoRouterBuilder: hasGoRouterBuilder,
        useAnnotations: useAnnotations,
      );
    }

    // ── components ────────────────────────────────────────────────────────
    await _write('$lib/components/.gitkeep', '');

    // ── feature ───────────────────────────────────────────────────────────
    await _writeFeature(
      lib: lib,
      featureName: featureName,
      packageName: packageName,
      architecture: architecture,
      hasRiverpod: hasRiverpod,
      hasBloc: hasBloc,
      useCubit: useCubit,
      useAnnotations: useAnnotations,
      hasGoRouter: hasGoRouter,
      hasGoRouterBuilder: hasGoRouterBuilder,
      hasHttpClient: hasHttpClient,
      httpClient: httpClient,
      hasFreezed: hasFreezed,
      hasJsonSerializable: hasJsonSerializable,
    );
  }

  // ── Theme files ───────────────────────────────────────────────────────────

  Future<void> _writeTheme({
    required String lib,
    required String packageName,
    required bool hasRiverpod,
    required bool useAnnotations,
    required bool hasBloc,
    required bool useCubit,
    required bool hasFlexColorScheme,
    required ThemeEngineState theme,
  }) async {
    final t = '$lib/core/theme';

    // constant/
    await _write('$t/constant/constant.dart', ThemeTemplates.constantBarrel());
    await _write(
      '$t/constant/app_color.dart',
      ThemeTemplates.appColor(seedHex: theme.seedColorHex),
    );
    await _write('$t/constant/app_gap.dart', ThemeTemplates.appGap());

    // typography/
    await _write(
      '$t/typography/typography.dart',
      ThemeTemplates.typographyBarrel(packageName: packageName),
    );
    await _write('$t/typography/font_size.dart', ThemeTemplates.fontSize(theme.textStyles));
    await _write('$t/typography/font_weight.dart', ThemeTemplates.fontWeight(theme.fontFamily));
    await _write('$t/typography/text_style.dart', ThemeTemplates.textStyle(theme.textStyles));

    // app_theme_extensions.dart
    await _write(
      '$t/app_theme_extensions.dart',
      ThemeTemplates.appThemeExtensions(packageName: packageName),
    );

    // app_theme.dart
    final useFlexColorScheme =
        hasFlexColorScheme || theme.approach == ThemeApproach.flexColorScheme;
    await _write(
      '$t/app_theme.dart',
      ThemeTemplates.appThemeForState(
        theme: theme,
        packageName: packageName,
        forceFlex: useFlexColorScheme,
      ),
    );

    // theme mode controller
    if (hasRiverpod) {
      await _write(
        '$t/theme_mode_controller.dart',
        useAnnotations
            ? ThemeTemplates.themeModeControllerRiverpod(packageName: packageName)
            : ThemeTemplates.themeModeControllerRiverpodManual(),
      );
    }

    if (hasBloc || useCubit) {
      if (useCubit) {
        await _write('$t/brightness_theme/brightness_cubit.dart', ThemeTemplates.brightnessCubit());
        await _write(
          '$t/brightness_theme/brightness_state.dart',
          ThemeTemplates.brightnessCubitState(),
        );
      } else {
        await _write('$t/brightness_theme/brightness_bloc.dart', ThemeTemplates.brightnessBloc());
        await _write(
          '$t/brightness_theme/brightness_event.dart',
          ThemeTemplates.brightnessBlocEvent(),
        );
        await _write(
          '$t/brightness_theme/brightness_state.dart',
          ThemeTemplates.brightnessBlocState(),
        );
      }
    }
  }

  // ── Router files ──────────────────────────────────────────────────────────

  Future<void> _writeRouter({
    required String lib,
    required String packageName,
    required String featureName,
    required bool hasGoRouterBuilder,
    required bool useAnnotations,
  }) async {
    final r = '$lib/core/router';

    if (hasGoRouterBuilder) {
      await _write(
        '$r/app_router.dart',
        CoreTemplates.appRouterBuilder(
          packageName: packageName,
          featureName: featureName,
          useAnnotations: useAnnotations,
        ),
      );
      await _write(
        '$r/routes.dart',
        CoreTemplates.routesBuilder(packageName: packageName, featureName: featureName),
      );
    } else {
      await _write(
        '$r/app_router.dart',
        CoreTemplates.appRouter(packageName: packageName, featureName: featureName),
      );
      await _write(
        '$r/routes.dart',
        CoreTemplates.routesManual(packageName: packageName, featureName: featureName),
      );
    }
  }

  // ── Feature files ─────────────────────────────────────────────────────────

  Future<void> _writeFeature({
    required String lib,
    required String featureName,
    required String packageName,
    required ArchitectureState architecture,
    required bool hasRiverpod,
    required bool hasBloc,
    required bool useCubit,
    required bool useAnnotations,
    required bool hasGoRouter,
    required bool hasGoRouterBuilder,
    required bool hasHttpClient,
    required String httpClient,
    required bool hasFreezed,
    required bool hasJsonSerializable,
  }) async {
    final isFeatureFirst = architecture.pattern == StructuralPattern.featureFirst;

    String domainBase;
    String dataBase;
    String presentationBase;

    if (isFeatureFirst) {
      domainBase = '$lib/features/$featureName/domain';
      dataBase = '$lib/features/$featureName/data';
      presentationBase = '$lib/features/$featureName/presentation';
    } else {
      domainBase = '$lib/domain/$featureName';
      dataBase = '$lib/data/$featureName';
      presentationBase = '$lib/presentation/$featureName';
    }

    // domain/entities
    await _write(
      '$domainBase/entities/${featureName}_entity.dart',
      DomainTemplates.featureEntity(featureName: featureName, hasFreezed: hasFreezed),
    );

    // domain/repositories
    await _write(
      '$domainBase/repositories/i_${featureName}_repository.dart',
      DomainTemplates.featureIRepository(featureName: featureName, packageName: packageName),
    );

    // domain/usecases
    await _write(
      '$domainBase/usecases/get_${featureName}_usecase.dart',
      DomainTemplates.featureGetUsecase(featureName: featureName, packageName: packageName),
    );

    // data/models
    await _write(
      '$dataBase/models/${featureName}_model.dart',
      DataTemplates.featureModel(
        featureName: featureName,
        packageName: packageName,
        hasFreezed: hasFreezed,
        hasJsonSerializable: hasJsonSerializable,
      ),
    );

    // data/repositories
    await _write(
      '$dataBase/repositories/${featureName}_repository_impl.dart',
      DataTemplates.featureRepositoryImpl(
        featureName: featureName,
        packageName: packageName,
        hasHttpClient: hasHttpClient,
        httpClient: httpClient,
      ),
    );

    // data/sources
    if (hasHttpClient) {
      await _write(
        '$dataBase/sources/${featureName}_api_source.dart',
        DataTemplates.featureApiSource(
          featureName: featureName,
          packageName: packageName,
          httpClient: httpClient,
        ),
      );
    }
    await _write(
      '$dataBase/sources/${featureName}_local_source.dart',
      DataTemplates.featureLocalSource(featureName: featureName, packageName: packageName),
    );

    // presentation/pages
    await _write(
      '$presentationBase/pages/${featureName}_page.dart',
      PresentationTemplates.featurePage(
        featureName: featureName,
        packageName: packageName,
        hasRiverpod: hasRiverpod,
        useAnnotations: useAnnotations,
        hasBloc: hasBloc,
        useCubit: useCubit,
      ),
    );

    // presentation/providers or bloc/cubit
    if (hasRiverpod) {
      await _write(
        '$presentationBase/providers/${featureName}_provider.dart',
        PresentationTemplates.featureProvider(
          featureName: featureName,
          useAnnotations: useAnnotations,
          useCubit: false,
        ),
      );
    } else if (useCubit) {
      await _write(
        '$presentationBase/cubit/${featureName}_cubit.dart',
        StateTemplates.featureCubit(featureName: featureName),
      );
      await _write(
        '$presentationBase/cubit/${featureName}_state.dart',
        StateTemplates.featureCubitState(featureName: featureName),
      );
    } else if (hasBloc) {
      await _write(
        '$presentationBase/bloc/${featureName}_bloc.dart',
        StateTemplates.featureBloc(featureName: featureName),
      );
      await _write(
        '$presentationBase/bloc/${featureName}_event.dart',
        StateTemplates.featureBlocEvent(featureName: featureName),
      );
      await _write(
        '$presentationBase/bloc/${featureName}_state.dart',
        StateTemplates.featureBlocState(featureName: featureName),
      );
    }

    // presentation/routes — only when NOT using go_router_builder
    // (with builder, the route class lives in core/router/routes.dart)
    if (hasGoRouter && !hasGoRouterBuilder) {
      await _write(
        '$presentationBase/routes/${featureName}_route.dart',
        PresentationTemplates.featureRoute(
          featureName: featureName,
          packageName: packageName,
          useBuilder: false,
        ),
      );
    }

    // presentation/widgets
    await _write('$presentationBase/widgets/.gitkeep', '');

    // Mirror test structure
    if (architecture.mirrorTestStructure) {
      final testDomainBase = domainBase.replaceFirst('/lib/', '/test/');
      final testDataBase = dataBase.replaceFirst('/lib/', '/test/');
      final testPresentationBase = presentationBase.replaceFirst('/lib/', '/test/');
      await _write('$testDomainBase/.gitkeep', '');
      await _write('$testDataBase/.gitkeep', '');
      await _write('$testPresentationBase/.gitkeep', '');
    }
  }

  // ── File writer ───────────────────────────────────────────────────────────

  Future<void> _write(String path, String content) async {
    final file = File(path);
    await file.create(recursive: true);
    await file.writeAsString(content);
  }

  // ── pub get ───────────────────────────────────────────────────────────────

  Future<void> _pubGet(Directory projectDir, String flutter, void Function(String) onLog) async {
    final result = await Process.run(flutter, ['pub', 'get'], workingDirectory: projectDir.path);

    if (result.exitCode != 0) {
      throw Exception(result.stderr.toString().trim());
    }

    onLog('[✓] Dependencies installed.');
  }

  // ── build_runner ──────────────────────────────────────────────────────────

  Future<void> _runBuildRunner(Directory projectDir, void Function(String) onLog) async {
    final result = await Process.run(
      'dart',
      ['run', 'build_runner', 'build', '--delete-conflicting-outputs'],
      workingDirectory: projectDir.path,
      environment: {
        ...Platform.environment,
        'PATH': '${Platform.environment['PATH']}:/usr/local/bin:/opt/homebrew/bin',
      },
    );

    if (result.stdout.toString().trim().isNotEmpty) {
      onLog(result.stdout.toString().trim());
    }

    if (result.exitCode != 0) {
      final stderr = result.stderr.toString().trim();
      if (stderr.isNotEmpty) onLog('[⚠] $stderr');
      onLog('[⚠] build_runner failed — likely a version conflict (analyzer/dart_style).');
      onLog('[ℹ] Run manually once pub resolution stabilises:');
      onLog('    dart run build_runner build --delete-conflicting-outputs');
      return;
    }

    onLog('[✓] Code generation complete.');
  }

  // ── pubspec.yaml ──────────────────────────────────────────────────────────

  Future<void> _writePubspec(Directory projectDir, List<PubPackage> packages) async {
    final pubspecFile = File('${projectDir.path}/pubspec.yaml');
    if (!pubspecFile.existsSync()) return;

    final deps = StringBuffer();
    final devDeps = StringBuffer();

    // Deduplicate by name — keepAlive state can accumulate duplicates across
    // multiple generation runs if the user applies a preset on a non-empty list.
    final seen = <String>{};
    final uniquePackages = packages.where((p) => seen.add(p.name)).toList();

    final hasGoRouterBuilder = uniquePackages.any((p) => p.name == 'go_router_builder');
    final hasGoRouterExplicit = uniquePackages.any((p) => p.name == 'go_router');

    for (final pkg in uniquePackages) {
      final line = '  ${pkg.name}: ^${pkg.version}\n';
      if (pkg.isDev) {
        devDeps.write(line);
      } else {
        deps.write(line);
      }
    }

    // go_router_builder is a dev dep but requires go_router as a runtime dep.
    // Auto-inject it when missing so the generated code compiles out of the box.
    if (hasGoRouterBuilder && !hasGoRouterExplicit) {
      deps.write('  go_router: ^17.2.3\n');
    }

    // The generated typography uses google_fonts to apply the chosen font
    // family at runtime — inject it unless the user already added it.
    if (!uniquePackages.any((p) => p.name == 'google_fonts')) {
      deps.write('  google_fonts: ^8.1.0\n');
    }

    var content = await pubspecFile.readAsString();

    if (deps.isNotEmpty) {
      content = content.replaceFirst(
        'dependencies:\n  flutter:\n    sdk: flutter',
        'dependencies:\n  flutter:\n    sdk: flutter\n$deps',
      );
    }
    if (devDeps.isNotEmpty) {
      content = content.replaceFirst(
        'dev_dependencies:\n  flutter_test:\n    sdk: flutter',
        'dev_dependencies:\n  flutter_test:\n    sdk: flutter\n$devDeps',
      );
    }

    await pubspecFile.writeAsString(content);
  }

  // ── CI/CD files ───────────────────────────────────────────────────────────

  Future<void> _writeCicdFiles(Directory projectDir, CicdState cicd) async {
    final generated = const GenerateYamlUsecase().execute(cicd);

    for (final file in generated) {
      final f = File('${projectDir.path}/${file.filename}');
      await f.create(recursive: true);
      await f.writeAsString(file.content);
    }
  }

  // ── Flutter binary resolution ─────────────────────────────────────────────

  Future<String> _resolveFlutter() async {
    final candidates = [
      '/usr/local/bin/flutter',
      '/opt/homebrew/bin/flutter',
      '${Platform.environment['HOME']}/develop/flutter/bin/flutter',
      '${Platform.environment['HOME']}/flutter/bin/flutter',
      '${Platform.environment['HOME']}/fvm/default/bin/flutter',
      '${Platform.environment['HOME']}/.pub-cache/bin/flutter',
    ];

    for (final path in candidates) {
      if (File(path).existsSync()) return path;
    }

    final which = await Process.run(
      'which',
      ['flutter'],
      environment: {
        ...Platform.environment,
        'PATH': '${Platform.environment['PATH']}:/usr/local/bin:/opt/homebrew/bin',
      },
    );
    final resolved = which.stdout.toString().trim();
    if (resolved.isNotEmpty && File(resolved).existsSync()) return resolved;

    throw Exception(
      'Flutter SDK not found. Add it to PATH or install it at ~/flutter or ~/develop/flutter.',
    );
  }
}
