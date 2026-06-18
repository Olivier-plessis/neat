// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'neat_contract.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$NeatContract {

 String get projectName;/// feature_first | layer_first
 String get architecture;/// riverpod | bloc | none
 String get stateManagement;/// go_router_builder | go_router | none
 String get navigation;/// chopper | dio | retrofit | none
 String get httpClient;/// none | customM3 | flexColorScheme
 String get themeApproach;/// remoteOnly | offlineFirstRead | offlineFirstSync
 String get storageStrategy; int get schemaVersion; bool get useRiverpodAnnotations; bool get extractUiPackage; bool get useScreenUtil; bool get hasEnvied; bool get hasFreezed; bool get hasJsonSerializable; bool get includeMappers; bool get mirrorTestStructure; bool get generateWidgetbook; bool get useNavigationShell; bool get generateAuth; bool get generateRealtime; bool get generateStorage; bool get generateOAuth; List<String> get components;
/// Create a copy of NeatContract
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NeatContractCopyWith<NeatContract> get copyWith => _$NeatContractCopyWithImpl<NeatContract>(this as NeatContract, _$identity);

  /// Serializes this NeatContract to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NeatContract&&(identical(other.projectName, projectName) || other.projectName == projectName)&&(identical(other.architecture, architecture) || other.architecture == architecture)&&(identical(other.stateManagement, stateManagement) || other.stateManagement == stateManagement)&&(identical(other.navigation, navigation) || other.navigation == navigation)&&(identical(other.httpClient, httpClient) || other.httpClient == httpClient)&&(identical(other.themeApproach, themeApproach) || other.themeApproach == themeApproach)&&(identical(other.storageStrategy, storageStrategy) || other.storageStrategy == storageStrategy)&&(identical(other.schemaVersion, schemaVersion) || other.schemaVersion == schemaVersion)&&(identical(other.useRiverpodAnnotations, useRiverpodAnnotations) || other.useRiverpodAnnotations == useRiverpodAnnotations)&&(identical(other.extractUiPackage, extractUiPackage) || other.extractUiPackage == extractUiPackage)&&(identical(other.useScreenUtil, useScreenUtil) || other.useScreenUtil == useScreenUtil)&&(identical(other.hasEnvied, hasEnvied) || other.hasEnvied == hasEnvied)&&(identical(other.hasFreezed, hasFreezed) || other.hasFreezed == hasFreezed)&&(identical(other.hasJsonSerializable, hasJsonSerializable) || other.hasJsonSerializable == hasJsonSerializable)&&(identical(other.includeMappers, includeMappers) || other.includeMappers == includeMappers)&&(identical(other.mirrorTestStructure, mirrorTestStructure) || other.mirrorTestStructure == mirrorTestStructure)&&(identical(other.generateWidgetbook, generateWidgetbook) || other.generateWidgetbook == generateWidgetbook)&&(identical(other.useNavigationShell, useNavigationShell) || other.useNavigationShell == useNavigationShell)&&(identical(other.generateAuth, generateAuth) || other.generateAuth == generateAuth)&&(identical(other.generateRealtime, generateRealtime) || other.generateRealtime == generateRealtime)&&(identical(other.generateStorage, generateStorage) || other.generateStorage == generateStorage)&&(identical(other.generateOAuth, generateOAuth) || other.generateOAuth == generateOAuth)&&const DeepCollectionEquality().equals(other.components, components));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,projectName,architecture,stateManagement,navigation,httpClient,themeApproach,storageStrategy,schemaVersion,useRiverpodAnnotations,extractUiPackage,useScreenUtil,hasEnvied,hasFreezed,hasJsonSerializable,includeMappers,mirrorTestStructure,generateWidgetbook,useNavigationShell,generateAuth,generateRealtime,generateStorage,generateOAuth,const DeepCollectionEquality().hash(components)]);

