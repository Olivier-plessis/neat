import 'package:freezed_annotation/freezed_annotation.dart';

part 'feature_gen_options.freezed.dart';

/// Per-feature generation choices made in the Workshop. These refine (but never
/// contradict) the project stack read from `.neat.json`.
enum FeatureRouting { root, child, shell }

@freezed
abstract class FeatureGenOptions with _$FeatureGenOptions {
  const factory FeatureGenOptions({
    @Default('') String name,
    @Default(FeatureRouting.root) FeatureRouting routing,
    @Default('') String parentFeature, // only when routing == child
    @Default('home') String shellIcon, // Material icon name, only when shell
    @Default('') String shellLabel, // NavigationBar label, only when shell
    @Default(true) bool includeRemoteDataSource,
    @Default(true) bool includeLocalDataSource,
    @Default(true) bool includeUseCase,
    @Default(true) bool includeMapper,
  }) = _FeatureGenOptions;

  const FeatureGenOptions._();

  /// The branch label shown in the NavigationBar (falls back to the feature
  /// name, capitalised, when left blank).
  String get effectiveShellLabel {
    if (shellLabel.trim().isNotEmpty) return shellLabel.trim();
    if (name.isEmpty) return '';
    return name[0].toUpperCase() + name.substring(1).replaceAll('_', ' ');
  }

  String? validateName() {
    if (name.isEmpty) return 'Feature name is required';
    if (!RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(name)) {
      return 'lowercase letters, digits & underscores; start with a letter';
    }
    return null;
  }

  bool get hasAnyDataSource => includeRemoteDataSource || includeLocalDataSource;
}
