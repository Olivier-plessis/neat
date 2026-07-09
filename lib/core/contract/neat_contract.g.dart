// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'neat_contract.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_NeatContract _$NeatContractFromJson(Map<String, dynamic> json) =>
    _NeatContract(
      projectName: json['projectName'] as String,
      architecture: json['architecture'] as String,
      stateManagement: json['stateManagement'] as String,
      navigation: json['navigation'] as String,
      httpClient: json['httpClient'] as String,
      themeApproach: json['themeApproach'] as String,
      storageStrategy: json['storageStrategy'] as String,
      schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 1,
      useRiverpodAnnotations: json['useRiverpodAnnotations'] as bool? ?? true,
      useCubit: json['useCubit'] as bool? ?? false,
      extractUiPackage: json['extractUiPackage'] as bool? ?? false,
      useScreenUtil: json['useScreenUtil'] as bool? ?? false,
      hasEnvied: json['hasEnvied'] as bool? ?? false,
      hasFreezed: json['hasFreezed'] as bool? ?? false,
      hasJsonSerializable: json['hasJsonSerializable'] as bool? ?? false,
      includeMappers: json['includeMappers'] as bool? ?? true,
      mirrorTestStructure: json['mirrorTestStructure'] as bool? ?? true,
      generateWidgetbook: json['generateWidgetbook'] as bool? ?? false,
      useNavigationShell: json['useNavigationShell'] as bool? ?? false,
      generateAuth: json['generateAuth'] as bool? ?? false,
      generateRealtime: json['generateRealtime'] as bool? ?? false,
      generateStorage: json['generateStorage'] as bool? ?? false,
      generateOAuth: json['generateOAuth'] as bool? ?? false,
      generateI18n: json['generateI18n'] as bool? ?? false,
      generateOnboarding: json['generateOnboarding'] as bool? ?? false,
      components:
          (json['components'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      packageSplit: json['packageSplit'] as bool? ?? false,
    );

Map<String, dynamic> _$NeatContractToJson(_NeatContract instance) =>
    <String, dynamic>{
      'projectName': instance.projectName,
      'architecture': instance.architecture,
      'stateManagement': instance.stateManagement,
      'navigation': instance.navigation,
      'httpClient': instance.httpClient,
      'themeApproach': instance.themeApproach,
      'storageStrategy': instance.storageStrategy,
      'schemaVersion': instance.schemaVersion,
      'useRiverpodAnnotations': instance.useRiverpodAnnotations,
      'useCubit': instance.useCubit,
      'extractUiPackage': instance.extractUiPackage,
      'useScreenUtil': instance.useScreenUtil,
      'hasEnvied': instance.hasEnvied,
      'hasFreezed': instance.hasFreezed,
      'hasJsonSerializable': instance.hasJsonSerializable,
      'includeMappers': instance.includeMappers,
      'mirrorTestStructure': instance.mirrorTestStructure,
      'generateWidgetbook': instance.generateWidgetbook,
      'useNavigationShell': instance.useNavigationShell,
      'generateAuth': instance.generateAuth,
      'generateRealtime': instance.generateRealtime,
      'generateStorage': instance.generateStorage,
      'generateOAuth': instance.generateOAuth,
      'generateI18n': instance.generateI18n,
      'generateOnboarding': instance.generateOnboarding,
      'components': instance.components,
      'packageSplit': instance.packageSplit,
    };
