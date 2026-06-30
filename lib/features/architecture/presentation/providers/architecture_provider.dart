import 'package:neat/features/architecture/domain/models/architecture_state.dart';
import 'package:neat/features/architecture/domain/models/env_config.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'architecture_provider.g.dart';

@Riverpod(keepAlive: true)
class ArchitectureNotifier extends _$ArchitectureNotifier {
  @override
  ArchitectureState build() => const ArchitectureState();

  void setPattern(StructuralPattern pattern) => state = state.copyWith(pattern: pattern);
  void toggleMappers(bool val) => state = state.copyWith(includeMappers: val);
  void toggleRiverpodAnnotations(bool val) => state = state.copyWith(useRiverpodAnnotations: val);
  void toggleCubit(bool val) => state = state.copyWith(useCubit: val);
  void toggleMirrorTest(bool val) => state = state.copyWith(mirrorTestStructure: val);
  void setFirstFeatureName(String val) =>
      state = state.copyWith(firstFeatureName: val.trim());
  void setStorageStrategy(StorageStrategy strategy) =>
      state = state.copyWith(storageStrategy: strategy);
  void toggleNavigationShell(bool val) => state = state.copyWith(useNavigationShell: val);
  void toggleGenerateAuth(bool val) => state = state.copyWith(generateAuth: val);
  void toggleGenerateRealtime(bool val) => state = state.copyWith(generateRealtime: val);
  void toggleGenerateStorage(bool val) => state = state.copyWith(generateStorage: val);
  void setFirebaseConfigPath(String path) =>
      state = state.copyWith(firebaseConfigPath: path.trim());
  void toggleGenerateOAuth(bool val) => state = state.copyWith(generateOAuth: val);
  void toggleGenerateI18n(bool val) => state = state.copyWith(generateI18n: val);
  void setI18nCsvPath(String path) => state = state.copyWith(i18nCsvPath: path.trim());
  void toggleGenerateFlavors(bool val) => state = state.copyWith(generateFlavors: val);

  void setEnvName(int index, String name) => _updateEnv(index, (e) => e.copyWith(name: name));
  void setEnvApiUrl(int index, String url) =>
      _updateEnv(index, (e) => e.copyWith(apiBaseUrl: url.trim()));

  void _updateEnv(int index, EnvConfig Function(EnvConfig) update) {
    if (index < 0 || index >= state.environments.length) return;
    final next = [...state.environments];
    next[index] = update(next[index]);
    state = state.copyWith(environments: next);
  }
  void setShellIcon(String icon) => state = state.copyWith(shellIcon: icon);
  void setShellLabel(String label) => state = state.copyWith(shellLabel: label);
}
