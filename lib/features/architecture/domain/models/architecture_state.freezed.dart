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
 bool get useCubit; bool get mirrorTestStructure;/// Opt-in: extract every feature into its own Dart workspace package
/// (`packages/<feature>/`) instead of a folder under `lib/features/` —
/// real package boundaries for a team where each dev owns a feature.
/// Requires a shared `core` package (Result/Failure/UseCase/
/// networking), gated to dio/chopper/supabase/firebase + Riverpod
/// annotations (manual or typed/go_router_builder routing, any storage
/// strategy, and auth/realtime/storage all work — Auth stays app-level
/// even when split — see ROADMAP.md §6a).
 bool get packageSplit;/// Opt-in: scaffold a first feature at all (mirrors `flutter create`'s
/// counter app — a real worked example so a fresh project runs and shows
/// data). Off → the app ships with zero features, just a placeholder
/// welcome screen; add your first real feature via the Workshop, which
/// owns all entity/JSON-paste editing (the wizard no longer does).
 bool get generateFirstFeature;/// Name of the first feature scaffolded under lib/features/ (snake_case).
/// Only meaningful when [generateFirstFeature] is on.
 String get firstFeatureName;/// The first feature's entity fields, inferred from a pasted Response JSON
/// (or the default id/name placeholder). Drives the entity/model/mapper/Drift
/// table/list tile of the generated feature.
 List<FieldSpec> get firstFeatureFields;/// The raw JSON the user pasted to infer [firstFeatureFields] (kept so the
/// UI can re-show / re-infer it). Empty → the default id/name placeholder.
 String get firstFeatureJson;/// Human-readable notes from the last inference (coerced id, dropped nested
/// fields, null types…). Shown under the editor so the user can review/edit.
 List<String> get firstFeatureFieldWarnings;/// Overrides the first feature's REST resource path (default:
/// `/<firstFeatureName>s`). Either a relative path or an absolute URL — an
/// absolute URL overrides the project's API Base URL entirely. Empty →
/// the default pluralised path. REST clients only (dio/chopper).
 String get firstFeatureApiPath;/// Data persistence strategy. [StorageStrategy.offlineFirst] switches the
/// generated project to a workspace with a Drift local-storage package.
 StorageStrategy get storageStrategy;/// When true (and go_router is in the stack), the app boots into a bottom
/// [NavigationBar] shell: the first feature is the first tab, so the nav bar
/// is the app's spine from launch. Requires go_router / go_router_builder.
 bool get useNavigationShell;/// Material icon name for the first tab (only when [useNavigationShell]).
 String get shellIcon;/// First tab label (blank → the feature name, capitalised).
 String get shellLabel;/// Opt-in: generate a Supabase **auth** feature (login/signup/forgot) + a
/// go_router guard. Only effective with a Supabase backend + go_router_builder.
 bool get generateAuth;/// Opt-in: make the first feature's list screen **live** via Supabase
/// Realtime (`.stream()`). Only effective with a Supabase backend + riverpod
/// annotations (the list becomes a StreamNotifier).
 bool get generateRealtime;/// Opt-in: generate a Supabase **Storage** service (+ provider + a sample
/// avatar upload widget). Only effective with a Supabase backend + riverpod.
 bool get generateStorage;/// Path to an uploaded Firebase config JSON (the web app config or a
/// FlutterFire export). When a Firebase backend is selected, NEAT generates
/// `firebase_options.dart` from it. Blank → compile-safe placeholders.
 String get firebaseConfigPath;/// Opt-in: add Google + Apple OAuth sign-in to the auth feature (via
/// `FirebaseAuth.signInWithProvider`). Only effective with a Firebase
/// backend + auth enabled.
 bool get generateOAuth;/// Opt-in: type-safe internationalisation with **slang** (base scaffold +
/// `TranslationProvider` + `context.t`, a sample language switcher).
 bool get generateI18n;/// Which languages ship in the default (non-CSV) scaffold — see
/// [i18nLocales]'s own doc for why at least one is always required.
 Set<String> get i18nLocales;/// Path to an uploaded **compact CSV** of translations (`key,en,fr,…`). When
/// set (and [generateI18n] is on), the CSV becomes the single source of
/// translations instead of the default JSON scaffold, and [i18nLocales] is
/// ignored — the CSV's own header columns decide the languages.
 String get i18nCsvPath;/// Opt-in: generate native **build flavors** (Android productFlavors, per-env
/// entry points `main_<flavor>.dart`, `.vscode/launch.json`). Off by default
/// so a plain `flutter run` works with zero config. Only effective with envied.
 bool get generateFlavors;/// The build environments, renamable, each with an optional API base URL
/// written into its `.env`. Starts as a **single** `prod` env (→ plain `.env`
/// + `main.dart`, no flavors); the user adds more on demand. Drives envied +
/// flavors. The production base is [baseEnvIndex] (not positional).
 List<EnvConfig> get environments;/// Index into [environments] of the production **base** (no appId suffix; the
