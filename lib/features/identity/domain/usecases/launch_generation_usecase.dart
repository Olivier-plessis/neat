import 'dart:io';

import 'package:neat/features/architecture/presentation/providers/architecture_provider.dart';
import 'package:neat/features/cicd/domain/usecases/generate_yaml_usecase.dart';
import 'package:neat/features/cicd/presentation/providers/cicd_provider.dart';
import 'package:neat/features/dependencies/domain/models/pub_package.dart';
import 'package:neat/features/identity/domain/services/templates/config_templates.dart';
import 'package:neat/features/identity/domain/services/templates/dart_templates.dart';
import 'package:neat/features/identity/domain/services/templates/platform_templates.dart';
import 'package:neat/features/identity/presentation/providers/identity_provider.dart';

class LaunchGenerationUsecase {
  const LaunchGenerationUsecase();

  Future<void> execute({
    required IdentityState identity,
    required List<PubPackage> packages,
    required ArchitectureState architecture,
    required CicdState cicd,
    required void Function(String) onLog,
  }) async {
    final root = '${identity.projectPath}/${identity.name}';
    final name = identity.name;
    final org = identity.organization;
    final platforms = identity.targetPlatforms;
    final hasRiverpod = packages.any((p) => p.name.contains('riverpod'));
    final hasBloc = packages.any((p) => p.name.contains('bloc'));

    // ── Root files ────────────────────────────────────────────────────────────

    onLog('[▶] Creating project structure...');
    await _dir(root);

    await _write('$root/pubspec.yaml', ConfigTemplates.pubspec(
      name: name,
      description: 'A new Flutter project.',
      org: org,
      flutterVersion: identity.flutterVersion,
      deps: packages.where((p) => !p.isDev).map((p) => '${p.name}: ^${p.version}').toList(),
      devDeps: packages.where((p) => p.isDev).map((p) => '${p.name}: ^${p.version}').toList(),
    ));

    await _write('$root/analysis_options.yaml', ConfigTemplates.analysisOptions());
    await _write('$root/.gitignore', ConfigTemplates.gitignore());
    await _write('$root/README.md', ConfigTemplates.readme(name: name, description: 'A new Flutter project.'));
    onLog('[✓] Root config files written.');

    // ── lib/ ──────────────────────────────────────────────────────────────────

    onLog('[▶] Writing Dart source files...');
    await _dir('$root/lib');
    await _write('$root/lib/main.dart', DartTemplates.mainDart(packages));
    await _write('$root/lib/app.dart', DartTemplates.appDart(name: name));

    // core/
    await _dir('$root/lib/core');
    await _write('$root/lib/core/result.dart', DartTemplates.coreResultDart());
    await _write('$root/lib/core/usecase.dart', DartTemplates.coreUsecaseDart());
    onLog('[✓] lib/ files written.');

    // ── Architecture ──────────────────────────────────────────────────────────

    onLog('[▶] Scaffolding Clean Architecture directories...');
    await _buildArchitecture(root, architecture, packages, hasRiverpod: hasRiverpod, hasBloc: hasBloc);
    onLog('[✓] Directory structure created.');

    // ── Platform files ────────────────────────────────────────────────────────

    onLog('[▶] Writing platform files...');

    if (platforms.contains('android')) {
      await _writeAndroid(root, org: org, name: name);
      onLog('[✓] Android files written.');
    }

    if (platforms.contains('ios')) {
      await _writeIos(root, org: org, name: name);
      onLog('[✓] iOS files written.');
    }

    if (platforms.contains('web')) {
      await _writeWeb(root, name: name);
      onLog('[✓] Web files written.');
    }

    if (platforms.contains('macos')) {
      await _writeMacos(root, name: name);
      onLog('[✓] macOS files written.');
    }

    if (platforms.contains('linux')) {
      await _writeLinux(root, name: name);
      onLog('[✓] Linux files written.');
    }

    if (platforms.contains('windows')) {
      await _writeWindows(root, name: name);
      onLog('[✓] Windows files written.');
    }

    // ── test/ ─────────────────────────────────────────────────────────────────

    await _dir('$root/test');
    await _write('$root/test/.gitkeep', DartTemplates.gitkeep());

    // ── CI/CD ─────────────────────────────────────────────────────────────────

    if (cicd.selectedTools.isNotEmpty) {
      onLog('[▶] Generating CI/CD configuration files...');
      final generated = const GenerateYamlUsecase().execute(cicd);
      for (final file in generated) {
        await _write('$root/${file.filename}', file.content);
      }
      onLog('[✓] CI/CD files written.');
    }

    // ── Done ──────────────────────────────────────────────────────────────────

    onLog('');
    onLog('[✓✓] Project generated at $root');
    onLog('');
    onLog('[!] Next step: run the following command to install dependencies:');
    onLog('    cd $root && flutter pub get');
  }

  // ── Android ─────────────────────────────────────────────────────────────────

  Future<void> _writeAndroid(String root, {required String org, required String name}) async {
    final base = '$root/android';
    final pkg = '$org/$name'.replaceAll('.', '/');

    await _write('$base/app/src/main/AndroidManifest.xml',
        PlatformTemplates.androidManifest(org: org, name: name));
    await _write('$base/app/src/main/kotlin/$pkg/MainActivity.kt',
        PlatformTemplates.androidMainActivity(org: org, name: name));
    await _write('$base/app/build.gradle',
        PlatformTemplates.androidBuildGradle(org: org, name: name));
    await _write('$base/build.gradle', PlatformTemplates.androidRootBuildGradle());
    await _write('$base/settings.gradle', PlatformTemplates.androidSettings(name: name));
    await _write('$base/gradle.properties', PlatformTemplates.androidGradleProperties());
    await _write('$base/local.properties', PlatformTemplates.androidLocalProperties());
  }