@override
String toString() {
  return 'NeatContract(projectName: $projectName, architecture: $architecture, stateManagement: $stateManagement, navigation: $navigation, httpClient: $httpClient, themeApproach: $themeApproach, storageStrategy: $storageStrategy, schemaVersion: $schemaVersion, useRiverpodAnnotations: $useRiverpodAnnotations, extractUiPackage: $extractUiPackage, useScreenUtil: $useScreenUtil, hasEnvied: $hasEnvied, hasFreezed: $hasFreezed, hasJsonSerializable: $hasJsonSerializable, includeMappers: $includeMappers, mirrorTestStructure: $mirrorTestStructure, generateWidgetbook: $generateWidgetbook, useNavigationShell: $useNavigationShell, generateAuth: $generateAuth, generateRealtime: $generateRealtime, generateStorage: $generateStorage, generateOAuth: $generateOAuth, components: $components)';
}


}

/// @nodoc
abstract mixin class $NeatContractCopyWith<$Res>  {
  factory $NeatContractCopyWith(NeatContract value, $Res Function(NeatContract) _then) = _$NeatContractCopyWithImpl;
@useResult
$Res call({
 String projectName, String architecture, String stateManagement, String navigation, String httpClient, String themeApproach, String storageStrategy, int schemaVersion, bool useRiverpodAnnotations, bool extractUiPackage, bool useScreenUtil, bool hasEnvied, bool hasFreezed, bool hasJsonSerializable, bool includeMappers, bool mirrorTestStructure, bool generateWidgetbook, bool useNavigationShell, bool generateAuth, bool generateRealtime, bool generateStorage, bool generateOAuth, List<String> components
});




}
/// @nodoc
class _$NeatContractCopyWithImpl<$Res>
    implements $NeatContractCopyWith<$Res> {
  _$NeatContractCopyWithImpl(this._self, this._then);

  final NeatContract _self;
  final $Res Function(NeatContract) _then;

/// Create a copy of NeatContract
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? projectName = null,Object? architecture = null,Object? stateManagement = null,Object? navigation = null,Object? httpClient = null,Object? themeApproach = null,Object? storageStrategy = null,Object? schemaVersion = null,Object? useRiverpodAnnotations = null,Object? extractUiPackage = null,Object? useScreenUtil = null,Object? hasEnvied = null,Object? hasFreezed = null,Object? hasJsonSerializable = null,Object? includeMappers = null,Object? mirrorTestStructure = null,Object? generateWidgetbook = null,Object? useNavigationShell = null,Object? generateAuth = null,Object? generateRealtime = null,Object? generateStorage = null,Object? generateOAuth = null,Object? components = null,}) {
  return _then(_self.copyWith(
projectName: null == projectName ? _self.projectName : projectName // ignore: cast_nullable_to_non_nullable
as String,architecture: null == architecture ? _self.architecture : architecture // ignore: cast_nullable_to_non_nullable
as String,stateManagement: null == stateManagement ? _self.stateManagement : stateManagement // ignore: cast_nullable_to_non_nullable
as String,navigation: null == navigation ? _self.navigation : navigation // ignore: cast_nullable_to_non_nullable
as String,httpClient: null == httpClient ? _self.httpClient : httpClient // ignore: cast_nullable_to_non_nullable
as String,themeApproach: null == themeApproach ? _self.themeApproach : themeApproach // ignore: cast_nullable_to_non_nullable
as String,storageStrategy: null == storageStrategy ? _self.storageStrategy : storageStrategy // ignore: cast_nullable_to_non_nullable
as String,schemaVersion: null == schemaVersion ? _self.schemaVersion : schemaVersion // ignore: cast_nullable_to_non_nullable
as int,useRiverpodAnnotations: null == useRiverpodAnnotations ? _self.useRiverpodAnnotations : useRiverpodAnnotations // ignore: cast_nullable_to_non_nullable
as bool,extractUiPackage: null == extractUiPackage ? _self.extractUiPackage : extractUiPackage // ignore: cast_nullable_to_non_nullable
as bool,useScreenUtil: null == useScreenUtil ? _self.useScreenUtil : useScreenUtil // ignore: cast_nullable_to_non_nullable
as bool,hasEnvied: null == hasEnvied ? _self.hasEnvied : hasEnvied // ignore: cast_nullable_to_non_nullable
as bool,hasFreezed: null == hasFreezed ? _self.hasFreezed : hasFreezed // ignore: cast_nullable_to_non_nullable
as bool,hasJsonSerializable: null == hasJsonSerializable ? _self.hasJsonSerializable : hasJsonSerializable // ignore: cast_nullable_to_non_nullable
as bool,includeMappers: null == includeMappers ? _self.includeMappers : includeMappers // ignore: cast_nullable_to_non_nullable
as bool,mirrorTestStructure: null == mirrorTestStructure ? _self.mirrorTestStructure : mirrorTestStructure // ignore: cast_nullable_to_non_nullable
as bool,generateWidgetbook: null == generateWidgetbook ? _self.generateWidgetbook : generateWidgetbook // ignore: cast_nullable_to_non_nullable
as bool,useNavigationShell: null == useNavigationShell ? _self.useNavigationShell : useNavigationShell // ignore: cast_nullable_to_non_nullable
as bool,generateAuth: null == generateAuth ? _self.generateAuth : generateAuth // ignore: cast_nullable_to_non_nullable
as bool,generateRealtime: null == generateRealtime ? _self.generateRealtime : generateRealtime // ignore: cast_nullable_to_non_nullable
as bool,generateStorage: null == generateStorage ? _self.generateStorage : generateStorage // ignore: cast_nullable_to_non_nullable
as bool,generateOAuth: null == generateOAuth ? _self.generateOAuth : generateOAuth // ignore: cast_nullable_to_non_nullable
as bool,components: null == components ? _self.components : components // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [NeatContract].
extension NeatContractPatterns on NeatContract {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NeatContract value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NeatContract() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NeatContract value)  $default,){
final _that = this;
switch (_that) {
case _NeatContract():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NeatContract value)?  $default,){
final _that = this;
switch (_that) {
case _NeatContract() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String projectName,  String architecture,  String stateManagement,  String navigation,  String httpClient,  String themeApproach,  String storageStrategy,  int schemaVersion,  bool useRiverpodAnnotations,  bool extractUiPackage,  bool useScreenUtil,  bool hasEnvied,  bool hasFreezed,  bool hasJsonSerializable,  bool includeMappers,  bool mirrorTestStructure,  bool generateWidgetbook,  bool useNavigationShell,  bool generateAuth,  bool generateRealtime,  bool generateStorage,  bool generateOAuth,  List<String> components)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NeatContract() when $default != null:
return $default(_that.projectName,_that.architecture,_that.stateManagement,_that.navigation,_that.httpClient,_that.themeApproach,_that.storageStrategy,_that.schemaVersion,_that.useRiverpodAnnotations,_that.extractUiPackage,_that.useScreenUtil,_that.hasEnvied,_that.hasFreezed,_that.hasJsonSerializable,_that.includeMappers,_that.mirrorTestStructure,_that.generateWidgetbook,_that.useNavigationShell,_that.generateAuth,_that.generateRealtime,_that.generateStorage,_that.generateOAuth,_that.components);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String projectName,  String architecture,  String stateManagement,  String navigation,  String httpClient,  String themeApproach,  String storageStrategy,  int schemaVersion,  bool useRiverpodAnnotations,  bool extractUiPackage,  bool useScreenUtil,  bool hasEnvied,  bool hasFreezed,  bool hasJsonSerializable,  bool includeMappers,  bool mirrorTestStructure,  bool generateWidgetbook,  bool useNavigationShell,  bool generateAuth,  bool generateRealtime,  bool generateStorage,  bool generateOAuth,  List<String> components)  $default,) {final _that = this;
switch (_that) {
case _NeatContract():
return $default(_that.projectName,_that.architecture,_that.stateManagement,_that.navigation,_that.httpClient,_that.themeApproach,_that.storageStrategy,_that.schemaVersion,_that.useRiverpodAnnotations,_that.extractUiPackage,_that.useScreenUtil,_that.hasEnvied,_that.hasFreezed,_that.hasJsonSerializable,_that.includeMappers,_that.mirrorTestStructure,_that.generateWidgetbook,_that.useNavigationShell,_that.generateAuth,_that.generateRealtime,_that.generateStorage,_that.generateOAuth,_that.components);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String projectName,  String architecture,  String stateManagement,  String navigation,  String httpClient,  String themeApproach,  String storageStrategy,  int schemaVersion,  bool useRiverpodAnnotations,  bool extractUiPackage,  bool useScreenUtil,  bool hasEnvied,  bool hasFreezed,  bool hasJsonSerializable,  bool includeMappers,  bool mirrorTestStructure,  bool generateWidgetbook,  bool useNavigationShell,  bool generateAuth,  bool generateRealtime,  bool generateStorage,  bool generateOAuth,  List<String> components)?  $default,) {final _that = this;
switch (_that) {
case _NeatContract() when $default != null:
return $default(_that.projectName,_that.architecture,_that.stateManagement,_that.navigation,_that.httpClient,_that.themeApproach,_that.storageStrategy,_that.schemaVersion,_that.useRiverpodAnnotations,_that.extractUiPackage,_that.useScreenUtil,_that.hasEnvied,_that.hasFreezed,_that.hasJsonSerializable,_that.includeMappers,_that.mirrorTestStructure,_that.generateWidgetbook,_that.useNavigationShell,_that.generateAuth,_that.generateRealtime,_that.generateStorage,_that.generateOAuth,_that.components);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NeatContract implements NeatContract {
  const _NeatContract({required this.projectName, required this.architecture, required this.stateManagement, required this.navigation, required this.httpClient, required this.themeApproach, required this.storageStrategy, this.schemaVersion = 1, this.useRiverpodAnnotations = true, this.extractUiPackage = false, this.useScreenUtil = false, this.hasEnvied = false, this.hasFreezed = false, this.hasJsonSerializable = false, this.includeMappers = true, this.mirrorTestStructure = true, this.generateWidgetbook = false, this.useNavigationShell = false, this.generateAuth = false, this.generateRealtime = false, this.generateStorage = false, this.generateOAuth = false, final  List<String> components = const <String>[]}): _components = components;
  factory _NeatContract.fromJson(Map<String, dynamic> json) => _$NeatContractFromJson(json);

@override final  String projectName;
/// feature_first | layer_first
@override final  String architecture;
/// riverpod | bloc | none
@override final  String stateManagement;
/// go_router_builder | go_router | none
@override final  String navigation;
/// chopper | dio | retrofit | none
@override final  String httpClient;
/// none | customM3 | flexColorScheme
@override final  String themeApproach;
/// remoteOnly | offlineFirstRead | offlineFirstSync
@override final  String storageStrategy;
@override@JsonKey() final  int schemaVersion;
@override@JsonKey() final  bool useRiverpodAnnotations;
@override@JsonKey() final  bool extractUiPackage;
@override@JsonKey() final  bool useScreenUtil;
@override@JsonKey() final  bool hasEnvied;
@override@JsonKey() final  bool hasFreezed;
@override@JsonKey() final  bool hasJsonSerializable;
@override@JsonKey() final  bool includeMappers;
@override@JsonKey() final  bool mirrorTestStructure;
@override@JsonKey() final  bool generateWidgetbook;
@override@JsonKey() final  bool useNavigationShell;
@override@JsonKey() final  bool generateAuth;
@override@JsonKey() final  bool generateRealtime;
@override@JsonKey() final  bool generateStorage;
@override@JsonKey() final  bool generateOAuth;
 final  List<String> _components;
@override@JsonKey() List<String> get components {
  if (_components is EqualUnmodifiableListView) return _components;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_components);
}


/// Create a copy of NeatContract
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NeatContractCopyWith<_NeatContract> get copyWith => __$NeatContractCopyWithImpl<_NeatContract>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NeatContractToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NeatContract&&(identical(other.projectName, projectName) || other.projectName == projectName)&&(identical(other.architecture, architecture) || other.architecture == architecture)&&(identical(other.stateManagement, stateManagement) || other.stateManagement == stateManagement)&&(identical(other.navigation, navigation) || other.navigation == navigation)&&(identical(other.httpClient, httpClient) || other.httpClient == httpClient)&&(identical(other.themeApproach, themeApproach) || other.themeApproach == themeApproach)&&(identical(other.storageStrategy, storageStrategy) || other.storageStrategy == storageStrategy)&&(identical(other.schemaVersion, schemaVersion) || other.schemaVersion == schemaVersion)&&(identical(other.useRiverpodAnnotations, useRiverpodAnnotations) || other.useRiverpodAnnotations == useRiverpodAnnotations)&&(identical(other.extractUiPackage, extractUiPackage) || other.extractUiPackage == extractUiPackage)&&(identical(other.useScreenUtil, useScreenUtil) || other.useScreenUtil == useScreenUtil)&&(identical(other.hasEnvied, hasEnvied) || other.hasEnvied == hasEnvied)&&(identical(other.hasFreezed, hasFreezed) || other.hasFreezed == hasFreezed)&&(identical(other.hasJsonSerializable, hasJsonSerializable) || other.hasJsonSerializable == hasJsonSerializable)&&(identical(other.includeMappers, includeMappers) || other.includeMappers == includeMappers)&&(identical(other.mirrorTestStructure, mirrorTestStructure) || other.mirrorTestStructure == mirrorTestStructure)&&(identical(other.generateWidgetbook, generateWidgetbook) || other.generateWidgetbook == generateWidgetbook)&&(identical(other.useNavigationShell, useNavigationShell) || other.useNavigationShell == useNavigationShell)&&(identical(other.generateAuth, generateAuth) || other.generateAuth == generateAuth)&&(identical(other.generateRealtime, generateRealtime) || other.generateRealtime == generateRealtime)&&(identical(other.generateStorage, generateStorage) || other.generateStorage == generateStorage)&&(identical(other.generateOAuth, generateOAuth) || other.generateOAuth == generateOAuth)&&const DeepCollectionEquality().equals(other._components, _components));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,projectName,architecture,stateManagement,navigation,httpClient,themeApproach,storageStrategy,schemaVersion,useRiverpodAnnotations,extractUiPackage,useScreenUtil,hasEnvied,hasFreezed,hasJsonSerializable,includeMappers,mirrorTestStructure,generateWidgetbook,useNavigationShell,generateAuth,generateRealtime,generateStorage,generateOAuth,const DeepCollectionEquality().hash(_components)]);