/// logger quietens there; release builds target it). Chosen explicitly via
/// the BASE chip — never positional, so adding an env never moves the base.
 int get baseEnvIndex;
/// Create a copy of ArchitectureState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ArchitectureStateCopyWith<ArchitectureState> get copyWith => _$ArchitectureStateCopyWithImpl<ArchitectureState>(this as ArchitectureState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ArchitectureState&&(identical(other.pattern, pattern) || other.pattern == pattern)&&(identical(other.includeMappers, includeMappers) || other.includeMappers == includeMappers)&&(identical(other.useRiverpodAnnotations, useRiverpodAnnotations) || other.useRiverpodAnnotations == useRiverpodAnnotations)&&(identical(other.useCubit, useCubit) || other.useCubit == useCubit)&&(identical(other.mirrorTestStructure, mirrorTestStructure) || other.mirrorTestStructure == mirrorTestStructure)&&(identical(other.packageSplit, packageSplit) || other.packageSplit == packageSplit)&&(identical(other.generateFirstFeature, generateFirstFeature) || other.generateFirstFeature == generateFirstFeature)&&(identical(other.firstFeatureName, firstFeatureName) || other.firstFeatureName == firstFeatureName)&&const DeepCollectionEquality().equals(other.firstFeatureFields, firstFeatureFields)&&(identical(other.firstFeatureJson, firstFeatureJson) || other.firstFeatureJson == firstFeatureJson)&&const DeepCollectionEquality().equals(other.firstFeatureFieldWarnings, firstFeatureFieldWarnings)&&(identical(other.firstFeatureApiPath, firstFeatureApiPath) || other.firstFeatureApiPath == firstFeatureApiPath)&&(identical(other.storageStrategy, storageStrategy) || other.storageStrategy == storageStrategy)&&(identical(other.useNavigationShell, useNavigationShell) || other.useNavigationShell == useNavigationShell)&&(identical(other.shellIcon, shellIcon) || other.shellIcon == shellIcon)&&(identical(other.shellLabel, shellLabel) || other.shellLabel == shellLabel)&&(identical(other.generateAuth, generateAuth) || other.generateAuth == generateAuth)&&(identical(other.generateRealtime, generateRealtime) || other.generateRealtime == generateRealtime)&&(identical(other.generateStorage, generateStorage) || other.generateStorage == generateStorage)&&(identical(other.firebaseConfigPath, firebaseConfigPath) || other.firebaseConfigPath == firebaseConfigPath)&&(identical(other.generateOAuth, generateOAuth) || other.generateOAuth == generateOAuth)&&(identical(other.generateI18n, generateI18n) || other.generateI18n == generateI18n)&&const DeepCollectionEquality().equals(other.i18nLocales, i18nLocales)&&(identical(other.i18nCsvPath, i18nCsvPath) || other.i18nCsvPath == i18nCsvPath)&&(identical(other.generateFlavors, generateFlavors) || other.generateFlavors == generateFlavors)&&const DeepCollectionEquality().equals(other.environments, environments)&&(identical(other.baseEnvIndex, baseEnvIndex) || other.baseEnvIndex == baseEnvIndex));
}


@override
int get hashCode => Object.hashAll([runtimeType,pattern,includeMappers,useRiverpodAnnotations,useCubit,mirrorTestStructure,packageSplit,generateFirstFeature,firstFeatureName,const DeepCollectionEquality().hash(firstFeatureFields),firstFeatureJson,const DeepCollectionEquality().hash(firstFeatureFieldWarnings),firstFeatureApiPath,storageStrategy,useNavigationShell,shellIcon,shellLabel,generateAuth,generateRealtime,generateStorage,firebaseConfigPath,generateOAuth,generateI18n,const DeepCollectionEquality().hash(i18nLocales),i18nCsvPath,generateFlavors,const DeepCollectionEquality().hash(environments),baseEnvIndex]);

@override
String toString() {
  return 'ArchitectureState(pattern: $pattern, includeMappers: $includeMappers, useRiverpodAnnotations: $useRiverpodAnnotations, useCubit: $useCubit, mirrorTestStructure: $mirrorTestStructure, packageSplit: $packageSplit, generateFirstFeature: $generateFirstFeature, firstFeatureName: $firstFeatureName, firstFeatureFields: $firstFeatureFields, firstFeatureJson: $firstFeatureJson, firstFeatureFieldWarnings: $firstFeatureFieldWarnings, firstFeatureApiPath: $firstFeatureApiPath, storageStrategy: $storageStrategy, useNavigationShell: $useNavigationShell, shellIcon: $shellIcon, shellLabel: $shellLabel, generateAuth: $generateAuth, generateRealtime: $generateRealtime, generateStorage: $generateStorage, firebaseConfigPath: $firebaseConfigPath, generateOAuth: $generateOAuth, generateI18n: $generateI18n, i18nLocales: $i18nLocales, i18nCsvPath: $i18nCsvPath, generateFlavors: $generateFlavors, environments: $environments, baseEnvIndex: $baseEnvIndex)';
}


}

