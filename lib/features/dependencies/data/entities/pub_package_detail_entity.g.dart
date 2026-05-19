// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pub_package_detail_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PubPackageDetailEntity _$PubPackageDetailEntityFromJson(
  Map<String, dynamic> json,
) => PubPackageDetailEntity(
  name: json['name'] as String,
  latest: PubPackageLatestEntity.fromJson(
    json['latest'] as Map<String, dynamic>,
  ),
);

PubPackageLatestEntity _$PubPackageLatestEntityFromJson(
  Map<String, dynamic> json,
) => PubPackageLatestEntity(
  version: json['version'] as String,
  pubspec: PubPackagePubspecEntity.fromJson(
    json['pubspec'] as Map<String, dynamic>,
  ),
);

PubPackagePubspecEntity _$PubPackagePubspecEntityFromJson(
  Map<String, dynamic> json,
) => PubPackagePubspecEntity(description: json['description'] as String?);
