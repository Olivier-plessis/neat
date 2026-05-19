// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pub_package.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PubPackage {

 String get name; String get version; String get description; int get likes; int get pubPoints; int get popularity;// 0–100
 bool get isDev;
/// Create a copy of PubPackage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PubPackageCopyWith<PubPackage> get copyWith => _$PubPackageCopyWithImpl<PubPackage>(this as PubPackage, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PubPackage&&(identical(other.name, name) || other.name == name)&&(identical(other.version, version) || other.version == version)&&(identical(other.description, description) || other.description == description)&&(identical(other.likes, likes) || other.likes == likes)&&(identical(other.pubPoints, pubPoints) || other.pubPoints == pubPoints)&&(identical(other.popularity, popularity) || other.popularity == popularity)&&(identical(other.isDev, isDev) || other.isDev == isDev));
}


@override
int get hashCode => Object.hash(runtimeType,name,version,description,likes,pubPoints,popularity,isDev);

@override
String toString() {
  return 'PubPackage(name: $name, version: $version, description: $description, likes: $likes, pubPoints: $pubPoints, popularity: $popularity, isDev: $isDev)';
}


}

/// @nodoc
abstract mixin class $PubPackageCopyWith<$Res>  {
  factory $PubPackageCopyWith(PubPackage value, $Res Function(PubPackage) _then) = _$PubPackageCopyWithImpl;
@useResult
$Res call({
 String name, String version, String description, int likes, int pubPoints, int popularity, bool isDev
});




}
/// @nodoc
class _$PubPackageCopyWithImpl<$Res>
    implements $PubPackageCopyWith<$Res> {
  _$PubPackageCopyWithImpl(this._self, this._then);

  final PubPackage _self;
  final $Res Function(PubPackage) _then;

/// Create a copy of PubPackage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? version = null,Object? description = null,Object? likes = null,Object? pubPoints = null,Object? popularity = null,Object? isDev = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,likes: null == likes ? _self.likes : likes // ignore: cast_nullable_to_non_nullable
as int,pubPoints: null == pubPoints ? _self.pubPoints : pubPoints // ignore: cast_nullable_to_non_nullable
as int,popularity: null == popularity ? _self.popularity : popularity // ignore: cast_nullable_to_non_nullable
as int,isDev: null == isDev ? _self.isDev : isDev // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [PubPackage].
extension PubPackagePatterns on PubPackage {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PubPackage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PubPackage() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PubPackage value)  $default,){
final _that = this;
switch (_that) {
case _PubPackage():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PubPackage value)?  $default,){
final _that = this;
switch (_that) {
case _PubPackage() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String version,  String description,  int likes,  int pubPoints,  int popularity,  bool isDev)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PubPackage() when $default != null:
return $default(_that.name,_that.version,_that.description,_that.likes,_that.pubPoints,_that.popularity,_that.isDev);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String version,  String description,  int likes,  int pubPoints,  int popularity,  bool isDev)  $default,) {final _that = this;
switch (_that) {
case _PubPackage():
return $default(_that.name,_that.version,_that.description,_that.likes,_that.pubPoints,_that.popularity,_that.isDev);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String version,  String description,  int likes,  int pubPoints,  int popularity,  bool isDev)?  $default,) {final _that = this;
switch (_that) {
case _PubPackage() when $default != null:
return $default(_that.name,_that.version,_that.description,_that.likes,_that.pubPoints,_that.popularity,_that.isDev);case _:
  return null;

}
}

}

/// @nodoc


class _PubPackage implements PubPackage {
  const _PubPackage({required this.name, required this.version, required this.description, this.likes = 0, this.pubPoints = 0, this.popularity = 0, this.isDev = false});
  

@override final  String name;
@override final  String version;
@override final  String description;
@override@JsonKey() final  int likes;
@override@JsonKey() final  int pubPoints;
@override@JsonKey() final  int popularity;
// 0–100
@override@JsonKey() final  bool isDev;

/// Create a copy of PubPackage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PubPackageCopyWith<_PubPackage> get copyWith => __$PubPackageCopyWithImpl<_PubPackage>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PubPackage&&(identical(other.name, name) || other.name == name)&&(identical(other.version, version) || other.version == version)&&(identical(other.description, description) || other.description == description)&&(identical(other.likes, likes) || other.likes == likes)&&(identical(other.pubPoints, pubPoints) || other.pubPoints == pubPoints)&&(identical(other.popularity, popularity) || other.popularity == popularity)&&(identical(other.isDev, isDev) || other.isDev == isDev));
}


@override
int get hashCode => Object.hash(runtimeType,name,version,description,likes,pubPoints,popularity,isDev);

@override
String toString() {
  return 'PubPackage(name: $name, version: $version, description: $description, likes: $likes, pubPoints: $pubPoints, popularity: $popularity, isDev: $isDev)';
}


}

/// @nodoc
abstract mixin class _$PubPackageCopyWith<$Res> implements $PubPackageCopyWith<$Res> {
  factory _$PubPackageCopyWith(_PubPackage value, $Res Function(_PubPackage) _then) = __$PubPackageCopyWithImpl;
@override @useResult
$Res call({
 String name, String version, String description, int likes, int pubPoints, int popularity, bool isDev
});




}
/// @nodoc
class __$PubPackageCopyWithImpl<$Res>
    implements _$PubPackageCopyWith<$Res> {
  __$PubPackageCopyWithImpl(this._self, this._then);

  final _PubPackage _self;
  final $Res Function(_PubPackage) _then;

/// Create a copy of PubPackage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? version = null,Object? description = null,Object? likes = null,Object? pubPoints = null,Object? popularity = null,Object? isDev = null,}) {
  return _then(_PubPackage(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,likes: null == likes ? _self.likes : likes // ignore: cast_nullable_to_non_nullable
as int,pubPoints: null == pubPoints ? _self.pubPoints : pubPoints // ignore: cast_nullable_to_non_nullable
as int,popularity: null == popularity ? _self.popularity : popularity // ignore: cast_nullable_to_non_nullable
as int,isDev: null == isDev ? _self.isDev : isDev // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
