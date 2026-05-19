import 'package:file_picker/file_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'identity_provider.g.dart';

class IdentityState {
  IdentityState({
    this.name = '',
    this.organization = 'com.example',
    this.projectPath = '',
    this.targetPlatforms = const ['android', 'ios'],
    this.flutterVersion = '3.44.x',
  });
  final String name;
  final String organization;
  final String projectPath;
  final List<String> targetPlatforms;
  final String flutterVersion;

  IdentityState copyWith({
    String? name,
    String? organization,
    String? projectPath,
    List<String>? targetPlatforms,
    String? flutterVersion,
  }) {
    return IdentityState(
      name: name ?? this.name,
      organization: organization ?? this.organization,
      projectPath: projectPath ?? this.projectPath,
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
  void updateOrganization(String val) =>
      state = state.copyWith(organization: val);
  void updateProjectPath(String val) =>
      state = state.copyWith(projectPath: val);
  void updateFlutterVersion(String val) =>
      state = state.copyWith(flutterVersion: val);

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
    final path = await FilePicker.getDirectoryPath();
    if (path != null) updateProjectPath(path);
  }
}
