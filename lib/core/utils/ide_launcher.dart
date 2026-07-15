import 'dart:io';

/// IDEs a generated project can be opened in (via macOS LaunchServices).
enum IdeTarget {
  vscode(label: 'VS Code', appName: 'Visual Studio Code'),
  androidStudio(label: 'Android Studio', appName: 'Android Studio'),
  antigravity(label: 'Antigravity', appName: 'Antigravity IDE');

  const IdeTarget({required this.label, required this.appName});

  /// Short label shown on the button.
  final String label;

  /// The macOS application bundle name passed to `open -a`.
  final String appName;
}

/// Opens [projectPath] in [ide] using `open -a "<App>" <path>`. Returns true on
/// success, false if the IDE isn't installed (or the platform isn't macOS) so
/// the caller can surface a friendly message instead of crashing.
Future<bool> openInIde(IdeTarget ide, String projectPath) async {
  if (!Platform.isMacOS) return false;
  try {
    final result = await Process.run('open', ['-a', ide.appName, projectPath]);
    return result.exitCode == 0;
  } catch (_) {
    return false;
  }
}
