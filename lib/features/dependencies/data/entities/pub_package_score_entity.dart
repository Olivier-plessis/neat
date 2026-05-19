import 'package:json_annotation/json_annotation.dart';

part 'pub_package_score_entity.g.dart';

@JsonSerializable(createToJson: false)
class PubPackageScoreEntity {
  const PubPackageScoreEntity({
    this.likeCount = 0,
    this.grantedPoints = 0,
    this.popularityScore = 0.0,
  });

  @JsonKey(defaultValue: 0)
  final int likeCount;
  @JsonKey(defaultValue: 0)
  final int grantedPoints;
  @JsonKey(defaultValue: 0.0)
  final double popularityScore; // 0.0 → 1.0

  factory PubPackageScoreEntity.fromJson(Map<String, dynamic> json) =>
      _$PubPackageScoreEntityFromJson(json);
}
