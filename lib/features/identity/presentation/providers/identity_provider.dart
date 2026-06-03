import 'package:file_picker/file_picker.dart';
import 'package:neat/features/identity/domain/models/identity_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'identity_provider.g.dart';

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
