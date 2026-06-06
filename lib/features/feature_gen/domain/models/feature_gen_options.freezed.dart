// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'feature_gen_options.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$FeatureGenOptions {

 String get name; FeatureRouting get routing; String get parentFeature;// only when routing == child
 String get shellIcon;// Material icon name, only when shell
 String get shellLabel;// NavigationBar label, only when shell
 bool get includeRemoteDataSource; bool get includeLocalDataSource; bool get includeUseCase; bool get includeMapper;
/// Create a copy of FeatureGenOptions
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FeatureGenOptionsCopyWith<FeatureGenOptions> get copyWith => _$FeatureGenOptionsCopyWithImpl<FeatureGenOptions>(this as FeatureGenOptions, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FeatureGenOptions&&(identical(other.name, name) || other.name == name)&&(identical(other.routing, routing) || other.routing == routing)&&(identical(other.parentFeature, parentFeature) || other.parentFeature == parentFeature)&&(identical(other.shellIcon, shellIcon) || other.shellIcon == shellIcon)&&(identical(other.shellLabel, shellLabel) || other.shellLabel == shellLabel)&&(identical(other.includeRemoteDataSource, includeRemoteDataSource) || other.includeRemoteDataSource == includeRemoteDataSource)&&(identical(other.includeLocalDataSource, includeLocalDataSource) || other.includeLocalDataSource == includeLocalDataSource)&&(identical(other.includeUseCase, includeUseCase) || other.includeUseCase == includeUseCase)&&(identical(other.includeMapper, includeMapper) || other.includeMapper == includeMapper));
}


@override
int get hashCode => Object.hash(runtimeType,name,routing,parentFeature,shellIcon,shellLabel,includeRemoteDataSource,includeLocalDataSource,includeUseCase,includeMapper);

@override
String toString() {
  return 'FeatureGenOptions(name: $name, routing: $routing, parentFeature: $parentFeature, shellIcon: $shellIcon, shellLabel: $shellLabel, includeRemoteDataSource: $includeRemoteDataSource, includeLocalDataSource: $includeLocalDataSource, includeUseCase: $includeUseCase, includeMapper: $includeMapper)';
}


}

/// @nodoc
abstract mixin class $FeatureGenOptionsCopyWith<$Res>  {
  factory $FeatureGenOptionsCopyWith(FeatureGenOptions value, $Res Function(FeatureGenOptions) _then) = _$FeatureGenOptionsCopyWithImpl;
@useResult
$Res call({
 String name, FeatureRouting routing, String parentFeature, String shellIcon, String shellLabel, bool includeRemoteDataSource, bool includeLocalDataSource, bool includeUseCase, bool includeMapper
});




}
/// @nodoc
class _$FeatureGenOptionsCopyWithImpl<$Res>
    implements $FeatureGenOptionsCopyWith<$Res> {
  _$FeatureGenOptionsCopyWithImpl(this._self, this._then);

  final FeatureGenOptions _self;
  final $Res Function(FeatureGenOptions) _then;

/// Create a copy of FeatureGenOptions
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? routing = null,Object? parentFeature = null,Object? shellIcon = null,Object? shellLabel = null,Object? includeRemoteDataSource = null,Object? includeLocalDataSource = null,Object? includeUseCase = null,Object? includeMapper = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,routing: null == routing ? _self.routing : routing // ignore: cast_nullable_to_non_nullable
as FeatureRouting,parentFeature: null == parentFeature ? _self.parentFeature : parentFeature // ignore: cast_nullable_to_non_nullable
as String,shellIcon: null == shellIcon ? _self.shellIcon : shellIcon // ignore: cast_nullable_to_non_nullable
as String,shellLabel: null == shellLabel ? _self.shellLabel : shellLabel // ignore: cast_nullable_to_non_nullable
as String,includeRemoteDataSource: null == includeRemoteDataSource ? _self.includeRemoteDataSource : includeRemoteDataSource // ignore: cast_nullable_to_non_nullable
as bool,includeLocalDataSource: null == includeLocalDataSource ? _self.includeLocalDataSource : includeLocalDataSource // ignore: cast_nullable_to_non_nullable
as bool,includeUseCase: null == includeUseCase ? _self.includeUseCase : includeUseCase // ignore: cast_nullable_to_non_nullable
as bool,includeMapper: null == includeMapper ? _self.includeMapper : includeMapper // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [FeatureGenOptions].
extension FeatureGenOptionsPatterns on FeatureGenOptions {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FeatureGenOptions value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FeatureGenOptions() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FeatureGenOptions value)  $default,){
final _that = this;
switch (_that) {
case _FeatureGenOptions():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FeatureGenOptions value)?  $default,){
final _that = this;
switch (_that) {
case _FeatureGenOptions() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  FeatureRouting routing,  String parentFeature,  String shellIcon,  String shellLabel,  bool includeRemoteDataSource,  bool includeLocalDataSource,  bool includeUseCase,  bool includeMapper)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FeatureGenOptions() when $default != null:
return $default(_that.name,_that.routing,_that.parentFeature,_that.shellIcon,_that.shellLabel,_that.includeRemoteDataSource,_that.includeLocalDataSource,_that.includeUseCase,_that.includeMapper);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  FeatureRouting routing,  String parentFeature,  String shellIcon,  String shellLabel,  bool includeRemoteDataSource,  bool includeLocalDataSource,  bool includeUseCase,  bool includeMapper)  $default,) {final _that = this;
switch (_that) {
case _FeatureGenOptions():
return $default(_that.name,_that.routing,_that.parentFeature,_that.shellIcon,_that.shellLabel,_that.includeRemoteDataSource,_that.includeLocalDataSource,_that.includeUseCase,_that.includeMapper);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  FeatureRouting routing,  String parentFeature,  String shellIcon,  String shellLabel,  bool includeRemoteDataSource,  bool includeLocalDataSource,  bool includeUseCase,  bool includeMapper)?  $default,) {final _that = this;
switch (_that) {
case _FeatureGenOptions() when $default != null:
return $default(_that.name,_that.routing,_that.parentFeature,_that.shellIcon,_that.shellLabel,_that.includeRemoteDataSource,_that.includeLocalDataSource,_that.includeUseCase,_that.includeMapper);case _:
  return null;

}
}

}

