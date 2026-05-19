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
  });

  final StructuralPattern pattern;
  final bool includeMappers;
  /// Use @riverpod annotation syntax instead of manual NotifierProvider setup
  final bool useRiverpodAnnotations;
  /// Use Cubit (simpler) instead of full Bloc with Events/States
  final bool useCubit;
  final bool mirrorTestStructure;

  ArchitectureState copyWith({
    StructuralPattern? pattern,
    bool? includeMappers,
    bool? useRiverpodAnnotations,
    bool? useCubit,
    bool? mirrorTestStructure,
  }) =>
      ArchitectureState(
        pattern: pattern ?? this.pattern,
        includeMappers: includeMappers ?? this.includeMappers,
        useRiverpodAnnotations: useRiverpodAnnotations ?? this.useRiverpodAnnotations,
        useCubit: useCubit ?? this.useCubit,
        mirrorTestStructure: mirrorTestStructure ?? this.mirrorTestStructure,
      );
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
}