/// @nodoc
abstract mixin class $ArchitectureStateCopyWith<$Res>  {
  factory $ArchitectureStateCopyWith(ArchitectureState value, $Res Function(ArchitectureState) _then) = _$ArchitectureStateCopyWithImpl;
@useResult
$Res call({
 StructuralPattern pattern, bool includeMappers, bool useRiverpodAnnotations, bool useCubit, bool mirrorTestStructure, bool packageSplit, bool generateFirstFeature, String firstFeatureName, List<FieldSpec> firstFeatureFields, String firstFeatureJson, List<String> firstFeatureFieldWarnings, String firstFeatureApiPath, StorageStrategy storageStrategy, bool useNavigationShell, String shellIcon, String shellLabel, bool generateAuth, bool generateRealtime, bool generateStorage, String firebaseConfigPath, bool generateOAuth, bool generateI18n, Set<String> i18nLocales, String i18nCsvPath, bool generateFlavors, List<EnvConfig> environments, int baseEnvIndex
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
@pragma('vm:prefer-inline') @override $Res call({Object? pattern = null,Object? includeMappers = null,Object? useRiverpodAnnotations = null,Object? useCubit = null,Object? mirrorTestStructure = null,Object? packageSplit = null,Object? generateFirstFeature = null,Object? firstFeatureName = null,Object? firstFeatureFields = null,Object? firstFeatureJson = null,Object? firstFeatureFieldWarnings = null,Object? firstFeatureApiPath = null,Object? storageStrategy = null,Object? useNavigationShell = null,Object? shellIcon = null,Object? shellLabel = null,Object? generateAuth = null,Object? generateRealtime = null,Object? generateStorage = null,Object? firebaseConfigPath = null,Object? generateOAuth = null,Object? generateI18n = null,Object? i18nLocales = null,Object? i18nCsvPath = null,Object? generateFlavors = null,Object? environments = null,Object? baseEnvIndex = null,}) {
  return _then(_self.copyWith(
pattern: null == pattern ? _self.pattern : pattern // ignore: cast_nullable_to_non_nullable
as StructuralPattern,includeMappers: null == includeMappers ? _self.includeMappers : includeMappers // ignore: cast_nullable_to_non_nullable
as bool,useRiverpodAnnotations: null == useRiverpodAnnotations ? _self.useRiverpodAnnotations : useRiverpodAnnotations // ignore: cast_nullable_to_non_nullable
as bool,useCubit: null == useCubit ? _self.useCubit : useCubit // ignore: cast_nullable_to_non_nullable
as bool,mirrorTestStructure: null == mirrorTestStructure ? _self.mirrorTestStructure : mirrorTestStructure // ignore: cast_nullable_to_non_nullable
as bool,packageSplit: null == packageSplit ? _self.packageSplit : packageSplit // ignore: cast_nullable_to_non_nullable
as bool,generateFirstFeature: null == generateFirstFeature ? _self.generateFirstFeature : generateFirstFeature // ignore: cast_nullable_to_non_nullable
as bool,firstFeatureName: null == firstFeatureName ? _self.firstFeatureName : firstFeatureName // ignore: cast_nullable_to_non_nullable
as String,firstFeatureFields: null == firstFeatureFields ? _self.firstFeatureFields : firstFeatureFields // ignore: cast_nullable_to_non_nullable
as List<FieldSpec>,firstFeatureJson: null == firstFeatureJson ? _self.firstFeatureJson : firstFeatureJson // ignore: cast_nullable_to_non_nullable
as String,firstFeatureFieldWarnings: null == firstFeatureFieldWarnings ? _self.firstFeatureFieldWarnings : firstFeatureFieldWarnings // ignore: cast_nullable_to_non_nullable
as List<String>,firstFeatureApiPath: null == firstFeatureApiPath ? _self.firstFeatureApiPath : firstFeatureApiPath // ignore: cast_nullable_to_non_nullable
as String,storageStrategy: null == storageStrategy ? _self.storageStrategy : storageStrategy // ignore: cast_nullable_to_non_nullable
as StorageStrategy,useNavigationShell: null == useNavigationShell ? _self.useNavigationShell : useNavigationShell // ignore: cast_nullable_to_non_nullable
as bool,shellIcon: null == shellIcon ? _self.shellIcon : shellIcon // ignore: cast_nullable_to_non_nullable
as String,shellLabel: null == shellLabel ? _self.shellLabel : shellLabel // ignore: cast_nullable_to_non_nullable
as String,generateAuth: null == generateAuth ? _self.generateAuth : generateAuth // ignore: cast_nullable_to_non_nullable
as bool,generateRealtime: null == generateRealtime ? _self.generateRealtime : generateRealtime // ignore: cast_nullable_to_non_nullable
as bool,generateStorage: null == generateStorage ? _self.generateStorage : generateStorage // ignore: cast_nullable_to_non_nullable
as bool,firebaseConfigPath: null == firebaseConfigPath ? _self.firebaseConfigPath : firebaseConfigPath // ignore: cast_nullable_to_non_nullable
as String,generateOAuth: null == generateOAuth ? _self.generateOAuth : generateOAuth // ignore: cast_nullable_to_non_nullable
as bool,generateI18n: null == generateI18n ? _self.generateI18n : generateI18n // ignore: cast_nullable_to_non_nullable
as bool,i18nLocales: null == i18nLocales ? _self.i18nLocales : i18nLocales // ignore: cast_nullable_to_non_nullable
as Set<String>,i18nCsvPath: null == i18nCsvPath ? _self.i18nCsvPath : i18nCsvPath // ignore: cast_nullable_to_non_nullable
as String,generateFlavors: null == generateFlavors ? _self.generateFlavors : generateFlavors // ignore: cast_nullable_to_non_nullable
as bool,environments: null == environments ? _self.environments : environments // ignore: cast_nullable_to_non_nullable
as List<EnvConfig>,baseEnvIndex: null == baseEnvIndex ? _self.baseEnvIndex : baseEnvIndex // ignore: cast_nullable_to_non_nullable
as int,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( StructuralPattern pattern,  bool includeMappers,  bool useRiverpodAnnotations,  bool useCubit,  bool mirrorTestStructure,  bool packageSplit,  bool generateFirstFeature,  String firstFeatureName,  List<FieldSpec> firstFeatureFields,  String firstFeatureJson,  List<String> firstFeatureFieldWarnings,  String firstFeatureApiPath,  StorageStrategy storageStrategy,  bool useNavigationShell,  String shellIcon,  String shellLabel,  bool generateAuth,  bool generateRealtime,  bool generateStorage,  String firebaseConfigPath,  bool generateOAuth,  bool generateI18n,  Set<String> i18nLocales,  String i18nCsvPath,  bool generateFlavors,  List<EnvConfig> environments,  int baseEnvIndex)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ArchitectureState() when $default != null:
return $default(_that.pattern,_that.includeMappers,_that.useRiverpodAnnotations,_that.useCubit,_that.mirrorTestStructure,_that.packageSplit,_that.generateFirstFeature,_that.firstFeatureName,_that.firstFeatureFields,_that.firstFeatureJson,_that.firstFeatureFieldWarnings,_that.firstFeatureApiPath,_that.storageStrategy,_that.useNavigationShell,_that.shellIcon,_that.shellLabel,_that.generateAuth,_that.generateRealtime,_that.generateStorage,_that.firebaseConfigPath,_that.generateOAuth,_that.generateI18n,_that.i18nLocales,_that.i18nCsvPath,_that.generateFlavors,_that.environments,_that.baseEnvIndex);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( StructuralPattern pattern,  bool includeMappers,  bool useRiverpodAnnotations,  bool useCubit,  bool mirrorTestStructure,  bool packageSplit,  bool generateFirstFeature,  String firstFeatureName,  List<FieldSpec> firstFeatureFields,  String firstFeatureJson,  List<String> firstFeatureFieldWarnings,  String firstFeatureApiPath,  StorageStrategy storageStrategy,  bool useNavigationShell,  String shellIcon,  String shellLabel,  bool generateAuth,  bool generateRealtime,  bool generateStorage,  String firebaseConfigPath,  bool generateOAuth,  bool generateI18n,  Set<String> i18nLocales,  String i18nCsvPath,  bool generateFlavors,  List<EnvConfig> environments,  int baseEnvIndex)  $default,) {final _that = this;
switch (_that) {
case _ArchitectureState():
return $default(_that.pattern,_that.includeMappers,_that.useRiverpodAnnotations,_that.useCubit,_that.mirrorTestStructure,_that.packageSplit,_that.generateFirstFeature,_that.firstFeatureName,_that.firstFeatureFields,_that.firstFeatureJson,_that.firstFeatureFieldWarnings,_that.firstFeatureApiPath,_that.storageStrategy,_that.useNavigationShell,_that.shellIcon,_that.shellLabel,_that.generateAuth,_that.generateRealtime,_that.generateStorage,_that.firebaseConfigPath,_that.generateOAuth,_that.generateI18n,_that.i18nLocales,_that.i18nCsvPath,_that.generateFlavors,_that.environments,_that.baseEnvIndex);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( StructuralPattern pattern,  bool includeMappers,  bool useRiverpodAnnotations,  bool useCubit,  bool mirrorTestStructure,  bool packageSplit,  bool generateFirstFeature,  String firstFeatureName,  List<FieldSpec> firstFeatureFields,  String firstFeatureJson,  List<String> firstFeatureFieldWarnings,  String firstFeatureApiPath,  StorageStrategy storageStrategy,  bool useNavigationShell,  String shellIcon,  String shellLabel,  bool generateAuth,  bool generateRealtime,  bool generateStorage,  String firebaseConfigPath,  bool generateOAuth,  bool generateI18n,  Set<String> i18nLocales,  String i18nCsvPath,  bool generateFlavors,  List<EnvConfig> environments,  int baseEnvIndex)?  $default,) {final _that = this;
switch (_that) {
case _ArchitectureState() when $default != null:
return $default(_that.pattern,_that.includeMappers,_that.useRiverpodAnnotations,_that.useCubit,_that.mirrorTestStructure,_that.packageSplit,_that.generateFirstFeature,_that.firstFeatureName,_that.firstFeatureFields,_that.firstFeatureJson,_that.firstFeatureFieldWarnings,_that.firstFeatureApiPath,_that.storageStrategy,_that.useNavigationShell,_that.shellIcon,_that.shellLabel,_that.generateAuth,_that.generateRealtime,_that.generateStorage,_that.firebaseConfigPath,_that.generateOAuth,_that.generateI18n,_that.i18nLocales,_that.i18nCsvPath,_that.generateFlavors,_that.environments,_that.baseEnvIndex);case _:
  return null;

}
}

}

/// @nodoc


class _ArchitectureState extends ArchitectureState {
  const _ArchitectureState({this.pattern = StructuralPattern.featureFirst, this.includeMappers = true, this.useRiverpodAnnotations = true, this.useCubit = false, this.mirrorTestStructure = true, this.packageSplit = false, this.generateFirstFeature = true, this.firstFeatureName = 'home', final  List<FieldSpec> firstFeatureFields = FieldSpec.idName, this.firstFeatureJson = '', final  List<String> firstFeatureFieldWarnings = const <String>[], this.firstFeatureApiPath = '', this.storageStrategy = StorageStrategy.remoteOnly, this.useNavigationShell = false, this.shellIcon = 'home', this.shellLabel = '', this.generateAuth = false, this.generateRealtime = false, this.generateStorage = false, this.firebaseConfigPath = '', this.generateOAuth = false, this.generateI18n = false, final  Set<String> i18nLocales = const <String>{'en', 'fr'}, this.i18nCsvPath = '', this.generateFlavors = false, final  List<EnvConfig> environments = const <EnvConfig>[EnvConfig(name: 'prod')], this.baseEnvIndex = 0}): _firstFeatureFields = firstFeatureFields,_firstFeatureFieldWarnings = firstFeatureFieldWarnings,_i18nLocales = i18nLocales,_environments = environments,super._();
  

@override@JsonKey() final  StructuralPattern pattern;
@override@JsonKey() final  bool includeMappers;
/// Use @riverpod annotation syntax instead of manual NotifierProvider setup
@override@JsonKey() final  bool useRiverpodAnnotations;
/// Use Cubit (simpler) instead of full Bloc with Events/States
@override@JsonKey() final  bool useCubit;
@override@JsonKey() final  bool mirrorTestStructure;
/// Opt-in: extract every feature into its own Dart workspace package
/// (`packages/<feature>/`) instead of a folder under `lib/features/` —
/// real package boundaries for a team where each dev owns a feature.
/// Requires a shared `core` package (Result/Failure/UseCase/
/// networking), gated to dio/chopper/supabase/firebase + Riverpod
/// annotations (manual or typed/go_router_builder routing, any storage
/// strategy, and auth/realtime/storage all work — Auth stays app-level
/// even when split — see ROADMAP.md §6a).
@override@JsonKey() final  bool packageSplit;
/// Opt-in: scaffold a first feature at all (mirrors `flutter create`'s
/// counter app — a real worked example so a fresh project runs and shows
/// data). Off → the app ships with zero features, just a placeholder
/// welcome screen; add your first real feature via the Workshop, which
/// owns all entity/JSON-paste editing (the wizard no longer does).
@override@JsonKey() final  bool generateFirstFeature;
/// Name of the first feature scaffolded under lib/features/ (snake_case).
/// Only meaningful when [generateFirstFeature] is on.
@override@JsonKey() final  String firstFeatureName;
/// The first feature's entity fields, inferred from a pasted Response JSON
/// (or the default id/name placeholder). Drives the entity/model/mapper/Drift
/// table/list tile of the generated feature.
 final  List<FieldSpec> _firstFeatureFields;
/// The first feature's entity fields, inferred from a pasted Response JSON
/// (or the default id/name placeholder). Drives the entity/model/mapper/Drift
/// table/list tile of the generated feature.
@override@JsonKey() List<FieldSpec> get firstFeatureFields {
  if (_firstFeatureFields is EqualUnmodifiableListView) return _firstFeatureFields;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_firstFeatureFields);
}

/// The raw JSON the user pasted to infer [firstFeatureFields] (kept so the
/// UI can re-show / re-infer it). Empty → the default id/name placeholder.
@override@JsonKey() final  String firstFeatureJson;
/// Human-readable notes from the last inference (coerced id, dropped nested
/// fields, null types…). Shown under the editor so the user can review/edit.
 final  List<String> _firstFeatureFieldWarnings;
/// Human-readable notes from the last inference (coerced id, dropped nested
/// fields, null types…). Shown under the editor so the user can review/edit.
@override@JsonKey() List<String> get firstFeatureFieldWarnings {
  if (_firstFeatureFieldWarnings is EqualUnmodifiableListView) return _firstFeatureFieldWarnings;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_firstFeatureFieldWarnings);
}

/// Overrides the first feature's REST resource path (default:
/// `/<firstFeatureName>s`). Either a relative path or an absolute URL — an
/// absolute URL overrides the project's API Base URL entirely. Empty →
/// the default pluralised path. REST clients only (dio/chopper).
@override@JsonKey() final  String firstFeatureApiPath;
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
/// Opt-in: make the first feature's list screen **live** via Supabase
/// Realtime (`.stream()`). Only effective with a Supabase backend + riverpod
/// annotations (the list becomes a StreamNotifier).
@override@JsonKey() final  bool generateRealtime;
/// Opt-in: generate a Supabase **Storage** service (+ provider + a sample
/// avatar upload widget). Only effective with a Supabase backend + riverpod.
@override@JsonKey() final  bool generateStorage;
/// Path to an uploaded Firebase config JSON (the web app config or a
/// FlutterFire export). When a Firebase backend is selected, NEAT generates
/// `firebase_options.dart` from it. Blank → compile-safe placeholders.
@override@JsonKey() final  String firebaseConfigPath;
/// Opt-in: add Google + Apple OAuth sign-in to the auth feature (via
/// `FirebaseAuth.signInWithProvider`). Only effective with a Firebase
/// backend + auth enabled.
@override@JsonKey() final  bool generateOAuth;
/// Opt-in: type-safe internationalisation with **slang** (base scaffold +
/// `TranslationProvider` + `context.t`, a sample language switcher).
@override@JsonKey() final  bool generateI18n;
/// Which languages ship in the default (non-CSV) scaffold — see
/// [i18nLocales]'s own doc for why at least one is always required.
 final  Set<String> _i18nLocales;
/// Which languages ship in the default (non-CSV) scaffold — see
/// [i18nLocales]'s own doc for why at least one is always required.
@override@JsonKey() Set<String> get i18nLocales {
  if (_i18nLocales is EqualUnmodifiableSetView) return _i18nLocales;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_i18nLocales);
}

/// Path to an uploaded **compact CSV** of translations (`key,en,fr,…`). When
/// set (and [generateI18n] is on), the CSV becomes the single source of
/// translations instead of the default JSON scaffold, and [i18nLocales] is
/// ignored — the CSV's own header columns decide the languages.
@override@JsonKey() final  String i18nCsvPath;
/// Opt-in: generate native **build flavors** (Android productFlavors, per-env
/// entry points `main_<flavor>.dart`, `.vscode/launch.json`). Off by default
/// so a plain `flutter run` works with zero config. Only effective with envied.
@override@JsonKey() final  bool generateFlavors;
/// The build environments, renamable, each with an optional API base URL
/// written into its `.env`. Starts as a **single** `prod` env (→ plain `.env`
/// + `main.dart`, no flavors); the user adds more on demand. Drives envied +
/// flavors. The production base is [baseEnvIndex] (not positional).
 final  List<EnvConfig> _environments;
/// The build environments, renamable, each with an optional API base URL
/// written into its `.env`. Starts as a **single** `prod` env (→ plain `.env`
/// + `main.dart`, no flavors); the user adds more on demand. Drives envied +
/// flavors. The production base is [baseEnvIndex] (not positional).
@override@JsonKey() List<EnvConfig> get environments {
  if (_environments is EqualUnmodifiableListView) return _environments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_environments);
}

/// Index into [environments] of the production **base** (no appId suffix; the
/// logger quietens there; release builds target it). Chosen explicitly via
/// the BASE chip — never positional, so adding an env never moves the base.
@override@JsonKey() final  int baseEnvIndex;

/// Create a copy of ArchitectureState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ArchitectureStateCopyWith<_ArchitectureState> get copyWith => __$ArchitectureStateCopyWithImpl<_ArchitectureState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ArchitectureState&&(identical(other.pattern, pattern) || other.pattern == pattern)&&(identical(other.includeMappers, includeMappers) || other.includeMappers == includeMappers)&&(identical(other.useRiverpodAnnotations, useRiverpodAnnotations) || other.useRiverpodAnnotations == useRiverpodAnnotations)&&(identical(other.useCubit, useCubit) || other.useCubit == useCubit)&&(identical(other.mirrorTestStructure, mirrorTestStructure) || other.mirrorTestStructure == mirrorTestStructure)&&(identical(other.packageSplit, packageSplit) || other.packageSplit == packageSplit)&&(identical(other.generateFirstFeature, generateFirstFeature) || other.generateFirstFeature == generateFirstFeature)&&(identical(other.firstFeatureName, firstFeatureName) || other.firstFeatureName == firstFeatureName)&&const DeepCollectionEquality().equals(other._firstFeatureFields, _firstFeatureFields)&&(identical(other.firstFeatureJson, firstFeatureJson) || other.firstFeatureJson == firstFeatureJson)&&const DeepCollectionEquality().equals(other._firstFeatureFieldWarnings, _firstFeatureFieldWarnings)&&(identical(other.firstFeatureApiPath, firstFeatureApiPath) || other.firstFeatureApiPath == firstFeatureApiPath)&&(identical(other.storageStrategy, storageStrategy) || other.storageStrategy == storageStrategy)&&(identical(other.useNavigationShell, useNavigationShell) || other.useNavigationShell == useNavigationShell)&&(identical(other.shellIcon, shellIcon) || other.shellIcon == shellIcon)&&(identical(other.shellLabel, shellLabel) || other.shellLabel == shellLabel)&&(identical(other.generateAuth, generateAuth) || other.generateAuth == generateAuth)&&(identical(other.generateRealtime, generateRealtime) || other.generateRealtime == generateRealtime)&&(identical(other.generateStorage, generateStorage) || other.generateStorage == generateStorage)&&(identical(other.firebaseConfigPath, firebaseConfigPath) || other.firebaseConfigPath == firebaseConfigPath)&&(identical(other.generateOAuth, generateOAuth) || other.generateOAuth == generateOAuth)&&(identical(other.generateI18n, generateI18n) || other.generateI18n == generateI18n)&&const DeepCollectionEquality().equals(other._i18nLocales, _i18nLocales)&&(identical(other.i18nCsvPath, i18nCsvPath) || other.i18nCsvPath == i18nCsvPath)&&(identical(other.generateFlavors, generateFlavors) || other.generateFlavors == generateFlavors)&&const DeepCollectionEquality().equals(other._environments, _environments)&&(identical(other.baseEnvIndex, baseEnvIndex) || other.baseEnvIndex == baseEnvIndex));
}


@override
int get hashCode => Object.hashAll([runtimeType,pattern,includeMappers,useRiverpodAnnotations,useCubit,mirrorTestStructure,packageSplit,generateFirstFeature,firstFeatureName,const DeepCollectionEquality().hash(_firstFeatureFields),firstFeatureJson,const DeepCollectionEquality().hash(_firstFeatureFieldWarnings),firstFeatureApiPath,storageStrategy,useNavigationShell,shellIcon,shellLabel,generateAuth,generateRealtime,generateStorage,firebaseConfigPath,generateOAuth,generateI18n,const DeepCollectionEquality().hash(_i18nLocales),i18nCsvPath,generateFlavors,const DeepCollectionEquality().hash(_environments),baseEnvIndex]);

@override
String toString() {
  return 'ArchitectureState(pattern: $pattern, includeMappers: $includeMappers, useRiverpodAnnotations: $useRiverpodAnnotations, useCubit: $useCubit, mirrorTestStructure: $mirrorTestStructure, packageSplit: $packageSplit, generateFirstFeature: $generateFirstFeature, firstFeatureName: $firstFeatureName, firstFeatureFields: $firstFeatureFields, firstFeatureJson: $firstFeatureJson, firstFeatureFieldWarnings: $firstFeatureFieldWarnings, firstFeatureApiPath: $firstFeatureApiPath, storageStrategy: $storageStrategy, useNavigationShell: $useNavigationShell, shellIcon: $shellIcon, shellLabel: $shellLabel, generateAuth: $generateAuth, generateRealtime: $generateRealtime, generateStorage: $generateStorage, firebaseConfigPath: $firebaseConfigPath, generateOAuth: $generateOAuth, generateI18n: $generateI18n, i18nLocales: $i18nLocales, i18nCsvPath: $i18nCsvPath, generateFlavors: $generateFlavors, environments: $environments, baseEnvIndex: $baseEnvIndex)';
}


}

