import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:neat/features/generation/domain/services/feature_scaffolder.dart';

/// Fast filesystem-level checks that the per-feature layer toggles actually
/// gate which files get scaffolded (no build_runner needed). The integration
/// suite proves the combos compile; this proves the wiring cheaply.
void main() {
  late Directory tmp;
  late String lib;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('neat_scaffold_');
    lib = '${tmp.path}/lib';
  });
  tearDown(() async {
    if (tmp.existsSync()) await tmp.delete(recursive: true);
  });

  bool exists(String rel) => File('$lib/$rel').existsSync();

  Future<void> scaffold({
    required bool hasHttpClient,
    required bool includeLocalSource,
    required bool includeUseCases,
    String? localStoragePackage,
  }) {
    return const FeatureScaffolder().writeFeature(
      lib: lib,
      featureName: 'orders',
      packageName: 'demo',
      isFeatureFirst: true,
      mirrorTestStructure: false,
      hasRiverpod: true,
      hasBloc: false,
      useCubit: false,
      useAnnotations: true,
      hasGoRouter: true,
      hasGoRouterBuilder: false,
      hasHttpClient: hasHttpClient,
      httpClient: hasHttpClient ? 'chopper' : '',
      hasFreezed: true,
      hasJsonSerializable: true,
      localStoragePackage: localStoragePackage,
      includeLocalSource: includeLocalSource,
      includeUseCases: includeUseCases,
    );
  }

  const api = 'features/orders/data/sources/orders_api_source.dart';
  const local = 'features/orders/data/sources/orders_local_source.dart';
  const repo = 'features/orders/data/repositories/orders_repository_impl.dart';
  const getUc = 'features/orders/domain/usecases/get_orders_usecase.dart';
  const crudUc = 'features/orders/domain/usecases/orders_crud_usecases.dart';
  // Split by layer: repository-level DI (ApiSource/LocalSource/Repository/Sync)
  // lives in data/; usecase-level DI (built from the repository provider) is
  // the only DI-graph piece left in presentation/ (see the wesioo-inspired
  // layering fix — presentation never references a concrete Data class).
  const repoProviders = 'features/orders/data/repositories/orders_repository_providers.dart';
  const di = 'features/orders/presentation/providers/orders_usecase_providers.dart';

  test('full feature (offline-first + usecases) scaffolds every layer', () async {
    // Local source is only ever referenced by the offline-first 3-source
    // repository — that requires a Drift-backed project (localStoragePackage),
    // not just includeLocalSource: true on its own (see the test below).
    await scaffold(
      hasHttpClient: true,
      includeLocalSource: true,
      includeUseCases: true,
      localStoragePackage: 'demo_local_storage',
    );
    expect(exists(api), isTrue);
    expect(exists(local), isTrue);
    expect(exists(repo), isTrue);
    expect(exists(getUc), isTrue);
    expect(exists(crudUc), isTrue);
    expect(exists(repoProviders), isTrue);
    expect(exists(di), isTrue);
  });

  test('remote-only feature (no local source) omits the local source', () async {
    await scaffold(hasHttpClient: true, includeLocalSource: false, includeUseCases: true);
    expect(exists(api), isTrue);
    expect(exists(local), isFalse);
    expect(exists(repo), isTrue);
  });

  test(
    'remote-only storage (no Drift package) omits the local source even with '
    'includeLocalSource: true — the remote-only repository never takes one, '
    'so writing it would be dead code',
    () async {
      await scaffold(hasHttpClient: true, includeLocalSource: true, includeUseCases: true);
      expect(exists(api), isTrue);
      expect(exists(local), isFalse);
      expect(exists(repo), isTrue);
    },
  );

  test('local-only feature (no remote) omits the API source & CRUD usecases', () async {
    await scaffold(hasHttpClient: false, includeLocalSource: true, includeUseCases: true);
    expect(exists(api), isFalse);
    expect(exists(local), isTrue, reason: 'a local-only feature always keeps its local source');
    expect(exists(repo), isTrue);
    expect(exists(getUc), isTrue);
    expect(exists(crudUc), isFalse, reason: 'no remote → no write CRUD usecases');
  });

  test('usecases off → no usecase files and no DI graph', () async {
    await scaffold(hasHttpClient: true, includeLocalSource: true, includeUseCases: false);
    expect(exists(getUc), isFalse);
    expect(exists(crudUc), isFalse);
    expect(exists(repoProviders), isFalse,
        reason: 'repository-level DI wires into the usecase graph — skipped when they are off');
    expect(exists(di), isFalse, reason: 'the DI graph wires usecases — skipped when they are off');
  });
}
