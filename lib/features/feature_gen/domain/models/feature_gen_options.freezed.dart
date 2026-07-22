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
/// Opt-in, only when routing == child: instead of a separate
/// feature/package, the new feature's files nest inside the parent's own
/// package/folder (`data`/`domain`/`presentation`, each gaining a
/// `<name>/` subfolder), like a settings sub-page — no new pubspec,
/// workspace member, or path: dependency. Mirrors maxit-front-flutter's
/// `page/<sub-feature>/` pattern.
 bool get mergeIntoParent; String get shellIcon;// Material icon name, only when shell
 String get shellLabel;// NavigationBar label, only when shell
/// Opt-in, only meaningful when this is the project's first real feature
/// (Workshop only shows it then): replaces the launch-time "welcome"
/// placeholder as the app's home route instead of leaving it in place
/// alongside this feature — every `AppRoutePath.welcome` reference is
/// repointed at this feature, and the placeholder's own route/page files
/// are deleted. See GenerateFeatureUsecase's own routing-wiring step.
 bool get setAsHomePage; bool get includeRemoteDataSource; bool get includeLocalDataSource; bool get includeUseCase; bool get includeMapper;/// Entity fields (inferred from a pasted Response JSON, or the id/name
/// default). Drives the entity/model/mapper/Drift table of the new feature.
 List<FieldSpec> get fields;/// The raw JSON pasted to infer [fields] (kept for the editor round-trip).
 String get json;/// Notes from the last inference (shown under the editor).
 List<String> get fieldWarnings;/// Set when the last inferred JSON was a paginated list wrapper (e.g.
/// dummyjson's `{ "recipes": [...], "total": ... }`) — the JSON key the
/// entity's own list lives under. Empty means no wrapper: `getAll()`
/// decodes the response as a bare array, same as before this existed.
/// See JsonEntityInferencer's own envelope-detection doc.
 String get listEnvelopeKey;/// The wrapper's own sibling scalar fields when [listEnvelopeKey] is set
/// (e.g. `total`/`skip`/`limit`) — generates a typed `<Feature>ListModel`
/// alongside the entity model, instead of discarding this pagination
/// metadata. Always empty when [listEnvelopeKey] is empty.
 List<FieldSpec> get envelopeFields;/// Overrides the REST resource path (default: `/<name>s`). Either a
/// relative path or an absolute URL — an absolute URL overrides the
/// project's API Base URL entirely. Empty → the default pluralised path.
/// REST clients only (dio/chopper).
 String get apiPath;/// "Custom Endpoints" mode (see ROADMAP.md §7 Phase 2): the feature is N
/// arbitrary REST calls instead of one entity + fixed CRUD. Mutually
/// exclusive with [fields]/[json]/[apiPath]/the data-source toggles above
/// — the Workshop UI shows one section or the other, never both.
/// Chopper-only, remote-only (no local storage/offline-first/realtime).
 bool get useCustomEndpoints;/// The endpoints when [useCustomEndpoints] is on.
 List<EndpointSpec> get endpoints;/// Opt-in (Entity + CRUD only, chopper — Architecture Layers step):
/// customize each of the 5 fixed CRUD operations' own HTTP method + path,
/// instead of deriving all 5 from [apiPath]'s single base path. Off by
/// default — most REST APIs follow the plain convention [apiPath] alone
/// already covers.
 bool get customizeEndpoints;/// The per-operation overrides when [customizeEndpoints] is on.
 CrudEndpointOverrides get endpointOverrides;
