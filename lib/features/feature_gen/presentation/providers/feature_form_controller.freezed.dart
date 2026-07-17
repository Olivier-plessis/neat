// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'feature_form_controller.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$FeatureFormState {

 FeatureGenOptions get opts; int get step;
/// Create a copy of FeatureFormState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FeatureFormStateCopyWith<FeatureFormState> get copyWith => _$FeatureFormStateCopyWithImpl<FeatureFormState>(this as FeatureFormState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FeatureFormState&&(identical(other.opts, opts) || other.opts == opts)&&(identical(other.step, step) || other.step == step));
}


@override
int get hashCode => Object.hash(runtimeType,opts,step);

@override
String toString() {
  return 'FeatureFormState(opts: $opts, step: $step)';
}


}

/// @nodoc
abstract mixin class $FeatureFormStateCopyWith<$Res>  {
  factory $FeatureFormStateCopyWith(FeatureFormState value, $Res Function(FeatureFormState) _then) = _$FeatureFormStateCopyWithImpl;
@useResult
$Res call({
 FeatureGenOptions opts, int step
});


$FeatureGenOptionsCopyWith<$Res> get opts;

}
/// @nodoc
class _$FeatureFormStateCopyWithImpl<$Res>
    implements $FeatureFormStateCopyWith<$Res> {
  _$FeatureFormStateCopyWithImpl(this._self, this._then);

  final FeatureFormState _self;
  final $Res Function(FeatureFormState) _then;

/// Create a copy of FeatureFormState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? opts = null,Object? step = null,}) {
  return _then(_self.copyWith(
opts: null == opts ? _self.opts : opts // ignore: cast_nullable_to_non_nullable
as FeatureGenOptions,step: null == step ? _self.step : step // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of FeatureFormState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FeatureGenOptionsCopyWith<$Res> get opts {
  
  return $FeatureGenOptionsCopyWith<$Res>(_self.opts, (value) {
    return _then(_self.copyWith(opts: value));
  });
}
}


/// Adds pattern-matching-related methods to [FeatureFormState].
extension FeatureFormStatePatterns on FeatureFormState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FeatureFormState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FeatureFormState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FeatureFormState value)  $default,){
final _that = this;
switch (_that) {
case _FeatureFormState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FeatureFormState value)?  $default,){
final _that = this;
switch (_that) {
case _FeatureFormState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( FeatureGenOptions opts,  int step)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FeatureFormState() when $default != null:
return $default(_that.opts,_that.step);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( FeatureGenOptions opts,  int step)  $default,) {final _that = this;
switch (_that) {
case _FeatureFormState():
return $default(_that.opts,_that.step);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( FeatureGenOptions opts,  int step)?  $default,) {final _that = this;
switch (_that) {
case _FeatureFormState() when $default != null:
return $default(_that.opts,_that.step);case _:
  return null;

}
}

}

/// @nodoc


class _FeatureFormState implements FeatureFormState {
  const _FeatureFormState({this.opts = const FeatureGenOptions(), this.step = 0});
  

@override@JsonKey() final  FeatureGenOptions opts;
@override@JsonKey() final  int step;

/// Create a copy of FeatureFormState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FeatureFormStateCopyWith<_FeatureFormState> get copyWith => __$FeatureFormStateCopyWithImpl<_FeatureFormState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FeatureFormState&&(identical(other.opts, opts) || other.opts == opts)&&(identical(other.step, step) || other.step == step));
}


@override
int get hashCode => Object.hash(runtimeType,opts,step);

@override
String toString() {
  return 'FeatureFormState(opts: $opts, step: $step)';
}


}

/// @nodoc
abstract mixin class _$FeatureFormStateCopyWith<$Res> implements $FeatureFormStateCopyWith<$Res> {
  factory _$FeatureFormStateCopyWith(_FeatureFormState value, $Res Function(_FeatureFormState) _then) = __$FeatureFormStateCopyWithImpl;
@override @useResult
$Res call({
 FeatureGenOptions opts, int step
});


@override $FeatureGenOptionsCopyWith<$Res> get opts;

}
/// @nodoc
class __$FeatureFormStateCopyWithImpl<$Res>
    implements _$FeatureFormStateCopyWith<$Res> {
  __$FeatureFormStateCopyWithImpl(this._self, this._then);

  final _FeatureFormState _self;
  final $Res Function(_FeatureFormState) _then;

/// Create a copy of FeatureFormState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? opts = null,Object? step = null,}) {
  return _then(_FeatureFormState(
opts: null == opts ? _self.opts : opts // ignore: cast_nullable_to_non_nullable
as FeatureGenOptions,step: null == step ? _self.step : step // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of FeatureFormState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FeatureGenOptionsCopyWith<$Res> get opts {
  
  return $FeatureGenOptionsCopyWith<$Res>(_self.opts, (value) {
    return _then(_self.copyWith(opts: value));
  });
}
}

// dart format on
