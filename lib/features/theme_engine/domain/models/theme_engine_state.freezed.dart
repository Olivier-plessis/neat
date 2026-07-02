// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'theme_engine_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TextStyleConfig {

 double get fontSize; int get fontWeight;// 100–900 step 100
 double get letterSpacing; double get height;
/// Create a copy of TextStyleConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TextStyleConfigCopyWith<TextStyleConfig> get copyWith => _$TextStyleConfigCopyWithImpl<TextStyleConfig>(this as TextStyleConfig, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TextStyleConfig&&(identical(other.fontSize, fontSize) || other.fontSize == fontSize)&&(identical(other.fontWeight, fontWeight) || other.fontWeight == fontWeight)&&(identical(other.letterSpacing, letterSpacing) || other.letterSpacing == letterSpacing)&&(identical(other.height, height) || other.height == height));
}


@override
int get hashCode => Object.hash(runtimeType,fontSize,fontWeight,letterSpacing,height);

@override
String toString() {
  return 'TextStyleConfig(fontSize: $fontSize, fontWeight: $fontWeight, letterSpacing: $letterSpacing, height: $height)';
}


}

/// @nodoc
abstract mixin class $TextStyleConfigCopyWith<$Res>  {
  factory $TextStyleConfigCopyWith(TextStyleConfig value, $Res Function(TextStyleConfig) _then) = _$TextStyleConfigCopyWithImpl;
@useResult
$Res call({
 double fontSize, int fontWeight, double letterSpacing, double height
});




}
/// @nodoc
class _$TextStyleConfigCopyWithImpl<$Res>
    implements $TextStyleConfigCopyWith<$Res> {
  _$TextStyleConfigCopyWithImpl(this._self, this._then);

  final TextStyleConfig _self;
  final $Res Function(TextStyleConfig) _then;

/// Create a copy of TextStyleConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? fontSize = null,Object? fontWeight = null,Object? letterSpacing = null,Object? height = null,}) {
  return _then(_self.copyWith(
fontSize: null == fontSize ? _self.fontSize : fontSize // ignore: cast_nullable_to_non_nullable
as double,fontWeight: null == fontWeight ? _self.fontWeight : fontWeight // ignore: cast_nullable_to_non_nullable
as int,letterSpacing: null == letterSpacing ? _self.letterSpacing : letterSpacing // ignore: cast_nullable_to_non_nullable
as double,height: null == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [TextStyleConfig].
extension TextStyleConfigPatterns on TextStyleConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TextStyleConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TextStyleConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TextStyleConfig value)  $default,){
final _that = this;
switch (_that) {
case _TextStyleConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TextStyleConfig value)?  $default,){
final _that = this;
switch (_that) {
case _TextStyleConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double fontSize,  int fontWeight,  double letterSpacing,  double height)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TextStyleConfig() when $default != null:
return $default(_that.fontSize,_that.fontWeight,_that.letterSpacing,_that.height);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double fontSize,  int fontWeight,  double letterSpacing,  double height)  $default,) {final _that = this;
switch (_that) {
case _TextStyleConfig():
return $default(_that.fontSize,_that.fontWeight,_that.letterSpacing,_that.height);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double fontSize,  int fontWeight,  double letterSpacing,  double height)?  $default,) {final _that = this;
switch (_that) {
case _TextStyleConfig() when $default != null:
return $default(_that.fontSize,_that.fontWeight,_that.letterSpacing,_that.height);case _:
  return null;

}
}

}

/// @nodoc


class _TextStyleConfig implements TextStyleConfig {
  const _TextStyleConfig({required this.fontSize, required this.fontWeight, required this.letterSpacing, this.height = 1.5});
  

@override final  double fontSize;
@override final  int fontWeight;
// 100–900 step 100
@override final  double letterSpacing;
@override@JsonKey() final  double height;

/// Create a copy of TextStyleConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TextStyleConfigCopyWith<_TextStyleConfig> get copyWith => __$TextStyleConfigCopyWithImpl<_TextStyleConfig>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TextStyleConfig&&(identical(other.fontSize, fontSize) || other.fontSize == fontSize)&&(identical(other.fontWeight, fontWeight) || other.fontWeight == fontWeight)&&(identical(other.letterSpacing, letterSpacing) || other.letterSpacing == letterSpacing)&&(identical(other.height, height) || other.height == height));
}


@override
int get hashCode => Object.hash(runtimeType,fontSize,fontWeight,letterSpacing,height);

@override
String toString() {
  return 'TextStyleConfig(fontSize: $fontSize, fontWeight: $fontWeight, letterSpacing: $letterSpacing, height: $height)';
}


}

