import 'package:json_annotation/json_annotation.dart';

part 'pub_package_detail_entity.g.dart';

@JsonSerializable(createToJson: false)
class PubPackageDetailEntity {
  const PubPackageDetailEntity({required this.name, required this.latest});

  final String name;
  final PubPackageLatestEntity latest;

  factory PubPackageDetailEntity.fromJson(Map<String, dynamic> json) =>
      _$PubPackageDetailEntityFromJson(json);
}

@JsonSerializable(createToJson: false)
class PubPackageLatestEntity {
  const PubPackageLatestEntity({required this.version, required this.pubspec});

  final String version;
  final PubPackagePubspecEntity pubspec;

  factory PubPackageLatestEntity.fromJson(Map<String, dynamic> json) =>
      _$PubPackageLatestEntityFromJson(json);
}

@JsonSerializable(createToJson: false)
class PubPackagePubspecEntity {
  const PubPackagePubspecEntity({this.description});

  final String? description;

  factory PubPackagePubspecEntity.fromJson(Map<String, dynamic> json) =>
      _$PubPackagePubspecEntityFromJson(json);
}
