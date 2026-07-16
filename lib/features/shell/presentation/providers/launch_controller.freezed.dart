// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'launch_controller.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$LaunchState {

 bool get hasFinished; List<String> get logs; String? get error;
/// Create a copy of LaunchState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LaunchStateCopyWith<LaunchState> get copyWith => _$LaunchStateCopyWithImpl<LaunchState>(this as LaunchState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LaunchState&&(identical(other.hasFinished, hasFinished) || other.hasFinished == hasFinished)&&const DeepCollectionEquality().equals(other.logs, logs)&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,hasFinished,const DeepCollectionEquality().hash(logs),error);

@override
String toString() {
  return 'LaunchState(hasFinished: $hasFinished, logs: $logs, error: $error)';
}


}

/// @nodoc
abstract mixin class $LaunchStateCopyWith<$Res>  {
  factory $LaunchStateCopyWith(LaunchState value, $Res Function(LaunchState) _then) = _$LaunchStateCopyWithImpl;
@useResult
$Res call({
 bool hasFinished, List<String> logs, String? error
});




}
/// @nodoc
class _$LaunchStateCopyWithImpl<$Res>
    implements $LaunchStateCopyWith<$Res> {
  _$LaunchStateCopyWithImpl(this._self, this._then);

  final LaunchState _self;
  final $Res Function(LaunchState) _then;

/// Create a copy of LaunchState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? hasFinished = null,Object? logs = null,Object? error = freezed,}) {
  return _then(_self.copyWith(
hasFinished: null == hasFinished ? _self.hasFinished : hasFinished // ignore: cast_nullable_to_non_nullable
as bool,logs: null == logs ? _self.logs : logs // ignore: cast_nullable_to_non_nullable
as List<String>,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [LaunchState].
extension LaunchStatePatterns on LaunchState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LaunchState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LaunchState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LaunchState value)  $default,){
final _that = this;
switch (_that) {
case _LaunchState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LaunchState value)?  $default,){
final _that = this;
switch (_that) {
case _LaunchState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool hasFinished,  List<String> logs,  String? error)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LaunchState() when $default != null:
return $default(_that.hasFinished,_that.logs,_that.error);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool hasFinished,  List<String> logs,  String? error)  $default,) {final _that = this;
switch (_that) {
case _LaunchState():
return $default(_that.hasFinished,_that.logs,_that.error);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool hasFinished,  List<String> logs,  String? error)?  $default,) {final _that = this;
switch (_that) {
case _LaunchState() when $default != null:
return $default(_that.hasFinished,_that.logs,_that.error);case _:
  return null;

}
}

}

/// @nodoc


class _LaunchState implements LaunchState {
  const _LaunchState({this.hasFinished = false, final  List<String> logs = const <String>[], this.error}): _logs = logs;
  

@override@JsonKey() final  bool hasFinished;
 final  List<String> _logs;
@override@JsonKey() List<String> get logs {
  if (_logs is EqualUnmodifiableListView) return _logs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_logs);
}

@override final  String? error;

/// Create a copy of LaunchState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LaunchStateCopyWith<_LaunchState> get copyWith => __$LaunchStateCopyWithImpl<_LaunchState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LaunchState&&(identical(other.hasFinished, hasFinished) || other.hasFinished == hasFinished)&&const DeepCollectionEquality().equals(other._logs, _logs)&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,hasFinished,const DeepCollectionEquality().hash(_logs),error);

@override
String toString() {
  return 'LaunchState(hasFinished: $hasFinished, logs: $logs, error: $error)';
}


}

/// @nodoc
abstract mixin class _$LaunchStateCopyWith<$Res> implements $LaunchStateCopyWith<$Res> {
  factory _$LaunchStateCopyWith(_LaunchState value, $Res Function(_LaunchState) _then) = __$LaunchStateCopyWithImpl;
@override @useResult
$Res call({
 bool hasFinished, List<String> logs, String? error
});




}
/// @nodoc
class __$LaunchStateCopyWithImpl<$Res>
    implements _$LaunchStateCopyWith<$Res> {
  __$LaunchStateCopyWithImpl(this._self, this._then);

  final _LaunchState _self;
  final $Res Function(_LaunchState) _then;

/// Create a copy of LaunchState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? hasFinished = null,Object? logs = null,Object? error = freezed,}) {
  return _then(_LaunchState(
hasFinished: null == hasFinished ? _self.hasFinished : hasFinished // ignore: cast_nullable_to_non_nullable
as bool,logs: null == logs ? _self._logs : logs // ignore: cast_nullable_to_non_nullable
as List<String>,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
