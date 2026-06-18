// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'architecture_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ArchitectureState {

 StructuralPattern get pattern; bool get includeMappers;/// Use @riverpod annotation syntax instead of manual NotifierProvider setup
 bool get useRiverpodAnnotations;/// Use Cubit (simpler) instead of full Bloc with Events/States
 bool get useCubit; bool get mirrorTestStructure;/// Name of the first feature scaffolded under lib/features/ (snake_case).
 String get firstFeatureName;/// Data persistence strategy. [StorageStrategy.offlineFirst] switches the
/// generated project to a workspace with a Drift local-storage package.
 StorageStrategy get storageStrategy;/// When true (and go_router is in the stack), the app boots into a bottom
/// [NavigationBar] shell: the first feature is the first tab, so the nav bar
/// is the app's spine from launch. Requires go_router / go_router_builder.
 bool get useNavigationShell;/// Material icon name for the first tab (only when [useNavigationShell]).
 String get shellIcon;/// First tab label (blank → the feature name, capitalised).
 String get shellLabel;/// Opt-in: generate a Supabase **auth** feature (login/signup/forgot) + a
/// go_router guard. Only effective with a Supabase backend + go_router_builder.
 bool get generateAuth;
/// Create a copy of ArchitectureState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ArchitectureStateCopyWith<ArchitectureState> get copyWith => _$ArchitectureStateCopyWithImpl<ArchitectureState>(this as ArchitectureState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ArchitectureState&&(identical(other.pattern, pattern) || other.pattern == pattern)&&(identical(other.includeMappers, includeMappers) || other.includeMappers == includeMappers)&&(identical(other.useRiverpodAnnotations, useRiverpodAnnotations) || other.useRiverpodAnnotations == useRiverpodAnnotations)&&(identical(other.useCubit, useCubit) || other.useCubit == useCubit)&&(identical(other.mirrorTestStructure, mirrorTestStructure) || other.mirrorTestStructure == mirrorTestStructure)&&(identical(other.firstFeatureName, firstFeatureName) || other.firstFeatureName == firstFeatureName)&&(identical(other.storageStrategy, storageStrategy) || other.storageStrategy == storageStrategy)&&(identical(other.useNavigationShell, useNavigationShell) || other.useNavigationShell == useNavigationShell)&&(identical(other.shellIcon, shellIcon) || other.shellIcon == shellIcon)&&(identical(other.shellLabel, shellLabel) || other.shellLabel == shellLabel)&&(identical(other.generateAuth, generateAuth) || other.generateAuth == generateAuth));
}


@override
int get hashCode => Object.hash(runtimeType,pattern,includeMappers,useRiverpodAnnotations,useCubit,mirrorTestStructure,firstFeatureName,storageStrategy,useNavigationShell,shellIcon,shellLabel,generateAuth);

@override
String toString() {
  return 'ArchitectureState(pattern: $pattern, includeMappers: $includeMappers, useRiverpodAnnotations: $useRiverpodAnnotations, useCubit: $useCubit, mirrorTestStructure: $mirrorTestStructure, firstFeatureName: $firstFeatureName, storageStrategy: $storageStrategy, useNavigationShell: $useNavigationShell, shellIcon: $shellIcon, shellLabel: $shellLabel, generateAuth: $generateAuth)';
}


}

