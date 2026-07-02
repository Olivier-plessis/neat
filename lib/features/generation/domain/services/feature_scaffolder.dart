import 'dart:io';

import 'package:neat/features/generation/domain/models/field_spec.dart';
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
    // Per-feature layer toggles (Workshop). Default true = full feature.
    bool includeLocalSource = true,
    bool includeUseCases = true,
    // A child route lives inside its parent's route tree, and a shell branch
    // lives inside the shell's tree, so neither emits its own standalone
    // (aggregated) route file — the caller wires them instead.
    bool isChildRoute = false,
    bool isShellBranch = false,
    // Supabase Realtime: the list screen becomes a live StreamNotifier and the
    // repository exposes `watchAll()`. Only effective with the full DI graph.
    bool realtime = false,
    // slang i18n: the riverpod page consumes `context.t.<feature>.title` and
    // shows a LanguageSwitcher in the AppBar.
    bool i18n = false,
    // The entity's fields (inferred from a pasted JSON, or the default id/name).
    List<FieldSpec> fields = FieldSpec.idName,
    // Overrides the REST resource path (default: `/<featureName>s`). Either a
    // relative path or an absolute URL — an absolute URL overrides the
    // client's configured base URL entirely (e.g. the FakeStore example
    // feature always targets fakestoreapi.com regardless of the project's
    // own API Base URL). REST clients only (dio/chopper/retrofit); ignored
    // for supabase/firebase, which address a table/collection, not a path.
    String? apiPath,
    // Adds a tap-for-detail (+ delete) sheet and an "add" (create) sheet to
    // the riverpod list page. Off by default — deliberately not exposed as a
    // general Workshop/wizard toggle yet; only NEAT's own FakeStore example
    // feature turns it on.
    bool includeCrudUi = false,
  }) async {
    // The project ships a Drift package → any local source is Drift-backed.
    final localIsDrift = localStoragePackage != null;
    // A local-only feature (no remote) always needs its local source.
    final writeLocal = includeLocalSource || !hasHttpClient;
    // The offline 3-source repository requires BOTH a remote and a local source.
    final offlineFirst = localIsDrift && hasHttpClient && includeLocalSource;
    // A real list screen (provider fetches via the usecase → Skeletonizer) needs
    // the DI graph, which exists only with annotations + a remote source + usecases.
    final dataList = useAnnotations && hasHttpClient && includeUseCases;
    // Realtime needs the full DI graph (repository provider + list notifier).
    final liveList = realtime && dataList;

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
      DomainTemplates.featureEntity(featureName: featureName, hasFreezed: hasFreezed, fields: fields),
    );

    // domain/repositories
    await _write(
      '$domainBase/repositories/i_${featureName}_repository.dart',
      DomainTemplates.featureIRepository(
        featureName: featureName,
        packageName: packageName,
        hasHttpClient: hasHttpClient,
        offlineFirst: offlineFirst,
        realtime: liveList,
      ),
    );

    // domain/usecases
    if (includeUseCases) {
      await _write(
        '$domainBase/usecases/get_${featureName}_usecase.dart',
        DomainTemplates.featureGetUsecase(
          featureName: featureName,
          packageName: packageName,
          offlineFirst: offlineFirst,
        ),
      );
      if (hasHttpClient) {
        await _write(
          '$domainBase/usecases/${featureName}_crud_usecases.dart',
          DomainTemplates.featureCrudUsecases(featureName: featureName, packageName: packageName),
        );
      }
    }

    // data/models
    await _write(
      '$dataBase/models/${featureName}_model.dart',
      DataTemplates.featureModel(
        featureName: featureName,
        packageName: packageName,
        hasFreezed: hasFreezed,
        hasJsonSerializable: hasJsonSerializable,
        fields: fields,
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
        realtime: liveList,
        fields: fields,
        apiPath: apiPath,
      ),
    );
    // The repository-level DI graph (ApiSource/LocalSource/Repository/Sync
    // providers) lives in data/ — never presentation/ — since it only ever
    // touches concrete Data types. Only emit it when there's a usecase graph
    // to wire (mirrors the old DI-graph gate).
    if (useAnnotations && hasHttpClient && includeUseCases) {
      await _write(
        '$dataBase/repositories/${featureName}_repository_providers.dart',
        DataTemplates.featureRepositoryProviders(
          featureName: featureName,
          packageName: packageName,
          httpClient: httpClient,
          offlineFirst: offlineFirst,
          hasSync: hasSync,
          localStoragePackage: localStoragePackage,
        ),
      );
    }

    // data/sources
    if (hasHttpClient) {
      await _write(
        '$dataBase/sources/${featureName}_api_source.dart',
        DataTemplates.featureApiSource(
          featureName: featureName,
          packageName: packageName,
          httpClient: httpClient,
          realtime: liveList,
          apiPath: apiPath,
        ),
      );
    }
    if (writeLocal) {
      await _write(
        '$dataBase/sources/${featureName}_local_source.dart',
        DataTemplates.featureLocalSource(
          featureName: featureName,
          packageName: packageName,
          offlineFirst: localIsDrift,
          hasSync: hasSync,
          localStoragePackage: localStoragePackage,
          fields: fields,
        ),
      );
    }

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
        dataList: dataList,
        i18n: i18n,
        fields: fields,
        includeCrudUi: includeCrudUi,
      ),
    );

    // presentation/providers or bloc/cubit
    if (hasRiverpod) {
      await _write(
        '$presentationBase/providers/${featureName}_provider.dart',
        PresentationTemplates.featureProvider(
          featureName: featureName,
          packageName: packageName,
          useAnnotations: useAnnotations,
          useCubit: false,
          dataList: dataList,
          realtime: liveList,
          includeCrudUi: includeCrudUi,
          fields: fields,
        ),
      );
      // Usecase-level DI wires the usecases to the repository → only emit it
      // when both exist. The repository-level providers it depends on
      // (ApiSource/LocalSource/Repository/Sync) live in data/, written above.
      if (useAnnotations && hasHttpClient && includeUseCases) {
        await _write(
          '$presentationBase/providers/${featureName}_usecase_providers.dart',
          PresentationTemplates.featureUsecaseProviders(
            featureName: featureName,
            packageName: packageName,
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

    // presentation/routes — skipped for child routes & shell branches (their
    // route lives in the parent's/shell's tree, wired by the caller).
    if (isChildRoute || isShellBranch) {
      // nothing: the parent/shell owns this feature's route declaration.
    } else if (hasGoRouterBuilder) {
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
