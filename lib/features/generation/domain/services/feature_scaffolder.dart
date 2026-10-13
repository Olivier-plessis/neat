import 'dart:io';

import 'package:neat/features/generation/domain/models/crud_endpoint_overrides.dart';
import 'package:neat/features/generation/domain/models/endpoint_spec.dart';
import 'package:neat/features/generation/domain/models/field_spec.dart';
import 'package:neat/features/generation/domain/services/templates/core_templates.dart';
import 'package:neat/features/generation/domain/services/templates/dart/data_templates.dart';
import 'package:neat/features/generation/domain/services/templates/dart/domain_templates.dart';
import 'package:neat/features/generation/domain/services/templates/dart/endpoint_templates.dart';
import 'package:neat/features/generation/domain/services/templates/dart/field_codegen.dart';
import 'package:neat/features/generation/domain/services/templates/dart/offline_test_templates.dart';
import 'package:neat/features/generation/domain/services/templates/dart/presentation_templates.dart';
import 'package:neat/features/generation/domain/services/templates/dart/state_templates.dart';
import 'package:neat/features/generation/domain/services/templates/supabase_templates.dart';

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
    // own API Base URL). REST clients only (dio/chopper); ignored for
    // supabase/firebase, which address a table/collection, not a path.
    String? apiPath,
    // Adds a tap-for-detail (+ delete) sheet and an "add" (create) sheet to
    // the riverpod list page. Off by default — deliberately not exposed as a
    // general Workshop/wizard toggle yet; only NEAT's own FakeStore example
    // feature turns it on.
    bool includeCrudUi = false,
    // Supabase table / Firestore collection the feature reads and writes
    // (default `<featureName>s`). Replaces [apiPath] for those backends, which
    // address a table, not a REST path; the Outbox `resource` follows it.
    String? tableName,
    // Supabase only: every row belongs to the signed-in user (`owner_id`,
    // owner-scoped RLS policies — see SupabaseTemplates.migration). False → a
    // shared table. [hasAuth]: the project has sign-in at all (decides who a
    // shared table is open to). Both only shape the generated migration.
    bool ownedByUser = true,
    bool hasAuth = true,
    // The migration's timestamp (default: now, UTC). Injectable for tests.
    DateTime? migrationTime,
    // Outbox resources of the already-synced features this one's rows point at
    // (see SyncParents): its SyncService waits for their older writes.
    List<String> syncDependsOn = const [],
    // Fields (by JSON key) that point at another feature's Supabase table (see
    // ParentTables): the migration makes them `uuid` foreign keys.
    Map<String, ForeignKey> foreignKeys = const {},
    // The generated project's root. When set, an offline-first + sync feature
    // also gets its repository test in the root `test/` (the only suite the
    // generated CI runs): flat as `test/<feature>/<feature>_offline_first_test
    // .dart`, or mirroring the repository's path when [mirrorTestStructure] is
    // on. Null (unit tests of this class) writes none.
    String? projectRoot,
    // Opt-in: the feature lives at the root of its own workspace package
    // (`packages/<packageName>_<featureName>/lib/...`) instead of a folder
    // under the app (see ROADMAP.md §6a). [corePackageName] is required in
    // that mode — a pub workspace forbids the feature package depending back
    // on the app, so Result/Failure/UseCase/dio networking live in a shared
    // package below both instead.
    bool packageSplit = false,
    String? corePackageName,
    // "Custom Endpoints" (ROADMAP.md §7 Phase 2): the feature is N arbitrary
    // REST calls instead of one entity + fixed CRUD — chopper-only,
    // remote-only. No entity, no repository interface, no local source:
    // there's nothing to abstract over without a single entity. Presentation
    // (page/provider-or-cubit-or-bloc/route) is unaffected — it already
    // degrades to the same plain-stub shape the zero-data-source case uses,
    // since `dataList` is always false here (no CRUD DI graph to build a
    // list off of).
    bool useCustomEndpoints = false,
    List<EndpointSpec> endpoints = const [],
    // Opt-in (Entity + CRUD only, chopper): each of the 5 fixed CRUD
    // operations gets its own HTTP method + path instead of all 5 being
    // derived from [apiPath]'s single base — see CrudEndpointOverrides' doc.
    bool customizeEndpoints = false,
    CrudEndpointOverrides? endpointOverrides,
    // See DataTemplates.featureApiSource/featureRepositoryImpl's own doc —
    // set when the entity was inferred from a paginated list wrapper, so
    // getAll() returns a typed <Feature>ListModel instead of a bare array.
    String listEnvelopeKey = '',
    // The wrapper's own sibling scalar fields (total/skip/limit-style) — see
    // DataTemplates.featureModel's own doc. Always empty when listEnvelopeKey
    // is empty.
    List<FieldSpec> envelopeFields = const [],
    // packageSplit + shell branch, or a child nested under one (see
    // ROADMAP.md §6a): app_shell_route.dart/routes.dart can't import this
    // feature's page directly without the app depending on a page it
    // doesn't otherwise need at aggregation time, so it self-registers into
    // core's shellPageBuilders instead. Independent of isChildRoute/
    // isShellBranch's routes-file gate above — a shell branch/child skips
    // <f>_routes.dart but gains <f>_shell_registration.dart instead, when
    // packageSplit.
    bool needsShellRegistration = false,
    // Opt-in (Workshop, child routes only — see FeatureGenOptions
    // .mergeIntoParent): the parent's own lib root (packages/<parent>/lib
    // when packageSplit, lib/features/<parent> otherwise). When set, this
    // feature's files nest by name under it — domain/$featureName,
    // data/$featureName, presentation/$featureName — exactly the
    // non-feature-first layer-first shape below, just re-rooted at the
    // parent instead of the app. Checked first: takes priority over
    // packageSplit/isFeatureFirst, which otherwise decide this.
    String? mergeBase,
  }) async {
    // Enum fields get their class name now (`<Feature><Field>`) — resolved
    // here, once, so every template below sees the same names.
    final resolved = resolveEnumNames(featureName, fields);
    // The project ships a Drift package → any local source is Drift-backed.
    final localIsDrift = localStoragePackage != null;
    // The offline 3-source repository requires BOTH a remote and a local source.
    final offlineFirst = localIsDrift && hasHttpClient && includeLocalSource;
    // Only write the local source when the repository will actually reference
    // it: the offline-first 3-source repo, or a genuinely local-only feature
    // (no remote, Local Data Source explicitly on). Previously this was
    // `offlineFirst || !hasHttpClient`, which forced a local source into
    // existence any time Remote was off — even when Local was *also*
    // explicitly off, making that toggle meaningless in practice (found via
    // a real Workshop combo: Remote off + Local off still generated a
    // `_local_source.dart` nothing referenced).
    // Custom-endpoints features are remote-only by design (ROADMAP.md §7
    // Phase 2 scope) — force off regardless of what the caller passes, so a
    // stray includeLocalSource/localStoragePackage can't sneak in a local
    // source with nothing behind it.
    final writeLocal =
        !useCustomEndpoints &&
        (offlineFirst || (!hasHttpClient && includeLocalSource));
    // No data source at all (both toggles off) → this is a pure
    // entity+presentation feature: skip domain/repositories, domain/usecases,
    // and the whole data/ layer entirely, since there'd be nothing behind
    // them to implement or call.
    final hasAnyDataSource = hasHttpClient || includeLocalSource;
    // A real list screen (provider fetches via the usecase → Skeletonizer) needs
    // the DI graph, which exists only with annotations + a remote source + usecases.
    // Custom-endpoints features never have this graph (no entity, no
    // repository — see the useCustomEndpoints branch below), regardless of
    // what the caller passes for useAnnotations/includeUseCases.
    final dataList =
        !useCustomEndpoints &&
        useAnnotations &&
        hasHttpClient &&
        includeUseCases;
    // Realtime needs the full DI graph (repository provider + list notifier).
    final liveList = realtime && dataList;
    // Offline-first + sync: Drift is the source of truth the UI watches — the
    // repository's `watchAll()` reads the local table, so it also shows writes
    // still waiting in the Outbox (the remote result would hide them). This
    // wins over realtime's remote `watchAll()` (one method name, one meaning):
    // the realtime stream is then written through into Drift by the sync
    // provider instead of being shown directly. See ROADMAP.md §5w.
    final localFirst = offlineFirst && hasSync;
    final remoteLive = liveList && !localFirst;

    final String domainBase;
    final String dataBase;
    final String presentationBase;

    if (mergeBase != null) {
      domainBase = '$mergeBase/domain/$featureName';
      dataBase = '$mergeBase/data/$featureName';
      presentationBase = '$mergeBase/presentation/$featureName';
    } else if (packageSplit) {
      // The package root IS the feature — no features/<name>/ nesting, and
      // no layer-first variant (splitting by feature only makes sense
      // feature-first: layer-first shares lib/domain/ across every feature,
      // which contradicts giving each feature its own package).
      domainBase = '$lib/domain';
      dataBase = '$lib/data';
      presentationBase = '$lib/presentation';
    } else if (isFeatureFirst) {
      domainBase = '$lib/features/$featureName/domain';
      dataBase = '$lib/features/$featureName/data';
      presentationBase = '$lib/features/$featureName/presentation';
    } else {
      domainBase = '$lib/domain/$featureName';
      dataBase = '$lib/data/$featureName';
      presentationBase = '$lib/presentation/$featureName';
    }

    // Cross-layer relative imports (data/domain, presentation/domain,
    // presentation/data) hardcode a 2-levels-up prefix ('../../domain',
    // '../../data') — correct only when domainBase/dataBase/presentationBase
    // are direct siblings under a shared root (the packageSplit and
    // isFeatureFirst branches above). The mergeBase and layer-first branches
    // instead nest an extra `$featureName/` folder *inside* each layer, which
    // adds one more directory level and moves the sibling layer's own
    // `$featureName/` folder into the path — see DataTemplates.featureModel's
    // domainCross doc.
    final crossLayerNested =
        mergeBase != null || (!packageSplit && !isFeatureFirst);
    final domainCross = crossLayerNested
        ? '../../../domain/$featureName'
        : '../../domain';
    final dataCross = crossLayerNested
        ? '../../../data/$featureName'
        : '../../data';

    if (useCustomEndpoints) {
      // domain/usecases — one per endpoint, calling the ApiSource directly
      // (no repository interface to mediate: there's no entity to abstract
      // over).
      for (final ep in endpoints) {
        await _write(
          '$domainBase/usecases/${ep.name}_usecase.dart',
          EndpointTemplates.endpointUsecase(
            endpoint: ep,
            featureName: featureName,
            packageName: packageName,
            corePackageName: corePackageName,
          ),
        );
      }

      // data/models — only for endpoints that actually have a request or
      // response body (a bodyless call like DELETE /logout needs neither).
      for (final ep in endpoints) {
        if (!ep.hasRequestBody && !ep.hasResponseBody) continue;
        final content = EndpointTemplates.endpointModelFile(
          endpoint: ep,
          hasFreezed: hasFreezed,
          hasJsonSerializable: hasJsonSerializable,
        );
        if (content.isNotEmpty) {
          await _write('$dataBase/models/${ep.name}_model.dart', content);
        }
      }

      // data/sources — one shared API source, N typed chopper methods.
      await _write(
        '$dataBase/sources/${featureName}_api_source.dart',
        DataTemplates.featureApiSource(
          featureName: featureName,
          httpClient: 'chopper',
          useCustomEndpoints: true,
          endpoints: endpoints,
        ),
      );
    } else {
      // domain/entities
      await _write(
        '$domainBase/entities/${featureName}_entity.dart',
        DomainTemplates.featureEntity(
          featureName: featureName,
          hasFreezed: hasFreezed,
          fields: resolved,
          // Offline creation can't wait for a server-assigned id.
          clientId: localFirst,
        ),
      );

      // domain/entities — one Dart enum per enum field. Each carries its
      // database text; the DTO and the Drift row stay plain `String`.
      final table = tableName ?? '${featureName}s';
      for (final e in collectEnumSpecs(resolved)) {
        await _write(
          '$domainBase/entities/${e.enumFileName}.dart',
          DomainTemplates.featureEnum(
            field: e,
            featureName: featureName,
            checkedBy: httpClient == 'supabase' && hasHttpClient ? table : null,
          ),
        );
      }

      // supabase/migrations/<timestamp>_create_<table>.sql — the table, RLS and
      // grants the Supabase API source above talks to. Without it the feature
      // targets a table that doesn't exist.
      if (httpClient == 'supabase' && hasHttpClient && projectRoot != null) {
        final dir = '$projectRoot/supabase/migrations';
        final name = SupabaseTemplates.migrationFileName(
          _freeMigrationTime(dir, migrationTime ?? DateTime.now()),
          table,
        );
        await _write(
          '$dir/$name',
          SupabaseTemplates.migration(
            featureName: featureName,
            fields: resolved,
            tableName: table,
            ownedByUser: ownedByUser,
            hasAuth: hasAuth,
            references: foreignKeys,
          ),
        );
      }

      // domain/repositories — skipped entirely with no data source: an
      // interface with no implementation behind it would be dead code.
      if (hasAnyDataSource) {
        await _write(
          '$domainBase/repositories/i_${featureName}_repository.dart',
          DomainTemplates.featureIRepository(
            featureName: featureName,
            packageName: packageName,
            hasHttpClient: hasHttpClient,
            offlineFirst: offlineFirst,
            realtime: remoteLive,
            localWatch: localFirst,
            corePackageName: corePackageName,
          ),
        );
      }

      // domain/usecases — same reasoning: a usecase needs a repository to call.
      if (includeUseCases && hasAnyDataSource) {
        await _write(
          '$domainBase/usecases/get_${featureName}_usecase.dart',
          DomainTemplates.featureGetUsecase(
            featureName: featureName,
            packageName: packageName,
            offlineFirst: offlineFirst,
            corePackageName: corePackageName,
          ),
        );
        if (hasHttpClient) {
          await _write(
            '$domainBase/usecases/${featureName}_crud_usecases.dart',
            DomainTemplates.featureCrudUsecases(
              featureName: featureName,
              packageName: packageName,
              corePackageName: corePackageName,
            ),
          );
        }
      }

      // data/models — no repository means nothing (de)serializes JSON, so
      // there's nothing for a Model to do.
      if (hasAnyDataSource) {
        await _write(
          '$dataBase/models/${featureName}_model.dart',
          DataTemplates.featureModel(
            featureName: featureName,
            hasFreezed: hasFreezed,
            hasJsonSerializable: hasJsonSerializable,
            fields: resolved,
            domainCross: domainCross,
            listEnvelopeKey: listEnvelopeKey,
            envelopeFields: envelopeFields,
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
            realtime: remoteLive,
            localWatch: localFirst,
            fields: resolved,
            apiPath: apiPath,
            tableName: tableName,
            corePackageName: corePackageName,
            domainCross: domainCross,
            customizeEndpoints: customizeEndpoints,
            endpointOverrides: endpointOverrides,
            listEnvelopeKey: listEnvelopeKey,
          ),
        );
      }
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
            corePackageName: corePackageName,
            domainCross: domainCross,
            listEnvelopeKey: listEnvelopeKey,
            apiPath: apiPath,
            tableName: tableName,
            realtime: liveList && localFirst,
            dependsOn: syncDependsOn,
          ),
        );
      }

      // data/sources
      if (hasHttpClient) {
        await _write(
          '$dataBase/sources/${featureName}_api_source.dart',
          DataTemplates.featureApiSource(
            featureName: featureName,
            httpClient: httpClient,
            realtime: liveList,
            apiPath: apiPath,
            tableName: tableName,
            customizeEndpoints: customizeEndpoints,
            endpointOverrides: endpointOverrides,
            listEnvelopeKey: listEnvelopeKey,
          ),
        );
      }
      if (writeLocal) {
        await _write(
          '$dataBase/sources/${featureName}_local_source.dart',
          DataTemplates.featureLocalSource(
            featureName: featureName,
            offlineFirst: localIsDrift,
            hasSync: hasSync,
            localStoragePackage: localStoragePackage,
            fields: resolved,
          ),
        );
      }
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
        fields: resolved,
        includeCrudUi: includeCrudUi,
        corePackageName: corePackageName,
        domainCross: domainCross,
        localFirst: localFirst && dataList,
      ),
    );

    // presentation/providers or bloc/cubit
    if (hasRiverpod) {
      await _write(
        '$presentationBase/providers/${featureName}_provider.dart',
        PresentationTemplates.featureProvider(
          featureName: featureName,
          useAnnotations: useAnnotations,
          dataList: dataList,
          realtime: remoteLive,
          includeCrudUi: includeCrudUi,
          fields: resolved,
          domainCross: domainCross,
          dataCross: dataCross,
          localFirst: localFirst,
        ),
      );
      // Usecase-level DI wires the usecases to the repository → only emit it
      // when both exist. The repository-level providers it depends on
      // (ApiSource/LocalSource/Repository/Sync) live in data/, written above.
      // Custom-endpoints features have no repository (and their own usecases
      // call the ApiSource directly, wired by the caller) — never this file.
      if (!useCustomEndpoints &&
          useAnnotations &&
          hasHttpClient &&
          includeUseCases) {
        await _write(
          '$presentationBase/providers/${featureName}_usecase_providers.dart',
          PresentationTemplates.featureUsecaseProviders(
            featureName: featureName,
            domainCross: domainCross,
            dataCross: dataCross,
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
        CoreTemplates.featureRoutes(
          packageName: packageName,
          featureName: featureName,
          corePackageName: corePackageName,
        ),
      );
    } else if (hasGoRouter) {
      await _write(
        '$presentationBase/routes/${featureName}_route.dart',
        PresentationTemplates.featureRoute(
          featureName: featureName,
          useBuilder: false,
        ),
      );
    }

    // presentation/routes/<f>_shell_registration.dart — packageSplit shell
    // self-registration (see needsShellRegistration's doc). Additive: never
    // interacts with the routes-file gate just above.
    if (needsShellRegistration && packageSplit && corePackageName != null) {
      await _write(
        '$presentationBase/routes/${featureName}_shell_registration.dart',
        PresentationTemplates.featureShellRegistration(
          featureName: featureName,
          corePackageName: corePackageName,
        ),
      );
    }

    // presentation/widgets
    await _write('$presentationBase/widgets/.gitkeep', '');

    // Mirror test structure
    if (mirrorTestStructure) {
      await _write(
        '${domainBase.replaceFirst('/lib/', '/test/')}/.gitkeep',
        '',
      );
      await _write('${dataBase.replaceFirst('/lib/', '/test/')}/.gitkeep', '');
      await _write(
        '${presentationBase.replaceFirst('/lib/', '/test/')}/.gitkeep',
        '',
      );
    }

    // The offline-first repository's contract as an executable test (Drift
    // in memory + a fake remote). Only dio / supabase / firebase API sources
    // are concrete classes a test can fake — a chopper one extends
    // `ChopperService`, so it isn't shipped there.
    if (projectRoot != null &&
        localFirst &&
        !useCustomEndpoints &&
        httpClient != 'chopper' &&
        domainBase.startsWith('$projectRoot/') &&
        dataBase.startsWith('$projectRoot/')) {
      final dataUri = _packageUri(projectRoot, dataBase, packageName);
      final testDir = '$projectRoot/test';
      await _write(
        mirrorTestStructure
            ? '$testDir/${_testMirrorPath(projectRoot, dataBase)}'
                  '/repositories/${featureName}_repository_impl_test.dart'
            : '$testDir/$featureName/${featureName}_offline_first_test.dart',
        OfflineTestTemplates.offlineFirstRepositoryTest(
          featureName: featureName,
          corePackage: corePackageName ?? packageName,
          localStoragePackage: localStoragePackage,
          dataImport: dataUri,
          domainImport: _packageUri(projectRoot, domainBase, packageName),
          httpClient: httpClient,
          fields: resolved,
          apiPath: apiPath,
          tableName: tableName,
          realtime: liveList,
        ),
      );
    }
  }

  /// The first second at or after [wanted] with no migration file already
  /// carrying that timestamp: the Supabase CLI keys migrations by it, so two
  /// files sharing one would fail `supabase db push`.
  static DateTime _freeMigrationTime(String dir, DateTime wanted) {
    final folder = Directory(dir);
    final taken = folder.existsSync()
        ? folder.listSync().map((e) => e.uri.pathSegments.last).toList()
        : const <String>[];
    var t = wanted.toUtc();
    bool used(DateTime d) {
      final stamp = SupabaseTemplates.migrationFileName(d, '').split('_').first;
      return taken.any((f) => f.startsWith('${stamp}_'));
    }

    while (used(t)) {
      t = t.add(const Duration(seconds: 1));
    }
    return t;
  }

  /// `package:` URI of a directory under the project root: a path inside
  /// `packages/<pkg>/lib/` becomes `package:<pkg>/…`, one inside `lib/`
  /// becomes `package:<app>/…`.
  static String _packageUri(
    String projectRoot,
    String absDir,
    String appPackage,
  ) {
    final parts = absDir.substring(projectRoot.length + 1).split('/');
    return parts.first == 'packages'
        ? 'package:${parts[1]}/${parts.skip(3).join('/')}'
        : 'package:$appPackage/${parts.skip(1).join('/')}';
  }

  /// Where a root `test/` file mirrors [absDir]'s `lib/` path: a split
  /// feature's tests sit under its package name (`test/home/data/…`), an app
  /// feature's under `lib/`'s own layout (`test/features/home/data/…`).
  static String _testMirrorPath(String projectRoot, String absDir) {
    final parts = absDir.substring(projectRoot.length + 1).split('/');
    return parts.first == 'packages'
        ? '${parts[1]}/${parts.skip(3).join('/')}'
        : parts.skip(1).join('/');
  }

  Future<void> _write(String path, String content) async {
    final file = File(path);
    await file.create(recursive: true);
    await file.writeAsString(content);
  }
}
