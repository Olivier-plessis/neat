// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'workshop_controller.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$WorkshopState {

 LoadedProject? get project; bool get isGenerating; List<String> get logs; String? get error;
/// Create a copy of WorkshopState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkshopStateCopyWith<WorkshopState> get copyWith => _$WorkshopStateCopyWithImpl<WorkshopState>(this as WorkshopState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkshopState&&(identical(other.project, project) || other.project == project)&&(identical(other.isGenerating, isGenerating) || other.isGenerating == isGenerating)&&const DeepCollectionEquality().equals(other.logs, logs)&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,project,isGenerating,const DeepCollectionEquality().hash(logs),error);

@override
String toString() {
  return 'WorkshopState(project: $project, isGenerating: $isGenerating, logs: $logs, error: $error)';
}


}

/// @nodoc
abstract mixin class $WorkshopStateCopyWith<$Res>  {
  factory $WorkshopStateCopyWith(WorkshopState value, $Res Function(WorkshopState) _then) = _$WorkshopStateCopyWithImpl;
@useResult
$Res call({
 LoadedProject? project, bool isGenerating, List<String> logs, String? error
});




}
/// @nodoc
class _$WorkshopStateCopyWithImpl<$Res>
    implements $WorkshopStateCopyWith<$Res> {
  _$WorkshopStateCopyWithImpl(this._self, this._then);

  final WorkshopState _self;
  final $Res Function(WorkshopState) _then;

/// Create a copy of WorkshopState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? project = freezed,Object? isGenerating = null,Object? logs = null,Object? error = freezed,}) {
  return _then(_self.copyWith(
project: freezed == project ? _self.project : project // ignore: cast_nullable_to_non_nullable
as LoadedProject?,isGenerating: null == isGenerating ? _self.isGenerating : isGenerating // ignore: cast_nullable_to_non_nullable
as bool,logs: null == logs ? _self.logs : logs // ignore: cast_nullable_to_non_nullable
as List<String>,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [WorkshopState].
extension WorkshopStatePatterns on WorkshopState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorkshopState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorkshopState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorkshopState value)  $default,){
final _that = this;
switch (_that) {
case _WorkshopState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorkshopState value)?  $default,){
final _that = this;
switch (_that) {
case _WorkshopState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( LoadedProject? project,  bool isGenerating,  List<String> logs,  String? error)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorkshopState() when $default != null:
return $default(_that.project,_that.isGenerating,_that.logs,_that.error);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( LoadedProject? project,  bool isGenerating,  List<String> logs,  String? error)  $default,) {final _that = this;
switch (_that) {
case _WorkshopState():
return $default(_that.project,_that.isGenerating,_that.logs,_that.error);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( LoadedProject? project,  bool isGenerating,  List<String> logs,  String? error)?  $default,) {final _that = this;
switch (_that) {
case _WorkshopState() when $default != null:
return $default(_that.project,_that.isGenerating,_that.logs,_that.error);case _:
  return null;

}
}

}

/// @nodoc


class _WorkshopState implements WorkshopState {
  const _WorkshopState({this.project, this.isGenerating = false, final  List<String> logs = const <String>[], this.error}): _logs = logs;
  

@override final  LoadedProject? project;
@override@JsonKey() final  bool isGenerating;
 final  List<String> _logs;
@override@JsonKey() List<String> get logs {
  if (_logs is EqualUnmodifiableListView) return _logs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_logs);
}

@override final  String? error;

/// Create a copy of WorkshopState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkshopStateCopyWith<_WorkshopState> get copyWith => __$WorkshopStateCopyWithImpl<_WorkshopState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorkshopState&&(identical(other.project, project) || other.project == project)&&(identical(other.isGenerating, isGenerating) || other.isGenerating == isGenerating)&&const DeepCollectionEquality().equals(other._logs, _logs)&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,project,isGenerating,const DeepCollectionEquality().hash(_logs),error);

@override
String toString() {
  return 'WorkshopState(project: $project, isGenerating: $isGenerating, logs: $logs, error: $error)';
}


}

/// @nodoc
abstract mixin class _$WorkshopStateCopyWith<$Res> implements $WorkshopStateCopyWith<$Res> {
  factory _$WorkshopStateCopyWith(_WorkshopState value, $Res Function(_WorkshopState) _then) = __$WorkshopStateCopyWithImpl;
@override @useResult
$Res call({
 LoadedProject? project, bool isGenerating, List<String> logs, String? error
});




}
/// @nodoc
class __$WorkshopStateCopyWithImpl<$Res>
    implements _$WorkshopStateCopyWith<$Res> {
  __$WorkshopStateCopyWithImpl(this._self, this._then);

  final _WorkshopState _self;
  final $Res Function(_WorkshopState) _then;

/// Create a copy of WorkshopState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? project = freezed,Object? isGenerating = null,Object? logs = null,Object? error = freezed,}) {
  return _then(_WorkshopState(
project: freezed == project ? _self.project : project // ignore: cast_nullable_to_non_nullable
as LoadedProject?,isGenerating: null == isGenerating ? _self.isGenerating : isGenerating // ignore: cast_nullable_to_non_nullable
as bool,logs: null == logs ? _self._logs : logs // ignore: cast_nullable_to_non_nullable
as List<String>,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
