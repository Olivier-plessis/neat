import 'package:neat/features/architecture/domain/models/architecture_state.dart';
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
  void setShellIcon(String icon) => state = state.copyWith(shellIcon: icon);
  void setShellLabel(String label) => state = state.copyWith(shellLabel: label);
}