/// @nodoc
abstract mixin class _$TextStyleConfigCopyWith<$Res> implements $TextStyleConfigCopyWith<$Res> {
  factory _$TextStyleConfigCopyWith(_TextStyleConfig value, $Res Function(_TextStyleConfig) _then) = __$TextStyleConfigCopyWithImpl;
@override @useResult
$Res call({
 double fontSize, int fontWeight, double letterSpacing, double height
});




}
/// @nodoc
class __$TextStyleConfigCopyWithImpl<$Res>
    implements _$TextStyleConfigCopyWith<$Res> {
  __$TextStyleConfigCopyWithImpl(this._self, this._then);

  final _TextStyleConfig _self;
  final $Res Function(_TextStyleConfig) _then;

/// Create a copy of TextStyleConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? fontSize = null,Object? fontWeight = null,Object? letterSpacing = null,Object? height = null,}) {
  return _then(_TextStyleConfig(
fontSize: null == fontSize ? _self.fontSize : fontSize // ignore: cast_nullable_to_non_nullable
as double,fontWeight: null == fontWeight ? _self.fontWeight : fontWeight // ignore: cast_nullable_to_non_nullable
as int,letterSpacing: null == letterSpacing ? _self.letterSpacing : letterSpacing // ignore: cast_nullable_to_non_nullable
as double,height: null == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc
mixin _$ButtonConfig {

 double get hPadding; double get vPadding;/// null = fall back to [ThemeEngineState.containerRadius]
 double? get radiusOverride; double? get elevation;// ElevatedButton
 double? get strokeWidth;
/// Create a copy of ButtonConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ButtonConfigCopyWith<ButtonConfig> get copyWith => _$ButtonConfigCopyWithImpl<ButtonConfig>(this as ButtonConfig, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ButtonConfig&&(identical(other.hPadding, hPadding) || other.hPadding == hPadding)&&(identical(other.vPadding, vPadding) || other.vPadding == vPadding)&&(identical(other.radiusOverride, radiusOverride) || other.radiusOverride == radiusOverride)&&(identical(other.elevation, elevation) || other.elevation == elevation)&&(identical(other.strokeWidth, strokeWidth) || other.strokeWidth == strokeWidth));
}


@override
int get hashCode => Object.hash(runtimeType,hPadding,vPadding,radiusOverride,elevation,strokeWidth);

@override
String toString() {
  return 'ButtonConfig(hPadding: $hPadding, vPadding: $vPadding, radiusOverride: $radiusOverride, elevation: $elevation, strokeWidth: $strokeWidth)';
}


}

/// @nodoc
abstract mixin class $ButtonConfigCopyWith<$Res>  {
  factory $ButtonConfigCopyWith(ButtonConfig value, $Res Function(ButtonConfig) _then) = _$ButtonConfigCopyWithImpl;
@useResult
$Res call({
 double hPadding, double vPadding, double? radiusOverride, double? elevation, double? strokeWidth
});




}
/// @nodoc
class _$ButtonConfigCopyWithImpl<$Res>
    implements $ButtonConfigCopyWith<$Res> {
  _$ButtonConfigCopyWithImpl(this._self, this._then);

  final ButtonConfig _self;
  final $Res Function(ButtonConfig) _then;

/// Create a copy of ButtonConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? hPadding = null,Object? vPadding = null,Object? radiusOverride = freezed,Object? elevation = freezed,Object? strokeWidth = freezed,}) {
  return _then(_self.copyWith(
hPadding: null == hPadding ? _self.hPadding : hPadding // ignore: cast_nullable_to_non_nullable
as double,vPadding: null == vPadding ? _self.vPadding : vPadding // ignore: cast_nullable_to_non_nullable
as double,radiusOverride: freezed == radiusOverride ? _self.radiusOverride : radiusOverride // ignore: cast_nullable_to_non_nullable
as double?,elevation: freezed == elevation ? _self.elevation : elevation // ignore: cast_nullable_to_non_nullable
as double?,strokeWidth: freezed == strokeWidth ? _self.strokeWidth : strokeWidth // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [ButtonConfig].
extension ButtonConfigPatterns on ButtonConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ButtonConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ButtonConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ButtonConfig value)  $default,){
final _that = this;
switch (_that) {
case _ButtonConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ButtonConfig value)?  $default,){
final _that = this;
switch (_that) {
case _ButtonConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double hPadding,  double vPadding,  double? radiusOverride,  double? elevation,  double? strokeWidth)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ButtonConfig() when $default != null:
return $default(_that.hPadding,_that.vPadding,_that.radiusOverride,_that.elevation,_that.strokeWidth);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double hPadding,  double vPadding,  double? radiusOverride,  double? elevation,  double? strokeWidth)  $default,) {final _that = this;
switch (_that) {
case _ButtonConfig():
return $default(_that.hPadding,_that.vPadding,_that.radiusOverride,_that.elevation,_that.strokeWidth);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double hPadding,  double vPadding,  double? radiusOverride,  double? elevation,  double? strokeWidth)?  $default,) {final _that = this;
switch (_that) {
case _ButtonConfig() when $default != null:
return $default(_that.hPadding,_that.vPadding,_that.radiusOverride,_that.elevation,_that.strokeWidth);case _:
  return null;

}
}

}

/// @nodoc


class _ButtonConfig implements ButtonConfig {
  const _ButtonConfig({required this.hPadding, required this.vPadding, this.radiusOverride, this.elevation, this.strokeWidth});
  

@override final  double hPadding;
@override final  double vPadding;
/// null = fall back to [ThemeEngineState.containerRadius]
@override final  double? radiusOverride;
@override final  double? elevation;
// ElevatedButton
@override final  double? strokeWidth;

/// Create a copy of ButtonConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ButtonConfigCopyWith<_ButtonConfig> get copyWith => __$ButtonConfigCopyWithImpl<_ButtonConfig>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ButtonConfig&&(identical(other.hPadding, hPadding) || other.hPadding == hPadding)&&(identical(other.vPadding, vPadding) || other.vPadding == vPadding)&&(identical(other.radiusOverride, radiusOverride) || other.radiusOverride == radiusOverride)&&(identical(other.elevation, elevation) || other.elevation == elevation)&&(identical(other.strokeWidth, strokeWidth) || other.strokeWidth == strokeWidth));
}


@override
int get hashCode => Object.hash(runtimeType,hPadding,vPadding,radiusOverride,elevation,strokeWidth);

@override
String toString() {
  return 'ButtonConfig(hPadding: $hPadding, vPadding: $vPadding, radiusOverride: $radiusOverride, elevation: $elevation, strokeWidth: $strokeWidth)';
}


}