/// @nodoc
abstract mixin class _$ArchitectureStateCopyWith<$Res> implements $ArchitectureStateCopyWith<$Res> {
  factory _$ArchitectureStateCopyWith(_ArchitectureState value, $Res Function(_ArchitectureState) _then) = __$ArchitectureStateCopyWithImpl;
@override @useResult
$Res call({
 StructuralPattern pattern, bool includeMappers, bool useRiverpodAnnotations, bool useCubit, bool mirrorTestStructure, bool packageSplit, bool generateFirstFeature, String firstFeatureName, List<FieldSpec> firstFeatureFields, String firstFeatureJson, List<String> firstFeatureFieldWarnings, String firstFeatureApiPath, StorageStrategy storageStrategy, bool useNavigationShell, String shellIcon, String shellLabel, bool generateAuth, bool generateRealtime, bool generateStorage, String firebaseConfigPath, bool generateOAuth, bool generateI18n, Set<String> i18nLocales, String i18nCsvPath, bool generateFlavors, List<EnvConfig> environments, int baseEnvIndex
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
@override @pragma('vm:prefer-inline') $Res call({Object? pattern = null,Object? includeMappers = null,Object? useRiverpodAnnotations = null,Object? useCubit = null,Object? mirrorTestStructure = null,Object? packageSplit = null,Object? generateFirstFeature = null,Object? firstFeatureName = null,Object? firstFeatureFields = null,Object? firstFeatureJson = null,Object? firstFeatureFieldWarnings = null,Object? firstFeatureApiPath = null,Object? storageStrategy = null,Object? useNavigationShell = null,Object? shellIcon = null,Object? shellLabel = null,Object? generateAuth = null,Object? generateRealtime = null,Object? generateStorage = null,Object? firebaseConfigPath = null,Object? generateOAuth = null,Object? generateI18n = null,Object? i18nLocales = null,Object? i18nCsvPath = null,Object? generateFlavors = null,Object? environments = null,Object? baseEnvIndex = null,}) {
  return _then(_ArchitectureState(
pattern: null == pattern ? _self.pattern : pattern // ignore: cast_nullable_to_non_nullable
as StructuralPattern,includeMappers: null == includeMappers ? _self.includeMappers : includeMappers // ignore: cast_nullable_to_non_nullable
as bool,useRiverpodAnnotations: null == useRiverpodAnnotations ? _self.useRiverpodAnnotations : useRiverpodAnnotations // ignore: cast_nullable_to_non_nullable
as bool,useCubit: null == useCubit ? _self.useCubit : useCubit // ignore: cast_nullable_to_non_nullable
as bool,mirrorTestStructure: null == mirrorTestStructure ? _self.mirrorTestStructure : mirrorTestStructure // ignore: cast_nullable_to_non_nullable
as bool,packageSplit: null == packageSplit ? _self.packageSplit : packageSplit // ignore: cast_nullable_to_non_nullable
as bool,generateFirstFeature: null == generateFirstFeature ? _self.generateFirstFeature : generateFirstFeature // ignore: cast_nullable_to_non_nullable
as bool,firstFeatureName: null == firstFeatureName ? _self.firstFeatureName : firstFeatureName // ignore: cast_nullable_to_non_nullable
as String,firstFeatureFields: null == firstFeatureFields ? _self._firstFeatureFields : firstFeatureFields // ignore: cast_nullable_to_non_nullable
as List<FieldSpec>,firstFeatureJson: null == firstFeatureJson ? _self.firstFeatureJson : firstFeatureJson // ignore: cast_nullable_to_non_nullable
as String,firstFeatureFieldWarnings: null == firstFeatureFieldWarnings ? _self._firstFeatureFieldWarnings : firstFeatureFieldWarnings // ignore: cast_nullable_to_non_nullable
as List<String>,firstFeatureApiPath: null == firstFeatureApiPath ? _self.firstFeatureApiPath : firstFeatureApiPath // ignore: cast_nullable_to_non_nullable
as String,storageStrategy: null == storageStrategy ? _self.storageStrategy : storageStrategy // ignore: cast_nullable_to_non_nullable
as StorageStrategy,useNavigationShell: null == useNavigationShell ? _self.useNavigationShell : useNavigationShell // ignore: cast_nullable_to_non_nullable
as bool,shellIcon: null == shellIcon ? _self.shellIcon : shellIcon // ignore: cast_nullable_to_non_nullable
as String,shellLabel: null == shellLabel ? _self.shellLabel : shellLabel // ignore: cast_nullable_to_non_nullable
as String,generateAuth: null == generateAuth ? _self.generateAuth : generateAuth // ignore: cast_nullable_to_non_nullable
as bool,generateRealtime: null == generateRealtime ? _self.generateRealtime : generateRealtime // ignore: cast_nullable_to_non_nullable
as bool,generateStorage: null == generateStorage ? _self.generateStorage : generateStorage // ignore: cast_nullable_to_non_nullable
as bool,firebaseConfigPath: null == firebaseConfigPath ? _self.firebaseConfigPath : firebaseConfigPath // ignore: cast_nullable_to_non_nullable
as String,generateOAuth: null == generateOAuth ? _self.generateOAuth : generateOAuth // ignore: cast_nullable_to_non_nullable
as bool,generateI18n: null == generateI18n ? _self.generateI18n : generateI18n // ignore: cast_nullable_to_non_nullable
as bool,i18nLocales: null == i18nLocales ? _self._i18nLocales : i18nLocales // ignore: cast_nullable_to_non_nullable
as Set<String>,i18nCsvPath: null == i18nCsvPath ? _self.i18nCsvPath : i18nCsvPath // ignore: cast_nullable_to_non_nullable
as String,generateFlavors: null == generateFlavors ? _self.generateFlavors : generateFlavors // ignore: cast_nullable_to_non_nullable
as bool,environments: null == environments ? _self._environments : environments // ignore: cast_nullable_to_non_nullable
as List<EnvConfig>,baseEnvIndex: null == baseEnvIndex ? _self.baseEnvIndex : baseEnvIndex // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