/// Create a copy of FeatureGenOptions
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FeatureGenOptionsCopyWith<FeatureGenOptions> get copyWith => _$FeatureGenOptionsCopyWithImpl<FeatureGenOptions>(this as FeatureGenOptions, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FeatureGenOptions&&(identical(other.name, name) || other.name == name)&&(identical(other.routing, routing) || other.routing == routing)&&(identical(other.parentFeature, parentFeature) || other.parentFeature == parentFeature)&&(identical(other.mergeIntoParent, mergeIntoParent) || other.mergeIntoParent == mergeIntoParent)&&(identical(other.shellIcon, shellIcon) || other.shellIcon == shellIcon)&&(identical(other.shellLabel, shellLabel) || other.shellLabel == shellLabel)&&(identical(other.setAsHomePage, setAsHomePage) || other.setAsHomePage == setAsHomePage)&&(identical(other.includeRemoteDataSource, includeRemoteDataSource) || other.includeRemoteDataSource == includeRemoteDataSource)&&(identical(other.includeLocalDataSource, includeLocalDataSource) || other.includeLocalDataSource == includeLocalDataSource)&&(identical(other.includeUseCase, includeUseCase) || other.includeUseCase == includeUseCase)&&(identical(other.includeMapper, includeMapper) || other.includeMapper == includeMapper)&&const DeepCollectionEquality().equals(other.fields, fields)&&(identical(other.json, json) || other.json == json)&&const DeepCollectionEquality().equals(other.fieldWarnings, fieldWarnings)&&(identical(other.listEnvelopeKey, listEnvelopeKey) || other.listEnvelopeKey == listEnvelopeKey)&&const DeepCollectionEquality().equals(other.envelopeFields, envelopeFields)&&(identical(other.apiPath, apiPath) || other.apiPath == apiPath)&&(identical(other.useCustomEndpoints, useCustomEndpoints) || other.useCustomEndpoints == useCustomEndpoints)&&const DeepCollectionEquality().equals(other.endpoints, endpoints)&&(identical(other.customizeEndpoints, customizeEndpoints) || other.customizeEndpoints == customizeEndpoints)&&(identical(other.endpointOverrides, endpointOverrides) || other.endpointOverrides == endpointOverrides));
}


@override
int get hashCode => Object.hashAll([runtimeType,name,routing,parentFeature,mergeIntoParent,shellIcon,shellLabel,setAsHomePage,includeRemoteDataSource,includeLocalDataSource,includeUseCase,includeMapper,const DeepCollectionEquality().hash(fields),json,const DeepCollectionEquality().hash(fieldWarnings),listEnvelopeKey,const DeepCollectionEquality().hash(envelopeFields),apiPath,useCustomEndpoints,const DeepCollectionEquality().hash(endpoints),customizeEndpoints,endpointOverrides]);

@override
String toString() {
  return 'FeatureGenOptions(name: $name, routing: $routing, parentFeature: $parentFeature, mergeIntoParent: $mergeIntoParent, shellIcon: $shellIcon, shellLabel: $shellLabel, setAsHomePage: $setAsHomePage, includeRemoteDataSource: $includeRemoteDataSource, includeLocalDataSource: $includeLocalDataSource, includeUseCase: $includeUseCase, includeMapper: $includeMapper, fields: $fields, json: $json, fieldWarnings: $fieldWarnings, listEnvelopeKey: $listEnvelopeKey, envelopeFields: $envelopeFields, apiPath: $apiPath, useCustomEndpoints: $useCustomEndpoints, endpoints: $endpoints, customizeEndpoints: $customizeEndpoints, endpointOverrides: $endpointOverrides)';
}


}

