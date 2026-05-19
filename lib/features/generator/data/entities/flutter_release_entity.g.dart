// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'flutter_release_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FlutterReleasesResponseEntity _$FlutterReleasesResponseEntityFromJson(
  Map<String, dynamic> json,
) => FlutterReleasesResponseEntity(
  releases: (json['releases'] as List<dynamic>)
      .map((e) => FlutterReleaseItemEntity.fromJson(e as Map<String, dynamic>))
      .toList(),
);

FlutterReleaseItemEntity _$FlutterReleaseItemEntityFromJson(
  Map<String, dynamic> json,
) => FlutterReleaseItemEntity(
  version: json['version'] as String,
  channel: json['channel'] as String,
);
