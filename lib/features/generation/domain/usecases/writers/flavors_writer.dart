import 'dart:io';

import 'package:neat/features/generation/domain/usecases/writers/generation_io.dart';

/// Writes native build flavors (dev/staging/prod) support: VS Code run
/// configs, the FLAVORS.md how-to doc, and (when native flavors are on) the
/// Android Gradle `productFlavors` + manifest patch — split out of
/// `LaunchGenerationUsecase` (see ROADMAP.md for the per-domain writer
/// split).
abstract final class FlavorsWriter {
  static String titleCase(String snake) => snake
      .split('_')
      .where((w) => w.isNotEmpty)
      .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');

  static String _pascalFlavor(String flavor) =>
      titleCase(flavor).replaceAll(' ', '');

  static Future<void> write(
    Directory projectDir,
    String appName,
    List<String> flavors, {
    required bool nativeFlavors,
  }) async {
    // VS Code run/debug configs, one per env (--flavor only with native flavors).
    await writeFile(
      '${projectDir.path}/.vscode/launch.json',
      _launchJson(flavors, nativeFlavors: nativeFlavors),
    );
    // How-to (covers the iOS Xcode-scheme step we can't script reliably).
    await writeFile(
      '${projectDir.path}/docs/FLAVORS.md',
      _flavorsDoc(appName, flavors, nativeFlavors: nativeFlavors),
    );
    // Android productFlavors only make sense for native (mobile) flavors.
    if (nativeFlavors) {
      await _patchAndroidFlavors(projectDir, appName, flavors);
    }
  }

  /// Inserts Gradle `productFlavors` (one per environment) before `buildTypes {`
  /// and points the manifest label at the per-flavor `@string/app_name`. The
  /// **last** flavor is the production base (no appId suffix). No-op if the
  /// flutter-created Gradle/Manifest layout isn't recognised.
  static Future<void> _patchAndroidFlavors(
    Directory projectDir,
    String appName,
    List<String> flavors,
  ) async {
    final gradle = File('${projectDir.path}/android/app/build.gradle.kts');
    if (gradle.existsSync()) {
      var src = await gradle.readAsString();
      if (!src.contains('productFlavors') && src.contains('buildTypes {')) {
        final base = flavors.last;
        final flavorsBlock = StringBuffer();
        for (final f in flavors) {
          final isBase = f == base;
          final label = isBase ? appName : '$appName ${titleCase(f)}';
          flavorsBlock.writeln('        create("$f") {');
          flavorsBlock.writeln('            dimension = "env"');
          if (!isBase) {
            flavorsBlock.writeln('            applicationIdSuffix = ".$f"');
            flavorsBlock.writeln('            versionNameSuffix = "-$f"');
          }
          flavorsBlock.writeln(
            '            resValue("string", "app_name", "$label")',
          );
          flavorsBlock.writeln('        }');
        }
        // AGP 8+ disables resValues by default; the per-flavor app_name needs it.
        final block =
            '''    buildFeatures {
        resValues = true
    }
    flavorDimensions += "env"
    productFlavors {
${flavorsBlock.toString().trimRight()}
    }

''';
        src = src.replaceFirst('    buildTypes {', '$block    buildTypes {');
        await gradle.writeAsString(src);
      }
    }

    // Point the launcher label at the flavor-provided string resource.
    final manifest = File(
      '${projectDir.path}/android/app/src/main/AndroidManifest.xml',
    );
    if (manifest.existsSync()) {
      var src = await manifest.readAsString();
      src = src.replaceAll(
        RegExp(r'android:label="[^"]*"'),
        'android:label="@string/app_name"',
      );
      await manifest.writeAsString(src);
    }
  }