/// @nodoc
abstract mixin class _$ButtonConfigCopyWith<$Res> implements $ButtonConfigCopyWith<$Res> {
  factory _$ButtonConfigCopyWith(_ButtonConfig value, $Res Function(_ButtonConfig) _then) = __$ButtonConfigCopyWithImpl;
@override @useResult
$Res call({
 double hPadding, double vPadding, double? radiusOverride, double? elevation, double? strokeWidth
});




}
/// @nodoc
class __$ButtonConfigCopyWithImpl<$Res>
    implements _$ButtonConfigCopyWith<$Res> {
  __$ButtonConfigCopyWithImpl(this._self, this._then);

  final _ButtonConfig _self;
  final $Res Function(_ButtonConfig) _then;

/// Create a copy of ButtonConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? hPadding = null,Object? vPadding = null,Object? radiusOverride = freezed,Object? elevation = freezed,Object? strokeWidth = freezed,}) {
  return _then(_ButtonConfig(
hPadding: null == hPadding ? _self.hPadding : hPadding // ignore: cast_nullable_to_non_nullable
as double,vPadding: null == vPadding ? _self.vPadding : vPadding // ignore: cast_nullable_to_non_nullable
as double,radiusOverride: freezed == radiusOverride ? _self.radiusOverride : radiusOverride // ignore: cast_nullable_to_non_nullable
as double?,elevation: freezed == elevation ? _self.elevation : elevation // ignore: cast_nullable_to_non_nullable
as double?,strokeWidth: freezed == strokeWidth ? _self.strokeWidth : strokeWidth // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}

/// @nodoc
mixin _$ThemeEngineState {

 ThemeApproach get approach;// Colors
 Color get seedColor; String? get imagePath; Color? get primaryOverride; Color? get secondaryOverride; Color? get tertiaryOverride;// Shape / elevation (global)
 double get containerRadius; double get cardElevation;// Typography
 String get fontFamily; double get baseFontSize; Map<TextStyleKey, TextStyleConfig> get textStyles;// Buttons
 ButtonConfig get elevatedButton; ButtonConfig get filledButton; ButtonConfig get outlinedButton; ButtonConfig get textButton;// FlexColorScheme
 String? get flexColorSchemeCode; double get surfaceBlendLevel; double get onSurfaceBlendLevel;// Components
/// Design-system components to generate into lib/components/ (opt-in).
 Set<AppComponent> get components;/// When true, scaffold a Widgetbook catalog (widgetbook/main.dart).
 bool get generateWidgetbook;/// When true, extract theme + tokens + components into a workspace package
/// `<app>_ui` (the app and Widgetbook depend on it).
 bool get extractUiPackage;// Semantic palette colors (used by AppButton variants & the theme)
 Color get accentColor; Color get destructiveColor;// Preview
 Brightness get defaultBrightness;/// Absolute path to a logo (PNG) the user picked. When set, NEAT copies it
/// into the project and generates app icons + splash (flutter_launcher_icons
/// + flutter_native_splash) at generation time.
 String get logoPath;
/// Create a copy of ThemeEngineState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ThemeEngineStateCopyWith<ThemeEngineState> get copyWith => _$ThemeEngineStateCopyWithImpl<ThemeEngineState>(this as ThemeEngineState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ThemeEngineState&&(identical(other.approach, approach) || other.approach == approach)&&(identical(other.seedColor, seedColor) || other.seedColor == seedColor)&&(identical(other.imagePath, imagePath) || other.imagePath == imagePath)&&(identical(other.primaryOverride, primaryOverride) || other.primaryOverride == primaryOverride)&&(identical(other.secondaryOverride, secondaryOverride) || other.secondaryOverride == secondaryOverride)&&(identical(other.tertiaryOverride, tertiaryOverride) || other.tertiaryOverride == tertiaryOverride)&&(identical(other.containerRadius, containerRadius) || other.containerRadius == containerRadius)&&(identical(other.cardElevation, cardElevation) || other.cardElevation == cardElevation)&&(identical(other.fontFamily, fontFamily) || other.fontFamily == fontFamily)&&(identical(other.baseFontSize, baseFontSize) || other.baseFontSize == baseFontSize)&&const DeepCollectionEquality().equals(other.textStyles, textStyles)&&(identical(other.elevatedButton, elevatedButton) || other.elevatedButton == elevatedButton)&&(identical(other.filledButton, filledButton) || other.filledButton == filledButton)&&(identical(other.outlinedButton, outlinedButton) || other.outlinedButton == outlinedButton)&&(identical(other.textButton, textButton) || other.textButton == textButton)&&(identical(other.flexColorSchemeCode, flexColorSchemeCode) || other.flexColorSchemeCode == flexColorSchemeCode)&&(identical(other.surfaceBlendLevel, surfaceBlendLevel) || other.surfaceBlendLevel == surfaceBlendLevel)&&(identical(other.onSurfaceBlendLevel, onSurfaceBlendLevel) || other.onSurfaceBlendLevel == onSurfaceBlendLevel)&&const DeepCollectionEquality().equals(other.components, components)&&(identical(other.generateWidgetbook, generateWidgetbook) || other.generateWidgetbook == generateWidgetbook)&&(identical(other.extractUiPackage, extractUiPackage) || other.extractUiPackage == extractUiPackage)&&(identical(other.accentColor, accentColor) || other.accentColor == accentColor)&&(identical(other.destructiveColor, destructiveColor) || other.destructiveColor == destructiveColor)&&(identical(other.defaultBrightness, defaultBrightness) || other.defaultBrightness == defaultBrightness)&&(identical(other.logoPath, logoPath) || other.logoPath == logoPath));
}


@override
int get hashCode => Object.hashAll([runtimeType,approach,seedColor,imagePath,primaryOverride,secondaryOverride,tertiaryOverride,containerRadius,cardElevation,fontFamily,baseFontSize,const DeepCollectionEquality().hash(textStyles),elevatedButton,filledButton,outlinedButton,textButton,flexColorSchemeCode,surfaceBlendLevel,onSurfaceBlendLevel,const DeepCollectionEquality().hash(components),generateWidgetbook,extractUiPackage,accentColor,destructiveColor,defaultBrightness,logoPath]);

@override
String toString() {
  return 'ThemeEngineState(approach: $approach, seedColor: $seedColor, imagePath: $imagePath, primaryOverride: $primaryOverride, secondaryOverride: $secondaryOverride, tertiaryOverride: $tertiaryOverride, containerRadius: $containerRadius, cardElevation: $cardElevation, fontFamily: $fontFamily, baseFontSize: $baseFontSize, textStyles: $textStyles, elevatedButton: $elevatedButton, filledButton: $filledButton, outlinedButton: $outlinedButton, textButton: $textButton, flexColorSchemeCode: $flexColorSchemeCode, surfaceBlendLevel: $surfaceBlendLevel, onSurfaceBlendLevel: $onSurfaceBlendLevel, components: $components, generateWidgetbook: $generateWidgetbook, extractUiPackage: $extractUiPackage, accentColor: $accentColor, destructiveColor: $destructiveColor, defaultBrightness: $defaultBrightness, logoPath: $logoPath)';
}


}

/// @nodoc
abstract mixin class $ThemeEngineStateCopyWith<$Res>  {
  factory $ThemeEngineStateCopyWith(ThemeEngineState value, $Res Function(ThemeEngineState) _then) = _$ThemeEngineStateCopyWithImpl;
@useResult
$Res call({
 ThemeApproach approach, Color seedColor, String? imagePath, Color? primaryOverride, Color? secondaryOverride, Color? tertiaryOverride, double containerRadius, double cardElevation, String fontFamily, double baseFontSize, Map<TextStyleKey, TextStyleConfig> textStyles, ButtonConfig elevatedButton, ButtonConfig filledButton, ButtonConfig outlinedButton, ButtonConfig textButton, String? flexColorSchemeCode, double surfaceBlendLevel, double onSurfaceBlendLevel, Set<AppComponent> components, bool generateWidgetbook, bool extractUiPackage, Color accentColor, Color destructiveColor, Brightness defaultBrightness, String logoPath
});


$ButtonConfigCopyWith<$Res> get elevatedButton;$ButtonConfigCopyWith<$Res> get filledButton;$ButtonConfigCopyWith<$Res> get outlinedButton;$ButtonConfigCopyWith<$Res> get textButton;

}
/// @nodoc
class _$ThemeEngineStateCopyWithImpl<$Res>
    implements $ThemeEngineStateCopyWith<$Res> {
  _$ThemeEngineStateCopyWithImpl(this._self, this._then);

  final ThemeEngineState _self;
  final $Res Function(ThemeEngineState) _then;

/// Create a copy of ThemeEngineState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? approach = null,Object? seedColor = null,Object? imagePath = freezed,Object? primaryOverride = freezed,Object? secondaryOverride = freezed,Object? tertiaryOverride = freezed,Object? containerRadius = null,Object? cardElevation = null,Object? fontFamily = null,Object? baseFontSize = null,Object? textStyles = null,Object? elevatedButton = null,Object? filledButton = null,Object? outlinedButton = null,Object? textButton = null,Object? flexColorSchemeCode = freezed,Object? surfaceBlendLevel = null,Object? onSurfaceBlendLevel = null,Object? components = null,Object? generateWidgetbook = null,Object? extractUiPackage = null,Object? accentColor = null,Object? destructiveColor = null,Object? defaultBrightness = null,Object? logoPath = null,}) {
  return _then(_self.copyWith(
approach: null == approach ? _self.approach : approach // ignore: cast_nullable_to_non_nullable
as ThemeApproach,seedColor: null == seedColor ? _self.seedColor : seedColor // ignore: cast_nullable_to_non_nullable
as Color,imagePath: freezed == imagePath ? _self.imagePath : imagePath // ignore: cast_nullable_to_non_nullable
as String?,primaryOverride: freezed == primaryOverride ? _self.primaryOverride : primaryOverride // ignore: cast_nullable_to_non_nullable
as Color?,secondaryOverride: freezed == secondaryOverride ? _self.secondaryOverride : secondaryOverride // ignore: cast_nullable_to_non_nullable
as Color?,tertiaryOverride: freezed == tertiaryOverride ? _self.tertiaryOverride : tertiaryOverride // ignore: cast_nullable_to_non_nullable
as Color?,containerRadius: null == containerRadius ? _self.containerRadius : containerRadius // ignore: cast_nullable_to_non_nullable
as double,cardElevation: null == cardElevation ? _self.cardElevation : cardElevation // ignore: cast_nullable_to_non_nullable
as double,fontFamily: null == fontFamily ? _self.fontFamily : fontFamily // ignore: cast_nullable_to_non_nullable
as String,baseFontSize: null == baseFontSize ? _self.baseFontSize : baseFontSize // ignore: cast_nullable_to_non_nullable
as double,textStyles: null == textStyles ? _self.textStyles : textStyles // ignore: cast_nullable_to_non_nullable
as Map<TextStyleKey, TextStyleConfig>,elevatedButton: null == elevatedButton ? _self.elevatedButton : elevatedButton // ignore: cast_nullable_to_non_nullable
as ButtonConfig,filledButton: null == filledButton ? _self.filledButton : filledButton // ignore: cast_nullable_to_non_nullable
as ButtonConfig,outlinedButton: null == outlinedButton ? _self.outlinedButton : outlinedButton // ignore: cast_nullable_to_non_nullable
as ButtonConfig,textButton: null == textButton ? _self.textButton : textButton // ignore: cast_nullable_to_non_nullable
as ButtonConfig,flexColorSchemeCode: freezed == flexColorSchemeCode ? _self.flexColorSchemeCode : flexColorSchemeCode // ignore: cast_nullable_to_non_nullable
as String?,surfaceBlendLevel: null == surfaceBlendLevel ? _self.surfaceBlendLevel : surfaceBlendLevel // ignore: cast_nullable_to_non_nullable
as double,onSurfaceBlendLevel: null == onSurfaceBlendLevel ? _self.onSurfaceBlendLevel : onSurfaceBlendLevel // ignore: cast_nullable_to_non_nullable
as double,components: null == components ? _self.components : components // ignore: cast_nullable_to_non_nullable
as Set<AppComponent>,generateWidgetbook: null == generateWidgetbook ? _self.generateWidgetbook : generateWidgetbook // ignore: cast_nullable_to_non_nullable
as bool,extractUiPackage: null == extractUiPackage ? _self.extractUiPackage : extractUiPackage // ignore: cast_nullable_to_non_nullable
as bool,accentColor: null == accentColor ? _self.accentColor : accentColor // ignore: cast_nullable_to_non_nullable
as Color,destructiveColor: null == destructiveColor ? _self.destructiveColor : destructiveColor // ignore: cast_nullable_to_non_nullable
as Color,defaultBrightness: null == defaultBrightness ? _self.defaultBrightness : defaultBrightness // ignore: cast_nullable_to_non_nullable
as Brightness,logoPath: null == logoPath ? _self.logoPath : logoPath // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of ThemeEngineState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ButtonConfigCopyWith<$Res> get elevatedButton {
  
  return $ButtonConfigCopyWith<$Res>(_self.elevatedButton, (value) {
    return _then(_self.copyWith(elevatedButton: value));
  });
}/// Create a copy of ThemeEngineState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ButtonConfigCopyWith<$Res> get filledButton {
  
  return $ButtonConfigCopyWith<$Res>(_self.filledButton, (value) {
    return _then(_self.copyWith(filledButton: value));
  });
}/// Create a copy of ThemeEngineState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ButtonConfigCopyWith<$Res> get outlinedButton {
  
  return $ButtonConfigCopyWith<$Res>(_self.outlinedButton, (value) {
    return _then(_self.copyWith(outlinedButton: value));
  });
}/// Create a copy of ThemeEngineState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ButtonConfigCopyWith<$Res> get textButton {
  
  return $ButtonConfigCopyWith<$Res>(_self.textButton, (value) {
    return _then(_self.copyWith(textButton: value));
  });
}
}


