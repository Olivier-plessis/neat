import 'package:json_annotation/json_annotation.dart';

part 'pub_search_entity.g.dart';

@JsonSerializable(createToJson: false)
class PubSearchResponseEntity {
  factory PubSearchResponseEntity.fromJson(Map<String, dynamic> json) =>
      _$PubSearchResponseEntityFromJson(json);

  const PubSearchResponseEntity({required this.packages});

  final List<PubSearchItemEntity> packages;
}

@JsonSerializable(createToJson: false)
class PubSearchItemEntity {
  factory PubSearchItemEntity.fromJson(Map<String, dynamic> json) =>
      _$PubSearchItemEntityFromJson(json);

  const PubSearchItemEntity({required this.package});

  final String package;
}