/// @nodoc
abstract mixin class $FeatureGenOptionsCopyWith<$Res>  {
  factory $FeatureGenOptionsCopyWith(FeatureGenOptions value, $Res Function(FeatureGenOptions) _then) = _$FeatureGenOptionsCopyWithImpl;
@useResult
$Res call({
 String name, FeatureRouting routing, String parentFeature, bool mergeIntoParent, String shellIcon, String shellLabel, bool setAsHomePage, bool includeRemoteDataSource, bool includeLocalDataSource, bool includeUseCase, bool includeMapper, List<FieldSpec> fields, String json, List<String> fieldWarnings, String listEnvelopeKey, List<FieldSpec> envelopeFields, String apiPath, bool useCustomEndpoints, List<EndpointSpec> endpoints, bool customizeEndpoints, CrudEndpointOverrides endpointOverrides
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
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? routing = null,Object? parentFeature = null,Object? mergeIntoParent = null,Object? shellIcon = null,Object? shellLabel = null,Object? setAsHomePage = null,Object? includeRemoteDataSource = null,Object? includeLocalDataSource = null,Object? includeUseCase = null,Object? includeMapper = null,Object? fields = null,Object? json = null,Object? fieldWarnings = null,Object? listEnvelopeKey = null,Object? envelopeFields = null,Object? apiPath = null,Object? useCustomEndpoints = null,Object? endpoints = null,Object? customizeEndpoints = null,Object? endpointOverrides = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,routing: null == routing ? _self.routing : routing // ignore: cast_nullable_to_non_nullable
as FeatureRouting,parentFeature: null == parentFeature ? _self.parentFeature : parentFeature // ignore: cast_nullable_to_non_nullable
as String,mergeIntoParent: null == mergeIntoParent ? _self.mergeIntoParent : mergeIntoParent // ignore: cast_nullable_to_non_nullable
as bool,shellIcon: null == shellIcon ? _self.shellIcon : shellIcon // ignore: cast_nullable_to_non_nullable
as String,shellLabel: null == shellLabel ? _self.shellLabel : shellLabel // ignore: cast_nullable_to_non_nullable
as String,setAsHomePage: null == setAsHomePage ? _self.setAsHomePage : setAsHomePage // ignore: cast_nullable_to_non_nullable
as bool,includeRemoteDataSource: null == includeRemoteDataSource ? _self.includeRemoteDataSource : includeRemoteDataSource // ignore: cast_nullable_to_non_nullable
as bool,includeLocalDataSource: null == includeLocalDataSource ? _self.includeLocalDataSource : includeLocalDataSource // ignore: cast_nullable_to_non_nullable
as bool,includeUseCase: null == includeUseCase ? _self.includeUseCase : includeUseCase // ignore: cast_nullable_to_non_nullable
as bool,includeMapper: null == includeMapper ? _self.includeMapper : includeMapper // ignore: cast_nullable_to_non_nullable
as bool,fields: null == fields ? _self.fields : fields // ignore: cast_nullable_to_non_nullable
as List<FieldSpec>,json: null == json ? _self.json : json // ignore: cast_nullable_to_non_nullable
as String,fieldWarnings: null == fieldWarnings ? _self.fieldWarnings : fieldWarnings // ignore: cast_nullable_to_non_nullable
as List<String>,listEnvelopeKey: null == listEnvelopeKey ? _self.listEnvelopeKey : listEnvelopeKey // ignore: cast_nullable_to_non_nullable
as String,envelopeFields: null == envelopeFields ? _self.envelopeFields : envelopeFields // ignore: cast_nullable_to_non_nullable
as List<FieldSpec>,apiPath: null == apiPath ? _self.apiPath : apiPath // ignore: cast_nullable_to_non_nullable
as String,useCustomEndpoints: null == useCustomEndpoints ? _self.useCustomEndpoints : useCustomEndpoints // ignore: cast_nullable_to_non_nullable
as bool,endpoints: null == endpoints ? _self.endpoints : endpoints // ignore: cast_nullable_to_non_nullable
as List<EndpointSpec>,customizeEndpoints: null == customizeEndpoints ? _self.customizeEndpoints : customizeEndpoints // ignore: cast_nullable_to_non_nullable
as bool,endpointOverrides: null == endpointOverrides ? _self.endpointOverrides : endpointOverrides // ignore: cast_nullable_to_non_nullable
as CrudEndpointOverrides,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  FeatureRouting routing,  String parentFeature,  bool mergeIntoParent,  String shellIcon,  String shellLabel,  bool setAsHomePage,  bool includeRemoteDataSource,  bool includeLocalDataSource,  bool includeUseCase,  bool includeMapper,  List<FieldSpec> fields,  String json,  List<String> fieldWarnings,  String listEnvelopeKey,  List<FieldSpec> envelopeFields,  String apiPath,  bool useCustomEndpoints,  List<EndpointSpec> endpoints,  bool customizeEndpoints,  CrudEndpointOverrides endpointOverrides)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FeatureGenOptions() when $default != null:
return $default(_that.name,_that.routing,_that.parentFeature,_that.mergeIntoParent,_that.shellIcon,_that.shellLabel,_that.setAsHomePage,_that.includeRemoteDataSource,_that.includeLocalDataSource,_that.includeUseCase,_that.includeMapper,_that.fields,_that.json,_that.fieldWarnings,_that.listEnvelopeKey,_that.envelopeFields,_that.apiPath,_that.useCustomEndpoints,_that.endpoints,_that.customizeEndpoints,_that.endpointOverrides);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  FeatureRouting routing,  String parentFeature,  bool mergeIntoParent,  String shellIcon,  String shellLabel,  bool setAsHomePage,  bool includeRemoteDataSource,  bool includeLocalDataSource,  bool includeUseCase,  bool includeMapper,  List<FieldSpec> fields,  String json,  List<String> fieldWarnings,  String listEnvelopeKey,  List<FieldSpec> envelopeFields,  String apiPath,  bool useCustomEndpoints,  List<EndpointSpec> endpoints,  bool customizeEndpoints,  CrudEndpointOverrides endpointOverrides)  $default,) {final _that = this;
switch (_that) {
case _FeatureGenOptions():
return $default(_that.name,_that.routing,_that.parentFeature,_that.mergeIntoParent,_that.shellIcon,_that.shellLabel,_that.setAsHomePage,_that.includeRemoteDataSource,_that.includeLocalDataSource,_that.includeUseCase,_that.includeMapper,_that.fields,_that.json,_that.fieldWarnings,_that.listEnvelopeKey,_that.envelopeFields,_that.apiPath,_that.useCustomEndpoints,_that.endpoints,_that.customizeEndpoints,_that.endpointOverrides);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  FeatureRouting routing,  String parentFeature,  bool mergeIntoParent,  String shellIcon,  String shellLabel,  bool setAsHomePage,  bool includeRemoteDataSource,  bool includeLocalDataSource,  bool includeUseCase,  bool includeMapper,  List<FieldSpec> fields,  String json,  List<String> fieldWarnings,  String listEnvelopeKey,  List<FieldSpec> envelopeFields,  String apiPath,  bool useCustomEndpoints,  List<EndpointSpec> endpoints,  bool customizeEndpoints,  CrudEndpointOverrides endpointOverrides)?  $default,) {final _that = this;
switch (_that) {
case _FeatureGenOptions() when $default != null:
return $default(_that.name,_that.routing,_that.parentFeature,_that.mergeIntoParent,_that.shellIcon,_that.shellLabel,_that.setAsHomePage,_that.includeRemoteDataSource,_that.includeLocalDataSource,_that.includeUseCase,_that.includeMapper,_that.fields,_that.json,_that.fieldWarnings,_that.listEnvelopeKey,_that.envelopeFields,_that.apiPath,_that.useCustomEndpoints,_that.endpoints,_that.customizeEndpoints,_that.endpointOverrides);case _:
  return null;

}
}

}

