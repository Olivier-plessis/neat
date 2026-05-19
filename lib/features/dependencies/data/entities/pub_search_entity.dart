import 'package:json_annotation/json_annotation.dart';

part 'pub_search_entity.g.dart';

@JsonSerializable(createToJson: false)
class PubSearchResponseEntity {
  const PubSearchResponseEntity({required this.packages});

  final List<PubSearchItemEntity> packages;

  factory PubSearchResponseEntity.fromJson(Map<String, dynamic> json) =>
      _$PubSearchResponseEntityFromJson(json);
}

@JsonSerializable(createToJson: false)
class PubSearchItemEntity {
  const PubSearchItemEntity({required this.package});

  final String package;

  factory PubSearchItemEntity.fromJson(Map<String, dynamic> json) =>
      _$PubSearchItemEntityFromJson(json);
}
