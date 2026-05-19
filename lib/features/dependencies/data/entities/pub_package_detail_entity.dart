import 'package:json_annotation/json_annotation.dart';

part 'pub_package_detail_entity.g.dart';

@JsonSerializable(createToJson: false)
class PubPackageDetailEntity {
  factory PubPackageDetailEntity.fromJson(Map<String, dynamic> json) =>
      _$PubPackageDetailEntityFromJson(json);

  const PubPackageDetailEntity({required this.name, required this.latest});

  final String name;
  final PubPackageLatestEntity latest;
}

@JsonSerializable(createToJson: false)
class PubPackageLatestEntity {
  factory PubPackageLatestEntity.fromJson(Map<String, dynamic> json) =>
      _$PubPackageLatestEntityFromJson(json);

  const PubPackageLatestEntity({required this.version, required this.pubspec});

  final String version;
  final PubPackagePubspecEntity pubspec;
}

@JsonSerializable(createToJson: false)
class PubPackagePubspecEntity {
  factory PubPackagePubspecEntity.fromJson(Map<String, dynamic> json) =>
      _$PubPackagePubspecEntityFromJson(json);

  const PubPackagePubspecEntity({this.description});

  final String? description;
}