  // ── iOS ──────────────────────────────────────────────────────────────────────

  Future<void> _writeIos(String root, {required String org, required String name}) async {
    final base = '$root/ios';

    await _write('$base/Runner/AppDelegate.swift', PlatformTemplates.iosAppDelegate());
    await _write('$base/Runner/Info.plist', PlatformTemplates.iosInfoPlist(name: name, org: org));
    await _write('$base/Podfile', PlatformTemplates.iosPodfile(org: org, name: name));
  }

  // ── Web ──────────────────────────────────────────────────────────────────────

  Future<void> _writeWeb(String root, {required String name}) async {
    final base = '$root/web';

    await _write('$base/index.html', PlatformTemplates.webIndex(name: name));
    await _write('$base/manifest.json', PlatformTemplates.webManifest(name: name));
  }

  // ── macOS ────────────────────────────────────────────────────────────────────

  Future<void> _writeMacos(String root, {required String name}) async {
    final base = '$root/macos';

    await _write('$base/Runner/AppDelegate.swift', PlatformTemplates.macosAppDelegate());
    await _write('$base/Runner/MainFlutterWindow.swift', PlatformTemplates.macosMainFlutterWindow());
    await _write('$base/Runner/Info.plist', PlatformTemplates.macosInfoPlist(name: name));
    await _write('$base/Runner/DebugProfile.entitlements', PlatformTemplates.macosDebugEntitlements());
    await _write('$base/Runner/Release.entitlements', PlatformTemplates.macosReleaseEntitlements());
  }

  // ── Linux ────────────────────────────────────────────────────────────────────

  Future<void> _writeLinux(String root, {required String name}) async {
    final base = '$root/linux/runner';

    await _write('$base/CMakeLists.txt', PlatformTemplates.linuxCmakeLists(name: name));
  }

  // ── Windows ──────────────────────────────────────────────────────────────────

  Future<void> _writeWindows(String root, {required String name}) async {
    final base = '$root/windows/runner';

    await _write('$base/CMakeLists.txt', PlatformTemplates.windowsCmakeLists(name: name));
  }

  // ── Architecture ─────────────────────────────────────────────────────────────

  Future<void> _buildArchitecture(
    String root,
    ArchitectureState arch,
    List<PubPackage> packages, {
    required bool hasRiverpod,
    required bool hasBloc,
  }) async {
    final baseLib = '$root/lib';
    final paths = <String>[];

    if (arch.pattern == StructuralPattern.featureFirst) {
      final base = '$baseLib/features/auth';
      paths.addAll([
        '$base/data/datasources',
        '$base/data/entities',
        if (arch.includeMappers) '$base/data/mappers',
        '$base/data/repositories',
        '$base/domain/models',
        '$base/domain/repositories',
        '$base/domain/usecases',
        '$base/presentation/screens',
        if (hasRiverpod) '$base/presentation/providers',
        if (hasBloc) '$base/presentation/${arch.useCubit ? 'cubits' : 'bloc'}',
      ]);
    } else {
      paths.addAll([
        '$baseLib/data/auth/datasources',
        '$baseLib/data/auth/entities',
        if (arch.includeMappers) '$baseLib/data/auth/mappers',
        '$baseLib/data/auth/repositories',
        '$baseLib/domain/auth/models',
        '$baseLib/domain/auth/repositories',
        '$baseLib/domain/auth/usecases',
        '$baseLib/presentation/auth/screens',
        if (hasRiverpod) '$baseLib/presentation/auth/providers',
        if (hasBloc) '$baseLib/presentation/auth/${arch.useCubit ? 'cubits' : 'bloc'}',
      ]);
    }

    for (final path in paths) {
      await _dir(path);
      await _write('$path/.gitkeep', DartTemplates.gitkeep());
    }

    // Example feature files in auth
    final featureName = 'auth';
    final presentationBase = arch.pattern == StructuralPattern.featureFirst
        ? '$baseLib/features/$featureName/domain'
        : '$baseLib/domain/$featureName';

    await _write('$presentationBase/usecases/example_usecase.dart',
        DartTemplates.featureExampleUsecase(featureName: featureName));
    await _write('$presentationBase/models/${featureName}_model.dart',
        DartTemplates.featureExampleModel(featureName: featureName));

    if (hasRiverpod || hasBloc) {
      final providerBase = arch.pattern == StructuralPattern.featureFirst
          ? '$baseLib/features/$featureName/presentation'
          : '$baseLib/presentation/$featureName';

      await _write(
        '$providerBase/providers/${featureName}_provider.dart',
        DartTemplates.featureProvider(
          featureName: featureName,
          useAnnotations: arch.useRiverpodAnnotations,
          useCubit: arch.useCubit,
        ),
      );
    }

    if (arch.mirrorTestStructure) {
      for (final path in paths) {
        final testPath = path.replaceFirst('/lib/', '/test/');
        await _dir(testPath);
        await _write('$testPath/.gitkeep', DartTemplates.gitkeep());
      }
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────

  Future<void> _dir(String path) async {
    await Directory(path).create(recursive: true);
  }

  Future<void> _write(String path, String content) async {
    final file = File(path);
    await file.parent.create(recursive: true);
    await file.writeAsString(content);
  }
}