@override
String toString() {
  return 'NeatContract(projectName: $projectName, architecture: $architecture, stateManagement: $stateManagement, navigation: $navigation, httpClient: $httpClient, themeApproach: $themeApproach, storageStrategy: $storageStrategy, schemaVersion: $schemaVersion, useRiverpodAnnotations: $useRiverpodAnnotations, extractUiPackage: $extractUiPackage, useScreenUtil: $useScreenUtil, hasEnvied: $hasEnvied, hasFreezed: $hasFreezed, hasJsonSerializable: $hasJsonSerializable, includeMappers: $includeMappers, mirrorTestStructure: $mirrorTestStructure, generateWidgetbook: $generateWidgetbook, useNavigationShell: $useNavigationShell, generateAuth: $generateAuth, generateRealtime: $generateRealtime, generateStorage: $generateStorage, generateOAuth: $generateOAuth, components: $components)';
}


}

/// @nodoc
abstract mixin class _$NeatContractCopyWith<$Res> implements $NeatContractCopyWith<$Res> {
  factory _$NeatContractCopyWith(_NeatContract value, $Res Function(_NeatContract) _then) = __$NeatContractCopyWithImpl;
@override @useResult
$Res call({
 String projectName, String architecture, String stateManagement, String navigation, String httpClient, String themeApproach, String storageStrategy, int schemaVersion, bool useRiverpodAnnotations, bool extractUiPackage, bool useScreenUtil, bool hasEnvied, bool hasFreezed, bool hasJsonSerializable, bool includeMappers, bool mirrorTestStructure, bool generateWidgetbook, bool useNavigationShell, bool generateAuth, bool generateRealtime, bool generateStorage, bool generateOAuth, List<String> components
});




}
/// @nodoc
class __$NeatContractCopyWithImpl<$Res>
    implements _$NeatContractCopyWith<$Res> {
  __$NeatContractCopyWithImpl(this._self, this._then);

  final _NeatContract _self;
  final $Res Function(_NeatContract) _then;

/// Create a copy of NeatContract
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? projectName = null,Object? architecture = null,Object? stateManagement = null,Object? navigation = null,Object? httpClient = null,Object? themeApproach = null,Object? storageStrategy = null,Object? schemaVersion = null,Object? useRiverpodAnnotations = null,Object? extractUiPackage = null,Object? useScreenUtil = null,Object? hasEnvied = null,Object? hasFreezed = null,Object? hasJsonSerializable = null,Object? includeMappers = null,Object? mirrorTestStructure = null,Object? generateWidgetbook = null,Object? useNavigationShell = null,Object? generateAuth = null,Object? generateRealtime = null,Object? generateStorage = null,Object? generateOAuth = null,Object? components = null,}) {
  return _then(_NeatContract(
projectName: null == projectName ? _self.projectName : projectName // ignore: cast_nullable_to_non_nullable
as String,architecture: null == architecture ? _self.architecture : architecture // ignore: cast_nullable_to_non_nullable
as String,stateManagement: null == stateManagement ? _self.stateManagement : stateManagement // ignore: cast_nullable_to_non_nullable
as String,navigation: null == navigation ? _self.navigation : navigation // ignore: cast_nullable_to_non_nullable
as String,httpClient: null == httpClient ? _self.httpClient : httpClient // ignore: cast_nullable_to_non_nullable
as String,themeApproach: null == themeApproach ? _self.themeApproach : themeApproach // ignore: cast_nullable_to_non_nullable
as String,storageStrategy: null == storageStrategy ? _self.storageStrategy : storageStrategy // ignore: cast_nullable_to_non_nullable
as String,schemaVersion: null == schemaVersion ? _self.schemaVersion : schemaVersion // ignore: cast_nullable_to_non_nullable
as int,useRiverpodAnnotations: null == useRiverpodAnnotations ? _self.useRiverpodAnnotations : useRiverpodAnnotations // ignore: cast_nullable_to_non_nullable
as bool,extractUiPackage: null == extractUiPackage ? _self.extractUiPackage : extractUiPackage // ignore: cast_nullable_to_non_nullable
as bool,useScreenUtil: null == useScreenUtil ? _self.useScreenUtil : useScreenUtil // ignore: cast_nullable_to_non_nullable
as bool,hasEnvied: null == hasEnvied ? _self.hasEnvied : hasEnvied // ignore: cast_nullable_to_non_nullable
as bool,hasFreezed: null == hasFreezed ? _self.hasFreezed : hasFreezed // ignore: cast_nullable_to_non_nullable
as bool,hasJsonSerializable: null == hasJsonSerializable ? _self.hasJsonSerializable : hasJsonSerializable // ignore: cast_nullable_to_non_nullable
as bool,includeMappers: null == includeMappers ? _self.includeMappers : includeMappers // ignore: cast_nullable_to_non_nullable
as bool,mirrorTestStructure: null == mirrorTestStructure ? _self.mirrorTestStructure : mirrorTestStructure // ignore: cast_nullable_to_non_nullable
as bool,generateWidgetbook: null == generateWidgetbook ? _self.generateWidgetbook : generateWidgetbook // ignore: cast_nullable_to_non_nullable
as bool,useNavigationShell: null == useNavigationShell ? _self.useNavigationShell : useNavigationShell // ignore: cast_nullable_to_non_nullable
as bool,generateAuth: null == generateAuth ? _self.generateAuth : generateAuth // ignore: cast_nullable_to_non_nullable
as bool,generateRealtime: null == generateRealtime ? _self.generateRealtime : generateRealtime // ignore: cast_nullable_to_non_nullable
as bool,generateStorage: null == generateStorage ? _self.generateStorage : generateStorage // ignore: cast_nullable_to_non_nullable
as bool,generateOAuth: null == generateOAuth ? _self.generateOAuth : generateOAuth // ignore: cast_nullable_to_non_nullable
as bool,components: null == components ? _self._components : components // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on
