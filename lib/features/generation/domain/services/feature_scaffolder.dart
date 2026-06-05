import 'dart:io';

import 'package:neat/features/generation/domain/services/templates/core_templates.dart';
import 'package:neat/features/generation/domain/services/templates/dart/data_templates.dart';
import 'package:neat/features/generation/domain/services/templates/dart/domain_templates.dart';
import 'package:neat/features/generation/domain/services/templates/dart/presentation_templates.dart';
import 'package:neat/features/generation/domain/services/templates/dart/state_templates.dart';

/// Writes a single feature's Clean Architecture files (domain / data /
/// presentation, + DI graph & routes). Shared by the new-project generator and
/// the feature generator so both stay perfectly consistent.
///
/// Purely additive: it only creates the feature's own files. Wiring into shared
/// files (router aggregator, AppRoutePath, Drift database) is handled by the
/// callers/insertion step, not here.
class FeatureScaffolder {
  const FeatureScaffolder();

  Future<void> writeFeature({
    required String lib,
    required String featureName,
    required String packageName,
    required bool isFeatureFirst,
    required bool mirrorTestStructure,
    required bool hasRiverpod,
    required bool hasBloc,
    required bool useCubit,
    required bool useAnnotations,
    required bool hasGoRouter,
    required bool hasGoRouterBuilder,
    required bool hasHttpClient,
    required String httpClient,
    required bool hasFreezed,
    required bool hasJsonSerializable,
    String? localStoragePackage,
    bool hasSync = false,
  }) async {
    final offlineFirst = localStoragePackage != null;

    final String domainBase;
    final String dataBase;
    final String presentationBase;

    if (isFeatureFirst) {
      domainBase = '$lib/features/$featureName/domain';
      dataBase = '$lib/features/$featureName/data';
      presentationBase = '$lib/features/$featureName/presentation';
    } else {
      domainBase = '$lib/domain/$featureName';
      dataBase = '$lib/data/$featureName';
      presentationBase = '$lib/presentation/$featureName';
    }

    // domain/entities
    await _write(
      '$domainBase/entities/${featureName}_entity.dart',
      DomainTemplates.featureEntity(featureName: featureName, hasFreezed: hasFreezed),
    );

    // domain/repositories
    await _write(
      '$domainBase/repositories/i_${featureName}_repository.dart',
      DomainTemplates.featureIRepository(
        featureName: featureName,
        packageName: packageName,
        hasHttpClient: hasHttpClient,
      ),
    );

    // domain/usecases
    await _write(
      '$domainBase/usecases/get_${featureName}_usecase.dart',
      DomainTemplates.featureGetUsecase(featureName: featureName, packageName: packageName),
    );
    if (hasHttpClient) {
      await _write(
        '$domainBase/usecases/${featureName}_crud_usecases.dart',
        DomainTemplates.featureCrudUsecases(featureName: featureName, packageName: packageName),
      );
    }

    // data/models
    await _write(
      '$dataBase/models/${featureName}_model.dart',
      DataTemplates.featureModel(
        featureName: featureName,
        packageName: packageName,
        hasFreezed: hasFreezed,
        hasJsonSerializable: hasJsonSerializable,
      ),
    );

    // data/repositories
    await _write(
      '$dataBase/repositories/${featureName}_repository_impl.dart',
      DataTemplates.featureRepositoryImpl(
        featureName: featureName,
        packageName: packageName,
        hasHttpClient: hasHttpClient,
        httpClient: httpClient,
        offlineFirst: offlineFirst,
        hasSync: hasSync,
      ),
    );

    // data/sources
    if (hasHttpClient) {
      await _write(
        '$dataBase/sources/${featureName}_api_source.dart',
        DataTemplates.featureApiSource(
          featureName: featureName,
          packageName: packageName,
          httpClient: httpClient,
        ),
      );
    }
    await _write(
      '$dataBase/sources/${featureName}_local_source.dart',
      DataTemplates.featureLocalSource(
        featureName: featureName,
        packageName: packageName,
        offlineFirst: offlineFirst,
        hasSync: hasSync,
        localStoragePackage: localStoragePackage,
      ),
    );

    // presentation/pages
    await _write(
      '$presentationBase/pages/${featureName}_page.dart',
      PresentationTemplates.featurePage(
        featureName: featureName,
        packageName: packageName,
        hasRiverpod: hasRiverpod,
        useAnnotations: useAnnotations,
        hasBloc: hasBloc,
        useCubit: useCubit,
      ),
    );

    // presentation/providers or bloc/cubit
    if (hasRiverpod) {
      await _write(
        '$presentationBase/providers/${featureName}_provider.dart',
        PresentationTemplates.featureProvider(
          featureName: featureName,
          useAnnotations: useAnnotations,
          useCubit: false,
        ),
      );
      if (useAnnotations && hasHttpClient) {
        await _write(
          '$presentationBase/providers/${featureName}_providers.dart',
          PresentationTemplates.featureDi(
            featureName: featureName,
            packageName: packageName,
            httpClient: httpClient,
            offlineFirst: offlineFirst,
            hasSync: hasSync,
            localStoragePackage: localStoragePackage,
          ),
        );
      }
    } else if (useCubit) {
      await _write(
        '$presentationBase/cubit/${featureName}_cubit.dart',
        StateTemplates.featureCubit(featureName: featureName),
      );
      await _write(
        '$presentationBase/cubit/${featureName}_state.dart',
        StateTemplates.featureCubitState(featureName: featureName),
      );
    } else if (hasBloc) {
      await _write(
        '$presentationBase/bloc/${featureName}_bloc.dart',
        StateTemplates.featureBloc(featureName: featureName),
      );
      await _write(
        '$presentationBase/bloc/${featureName}_event.dart',
        StateTemplates.featureBlocEvent(featureName: featureName),
      );
      await _write(
        '$presentationBase/bloc/${featureName}_state.dart',
        StateTemplates.featureBlocState(featureName: featureName),
      );
    }

    // presentation/routes
    if (hasGoRouterBuilder) {
      await _write(
        '$presentationBase/routes/${featureName}_routes.dart',
        CoreTemplates.featureRoutes(packageName: packageName, featureName: featureName),
      );
    } else if (hasGoRouter) {
      await _write(
        '$presentationBase/routes/${featureName}_route.dart',
        PresentationTemplates.featureRoute(
          featureName: featureName,
          packageName: packageName,
          useBuilder: false,
        ),
      );
    }

    // presentation/widgets
    await _write('$presentationBase/widgets/.gitkeep', '');

    // Mirror test structure
    if (mirrorTestStructure) {
      await _write('${domainBase.replaceFirst('/lib/', '/test/')}/.gitkeep', '');
      await _write('${dataBase.replaceFirst('/lib/', '/test/')}/.gitkeep', '');
      await _write('${presentationBase.replaceFirst('/lib/', '/test/')}/.gitkeep', '');
    }
  }

  Future<void> _write(String path, String content) async {
    final file = File(path);
    await file.create(recursive: true);
    await file.writeAsString(content);
  }
}
