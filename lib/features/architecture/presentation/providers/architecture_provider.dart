import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'architecture_provider.g.dart';

enum StructuralPattern { featureFirst, layerFirst }

class ArchitectureState {
  const ArchitectureState({
    this.pattern = StructuralPattern.featureFirst,
    this.includeMappers = true,
    this.useRiverpodAnnotations = true,
    this.useCubit = false,
    this.mirrorTestStructure = true,
    this.firstFeatureName = 'home',
  });

  final StructuralPattern pattern;
  final bool includeMappers;
  /// Use @riverpod annotation syntax instead of manual NotifierProvider setup
  final bool useRiverpodAnnotations;
  /// Use Cubit (simpler) instead of full Bloc with Events/States
  final bool useCubit;
  final bool mirrorTestStructure;

  /// Name of the first feature scaffolded under lib/features/ (snake_case).
  final String firstFeatureName;

  ArchitectureState copyWith({
    StructuralPattern? pattern,
    bool? includeMappers,
    bool? useRiverpodAnnotations,
    bool? useCubit,
    bool? mirrorTestStructure,
    String? firstFeatureName,
  }) =>
      ArchitectureState(
        pattern: pattern ?? this.pattern,
        includeMappers: includeMappers ?? this.includeMappers,
        useRiverpodAnnotations: useRiverpodAnnotations ?? this.useRiverpodAnnotations,
        useCubit: useCubit ?? this.useCubit,
        mirrorTestStructure: mirrorTestStructure ?? this.mirrorTestStructure,
        firstFeatureName: firstFeatureName ?? this.firstFeatureName,
      );

  /// Validates the first feature name (Dart folder/identifier rules).
  String? validateFirstFeatureName() {
    if (firstFeatureName.isEmpty) return 'Feature name is required';
    if (!RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(firstFeatureName)) {
      return 'lowercase letters, digits & underscores; start with a letter';
    }
    return null;
  }
}

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
}