/// @nodoc


class _FeatureGenOptions extends FeatureGenOptions {
  const _FeatureGenOptions({this.name = '', this.routing = FeatureRouting.root, this.parentFeature = '', this.shellIcon = 'home', this.shellLabel = '', this.includeRemoteDataSource = true, this.includeLocalDataSource = true, this.includeUseCase = true, this.includeMapper = true}): super._();
  

@override@JsonKey() final  String name;
@override@JsonKey() final  FeatureRouting routing;
@override@JsonKey() final  String parentFeature;
// only when routing == child
@override@JsonKey() final  String shellIcon;
// Material icon name, only when shell
@override@JsonKey() final  String shellLabel;
// NavigationBar label, only when shell
@override@JsonKey() final  bool includeRemoteDataSource;
@override@JsonKey() final  bool includeLocalDataSource;
@override@JsonKey() final  bool includeUseCase;
@override@JsonKey() final  bool includeMapper;

/// Create a copy of FeatureGenOptions
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FeatureGenOptionsCopyWith<_FeatureGenOptions> get copyWith => __$FeatureGenOptionsCopyWithImpl<_FeatureGenOptions>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FeatureGenOptions&&(identical(other.name, name) || other.name == name)&&(identical(other.routing, routing) || other.routing == routing)&&(identical(other.parentFeature, parentFeature) || other.parentFeature == parentFeature)&&(identical(other.shellIcon, shellIcon) || other.shellIcon == shellIcon)&&(identical(other.shellLabel, shellLabel) || other.shellLabel == shellLabel)&&(identical(other.includeRemoteDataSource, includeRemoteDataSource) || other.includeRemoteDataSource == includeRemoteDataSource)&&(identical(other.includeLocalDataSource, includeLocalDataSource) || other.includeLocalDataSource == includeLocalDataSource)&&(identical(other.includeUseCase, includeUseCase) || other.includeUseCase == includeUseCase)&&(identical(other.includeMapper, includeMapper) || other.includeMapper == includeMapper));
}


@override
int get hashCode => Object.hash(runtimeType,name,routing,parentFeature,shellIcon,shellLabel,includeRemoteDataSource,includeLocalDataSource,includeUseCase,includeMapper);

@override
String toString() {
  return 'FeatureGenOptions(name: $name, routing: $routing, parentFeature: $parentFeature, shellIcon: $shellIcon, shellLabel: $shellLabel, includeRemoteDataSource: $includeRemoteDataSource, includeLocalDataSource: $includeLocalDataSource, includeUseCase: $includeUseCase, includeMapper: $includeMapper)';
}


}

/// @nodoc
abstract mixin class _$FeatureGenOptionsCopyWith<$Res> implements $FeatureGenOptionsCopyWith<$Res> {
  factory _$FeatureGenOptionsCopyWith(_FeatureGenOptions value, $Res Function(_FeatureGenOptions) _then) = __$FeatureGenOptionsCopyWithImpl;
@override @useResult
$Res call({
 String name, FeatureRouting routing, String parentFeature, String shellIcon, String shellLabel, bool includeRemoteDataSource, bool includeLocalDataSource, bool includeUseCase, bool includeMapper
});




}
/// @nodoc
class __$FeatureGenOptionsCopyWithImpl<$Res>
    implements _$FeatureGenOptionsCopyWith<$Res> {
  __$FeatureGenOptionsCopyWithImpl(this._self, this._then);

  final _FeatureGenOptions _self;
  final $Res Function(_FeatureGenOptions) _then;

/// Create a copy of FeatureGenOptions
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? routing = null,Object? parentFeature = null,Object? shellIcon = null,Object? shellLabel = null,Object? includeRemoteDataSource = null,Object? includeLocalDataSource = null,Object? includeUseCase = null,Object? includeMapper = null,}) {
  return _then(_FeatureGenOptions(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,routing: null == routing ? _self.routing : routing // ignore: cast_nullable_to_non_nullable
as FeatureRouting,parentFeature: null == parentFeature ? _self.parentFeature : parentFeature // ignore: cast_nullable_to_non_nullable
as String,shellIcon: null == shellIcon ? _self.shellIcon : shellIcon // ignore: cast_nullable_to_non_nullable
as String,shellLabel: null == shellLabel ? _self.shellLabel : shellLabel // ignore: cast_nullable_to_non_nullable
as String,includeRemoteDataSource: null == includeRemoteDataSource ? _self.includeRemoteDataSource : includeRemoteDataSource // ignore: cast_nullable_to_non_nullable
as bool,includeLocalDataSource: null == includeLocalDataSource ? _self.includeLocalDataSource : includeLocalDataSource // ignore: cast_nullable_to_non_nullable
as bool,includeUseCase: null == includeUseCase ? _self.includeUseCase : includeUseCase // ignore: cast_nullable_to_non_nullable
as bool,includeMapper: null == includeMapper ? _self.includeMapper : includeMapper // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
