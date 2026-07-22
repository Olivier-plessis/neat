import 'package:flutter_test/flutter_test.dart';
import 'package:neat/features/feature_gen/domain/usecases/generate_feature_usecase.dart';

/// Projects generated before NEAT's anchor system lack the `// neat:` markers,
/// so feature-gen insertions silently no-op. These verify the self-healers add
/// the anchors to the *exact* legacy formats (taken from a real pre-anchor
/// project) so subsequent wiring works.
void main() {
  group('AppRoutePath', () {
    // Exact legacy format (no // neat:routes anchor).
    const legacy = '''class AppRoutePath {
  AppRoutePath._();

  /// First feature — app entry point.
  static const String home = '/';
}
''';

    test('adds // neat:routes before the closing brace', () {
      final healed = GenerateFeatureUsecase.healRoutePathAnchor(legacy);
      expect(healed, contains('// neat:routes'));
      // Anchor sits inside the class, after the last constant.
      final anchorIdx = healed.indexOf('// neat:routes');
      final homeIdx = healed.indexOf('static const String home');
      final braceIdx = healed.lastIndexOf('}');
      expect(homeIdx, lessThan(anchorIdx));
      expect(anchorIdx, lessThan(braceIdx));
    });

    test('is idempotent (already-anchored stays unchanged)', () {
      final once = GenerateFeatureUsecase.healRoutePathAnchor(legacy);
      final twice = GenerateFeatureUsecase.healRoutePathAnchor(once);
      expect(twice, once);
      expect('// neat:routes'.allMatches(twice).length, 1);
    });
  });

  group('routes.dart (builder aggregator)', () {
    // Exact legacy format: single-line list, no anchors.
    const legacy = r'''import 'package:go_router/go_router.dart';
import 'package:tot/features/home/presentation/routes/home_routes.dart' as home;

/// Aggregated app routes.
final List<RouteBase> appRoutes = [...home.$appRoutes];
''';

    test('adds both anchors and normalises the list', () {
      final healed = GenerateFeatureUsecase.healRoutesAnchors(legacy);
      expect(healed, contains('// neat:route-imports'));
      expect(healed, contains('// neat:route-entries'));
      // Existing spread preserved + given a trailing comma.
      expect(healed, contains(r'...home.$appRoutes,'));
      // import anchor sits after the last import.
      final importIdx = healed.indexOf('as home;');
      final importAnchorIdx = healed.indexOf('// neat:route-imports');
      expect(importIdx, lessThan(importAnchorIdx));
      // entries anchor sits inside the list, before the closing bracket.
      final entriesIdx = healed.indexOf('// neat:route-entries');
      final closeIdx = healed.indexOf('];');
      expect(entriesIdx, lessThan(closeIdx));
    });

    test('healed file accepts a normal feature insertion', () {
      final healed = GenerateFeatureUsecase.healRoutesAnchors(legacy);
      // Simulate what _wireRoutes(builder) does at the anchors.
      expect(healed, contains('// neat:route-entries'));
      expect(healed, contains('// neat:route-imports'));
      // Re-healing is a no-op (idempotent).
      expect(GenerateFeatureUsecase.healRoutesAnchors(healed), healed);
    });
  });

  group('routes.dart (plain, multi-line list)', () {
    const legacy = r'''import 'package:go_router/go_router.dart';
import 'package:tot/core/constants/app_route_path.dart';
import 'package:tot/features/home/presentation/pages/home_page.dart';

final List<RouteBase> appRoutes = [
  GoRoute(
    path: AppRoutePath.home,
    builder: (context, state) => const HomePage(),
  ),
];
''';

    test('adds anchors without breaking the existing GoRoute', () {
      final healed = GenerateFeatureUsecase.healRoutesAnchors(legacy);
      expect(healed, contains('// neat:route-imports'));
      expect(healed, contains('// neat:route-entries'));
      expect(healed, contains('path: AppRoutePath.home'));
      expect(healed, contains('const HomePage()'));
      // The entries anchor comes after the existing route, before the close.
      final routeIdx = healed.indexOf('GoRoute(');
      final entriesIdx = healed.indexOf('// neat:route-entries');
      expect(routeIdx, lessThan(entriesIdx));
    });
  });

  group('database.dart migration strategy', () {
    // Exact legacy format: no MigrationStrategy getter (predates the fix for
    // the real bug found via a device log — a table added later never got
    // created on a device that already had the app installed, since Drift
    // only runs onCreate on a brand-new db file).
    const legacy = '''class AppDatabase extends _\$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _open());

  @override
  int get schemaVersion => 1;

  // ── home CRUD ───────────────────────────────────────────────────────────

  Future<List<HomeRow>> getAllHomes() => select(homeRows).get();

  // neat:daos — feature DAOs are inserted above this line.

  static QueryExecutor _open() => driftDatabase(name: 'app_db');
}
''';

    test('currentSchemaVersion reads the getter', () {
      expect(GenerateFeatureUsecase.currentSchemaVersion(legacy), 1);
    });

    test('ensureMigrationStrategy adds the getter + anchor after schemaVersion', () {
      final healed = GenerateFeatureUsecase.ensureMigrationStrategy(legacy);
      expect(healed, contains('MigrationStrategy get migration'));
      expect(healed, contains('// neat:migrations'));
      expect(healed, contains('onCreate: (m) => m.createAll(),'));
      final schemaIdx = healed.indexOf('int get schemaVersion => 1;');
      final migrationIdx = healed.indexOf('MigrationStrategy get migration');
      final daoIdx = healed.indexOf('getAllHomes');
      expect(schemaIdx, lessThan(migrationIdx));
      expect(migrationIdx, lessThan(daoIdx));
    });

    test('ensureMigrationStrategy is idempotent (already-anchored stays unchanged)', () {
      final once = GenerateFeatureUsecase.ensureMigrationStrategy(legacy);
      final twice = GenerateFeatureUsecase.ensureMigrationStrategy(once);
      expect(twice, once);
      expect('MigrationStrategy get migration'.allMatches(twice).length, 1);
    });
  });

  group('bootstrap.dart chopper-register anchors', () {
    // Real bug, found via a real generated project: `AppTemplates.bootstrap`
    // only seeds `// neat:chopper-register-imports`/`-calls` when the
    // wizard's own first feature already uses chopper — a project launched
    // with zero features (generateFirstFeature: false, a fully valid, common
    // combo, not a legacy one) never had them. The Workshop's first chopper
    // feature then silently no-op'd its own registration insert, leaving
    // `register<Feature>ChopperDecoders()` generated but never called.
    // Exact shape taken from a real such project (shell-register anchors
    // present — that one self-heals already — chopper-register absent).
    const noAnchors = '''import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:arth/app.dart';
import 'package:core/core/utils/app_logger.dart';
import 'package:arth/core/observers/provider_observer.dart';

Future<void> bootstrap() async {
  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      registerErrorHandler();
      final container = ProviderContainer(observers: [RiverpodObserver()]);
      runApp(
        UncontrolledProviderScope(container: container, child: const App()),
      );
    },
    (error, stack) =>
        AppLogger.f('Uncaught exception', error: error, stackTrace: stack),
  );
}
''';

    test('adds both anchors, imports anchor after the last import, calls '
        'anchor right before registerErrorHandler()', () {
      final healed = GenerateFeatureUsecase.healBootstrapChopperAnchors(noAnchors);
      expect(healed, contains('// neat:chopper-register-imports'));
      expect(healed, contains('// neat:chopper-register-calls'));

      final lastImportIdx = healed.lastIndexOf(
        "import 'package:arth/core/observers/provider_observer.dart';",
      );
      final importAnchorIdx = healed.indexOf('// neat:chopper-register-imports');
      expect(lastImportIdx, lessThan(importAnchorIdx));

      final callsAnchorIdx = healed.indexOf('// neat:chopper-register-calls');
      final registerErrorIdx = healed.indexOf('registerErrorHandler();');
      expect(callsAnchorIdx, lessThan(registerErrorIdx));
    });

    test('is idempotent (already-anchored stays unchanged)', () {
      final once = GenerateFeatureUsecase.healBootstrapChopperAnchors(noAnchors);
      final twice = GenerateFeatureUsecase.healBootstrapChopperAnchors(once);
      expect(twice, once);
      expect('// neat:chopper-register-imports'.allMatches(twice).length, 1);
      expect('// neat:chopper-register-calls'.allMatches(twice).length, 1);
    });

    test('a bootstrap.dart that already has the anchors (the wizard\'s own '
        'first chopper feature) is left untouched', () {
      const alreadyAnchored = '''import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:home/data/repositories/home_repository_providers.dart';
// neat:chopper-register-imports

Future<void> bootstrap() async {
  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      registerHomeChopperDecoders();
      // neat:chopper-register-calls
      registerErrorHandler();
      runApp(const App());
    },
    (error, stack) => AppLogger.f('Uncaught exception', error: error, stackTrace: stack),
  );
}
''';
      expect(
        GenerateFeatureUsecase.healBootstrapChopperAnchors(alreadyAnchored),
        alreadyAnchored,
      );
    });
  });
}