/// Adds pattern-matching-related methods to [ThemeEngineState].
extension ThemeEngineStatePatterns on ThemeEngineState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ThemeEngineState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ThemeEngineState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ThemeEngineState value)  $default,){
final _that = this;
switch (_that) {
case _ThemeEngineState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ThemeEngineState value)?  $default,){
final _that = this;
switch (_that) {
case _ThemeEngineState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ThemeApproach approach,  Color seedColor,  String? imagePath,  Color? primaryOverride,  Color? secondaryOverride,  Color? tertiaryOverride,  double containerRadius,  double cardElevation,  String fontFamily,  double baseFontSize,  Map<TextStyleKey, TextStyleConfig> textStyles,  ButtonConfig elevatedButton,  ButtonConfig filledButton,  ButtonConfig outlinedButton,  ButtonConfig textButton,  String? flexColorSchemeCode,  double surfaceBlendLevel,  double onSurfaceBlendLevel,  Set<AppComponent> components,  bool generateWidgetbook,  bool extractUiPackage,  Color accentColor,  Color destructiveColor,  Brightness defaultBrightness,  String logoPath)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ThemeEngineState() when $default != null:
return $default(_that.approach,_that.seedColor,_that.imagePath,_that.primaryOverride,_that.secondaryOverride,_that.tertiaryOverride,_that.containerRadius,_that.cardElevation,_that.fontFamily,_that.baseFontSize,_that.textStyles,_that.elevatedButton,_that.filledButton,_that.outlinedButton,_that.textButton,_that.flexColorSchemeCode,_that.surfaceBlendLevel,_that.onSurfaceBlendLevel,_that.components,_that.generateWidgetbook,_that.extractUiPackage,_that.accentColor,_that.destructiveColor,_that.defaultBrightness,_that.logoPath);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ThemeApproach approach,  Color seedColor,  String? imagePath,  Color? primaryOverride,  Color? secondaryOverride,  Color? tertiaryOverride,  double containerRadius,  double cardElevation,  String fontFamily,  double baseFontSize,  Map<TextStyleKey, TextStyleConfig> textStyles,  ButtonConfig elevatedButton,  ButtonConfig filledButton,  ButtonConfig outlinedButton,  ButtonConfig textButton,  String? flexColorSchemeCode,  double surfaceBlendLevel,  double onSurfaceBlendLevel,  Set<AppComponent> components,  bool generateWidgetbook,  bool extractUiPackage,  Color accentColor,  Color destructiveColor,  Brightness defaultBrightness,  String logoPath)  $default,) {final _that = this;
switch (_that) {
case _ThemeEngineState():
return $default(_that.approach,_that.seedColor,_that.imagePath,_that.primaryOverride,_that.secondaryOverride,_that.tertiaryOverride,_that.containerRadius,_that.cardElevation,_that.fontFamily,_that.baseFontSize,_that.textStyles,_that.elevatedButton,_that.filledButton,_that.outlinedButton,_that.textButton,_that.flexColorSchemeCode,_that.surfaceBlendLevel,_that.onSurfaceBlendLevel,_that.components,_that.generateWidgetbook,_that.extractUiPackage,_that.accentColor,_that.destructiveColor,_that.defaultBrightness,_that.logoPath);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ThemeApproach approach,  Color seedColor,  String? imagePath,  Color? primaryOverride,  Color? secondaryOverride,  Color? tertiaryOverride,  double containerRadius,  double cardElevation,  String fontFamily,  double baseFontSize,  Map<TextStyleKey, TextStyleConfig> textStyles,  ButtonConfig elevatedButton,  ButtonConfig filledButton,  ButtonConfig outlinedButton,  ButtonConfig textButton,  String? flexColorSchemeCode,  double surfaceBlendLevel,  double onSurfaceBlendLevel,  Set<AppComponent> components,  bool generateWidgetbook,  bool extractUiPackage,  Color accentColor,  Color destructiveColor,  Brightness defaultBrightness,  String logoPath)?  $default,) {final _that = this;
switch (_that) {
case _ThemeEngineState() when $default != null:
return $default(_that.approach,_that.seedColor,_that.imagePath,_that.primaryOverride,_that.secondaryOverride,_that.tertiaryOverride,_that.containerRadius,_that.cardElevation,_that.fontFamily,_that.baseFontSize,_that.textStyles,_that.elevatedButton,_that.filledButton,_that.outlinedButton,_that.textButton,_that.flexColorSchemeCode,_that.surfaceBlendLevel,_that.onSurfaceBlendLevel,_that.components,_that.generateWidgetbook,_that.extractUiPackage,_that.accentColor,_that.destructiveColor,_that.defaultBrightness,_that.logoPath);case _:
  return null;

}
}

}

