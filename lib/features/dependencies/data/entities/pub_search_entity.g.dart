// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pub_search_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PubSearchResponseEntity _$PubSearchResponseEntityFromJson(
  Map<String, dynamic> json,
) => PubSearchResponseEntity(
  packages: (json['packages'] as List<dynamic>)
      .map((e) => PubSearchItemEntity.fromJson(e as Map<String, dynamic>))
      .toList(),
);

PubSearchItemEntity _$PubSearchItemEntityFromJson(Map<String, dynamic> json) =>
    PubSearchItemEntity(package: json['package'] as String);
