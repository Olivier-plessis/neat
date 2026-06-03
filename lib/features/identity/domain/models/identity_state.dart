import 'package:freezed_annotation/freezed_annotation.dart';

part 'identity_state.freezed.dart';

/// Project identity (name, org, path, target platforms) chosen in the wizard.
///
/// Pure domain value object — no Flutter/Riverpod imports — so domain usecases
/// (e.g. generation) can consume it without depending on the presentation layer.
@freezed
abstract class IdentityState with _$IdentityState {
  const factory IdentityState({
    @Default('') String name,
    @Default('com.example') String organization,
    @Default('') String projectPath,
    @Default('') String description,
    @Default(['android', 'ios']) List<String> targetPlatforms,
    @Default('3.44.x') String flutterVersion,
  }) = _IdentityState;
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