/// @nodoc


class _ThemeEngineState extends ThemeEngineState {
  const _ThemeEngineState({this.approach = ThemeApproach.none, this.seedColor = const Color(0xFF00DCE5), this.imagePath, this.primaryOverride, this.secondaryOverride, this.tertiaryOverride, this.containerRadius = 12.0, this.cardElevation = 0.0, this.fontFamily = 'Inter', this.baseFontSize = 16.0, final  Map<TextStyleKey, TextStyleConfig> textStyles = kM3Defaults, this.elevatedButton = kDefaultElevated, this.filledButton = kDefaultFilled, this.outlinedButton = kDefaultOutlined, this.textButton = kDefaultText, this.flexColorSchemeCode, this.surfaceBlendLevel = 13.0, this.onSurfaceBlendLevel = 20.0, final  Set<AppComponent> components = const <AppComponent>{}, this.generateWidgetbook = false, this.extractUiPackage = true, this.accentColor = const Color(0xFF1E293B), this.destructiveColor = const Color(0xFFEF4444), this.defaultBrightness = Brightness.light, this.logoPath = ''}): _textStyles = textStyles,_components = components,super._();
  

@override@JsonKey() final  ThemeApproach approach;
// Colors
@override@JsonKey() final  Color seedColor;
@override final  String? imagePath;
@override final  Color? primaryOverride;
@override final  Color? secondaryOverride;
@override final  Color? tertiaryOverride;
// Shape / elevation (global)
@override@JsonKey() final  double containerRadius;
@override@JsonKey() final  double cardElevation;
// Typography
@override@JsonKey() final  String fontFamily;
@override@JsonKey() final  double baseFontSize;
 final  Map<TextStyleKey, TextStyleConfig> _textStyles;
@override@JsonKey() Map<TextStyleKey, TextStyleConfig> get textStyles {
  if (_textStyles is EqualUnmodifiableMapView) return _textStyles;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_textStyles);
}