/// @nodoc


class _FeatureGenOptions extends FeatureGenOptions {
  const _FeatureGenOptions({this.name = '', this.routing = FeatureRouting.root, this.parentFeature = '', this.mergeIntoParent = false, this.shellIcon = 'home', this.shellLabel = '', this.setAsHomePage = true, this.includeRemoteDataSource = true, this.includeLocalDataSource = true, this.includeUseCase = true, this.includeMapper = true, final  List<FieldSpec> fields = FieldSpec.idName, this.json = '', final  List<String> fieldWarnings = const <String>[], this.listEnvelopeKey = '', final  List<FieldSpec> envelopeFields = const <FieldSpec>[], this.apiPath = '', this.useCustomEndpoints = false, final  List<EndpointSpec> endpoints = const <EndpointSpec>[], this.customizeEndpoints = false, this.endpointOverrides = const CrudEndpointOverrides()}): _fields = fields,_fieldWarnings = fieldWarnings,_envelopeFields = envelopeFields,_endpoints = endpoints,super._();
  

@override@JsonKey() final  String name;
@override@JsonKey() final  FeatureRouting routing;
@override@JsonKey() final  String parentFeature;
// only when routing == child
/// Opt-in, only when routing == child: instead of a separate
/// feature/package, the new feature's files nest inside the parent's own
/// package/folder (`data`/`domain`/`presentation`, each gaining a
/// `<name>/` subfolder), like a settings sub-page — no new pubspec,
/// workspace member, or path: dependency. Mirrors maxit-front-flutter's
/// `page/<sub-feature>/` pattern.
@override@JsonKey() final  bool mergeIntoParent;
@override@JsonKey() final  String shellIcon;
// Material icon name, only when shell
@override@JsonKey() final  String shellLabel;
// NavigationBar label, only when shell
/// Opt-in, only meaningful when this is the project's first real feature
/// (Workshop only shows it then): replaces the launch-time "welcome"
/// placeholder as the app's home route instead of leaving it in place
/// alongside this feature — every `AppRoutePath.welcome` reference is
/// repointed at this feature, and the placeholder's own route/page files
/// are deleted. See GenerateFeatureUsecase's own routing-wiring step.
@override@JsonKey() final  bool setAsHomePage;
@override@JsonKey() final  bool includeRemoteDataSource;
@override@JsonKey() final  bool includeLocalDataSource;
@override@JsonKey() final  bool includeUseCase;
@override@JsonKey() final  bool includeMapper;
/// Entity fields (inferred from a pasted Response JSON, or the id/name
/// default). Drives the entity/model/mapper/Drift table of the new feature.
 final  List<FieldSpec> _fields;
/// Entity fields (inferred from a pasted Response JSON, or the id/name
/// default). Drives the entity/model/mapper/Drift table of the new feature.
@override@JsonKey() List<FieldSpec> get fields {
  if (_fields is EqualUnmodifiableListView) return _fields;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_fields);
}

