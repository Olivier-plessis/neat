import 'package:file_picker/file_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'identity_provider.g.dart';

class IdentityState {
  IdentityState({
    this.name = '',
    this.organization = 'com.example',
    this.projectPath = '',
    this.description = '',
    this.targetPlatforms = const ['android', 'ios'],
    this.flutterVersion = '3.44.x',
  });

  final String name;
  final String organization;
  final String projectPath;
  final String description;
  final List<String> targetPlatforms;
  final String flutterVersion;

  IdentityState copyWith({
    String? name,
    String? organization,
    String? projectPath,
    String? description,
    List<String>? targetPlatforms,
    String? flutterVersion,
  }) {
    return IdentityState(
      name: name ?? this.name,
      organization: organization ?? this.organization,
      projectPath: projectPath ?? this.projectPath,
      description: description ?? this.description,
      targetPlatforms: targetPlatforms ?? this.targetPlatforms,
      flutterVersion: flutterVersion ?? this.flutterVersion,
    );
  }
}

@Riverpod(keepAlive: true)
class IdentityNotifier extends _$IdentityNotifier {
  @override
  IdentityState build() => IdentityState();

  void updateName(String val) => state = state.copyWith(name: val);

  void updateOrganization(String val) => state = state.copyWith(organization: val);

  void updateDescription(String val) => state = state.copyWith(description: val);

  void updateProjectPath(String val) => state = state.copyWith(projectPath: val);

  void updateFlutterVersion(String val) => state = state.copyWith(flutterVersion: val);

  void togglePlatform(String platform) {
    final platforms = List<String>.from(state.targetPlatforms);
    if (platforms.contains(platform)) {
      platforms.remove(platform);
    } else {
      platforms.add(platform);
    }
    state = state.copyWith(targetPlatforms: platforms);
  }

  Future<void> pickDirectory() async {
    await FilePicker.skipEntitlementsChecks();
    final path = await FilePicker.getDirectoryPath();
    if (path != null) updateProjectPath(path);
  }
}

// ── Validation Extension ──────────────────────────────────────────────────────

extension IdentityValidation on IdentityState {
  /// Validates the project name according to Dart/Flutter conventions:
  /// - Lowercase letters, digits, underscores only
  /// - Must start with a letter or underscore (not a digit)
  /// - Max 50 characters
  String? validateProjectName() {
    if (name.isEmpty) return 'Project name is required';
    if (name.length > 50) return 'Project name too long (max 50 characters)';
    if (!RegExp(r'^[a-z_][a-z0-9_]*$').hasMatch(name)) {
      return 'Use lowercase letters, digits, and underscores. Start with letter or underscore.';
    }
    return null;
  }

  /// Validates the organization name as a reverse domain (com.example.app):
  /// - Lowercase letters and digits only
  /// - Each segment must start with a letter (not a digit)
  /// - Segments separated by dots
  String? validateOrganization() {
    if (organization.isEmpty) return 'Organization is required';
    if (!RegExp(r'^[a-z][a-z0-9]*(\.[a-z][a-z0-9]*)*$').hasMatch(organization)) {
      return 'Use reverse domain format: com.example.myapp';
    }
    return null;
  }

  /// Returns true if both project name and organization are valid
  bool get isIdentityValid => validateProjectName() == null && validateOrganization() == null;
}