// Buttons
@override@JsonKey() final  ButtonConfig elevatedButton;
@override@JsonKey() final  ButtonConfig filledButton;
@override@JsonKey() final  ButtonConfig outlinedButton;
@override@JsonKey() final  ButtonConfig textButton;
// FlexColorScheme
@override final  String? flexColorSchemeCode;
@override@JsonKey() final  double surfaceBlendLevel;
@override@JsonKey() final  double onSurfaceBlendLevel;
// Components
/// Design-system components to generate into lib/components/ (opt-in).
 final  Set<AppComponent> _components;
// Components
/// Design-system components to generate into lib/components/ (opt-in).
@override@JsonKey() Set<AppComponent> get components {
  if (_components is EqualUnmodifiableSetView) return _components;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_components);
}

/// When true, scaffold a Widgetbook catalog (widgetbook/main.dart).
@override@JsonKey() final  bool generateWidgetbook;
/// When true, extract theme + tokens + components into a workspace package
/// `<app>_ui` (the app and Widgetbook depend on it).
@override@JsonKey() final  bool extractUiPackage;
// Semantic palette colors (used by AppButton variants & the theme)
@override@JsonKey() final  Color accentColor;
@override@JsonKey() final  Color destructiveColor;
// Preview
@override@JsonKey() final  Brightness defaultBrightness;
/// Absolute path to a logo (PNG) the user picked. When set, NEAT copies it
/// into the project and generates app icons + splash (flutter_launcher_icons
/// + flutter_native_splash) at generation time.
@override@JsonKey() final  String logoPath;