/// @nodoc
abstract mixin class $ArchitectureStateCopyWith<$Res>  {
  factory $ArchitectureStateCopyWith(ArchitectureState value, $Res Function(ArchitectureState) _then) = _$ArchitectureStateCopyWithImpl;
@useResult
$Res call({
 StructuralPattern pattern, bool includeMappers, bool useRiverpodAnnotations, bool useCubit, bool mirrorTestStructure, String firstFeatureName, StorageStrategy storageStrategy, bool useNavigationShell, String shellIcon, String shellLabel, bool generateAuth
});




}
/// @nodoc
class _$ArchitectureStateCopyWithImpl<$Res>
    implements $ArchitectureStateCopyWith<$Res> {
  _$ArchitectureStateCopyWithImpl(this._self, this._then);

  final ArchitectureState _self;
  final $Res Function(ArchitectureState) _then;

/// Create a copy of ArchitectureState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? pattern = null,Object? includeMappers = null,Object? useRiverpodAnnotations = null,Object? useCubit = null,Object? mirrorTestStructure = null,Object? firstFeatureName = null,Object? storageStrategy = null,Object? useNavigationShell = null,Object? shellIcon = null,Object? shellLabel = null,Object? generateAuth = null,}) {
  return _then(_self.copyWith(
pattern: null == pattern ? _self.pattern : pattern // ignore: cast_nullable_to_non_nullable
as StructuralPattern,includeMappers: null == includeMappers ? _self.includeMappers : includeMappers // ignore: cast_nullable_to_non_nullable
as bool,useRiverpodAnnotations: null == useRiverpodAnnotations ? _self.useRiverpodAnnotations : useRiverpodAnnotations // ignore: cast_nullable_to_non_nullable
as bool,useCubit: null == useCubit ? _self.useCubit : useCubit // ignore: cast_nullable_to_non_nullable
as bool,mirrorTestStructure: null == mirrorTestStructure ? _self.mirrorTestStructure : mirrorTestStructure // ignore: cast_nullable_to_non_nullable
as bool,firstFeatureName: null == firstFeatureName ? _self.firstFeatureName : firstFeatureName // ignore: cast_nullable_to_non_nullable
as String,storageStrategy: null == storageStrategy ? _self.storageStrategy : storageStrategy // ignore: cast_nullable_to_non_nullable
as StorageStrategy,useNavigationShell: null == useNavigationShell ? _self.useNavigationShell : useNavigationShell // ignore: cast_nullable_to_non_nullable
as bool,shellIcon: null == shellIcon ? _self.shellIcon : shellIcon // ignore: cast_nullable_to_non_nullable
as String,shellLabel: null == shellLabel ? _self.shellLabel : shellLabel // ignore: cast_nullable_to_non_nullable
as String,generateAuth: null == generateAuth ? _self.generateAuth : generateAuth // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ArchitectureState].
extension ArchitectureStatePatterns on ArchitectureState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ArchitectureState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ArchitectureState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ArchitectureState value)  $default,){
final _that = this;
switch (_that) {
case _ArchitectureState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ArchitectureState value)?  $default,){
final _that = this;
switch (_that) {
case _ArchitectureState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( StructuralPattern pattern,  bool includeMappers,  bool useRiverpodAnnotations,  bool useCubit,  bool mirrorTestStructure,  String firstFeatureName,  StorageStrategy storageStrategy,  bool useNavigationShell,  String shellIcon,  String shellLabel,  bool generateAuth)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ArchitectureState() when $default != null:
return $default(_that.pattern,_that.includeMappers,_that.useRiverpodAnnotations,_that.useCubit,_that.mirrorTestStructure,_that.firstFeatureName,_that.storageStrategy,_that.useNavigationShell,_that.shellIcon,_that.shellLabel,_that.generateAuth);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( StructuralPattern pattern,  bool includeMappers,  bool useRiverpodAnnotations,  bool useCubit,  bool mirrorTestStructure,  String firstFeatureName,  StorageStrategy storageStrategy,  bool useNavigationShell,  String shellIcon,  String shellLabel,  bool generateAuth)  $default,) {final _that = this;
switch (_that) {
case _ArchitectureState():
return $default(_that.pattern,_that.includeMappers,_that.useRiverpodAnnotations,_that.useCubit,_that.mirrorTestStructure,_that.firstFeatureName,_that.storageStrategy,_that.useNavigationShell,_that.shellIcon,_that.shellLabel,_that.generateAuth);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( StructuralPattern pattern,  bool includeMappers,  bool useRiverpodAnnotations,  bool useCubit,  bool mirrorTestStructure,  String firstFeatureName,  StorageStrategy storageStrategy,  bool useNavigationShell,  String shellIcon,  String shellLabel,  bool generateAuth)?  $default,) {final _that = this;
switch (_that) {
case _ArchitectureState() when $default != null:
return $default(_that.pattern,_that.includeMappers,_that.useRiverpodAnnotations,_that.useCubit,_that.mirrorTestStructure,_that.firstFeatureName,_that.storageStrategy,_that.useNavigationShell,_that.shellIcon,_that.shellLabel,_that.generateAuth);case _:
  return null;

}
}

}

/// @nodoc


class _ArchitectureState extends ArchitectureState {
  const _ArchitectureState({this.pattern = StructuralPattern.featureFirst, this.includeMappers = true, this.useRiverpodAnnotations = true, this.useCubit = false, this.mirrorTestStructure = true, this.firstFeatureName = 'home', this.storageStrategy = StorageStrategy.remoteOnly, this.useNavigationShell = false, this.shellIcon = 'home', this.shellLabel = '', this.generateAuth = false}): super._();
  

@override@JsonKey() final  StructuralPattern pattern;
@override@JsonKey() final  bool includeMappers;
/// Use @riverpod annotation syntax instead of manual NotifierProvider setup
@override@JsonKey() final  bool useRiverpodAnnotations;
/// Use Cubit (simpler) instead of full Bloc with Events/States
@override@JsonKey() final  bool useCubit;
@override@JsonKey() final  bool mirrorTestStructure;
/// Name of the first feature scaffolded under lib/features/ (snake_case).
@override@JsonKey() final  String firstFeatureName;
/// Data persistence strategy. [StorageStrategy.offlineFirst] switches the
/// generated project to a workspace with a Drift local-storage package.
@override@JsonKey() final  StorageStrategy storageStrategy;
/// When true (and go_router is in the stack), the app boots into a bottom
/// [NavigationBar] shell: the first feature is the first tab, so the nav bar
/// is the app's spine from launch. Requires go_router / go_router_builder.
@override@JsonKey() final  bool useNavigationShell;
/// Material icon name for the first tab (only when [useNavigationShell]).
@override@JsonKey() final  String shellIcon;
/// First tab label (blank → the feature name, capitalised).
@override@JsonKey() final  String shellLabel;
/// Opt-in: generate a Supabase **auth** feature (login/signup/forgot) + a
/// go_router guard. Only effective with a Supabase backend + go_router_builder.
@override@JsonKey() final  bool generateAuth;

/// Create a copy of ArchitectureState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ArchitectureStateCopyWith<_ArchitectureState> get copyWith => __$ArchitectureStateCopyWithImpl<_ArchitectureState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ArchitectureState&&(identical(other.pattern, pattern) || other.pattern == pattern)&&(identical(other.includeMappers, includeMappers) || other.includeMappers == includeMappers)&&(identical(other.useRiverpodAnnotations, useRiverpodAnnotations) || other.useRiverpodAnnotations == useRiverpodAnnotations)&&(identical(other.useCubit, useCubit) || other.useCubit == useCubit)&&(identical(other.mirrorTestStructure, mirrorTestStructure) || other.mirrorTestStructure == mirrorTestStructure)&&(identical(other.firstFeatureName, firstFeatureName) || other.firstFeatureName == firstFeatureName)&&(identical(other.storageStrategy, storageStrategy) || other.storageStrategy == storageStrategy)&&(identical(other.useNavigationShell, useNavigationShell) || other.useNavigationShell == useNavigationShell)&&(identical(other.shellIcon, shellIcon) || other.shellIcon == shellIcon)&&(identical(other.shellLabel, shellLabel) || other.shellLabel == shellLabel)&&(identical(other.generateAuth, generateAuth) || other.generateAuth == generateAuth));
}


@override
int get hashCode => Object.hash(runtimeType,pattern,includeMappers,useRiverpodAnnotations,useCubit,mirrorTestStructure,firstFeatureName,storageStrategy,useNavigationShell,shellIcon,shellLabel,generateAuth);

@override
String toString() {
  return 'ArchitectureState(pattern: $pattern, includeMappers: $includeMappers, useRiverpodAnnotations: $useRiverpodAnnotations, useCubit: $useCubit, mirrorTestStructure: $mirrorTestStructure, firstFeatureName: $firstFeatureName, storageStrategy: $storageStrategy, useNavigationShell: $useNavigationShell, shellIcon: $shellIcon, shellLabel: $shellLabel, generateAuth: $generateAuth)';
}


}

/// @nodoc
abstract mixin class _$ArchitectureStateCopyWith<$Res> implements $ArchitectureStateCopyWith<$Res> {
  factory _$ArchitectureStateCopyWith(_ArchitectureState value, $Res Function(_ArchitectureState) _then) = __$ArchitectureStateCopyWithImpl;
@override @useResult
$Res call({
 StructuralPattern pattern, bool includeMappers, bool useRiverpodAnnotations, bool useCubit, bool mirrorTestStructure, String firstFeatureName, StorageStrategy storageStrategy, bool useNavigationShell, String shellIcon, String shellLabel, bool generateAuth
});




}
/// @nodoc
class __$ArchitectureStateCopyWithImpl<$Res>
    implements _$ArchitectureStateCopyWith<$Res> {
  __$ArchitectureStateCopyWithImpl(this._self, this._then);

  final _ArchitectureState _self;
  final $Res Function(_ArchitectureState) _then;

/// Create a copy of ArchitectureState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? pattern = null,Object? includeMappers = null,Object? useRiverpodAnnotations = null,Object? useCubit = null,Object? mirrorTestStructure = null,Object? firstFeatureName = null,Object? storageStrategy = null,Object? useNavigationShell = null,Object? shellIcon = null,Object? shellLabel = null,Object? generateAuth = null,}) {
  return _then(_ArchitectureState(
pattern: null == pattern ? _self.pattern : pattern // ignore: cast_nullable_to_non_nullable
as StructuralPattern,includeMappers: null == includeMappers ? _self.includeMappers : includeMappers // ignore: cast_nullable_to_non_nullable
as bool,useRiverpodAnnotations: null == useRiverpodAnnotations ? _self.useRiverpodAnnotations : useRiverpodAnnotations // ignore: cast_nullable_to_non_nullable
as bool,useCubit: null == useCubit ? _self.useCubit : useCubit // ignore: cast_nullable_to_non_nullable
as bool,mirrorTestStructure: null == mirrorTestStructure ? _self.mirrorTestStructure : mirrorTestStructure // ignore: cast_nullable_to_non_nullable
as bool,firstFeatureName: null == firstFeatureName ? _self.firstFeatureName : firstFeatureName // ignore: cast_nullable_to_non_nullable
as String,storageStrategy: null == storageStrategy ? _self.storageStrategy : storageStrategy // ignore: cast_nullable_to_non_nullable
as StorageStrategy,useNavigationShell: null == useNavigationShell ? _self.useNavigationShell : useNavigationShell // ignore: cast_nullable_to_non_nullable
as bool,shellIcon: null == shellIcon ? _self.shellIcon : shellIcon // ignore: cast_nullable_to_non_nullable
as String,shellLabel: null == shellLabel ? _self.shellLabel : shellLabel // ignore: cast_nullable_to_non_nullable
as String,generateAuth: null == generateAuth ? _self.generateAuth : generateAuth // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
