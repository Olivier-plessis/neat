// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'env_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$EnvConfig {

 String get name; String get apiBaseUrl;
/// Create a copy of EnvConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EnvConfigCopyWith<EnvConfig> get copyWith => _$EnvConfigCopyWithImpl<EnvConfig>(this as EnvConfig, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EnvConfig&&(identical(other.name, name) || other.name == name)&&(identical(other.apiBaseUrl, apiBaseUrl) || other.apiBaseUrl == apiBaseUrl));
}


@override
int get hashCode => Object.hash(runtimeType,name,apiBaseUrl);

@override
String toString() {
  return 'EnvConfig(name: $name, apiBaseUrl: $apiBaseUrl)';
}


}

/// @nodoc
abstract mixin class $EnvConfigCopyWith<$Res>  {
  factory $EnvConfigCopyWith(EnvConfig value, $Res Function(EnvConfig) _then) = _$EnvConfigCopyWithImpl;
@useResult
$Res call({
 String name, String apiBaseUrl
});




}
/// @nodoc
class _$EnvConfigCopyWithImpl<$Res>
    implements $EnvConfigCopyWith<$Res> {
  _$EnvConfigCopyWithImpl(this._self, this._then);

  final EnvConfig _self;
  final $Res Function(EnvConfig) _then;

/// Create a copy of EnvConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? apiBaseUrl = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,apiBaseUrl: null == apiBaseUrl ? _self.apiBaseUrl : apiBaseUrl // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [EnvConfig].
extension EnvConfigPatterns on EnvConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EnvConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EnvConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EnvConfig value)  $default,){
final _that = this;
switch (_that) {
case _EnvConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EnvConfig value)?  $default,){
final _that = this;
switch (_that) {
case _EnvConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String apiBaseUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EnvConfig() when $default != null:
return $default(_that.name,_that.apiBaseUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String apiBaseUrl)  $default,) {final _that = this;
switch (_that) {
case _EnvConfig():
return $default(_that.name,_that.apiBaseUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String apiBaseUrl)?  $default,) {final _that = this;
switch (_that) {
case _EnvConfig() when $default != null:
return $default(_that.name,_that.apiBaseUrl);case _:
  return null;

}
}

}

/// @nodoc


class _EnvConfig extends EnvConfig {
  const _EnvConfig({required this.name, this.apiBaseUrl = ''}): super._();
  

@override final  String name;
@override@JsonKey() final  String apiBaseUrl;

/// Create a copy of EnvConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EnvConfigCopyWith<_EnvConfig> get copyWith => __$EnvConfigCopyWithImpl<_EnvConfig>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EnvConfig&&(identical(other.name, name) || other.name == name)&&(identical(other.apiBaseUrl, apiBaseUrl) || other.apiBaseUrl == apiBaseUrl));
}


@override
int get hashCode => Object.hash(runtimeType,name,apiBaseUrl);

@override
String toString() {
  return 'EnvConfig(name: $name, apiBaseUrl: $apiBaseUrl)';
}


}

/// @nodoc
abstract mixin class _$EnvConfigCopyWith<$Res> implements $EnvConfigCopyWith<$Res> {
  factory _$EnvConfigCopyWith(_EnvConfig value, $Res Function(_EnvConfig) _then) = __$EnvConfigCopyWithImpl;
@override @useResult
$Res call({
 String name, String apiBaseUrl
});




}
/// @nodoc
class __$EnvConfigCopyWithImpl<$Res>
    implements _$EnvConfigCopyWith<$Res> {
  __$EnvConfigCopyWithImpl(this._self, this._then);

  final _EnvConfig _self;
  final $Res Function(_EnvConfig) _then;

/// Create a copy of EnvConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? apiBaseUrl = null,}) {
  return _then(_EnvConfig(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,apiBaseUrl: null == apiBaseUrl ? _self.apiBaseUrl : apiBaseUrl // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