/// Create a copy of ThemeEngineState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ThemeEngineStateCopyWith<_ThemeEngineState> get copyWith => __$ThemeEngineStateCopyWithImpl<_ThemeEngineState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ThemeEngineState&&(identical(other.approach, approach) || other.approach == approach)&&(identical(other.seedColor, seedColor) || other.seedColor == seedColor)&&(identical(other.imagePath, imagePath) || other.imagePath == imagePath)&&(identical(other.primaryOverride, primaryOverride) || other.primaryOverride == primaryOverride)&&(identical(other.secondaryOverride, secondaryOverride) || other.secondaryOverride == secondaryOverride)&&(identical(other.tertiaryOverride, tertiaryOverride) || other.tertiaryOverride == tertiaryOverride)&&(identical(other.containerRadius, containerRadius) || other.containerRadius == containerRadius)&&(identical(other.cardElevation, cardElevation) || other.cardElevation == cardElevation)&&(identical(other.fontFamily, fontFamily) || other.fontFamily == fontFamily)&&(identical(other.baseFontSize, baseFontSize) || other.baseFontSize == baseFontSize)&&const DeepCollectionEquality().equals(other._textStyles, _textStyles)&&(identical(other.elevatedButton, elevatedButton) || other.elevatedButton == elevatedButton)&&(identical(other.filledButton, filledButton) || other.filledButton == filledButton)&&(identical(other.outlinedButton, outlinedButton) || other.outlinedButton == outlinedButton)&&(identical(other.textButton, textButton) || other.textButton == textButton)&&(identical(other.flexColorSchemeCode, flexColorSchemeCode) || other.flexColorSchemeCode == flexColorSchemeCode)&&(identical(other.surfaceBlendLevel, surfaceBlendLevel) || other.surfaceBlendLevel == surfaceBlendLevel)&&(identical(other.onSurfaceBlendLevel, onSurfaceBlendLevel) || other.onSurfaceBlendLevel == onSurfaceBlendLevel)&&const DeepCollectionEquality().equals(other._components, _components)&&(identical(other.generateWidgetbook, generateWidgetbook) || other.generateWidgetbook == generateWidgetbook)&&(identical(other.extractUiPackage, extractUiPackage) || other.extractUiPackage == extractUiPackage)&&(identical(other.accentColor, accentColor) || other.accentColor == accentColor)&&(identical(other.destructiveColor, destructiveColor) || other.destructiveColor == destructiveColor)&&(identical(other.defaultBrightness, defaultBrightness) || other.defaultBrightness == defaultBrightness)&&(identical(other.logoPath, logoPath) || other.logoPath == logoPath));
}


@override
int get hashCode => Object.hashAll([runtimeType,approach,seedColor,imagePath,primaryOverride,secondaryOverride,tertiaryOverride,containerRadius,cardElevation,fontFamily,baseFontSize,const DeepCollectionEquality().hash(_textStyles),elevatedButton,filledButton,outlinedButton,textButton,flexColorSchemeCode,surfaceBlendLevel,onSurfaceBlendLevel,const DeepCollectionEquality().hash(_components),generateWidgetbook,extractUiPackage,accentColor,destructiveColor,defaultBrightness,logoPath]);

@override
String toString() {
  return 'ThemeEngineState(approach: $approach, seedColor: $seedColor, imagePath: $imagePath, primaryOverride: $primaryOverride, secondaryOverride: $secondaryOverride, tertiaryOverride: $tertiaryOverride, containerRadius: $containerRadius, cardElevation: $cardElevation, fontFamily: $fontFamily, baseFontSize: $baseFontSize, textStyles: $textStyles, elevatedButton: $elevatedButton, filledButton: $filledButton, outlinedButton: $outlinedButton, textButton: $textButton, flexColorSchemeCode: $flexColorSchemeCode, surfaceBlendLevel: $surfaceBlendLevel, onSurfaceBlendLevel: $onSurfaceBlendLevel, components: $components, generateWidgetbook: $generateWidgetbook, extractUiPackage: $extractUiPackage, accentColor: $accentColor, destructiveColor: $destructiveColor, defaultBrightness: $defaultBrightness, logoPath: $logoPath)';
}


}