  static String _launchJson(
    List<String> flavors, {
    required bool nativeFlavors,
  }) {
    String args(String f) =>
        nativeFlavors ? ',\n      "args": ["--flavor", "$f"]' : '';
    final configs = <String>[
      for (final f in flavors)
        '''    {
      "name": "${titleCase(f)} (debug)",
      "request": "launch",
      "type": "dart",
      "program": "lib/main_$f.dart"${args(f)}
    }''',
      // Release config for the production (last) env.
      '''    {
      "name": "${titleCase(flavors.last)} (release)",
      "request": "launch",
      "type": "dart",
      "flutterMode": "release",
      "program": "lib/main_${flavors.last}.dart"${args(flavors.last)}
    }''',
    ];
    return '''{
  "version": "0.2.0",
  "configurations": [
${configs.join(',\n')}
  ]
}
''';
  }

  static String _flavorsDoc(
    String appName,
    List<String> flavors, {
    required bool nativeFlavors,
  }) {
    final base = flavors.last;
    final envFiles = flavors.map((f) => '`.env.$f`').join(' / ');
    final envClasses = flavors.map((f) => '${_pascalFlavor(f)}Env').join(' / ');
    final first = flavors.first;

    // Without native flavors (web/desktop targets, or the opt-in left off), the
    // environments are pure Dart entry points: same app id, selected via `-t`.
    if (!nativeFlavors) {
      final rows = flavors
          .map((f) {
            final tag = f == base ? '`$f` *(production base)*' : '`$f`';
            return '| $tag | `lib/main_$f.dart` | `.env.$f` → ${_pascalFlavor(f)}Env |';
          })
          .join('\n');
      return '''# Environments (${flavors.join(' / ')})

This project wires ${flavors.length} environments as **Dart entry points** (no native
build flavors — your targets don't support them, or the opt-in is off). They share a
single app id and are selected by the entry point you run. The **last** env (`$base`)
is the production base.

| Environment | Entry point | Config |
| --- | --- | --- |
$rows

## Run / build

```sh
flutter run -t lib/main_$first.dart
flutter build web --release -t lib/main_$base.dart
```

VS Code: pick an environment from the Run and Debug panel (`.vscode/launch.json`).

## Config (envied)

Each env's secrets live in $envFiles, baked into the generated $envClasses classes
at `build_runner` time and selected by the entry point
(`bootstrap(${_pascalFlavor(first)}Env())`, …). The API base URL you entered is
pre-filled in each `.env.<env>`.

> Enable **native build flavors** (Infrastructure step) on an Android/iOS target to
> get separate app ids + names that install side-by-side.
''';
    }

    final rows = flavors
        .map((f) {
          final isBase = f == base;
          final suffix = isBase ? '—' : '`.$f`';
          final label = isBase ? appName : '$appName ${titleCase(f)}';
          return '| $f | `lib/main_$f.dart` | $suffix | $label |';
        })
        .join('\n');
    return '''# Build flavors (${flavors.join(' / ')})

This project ships ${flavors.length} flavors. Each pairs a **native flavor** (separate
app id + name, so they install side-by-side) with a **Dart entry point** that loads
the matching envied config. The **last** flavor (`$base`) is the production base.

| Flavor | Entry point | App id suffix | App name |
| --- | --- | --- | --- |
$rows

## Run / build

```sh
flutter run   --flavor $first -t lib/main_$first.dart
flutter build appbundle --release --flavor $base -t lib/main_$base.dart
```

VS Code: pick a flavor from the Run and Debug panel (`.vscode/launch.json`).

## Config (envied)

Each flavor's secrets live in $envFiles, baked into the generated
$envClasses classes at `build_runner` time and selected by the entry point
(`bootstrap(${_pascalFlavor(first)}Env())`, …). The API base URL you entered is
pre-filled in each `.env.<flavor>`.

## Android — done

`android/app/build.gradle.kts` defines `productFlavors`; the launcher name comes
from the per-flavor `@string/app_name`. Nothing else to do.

## iOS — one manual step

Flutter's `--flavor` needs a matching **Xcode scheme** + build configurations, which
can't be generated reliably. In Xcode: duplicate the `Runner` scheme per flavor and
add `Debug-<flavor>` / `Release-<flavor>` build configs (set
`PRODUCT_BUNDLE_IDENTIFIER` + `PRODUCT_NAME` per flavor via an `.xcconfig`). See
https://docs.flutter.dev/deployment/flavors.
''';
  }
}
