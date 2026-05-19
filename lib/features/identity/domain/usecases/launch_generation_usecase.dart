import 'dart:io';

import 'package:neat/features/architecture/presentation/providers/architecture_provider.dart';
import 'package:neat/features/cicd/domain/usecases/generate_yaml_usecase.dart';
import 'package:neat/features/cicd/presentation/providers/cicd_provider.dart';
import 'package:neat/features/dependencies/domain/models/pub_package.dart';
import 'package:neat/features/identity/presentation/providers/identity_provider.dart';

// Sub-dependencies that the Flutter SDK pins strictly and that cause 95% of
// version conflicts when combining code-gen packages (build_runner, freezed,
// riverpod_generator, json_serializable…). Overriding them to `any` lets pub
// pick a mutually compatible version without touching the explicit ^version
// constraints on the user's actual packages.
const _dependencyOverrides = ['meta', 'analyzer', 'path'];

class LaunchGenerationUsecase {
  const LaunchGenerationUsecase();

  Future<void> execute({
    required IdentityState identity,
    required List<PubPackage> packages,
    required ArchitectureState architecture,
    required CicdState cicd,
    required void Function(String) onLog,
  }) async {
    final projectDir = Directory('${identity.projectPath}/${identity.name}');

    // 1. flutter create
    onLog("[▶] Running 'flutter create ${identity.name}'...");
    final createResult = await Process.run('flutter', [
      'create',
      '--project-name',
      identity.name,
      '-e',
      '--org',
      identity.organization,
      '--platforms',
      identity.targetPlatforms.join(','),
      projectDir.path,
    ]);

    if (createResult.exitCode != 0) {
      throw Exception(createResult.stderr.toString().trim());
    }
    onLog('[✓] Flutter project created.');

    // 2. Architecture directories
    onLog('[▶] Scaffolding Clean Architecture directories...');
    await _buildArchitecture(projectDir, architecture, packages);
    onLog('[✓] Directory structure created.');

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
    await _pubGet(projectDir, onLog);

    onLog('');
    onLog('[✓✓] Project successfully generated at ${projectDir.path}');
  }

  // ── pub get ───────────────────────────────────────────────────────────────

  Future<void> _pubGet(Directory projectDir, void Function(String) onLog) async {
    final result = await Process.run('flutter', ['pub', 'get'], workingDirectory: projectDir.path);

    if (result.exitCode != 0) {
      throw Exception(result.stderr.toString().trim());
    }

    onLog('[✓] Dependencies installed.');
  }

  // ── pubspec.yaml ──────────────────────────────────────────────────────────

  Future<void> _writePubspec(Directory projectDir, List<PubPackage> packages) async {
    final pubspecFile = File('${projectDir.path}/pubspec.yaml');
    if (!pubspecFile.existsSync()) return;

    final deps = StringBuffer();
    final devDeps = StringBuffer();

    for (final pkg in packages) {
      final line = '  ${pkg.name}: ^${pkg.version}\n';
      if (pkg.isDev) {
        devDeps.write(line);
      } else {
        deps.write(line);
      }
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

    // Always inject overrides for the sub-deps that the Flutter SDK pins
    // strictly — prevents conflicts between code-gen packages upfront.
    final overrides = StringBuffer('\ndependency_overrides:\n');
    for (final pkg in _dependencyOverrides) {
      overrides.writeln('  $pkg: any');
    }
    content += overrides.toString();

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

  // ── Architecture ──────────────────────────────────────────────────────────

  Future<void> _buildArchitecture(
    Directory projectDir,
    ArchitectureState arch,
    List<PubPackage> packages,
  ) async {
    final baseLib = '${projectDir.path}/lib';
    final hasRiverpod = packages.any((p) => p.name.contains('riverpod'));
    final hasBloc = packages.any((p) => p.name.contains('bloc'));

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
      await Directory(path).create(recursive: true);
      await File('$path/.gitkeep').create();
    }

    if (arch.mirrorTestStructure) {
      for (final path in paths) {
        final testPath = path.replaceFirst('/lib/', '/test/');
        await Directory(testPath).create(recursive: true);
        await File('$testPath/.gitkeep').create();
      }
    }
  }
}
