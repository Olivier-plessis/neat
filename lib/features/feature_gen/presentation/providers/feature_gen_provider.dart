import 'package:neat/features/feature_gen/domain/models/feature_gen_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'feature_gen_provider.g.dart';

@riverpod
class FeatureGenNotifier extends _$FeatureGenNotifier {
  @override
  FeatureGenState build() => const FeatureGenState();

  void setName(String name) => state = state.copyWith(name: name.trim());
  void setRouting(FeatureRouting routing) => state = state.copyWith(routing: routing);
  void setParentFeature(String parent) => state = state.copyWith(parentFeature: parent.trim());
  void toggleRemoteDataSource(bool val) => state = state.copyWith(includeRemoteDataSource: val);
  void toggleLocalDataSource(bool val) => state = state.copyWith(includeLocalDataSource: val);
  void toggleUseCase(bool val) => state = state.copyWith(includeUseCase: val);
  void toggleMapper(bool val) => state = state.copyWith(includeMapper: val);
}
