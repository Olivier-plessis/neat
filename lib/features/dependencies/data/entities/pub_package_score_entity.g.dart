// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pub_package_score_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PubPackageScoreEntity _$PubPackageScoreEntityFromJson(
  Map<String, dynamic> json,
) => PubPackageScoreEntity(
  likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
  grantedPoints: (json['grantedPoints'] as num?)?.toInt() ?? 0,
  popularityScore: (json['popularityScore'] as num?)?.toDouble() ?? 0.0,
);
