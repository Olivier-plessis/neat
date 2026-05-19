import 'package:freezed_annotation/freezed_annotation.dart';

part 'pub_package.freezed.dart';

@freezed
abstract class PubPackage with _$PubPackage {
  const factory PubPackage({
    required String name,
    required String version,
    required String description,
    @Default(0) int likes,
    @Default(0) int pubPoints,
    @Default(0) int popularity, // 0–100
    @Default(false) bool isDev,
  }) = _PubPackage;
}
