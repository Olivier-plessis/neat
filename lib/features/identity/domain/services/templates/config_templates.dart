class ConfigTemplates {
  ConfigTemplates._();

  static String pubspec({
    required String name,
    required String description,
    required String org,
    required String flutterVersion,
    required List<String> deps,
    required List<String> devDeps,
  }) =>
      '''name: $name
description: $description
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.4.0 <4.0.0'
  flutter: '>=$flutterVersion'

dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
${deps.map((d) => '  $d').join('\n')}

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
${devDeps.map((d) => '  $d').join('\n')}

flutter:
  uses-material-design: true
''';

  static String analysisOptions({bool veryGoodAnalysis = false}) => veryGoodAnalysis
      ? '''include: package:very_good_analysis/analysis_options.yaml
'''
      : '''include: package:flutter_lints/flutter.yaml
''';

  static String gitignore() => r'''# Miscellaneous
*.class
*.log
*.pyc
*.swp
.DS_Store
.atom/
.buildlog/
.history
.svn/
migrate_working_dir/

# IntelliJ related
*.iml
*.ipr
*.iws
.idea/

# The .vscode folder contains launch configuration and tasks you configure in
# VS Code which you may wish to be included in version control, so this is
# intentionally not ignored. Remove the # below to ignore it.
# .vscode/

# Flutter/Dart/Pub related
**/doc/api/
**/ios/Flutter/.last_build_id
.dart_tool/
.flutter-plugins
.flutter-plugins-dependencies
.packages
.pub-cache/
.pub/
/build/

# Symbolication related
app.*.symbols

# Obfuscation related
app.*.map.json

# Android Studio will place build artifacts here
/android/app/debug
/android/app/profile
/android/app/release
''';

  static String readme({required String name, required String description}) => '''# $name

$description

## Getting started

1. Install dependencies:
   ```bash
   flutter pub get
   ```

2. Run code generation:
   ```bash
   dart run build_runner build
   ```

3. Run the app:
   ```bash
   flutter run
   ```

## Architecture

This project was scaffolded with [NEAT](https://neat.dev) using Clean Architecture.

## License

MIT
''';
}