/// @nodoc
abstract mixin class _$ThemeEngineStateCopyWith<$Res> implements $ThemeEngineStateCopyWith<$Res> {
  factory _$ThemeEngineStateCopyWith(_ThemeEngineState value, $Res Function(_ThemeEngineState) _then) = __$ThemeEngineStateCopyWithImpl;
@override @useResult
$Res call({
 ThemeApproach approach, Color seedColor, String? imagePath, Color? primaryOverride, Color? secondaryOverride, Color? tertiaryOverride, double containerRadius, double cardElevation, String fontFamily, double baseFontSize, Map<TextStyleKey, TextStyleConfig> textStyles, ButtonConfig elevatedButton, ButtonConfig filledButton, ButtonConfig outlinedButton, ButtonConfig textButton, String? flexColorSchemeCode, double surfaceBlendLevel, double onSurfaceBlendLevel, Set<AppComponent> components, bool generateWidgetbook, bool extractUiPackage, Color accentColor, Color destructiveColor, Brightness defaultBrightness, String logoPath
});


@override $ButtonConfigCopyWith<$Res> get elevatedButton;@override $ButtonConfigCopyWith<$Res> get filledButton;@override $ButtonConfigCopyWith<$Res> get outlinedButton;@override $ButtonConfigCopyWith<$Res> get textButton;

}
/// @nodoc
class __$ThemeEngineStateCopyWithImpl<$Res>
    implements _$ThemeEngineStateCopyWith<$Res> {
  __$ThemeEngineStateCopyWithImpl(this._self, this._then);

  final _ThemeEngineState _self;
  final $Res Function(_ThemeEngineState) _then;

/// Create a copy of ThemeEngineState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? approach = null,Object? seedColor = null,Object? imagePath = freezed,Object? primaryOverride = freezed,Object? secondaryOverride = freezed,Object? tertiaryOverride = freezed,Object? containerRadius = null,Object? cardElevation = null,Object? fontFamily = null,Object? baseFontSize = null,Object? textStyles = null,Object? elevatedButton = null,Object? filledButton = null,Object? outlinedButton = null,Object? textButton = null,Object? flexColorSchemeCode = freezed,Object? surfaceBlendLevel = null,Object? onSurfaceBlendLevel = null,Object? components = null,Object? generateWidgetbook = null,Object? extractUiPackage = null,Object? accentColor = null,Object? destructiveColor = null,Object? defaultBrightness = null,Object? logoPath = null,}) {
  return _then(_ThemeEngineState(
approach: null == approach ? _self.approach : approach // ignore: cast_nullable_to_non_nullable
as ThemeApproach,seedColor: null == seedColor ? _self.seedColor : seedColor // ignore: cast_nullable_to_non_nullable
as Color,imagePath: freezed == imagePath ? _self.imagePath : imagePath // ignore: cast_nullable_to_non_nullable
as String?,primaryOverride: freezed == primaryOverride ? _self.primaryOverride : primaryOverride // ignore: cast_nullable_to_non_nullable
as Color?,secondaryOverride: freezed == secondaryOverride ? _self.secondaryOverride : secondaryOverride // ignore: cast_nullable_to_non_nullable
as Color?,tertiaryOverride: freezed == tertiaryOverride ? _self.tertiaryOverride : tertiaryOverride // ignore: cast_nullable_to_non_nullable
as Color?,containerRadius: null == containerRadius ? _self.containerRadius : containerRadius // ignore: cast_nullable_to_non_nullable
as double,cardElevation: null == cardElevation ? _self.cardElevation : cardElevation // ignore: cast_nullable_to_non_nullable
as double,fontFamily: null == fontFamily ? _self.fontFamily : fontFamily // ignore: cast_nullable_to_non_nullable
as String,baseFontSize: null == baseFontSize ? _self.baseFontSize : baseFontSize // ignore: cast_nullable_to_non_nullable
as double,textStyles: null == textStyles ? _self._textStyles : textStyles // ignore: cast_nullable_to_non_nullable
as Map<TextStyleKey, TextStyleConfig>,elevatedButton: null == elevatedButton ? _self.elevatedButton : elevatedButton // ignore: cast_nullable_to_non_nullable
as ButtonConfig,filledButton: null == filledButton ? _self.filledButton : filledButton // ignore: cast_nullable_to_non_nullable
as ButtonConfig,outlinedButton: null == outlinedButton ? _self.outlinedButton : outlinedButton // ignore: cast_nullable_to_non_nullable
as ButtonConfig,textButton: null == textButton ? _self.textButton : textButton // ignore: cast_nullable_to_non_nullable
as ButtonConfig,flexColorSchemeCode: freezed == flexColorSchemeCode ? _self.flexColorSchemeCode : flexColorSchemeCode // ignore: cast_nullable_to_non_nullable
as String?,surfaceBlendLevel: null == surfaceBlendLevel ? _self.surfaceBlendLevel : surfaceBlendLevel // ignore: cast_nullable_to_non_nullable
as double,onSurfaceBlendLevel: null == onSurfaceBlendLevel ? _self.onSurfaceBlendLevel : onSurfaceBlendLevel // ignore: cast_nullable_to_non_nullable
as double,components: null == components ? _self._components : components // ignore: cast_nullable_to_non_nullable
as Set<AppComponent>,generateWidgetbook: null == generateWidgetbook ? _self.generateWidgetbook : generateWidgetbook // ignore: cast_nullable_to_non_nullable
as bool,extractUiPackage: null == extractUiPackage ? _self.extractUiPackage : extractUiPackage // ignore: cast_nullable_to_non_nullable
as bool,accentColor: null == accentColor ? _self.accentColor : accentColor // ignore: cast_nullable_to_non_nullable
as Color,destructiveColor: null == destructiveColor ? _self.destructiveColor : destructiveColor // ignore: cast_nullable_to_non_nullable
as Color,defaultBrightness: null == defaultBrightness ? _self.defaultBrightness : defaultBrightness // ignore: cast_nullable_to_non_nullable
as Brightness,logoPath: null == logoPath ? _self.logoPath : logoPath // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of ThemeEngineState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ButtonConfigCopyWith<$Res> get elevatedButton {
  
  return $ButtonConfigCopyWith<$Res>(_self.elevatedButton, (value) {
    return _then(_self.copyWith(elevatedButton: value));
  });
}/// Create a copy of ThemeEngineState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ButtonConfigCopyWith<$Res> get filledButton {
  
  return $ButtonConfigCopyWith<$Res>(_self.filledButton, (value) {
    return _then(_self.copyWith(filledButton: value));
  });
}/// Create a copy of ThemeEngineState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ButtonConfigCopyWith<$Res> get outlinedButton {
  
  return $ButtonConfigCopyWith<$Res>(_self.outlinedButton, (value) {
    return _then(_self.copyWith(outlinedButton: value));
  });
}/// Create a copy of ThemeEngineState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ButtonConfigCopyWith<$Res> get textButton {
  
  return $ButtonConfigCopyWith<$Res>(_self.textButton, (value) {
    return _then(_self.copyWith(textButton: value));
  });
}
}

// dart format on