/// The raw JSON pasted to infer [fields] (kept for the editor round-trip).
@override@JsonKey() final  String json;
/// Notes from the last inference (shown under the editor).
 final  List<String> _fieldWarnings;
/// Notes from the last inference (shown under the editor).
@override@JsonKey() List<String> get fieldWarnings {
  if (_fieldWarnings is EqualUnmodifiableListView) return _fieldWarnings;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_fieldWarnings);
}

/// Set when the last inferred JSON was a paginated list wrapper (e.g.
/// dummyjson's `{ "recipes": [...], "total": ... }`) — the JSON key the
/// entity's own list lives under. Empty means no wrapper: `getAll()`
/// decodes the response as a bare array, same as before this existed.
/// See JsonEntityInferencer's own envelope-detection doc.
@override@JsonKey() final  String listEnvelopeKey;
/// The wrapper's own sibling scalar fields when [listEnvelopeKey] is set
/// (e.g. `total`/`skip`/`limit`) — generates a typed `<Feature>ListModel`
/// alongside the entity model, instead of discarding this pagination
/// metadata. Always empty when [listEnvelopeKey] is empty.
 final  List<FieldSpec> _envelopeFields;
/// The wrapper's own sibling scalar fields when [listEnvelopeKey] is set
/// (e.g. `total`/`skip`/`limit`) — generates a typed `<Feature>ListModel`
/// alongside the entity model, instead of discarding this pagination
/// metadata. Always empty when [listEnvelopeKey] is empty.
@override@JsonKey() List<FieldSpec> get envelopeFields {
  if (_envelopeFields is EqualUnmodifiableListView) return _envelopeFields;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_envelopeFields);
}

/// Overrides the REST resource path (default: `/<name>s`). Either a
/// relative path or an absolute URL — an absolute URL overrides the
/// project's API Base URL entirely. Empty → the default pluralised path.
/// REST clients only (dio/chopper).
@override@JsonKey() final  String apiPath;
/// "Custom Endpoints" mode (see ROADMAP.md §7 Phase 2): the feature is N
/// arbitrary REST calls instead of one entity + fixed CRUD. Mutually
/// exclusive with [fields]/[json]/[apiPath]/the data-source toggles above
/// — the Workshop UI shows one section or the other, never both.
/// Chopper-only, remote-only (no local storage/offline-first/realtime).
@override@JsonKey() final  bool useCustomEndpoints;
/// The endpoints when [useCustomEndpoints] is on.
 final  List<EndpointSpec> _endpoints;
/// The endpoints when [useCustomEndpoints] is on.
@override@JsonKey() List<EndpointSpec> get endpoints {
  if (_endpoints is EqualUnmodifiableListView) return _endpoints;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_endpoints);
}

/// Opt-in (Entity + CRUD only, chopper — Architecture Layers step):
/// customize each of the 5 fixed CRUD operations' own HTTP method + path,
/// instead of deriving all 5 from [apiPath]'s single base path. Off by
/// default — most REST APIs follow the plain convention [apiPath] alone
/// already covers.
@override@JsonKey() final  bool customizeEndpoints;
/// The per-operation overrides when [customizeEndpoints] is on.
@override@JsonKey() final  CrudEndpointOverrides endpointOverrides;

