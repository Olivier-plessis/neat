import 'dart:convert';
import 'dart:io';

import 'package:neat/core/contract/neat_contract.dart';

/// Shared low-level I/O and string helpers used by every writer in this
/// directory (extracted from `LaunchGenerationUsecase`, which used to hold
/// all of them as private instance methods — see ROADMAP.md for the
/// per-domain writer split this file underpins).

Future<void> writeFile(String path, String content) async {
  final file = File(path);
  await file.create(recursive: true);
  await file.writeAsString(content);
}

Future<void> appendGitignore(Directory projectDir, String content) async {
  final file = File('${projectDir.path}/.gitignore');
  if (file.existsSync()) {
    await file.writeAsString(content, mode: FileMode.append);
  } else {
    await file.writeAsString(content.trimLeft());
  }
}

String insertBeforeAnchor(String content, String anchor, String line) {
  final idx = content.indexOf(anchor);
  if (idx < 0) return content;
  final lineStart = content.lastIndexOf('\n', idx) + 1;
  return '${content.substring(0, lineStart)}$line\n${content.substring(lineStart)}';
}

String camelCase(String s) {
  final parts = s.split('_');
  final pascal = parts
      .map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1))
      .join();
  return pascal.isEmpty
      ? pascal
      : pascal[0].toLowerCase() + pascal.substring(1);
}

// No first feature → there's no `AppRoutePath.<feature>` constant to land on
// (see CoreTemplates.appRoutePath's own hasFirstFeature branch) — every "go
// home" redirect (onboarding's onDone, the post-login auth guard) must target
// the welcome placeholder instead, or it references a getter that was never
// generated.
String homeRouteExpr({
  required String featureName,
  required bool hasFirstFeature,
}) => 'AppRoutePath.${hasFirstFeature ? camelCase(featureName) : 'welcome'}';

/// Parses the uploaded Firebase config JSON into a flat map of option keys.
/// Accepts either the web app config (`{apiKey, projectId, …}`) or a nested
/// shape that wraps it under common keys. Falls back to placeholder values
/// (so the project still compiles) when no/invalid file is provided.
Map<String, dynamic> readFirebaseConfig(String path) {
  const fallback = <String, dynamic>{
    'apiKey': 'TODO_API_KEY',
    'appId': 'TODO_APP_ID',
    'messagingSenderId': 'TODO_SENDER_ID',
    'projectId': 'TODO_PROJECT_ID',
  };
  if (path.isEmpty) return fallback;
  final file = File(path);
  if (!file.existsSync()) return fallback;
  try {
    final decoded = jsonDecode(file.readAsStringSync());
    if (decoded is! Map<String, dynamic>) return fallback;
    // Unwrap common nesting (e.g. {"firebase": {...}} or {"web": {...}}).
    Map<String, dynamic> cfg = decoded;
    for (final key in const ['firebaseConfig', 'firebase', 'web', 'result']) {
      final inner = cfg[key];
      if (inner is Map<String, dynamic> && inner.containsKey('apiKey')) {
        cfg = inner;
        break;
      }
    }
    // Keep only string-valued config keys; merge over the fallback so any
    // missing required field still has a compile-safe placeholder.
    final cleaned = <String, dynamic>{...fallback};
    for (final entry in cfg.entries) {
      if (entry.value is String && (entry.value as String).isNotEmpty) {
        cleaned[entry.key] = entry.value;
      }
    }
    return cleaned;
  } catch (_) {
    return fallback;
  }
}

Future<void> pubGet(
  Directory projectDir,
  String flutter,
  void Function(String) onLog,
) async {
  final result = await Process.run(flutter, [
    'pub',
    'get',
  ], workingDirectory: projectDir.path);

  if (result.exitCode != 0) {
    throw Exception(result.stderr.toString().trim());
  }

  onLog('[✓] Dependencies installed.');
}

Future<void> runBuildRunner(
  Directory projectDir,
  void Function(String) onLog,
) async {
  final result = await Process.run(
    'dart',
    ['run', 'build_runner', 'build', '--delete-conflicting-outputs'],
    workingDirectory: projectDir.path,
    environment: {
      ...Platform.environment,
      'PATH':
          '${Platform.environment['PATH']}:/usr/local/bin:/opt/homebrew/bin',
    },
  );

  if (result.stdout.toString().trim().isNotEmpty) {
    onLog(result.stdout.toString().trim());
  }

  if (result.exitCode != 0) {
    final stderr = result.stderr.toString().trim();
    if (stderr.isNotEmpty) onLog('[⚠] $stderr');
    onLog(
      '[⚠] build_runner failed — likely a version conflict (analyzer/dart_style).',
    );
    onLog('[ℹ] Run manually once pub resolution stabilises:');
    onLog('    dart run build_runner build --delete-conflicting-outputs');
    return;
  }

  onLog('[✓] Code generation complete.');
}

Future<String> resolveFlutter() async {
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
      'PATH':
          '${Platform.environment['PATH']}:/usr/local/bin:/opt/homebrew/bin',
    },
  );
  final resolved = which.stdout.toString().trim();
  if (resolved.isNotEmpty && File(resolved).existsSync()) return resolved;

  throw Exception(
    'Flutter SDK not found. Add it to PATH or install it at ~/flutter or ~/develop/flutter.',
  );
}

Future<void> dartFormat(
  Directory projectDir,
  void Function(String) onLog,
) async {
  try {
    final result = await Process.run('dart', [
      'format',
      '.',
    ], workingDirectory: projectDir.path);
    if (result.exitCode == 0) {
      onLog('[✓] Code formatted.');
    } else {
      onLog('[!] dart format skipped: ${result.stderr.toString().trim()}');
    }
  } catch (e) {
    onLog('[!] dart format skipped: $e');
  }
}

Future<void> writeContract(Directory projectDir, NeatContract contract) async {
  const encoder = JsonEncoder.withIndent('  ');
  await writeFile(
    '${projectDir.path}/.neat.json',
    '${encoder.convert(contract.toJson())}\n',
  );
}
