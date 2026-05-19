import 'package:json_annotation/json_annotation.dart';

part 'flutter_release_entity.g.dart';

@JsonSerializable(createToJson: false)
class FlutterReleasesResponseEntity {

  factory FlutterReleasesResponseEntity.fromJson(Map<String, dynamic> json) =>
      _$FlutterReleasesResponseEntityFromJson(json);
  const FlutterReleasesResponseEntity({required this.releases});

  final List<FlutterReleaseItemEntity> releases;
}

@JsonSerializable(createToJson: false)
class FlutterReleaseItemEntity {

  factory FlutterReleaseItemEntity.fromJson(Map<String, dynamic> json) =>
      _$FlutterReleaseItemEntityFromJson(json);
  const FlutterReleaseItemEntity({
    required this.version,
    required this.channel,
  });

  final String version;
  final String channel;
}
