// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'cicd_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CicdState {

 Set<CiTool> get selectedTools; bool get runAnalyze; bool get runTests; bool get autoDeploy;/// The Sentry project DSN, only meaningful when [hasSentryDelivery]. Flows
/// into the generated app's `.env` (via envied, alongside apiBaseUrl) —
/// never embedded as a literal in `bootstrap.dart` — and is read back by
/// `SentryFlutter.init` there.
 String get sentryDsn;
/// Create a copy of CicdState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CicdStateCopyWith<CicdState> get copyWith => _$CicdStateCopyWithImpl<CicdState>(this as CicdState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CicdState&&const DeepCollectionEquality().equals(other.selectedTools, selectedTools)&&(identical(other.runAnalyze, runAnalyze) || other.runAnalyze == runAnalyze)&&(identical(other.runTests, runTests) || other.runTests == runTests)&&(identical(other.autoDeploy, autoDeploy) || other.autoDeploy == autoDeploy)&&(identical(other.sentryDsn, sentryDsn) || other.sentryDsn == sentryDsn));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(selectedTools),runAnalyze,runTests,autoDeploy,sentryDsn);

@override
String toString() {
  return 'CicdState(selectedTools: $selectedTools, runAnalyze: $runAnalyze, runTests: $runTests, autoDeploy: $autoDeploy, sentryDsn: $sentryDsn)';
}


}

/// @nodoc
abstract mixin class $CicdStateCopyWith<$Res>  {
  factory $CicdStateCopyWith(CicdState value, $Res Function(CicdState) _then) = _$CicdStateCopyWithImpl;
@useResult
$Res call({
 Set<CiTool> selectedTools, bool runAnalyze, bool runTests, bool autoDeploy, String sentryDsn
});




}
/// @nodoc
class _$CicdStateCopyWithImpl<$Res>
    implements $CicdStateCopyWith<$Res> {
  _$CicdStateCopyWithImpl(this._self, this._then);

  final CicdState _self;
  final $Res Function(CicdState) _then;

/// Create a copy of CicdState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? selectedTools = null,Object? runAnalyze = null,Object? runTests = null,Object? autoDeploy = null,Object? sentryDsn = null,}) {
  return _then(_self.copyWith(
selectedTools: null == selectedTools ? _self.selectedTools : selectedTools // ignore: cast_nullable_to_non_nullable
as Set<CiTool>,runAnalyze: null == runAnalyze ? _self.runAnalyze : runAnalyze // ignore: cast_nullable_to_non_nullable
as bool,runTests: null == runTests ? _self.runTests : runTests // ignore: cast_nullable_to_non_nullable
as bool,autoDeploy: null == autoDeploy ? _self.autoDeploy : autoDeploy // ignore: cast_nullable_to_non_nullable
as bool,sentryDsn: null == sentryDsn ? _self.sentryDsn : sentryDsn // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [CicdState].
extension CicdStatePatterns on CicdState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CicdState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CicdState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CicdState value)  $default,){
final _that = this;
switch (_that) {
case _CicdState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CicdState value)?  $default,){
final _that = this;
switch (_that) {
case _CicdState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Set<CiTool> selectedTools,  bool runAnalyze,  bool runTests,  bool autoDeploy,  String sentryDsn)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CicdState() when $default != null:
return $default(_that.selectedTools,_that.runAnalyze,_that.runTests,_that.autoDeploy,_that.sentryDsn);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Set<CiTool> selectedTools,  bool runAnalyze,  bool runTests,  bool autoDeploy,  String sentryDsn)  $default,) {final _that = this;
switch (_that) {
case _CicdState():
return $default(_that.selectedTools,_that.runAnalyze,_that.runTests,_that.autoDeploy,_that.sentryDsn);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Set<CiTool> selectedTools,  bool runAnalyze,  bool runTests,  bool autoDeploy,  String sentryDsn)?  $default,) {final _that = this;
switch (_that) {
case _CicdState() when $default != null:
return $default(_that.selectedTools,_that.runAnalyze,_that.runTests,_that.autoDeploy,_that.sentryDsn);case _:
  return null;

}
}

}

/// @nodoc


class _CicdState extends CicdState {
  const _CicdState({final  Set<CiTool> selectedTools = const <CiTool>{}, this.runAnalyze = true, this.runTests = true, this.autoDeploy = false, this.sentryDsn = ''}): _selectedTools = selectedTools,super._();
  

 final  Set<CiTool> _selectedTools;
@override@JsonKey() Set<CiTool> get selectedTools {
  if (_selectedTools is EqualUnmodifiableSetView) return _selectedTools;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_selectedTools);
}

@override@JsonKey() final  bool runAnalyze;
@override@JsonKey() final  bool runTests;
@override@JsonKey() final  bool autoDeploy;
/// The Sentry project DSN, only meaningful when [hasSentryDelivery]. Flows
/// into the generated app's `.env` (via envied, alongside apiBaseUrl) —
/// never embedded as a literal in `bootstrap.dart` — and is read back by
/// `SentryFlutter.init` there.
@override@JsonKey() final  String sentryDsn;

/// Create a copy of CicdState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CicdStateCopyWith<_CicdState> get copyWith => __$CicdStateCopyWithImpl<_CicdState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CicdState&&const DeepCollectionEquality().equals(other._selectedTools, _selectedTools)&&(identical(other.runAnalyze, runAnalyze) || other.runAnalyze == runAnalyze)&&(identical(other.runTests, runTests) || other.runTests == runTests)&&(identical(other.autoDeploy, autoDeploy) || other.autoDeploy == autoDeploy)&&(identical(other.sentryDsn, sentryDsn) || other.sentryDsn == sentryDsn));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_selectedTools),runAnalyze,runTests,autoDeploy,sentryDsn);

@override
String toString() {
  return 'CicdState(selectedTools: $selectedTools, runAnalyze: $runAnalyze, runTests: $runTests, autoDeploy: $autoDeploy, sentryDsn: $sentryDsn)';
}


}

/// @nodoc
abstract mixin class _$CicdStateCopyWith<$Res> implements $CicdStateCopyWith<$Res> {
  factory _$CicdStateCopyWith(_CicdState value, $Res Function(_CicdState) _then) = __$CicdStateCopyWithImpl;
@override @useResult
$Res call({
 Set<CiTool> selectedTools, bool runAnalyze, bool runTests, bool autoDeploy, String sentryDsn
});




}
/// @nodoc
class __$CicdStateCopyWithImpl<$Res>
    implements _$CicdStateCopyWith<$Res> {
  __$CicdStateCopyWithImpl(this._self, this._then);

  final _CicdState _self;
  final $Res Function(_CicdState) _then;

/// Create a copy of CicdState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? selectedTools = null,Object? runAnalyze = null,Object? runTests = null,Object? autoDeploy = null,Object? sentryDsn = null,}) {
  return _then(_CicdState(
selectedTools: null == selectedTools ? _self._selectedTools : selectedTools // ignore: cast_nullable_to_non_nullable
as Set<CiTool>,runAnalyze: null == runAnalyze ? _self.runAnalyze : runAnalyze // ignore: cast_nullable_to_non_nullable
as bool,runTests: null == runTests ? _self.runTests : runTests // ignore: cast_nullable_to_non_nullable
as bool,autoDeploy: null == autoDeploy ? _self.autoDeploy : autoDeploy // ignore: cast_nullable_to_non_nullable
as bool,sentryDsn: null == sentryDsn ? _self.sentryDsn : sentryDsn // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
