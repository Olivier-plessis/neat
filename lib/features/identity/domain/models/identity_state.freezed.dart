// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'identity_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$IdentityState {

 String get name; String get organization; String get projectPath; String get description; List<String> get targetPlatforms; String get flutterVersion;
/// Create a copy of IdentityState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IdentityStateCopyWith<IdentityState> get copyWith => _$IdentityStateCopyWithImpl<IdentityState>(this as IdentityState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IdentityState&&(identical(other.name, name) || other.name == name)&&(identical(other.organization, organization) || other.organization == organization)&&(identical(other.projectPath, projectPath) || other.projectPath == projectPath)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other.targetPlatforms, targetPlatforms)&&(identical(other.flutterVersion, flutterVersion) || other.flutterVersion == flutterVersion));
}


@override
int get hashCode => Object.hash(runtimeType,name,organization,projectPath,description,const DeepCollectionEquality().hash(targetPlatforms),flutterVersion);

@override
String toString() {
  return 'IdentityState(name: $name, organization: $organization, projectPath: $projectPath, description: $description, targetPlatforms: $targetPlatforms, flutterVersion: $flutterVersion)';
}


}

/// @nodoc
abstract mixin class $IdentityStateCopyWith<$Res>  {
  factory $IdentityStateCopyWith(IdentityState value, $Res Function(IdentityState) _then) = _$IdentityStateCopyWithImpl;
@useResult
$Res call({
 String name, String organization, String projectPath, String description, List<String> targetPlatforms, String flutterVersion
});




}
/// @nodoc
class _$IdentityStateCopyWithImpl<$Res>
    implements $IdentityStateCopyWith<$Res> {
  _$IdentityStateCopyWithImpl(this._self, this._then);

  final IdentityState _self;
  final $Res Function(IdentityState) _then;

/// Create a copy of IdentityState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? organization = null,Object? projectPath = null,Object? description = null,Object? targetPlatforms = null,Object? flutterVersion = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,organization: null == organization ? _self.organization : organization // ignore: cast_nullable_to_non_nullable
as String,projectPath: null == projectPath ? _self.projectPath : projectPath // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,targetPlatforms: null == targetPlatforms ? _self.targetPlatforms : targetPlatforms // ignore: cast_nullable_to_non_nullable
as List<String>,flutterVersion: null == flutterVersion ? _self.flutterVersion : flutterVersion // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [IdentityState].
extension IdentityStatePatterns on IdentityState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _IdentityState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _IdentityState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _IdentityState value)  $default,){
final _that = this;
switch (_that) {
case _IdentityState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _IdentityState value)?  $default,){
final _that = this;
switch (_that) {
case _IdentityState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String organization,  String projectPath,  String description,  List<String> targetPlatforms,  String flutterVersion)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _IdentityState() when $default != null:
return $default(_that.name,_that.organization,_that.projectPath,_that.description,_that.targetPlatforms,_that.flutterVersion);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String organization,  String projectPath,  String description,  List<String> targetPlatforms,  String flutterVersion)  $default,) {final _that = this;
switch (_that) {
case _IdentityState():
return $default(_that.name,_that.organization,_that.projectPath,_that.description,_that.targetPlatforms,_that.flutterVersion);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String organization,  String projectPath,  String description,  List<String> targetPlatforms,  String flutterVersion)?  $default,) {final _that = this;
switch (_that) {
case _IdentityState() when $default != null:
return $default(_that.name,_that.organization,_that.projectPath,_that.description,_that.targetPlatforms,_that.flutterVersion);case _:
  return null;

}
}

}

/// @nodoc


class _IdentityState implements IdentityState {
  const _IdentityState({this.name = '', this.organization = 'com.example', this.projectPath = '', this.description = '', final  List<String> targetPlatforms = const ['android', 'ios'], this.flutterVersion = '3.44.x'}): _targetPlatforms = targetPlatforms;
  

@override@JsonKey() final  String name;
@override@JsonKey() final  String organization;
@override@JsonKey() final  String projectPath;
@override@JsonKey() final  String description;
 final  List<String> _targetPlatforms;
@override@JsonKey() List<String> get targetPlatforms {
  if (_targetPlatforms is EqualUnmodifiableListView) return _targetPlatforms;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_targetPlatforms);
}

@override@JsonKey() final  String flutterVersion;

/// Create a copy of IdentityState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$IdentityStateCopyWith<_IdentityState> get copyWith => __$IdentityStateCopyWithImpl<_IdentityState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _IdentityState&&(identical(other.name, name) || other.name == name)&&(identical(other.organization, organization) || other.organization == organization)&&(identical(other.projectPath, projectPath) || other.projectPath == projectPath)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other._targetPlatforms, _targetPlatforms)&&(identical(other.flutterVersion, flutterVersion) || other.flutterVersion == flutterVersion));
}


@override
int get hashCode => Object.hash(runtimeType,name,organization,projectPath,description,const DeepCollectionEquality().hash(_targetPlatforms),flutterVersion);

@override
String toString() {
  return 'IdentityState(name: $name, organization: $organization, projectPath: $projectPath, description: $description, targetPlatforms: $targetPlatforms, flutterVersion: $flutterVersion)';
}


}

/// @nodoc
abstract mixin class _$IdentityStateCopyWith<$Res> implements $IdentityStateCopyWith<$Res> {
  factory _$IdentityStateCopyWith(_IdentityState value, $Res Function(_IdentityState) _then) = __$IdentityStateCopyWithImpl;
@override @useResult
$Res call({
 String name, String organization, String projectPath, String description, List<String> targetPlatforms, String flutterVersion
});




}
/// @nodoc
class __$IdentityStateCopyWithImpl<$Res>
    implements _$IdentityStateCopyWith<$Res> {
  __$IdentityStateCopyWithImpl(this._self, this._then);

  final _IdentityState _self;
  final $Res Function(_IdentityState) _then;

/// Create a copy of IdentityState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? organization = null,Object? projectPath = null,Object? description = null,Object? targetPlatforms = null,Object? flutterVersion = null,}) {
  return _then(_IdentityState(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,organization: null == organization ? _self.organization : organization // ignore: cast_nullable_to_non_nullable
as String,projectPath: null == projectPath ? _self.projectPath : projectPath // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,targetPlatforms: null == targetPlatforms ? _self._targetPlatforms : targetPlatforms // ignore: cast_nullable_to_non_nullable
as List<String>,flutterVersion: null == flutterVersion ? _self.flutterVersion : flutterVersion // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