/// Create a copy of FeatureGenOptions
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FeatureGenOptionsCopyWith<_FeatureGenOptions> get copyWith => __$FeatureGenOptionsCopyWithImpl<_FeatureGenOptions>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FeatureGenOptions&&(identical(other.name, name) || other.name == name)&&(identical(other.routing, routing) || other.routing == routing)&&(identical(other.parentFeature, parentFeature) || other.parentFeature == parentFeature)&&(identical(other.mergeIntoParent, mergeIntoParent) || other.mergeIntoParent == mergeIntoParent)&&(identical(other.shellIcon, shellIcon) || other.shellIcon == shellIcon)&&(identical(other.shellLabel, shellLabel) || other.shellLabel == shellLabel)&&(identical(other.setAsHomePage, setAsHomePage) || other.setAsHomePage == setAsHomePage)&&(identical(other.includeRemoteDataSource, includeRemoteDataSource) || other.includeRemoteDataSource == includeRemoteDataSource)&&(identical(other.includeLocalDataSource, includeLocalDataSource) || other.includeLocalDataSource == includeLocalDataSource)&&(identical(other.includeUseCase, includeUseCase) || other.includeUseCase == includeUseCase)&&(identical(other.includeMapper, includeMapper) || other.includeMapper == includeMapper)&&const DeepCollectionEquality().equals(other._fields, _fields)&&(identical(other.json, json) || other.json == json)&&const DeepCollectionEquality().equals(other._fieldWarnings, _fieldWarnings)&&(identical(other.listEnvelopeKey, listEnvelopeKey) || other.listEnvelopeKey == listEnvelopeKey)&&const DeepCollectionEquality().equals(other._envelopeFields, _envelopeFields)&&(identical(other.apiPath, apiPath) || other.apiPath == apiPath)&&(identical(other.useCustomEndpoints, useCustomEndpoints) || other.useCustomEndpoints == useCustomEndpoints)&&const DeepCollectionEquality().equals(other._endpoints, _endpoints)&&(identical(other.customizeEndpoints, customizeEndpoints) || other.customizeEndpoints == customizeEndpoints)&&(identical(other.endpointOverrides, endpointOverrides) || other.endpointOverrides == endpointOverrides));
}


@override
int get hashCode => Object.hashAll([runtimeType,name,routing,parentFeature,mergeIntoParent,shellIcon,shellLabel,setAsHomePage,includeRemoteDataSource,includeLocalDataSource,includeUseCase,includeMapper,const DeepCollectionEquality().hash(_fields),json,const DeepCollectionEquality().hash(_fieldWarnings),listEnvelopeKey,const DeepCollectionEquality().hash(_envelopeFields),apiPath,useCustomEndpoints,const DeepCollectionEquality().hash(_endpoints),customizeEndpoints,endpointOverrides]);

@override
String toString() {
  return 'FeatureGenOptions(name: $name, routing: $routing, parentFeature: $parentFeature, mergeIntoParent: $mergeIntoParent, shellIcon: $shellIcon, shellLabel: $shellLabel, setAsHomePage: $setAsHomePage, includeRemoteDataSource: $includeRemoteDataSource, includeLocalDataSource: $includeLocalDataSource, includeUseCase: $includeUseCase, includeMapper: $includeMapper, fields: $fields, json: $json, fieldWarnings: $fieldWarnings, listEnvelopeKey: $listEnvelopeKey, envelopeFields: $envelopeFields, apiPath: $apiPath, useCustomEndpoints: $useCustomEndpoints, endpoints: $endpoints, customizeEndpoints: $customizeEndpoints, endpointOverrides: $endpointOverrides)';
}


}

