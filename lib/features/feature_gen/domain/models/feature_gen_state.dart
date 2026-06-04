import 'package:freezed_annotation/freezed_annotation.dart';

part 'feature_gen_state.freezed.dart';

enum FeatureRouting { root, child, shell }

@freezed
abstract class FeatureGenState with _$FeatureGenState {
  const factory FeatureGenState({
    @Default('') String name,
    @Default(FeatureRouting.root) FeatureRouting routing,
    @Default('') String parentFeature, // only if routing == child
    @Default(true) bool includeRemoteDataSource,
    @Default(false) bool includeLocalDataSource,
    @Default(true) bool includeUseCase,
    @Default(true) bool includeMapper,
  }) = _FeatureGenState;

  const FeatureGenState._();

  String? validateName() {
    if (name.isEmpty) return 'Feature name is required';
    if (!RegExp(r'^[a-z_][a-z0-9_]*$').hasMatch(name)) {
      return 'Use lowercase letters, digits, and underscores. Start with letter or underscore.';
    }
    return null;
  }
}