/// @nodoc
abstract mixin class _$FeatureGenOptionsCopyWith<$Res> implements $FeatureGenOptionsCopyWith<$Res> {
  factory _$FeatureGenOptionsCopyWith(_FeatureGenOptions value, $Res Function(_FeatureGenOptions) _then) = __$FeatureGenOptionsCopyWithImpl;
@override @useResult
$Res call({
 String name, FeatureRouting routing, String parentFeature, bool mergeIntoParent, String shellIcon, String shellLabel, bool setAsHomePage, bool includeRemoteDataSource, bool includeLocalDataSource, bool includeUseCase, bool includeMapper, List<FieldSpec> fields, String json, List<String> fieldWarnings, String listEnvelopeKey, List<FieldSpec> envelopeFields, String apiPath, bool useCustomEndpoints, List<EndpointSpec> endpoints, bool customizeEndpoints, CrudEndpointOverrides endpointOverrides
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
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? routing = null,Object? parentFeature = null,Object? mergeIntoParent = null,Object? shellIcon = null,Object? shellLabel = null,Object? setAsHomePage = null,Object? includeRemoteDataSource = null,Object? includeLocalDataSource = null,Object? includeUseCase = null,Object? includeMapper = null,Object? fields = null,Object? json = null,Object? fieldWarnings = null,Object? listEnvelopeKey = null,Object? envelopeFields = null,Object? apiPath = null,Object? useCustomEndpoints = null,Object? endpoints = null,Object? customizeEndpoints = null,Object? endpointOverrides = null,}) {
  return _then(_FeatureGenOptions(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,routing: null == routing ? _self.routing : routing // ignore: cast_nullable_to_non_nullable
as FeatureRouting,parentFeature: null == parentFeature ? _self.parentFeature : parentFeature // ignore: cast_nullable_to_non_nullable
as String,mergeIntoParent: null == mergeIntoParent ? _self.mergeIntoParent : mergeIntoParent // ignore: cast_nullable_to_non_nullable
as bool,shellIcon: null == shellIcon ? _self.shellIcon : shellIcon // ignore: cast_nullable_to_non_nullable
as String,shellLabel: null == shellLabel ? _self.shellLabel : shellLabel // ignore: cast_nullable_to_non_nullable
as String,setAsHomePage: null == setAsHomePage ? _self.setAsHomePage : setAsHomePage // ignore: cast_nullable_to_non_nullable
as bool,includeRemoteDataSource: null == includeRemoteDataSource ? _self.includeRemoteDataSource : includeRemoteDataSource // ignore: cast_nullable_to_non_nullable
as bool,includeLocalDataSource: null == includeLocalDataSource ? _self.includeLocalDataSource : includeLocalDataSource // ignore: cast_nullable_to_non_nullable
as bool,includeUseCase: null == includeUseCase ? _self.includeUseCase : includeUseCase // ignore: cast_nullable_to_non_nullable
as bool,includeMapper: null == includeMapper ? _self.includeMapper : includeMapper // ignore: cast_nullable_to_non_nullable
as bool,fields: null == fields ? _self._fields : fields // ignore: cast_nullable_to_non_nullable
as List<FieldSpec>,json: null == json ? _self.json : json // ignore: cast_nullable_to_non_nullable
as String,fieldWarnings: null == fieldWarnings ? _self._fieldWarnings : fieldWarnings // ignore: cast_nullable_to_non_nullable
as List<String>,listEnvelopeKey: null == listEnvelopeKey ? _self.listEnvelopeKey : listEnvelopeKey // ignore: cast_nullable_to_non_nullable
as String,envelopeFields: null == envelopeFields ? _self._envelopeFields : envelopeFields // ignore: cast_nullable_to_non_nullable
as List<FieldSpec>,apiPath: null == apiPath ? _self.apiPath : apiPath // ignore: cast_nullable_to_non_nullable
as String,useCustomEndpoints: null == useCustomEndpoints ? _self.useCustomEndpoints : useCustomEndpoints // ignore: cast_nullable_to_non_nullable
as bool,endpoints: null == endpoints ? _self._endpoints : endpoints // ignore: cast_nullable_to_non_nullable
as List<EndpointSpec>,customizeEndpoints: null == customizeEndpoints ? _self.customizeEndpoints : customizeEndpoints // ignore: cast_nullable_to_non_nullable
as bool,endpointOverrides: null == endpointOverrides ? _self.endpointOverrides : endpointOverrides // ignore: cast_nullable_to_non_nullable
as CrudEndpointOverrides,
  ));
}


}

// dart format on
