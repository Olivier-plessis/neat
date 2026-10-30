import 'package:flutter_test/flutter_test.dart';
import 'package:neat/core/contract/neat_contract.dart';
import 'package:neat/features/generation/domain/services/templates/agents_md_template.dart';

/// The whole point of NEAT's AGENTS.md is **accuracy**: it must describe exactly
/// the project's stack (from `.neat.json`) with no generic template bleed.
void main() {
  test('full stack: mentions the exact stack + the NEAT anchors, no bleed', () {
    const c = NeatContract(
      projectName: 'shop',
      architecture: 'feature_first',
      stateManagement: 'riverpod',
      navigation: 'go_router_builder',
      httpClient: 'chopper',
      themeApproach: 'customM3',
      storageStrategy: 'offlineFirstSync',
      hasEnvied: true,
      hasFreezed: true,
      hasJsonSerializable: true,
      useNavigationShell: true,
    );
    final md = AgentsMdTemplate.generate(c);

    // Accurate to the chosen stack.
    expect(md, contains('chopperClientProvider'));
    expect(md, contains('go_router_builder'));
    expect(md, contains('TypedGoRoute'));
    expect(md, contains('StatefulShellRoute'));
    expect(md, contains('packages/shop_database'));
    expect(md, contains('Outbox'));
    expect(md, contains('SyncService'));
    expect(md, contains('infrastructure_providers.dart'));
    expect(md, contains('envied'));
    // The unique part: the anchor system + Workshop.
    expect(md, contains('// neat:route-entries'));
    expect(md, contains('// neat:table-imports'));
    expect(md, contains('NEAT Workshop'));
    // Codegen commands are accurate (this stack DOES use build_runner).
    expect(md, contains('dart run build_runner build'));

    // No bleed: it must NOT mention the *other* http client…
    expect(md, isNot(contains('dioProvider')));
    // …nor things NEAT never generates (the failure mode of generic AI-rules files).
    expect(md, isNot(contains('MobX')));
    expect(md, isNot(contains('Hive')));
  });

  test(
    'minimal remote-only stack: omits offline/shell/builder sections entirely',
    () {
      const c = NeatContract(
        projectName: 'blog',
        architecture: 'feature_first',
        stateManagement: 'riverpod',
        navigation: 'go_router',
        httpClient: 'dio',
        themeApproach: 'none',
        storageStrategy: 'remoteOnly',
      );
      final md = AgentsMdTemplate.generate(c);

      expect(md, contains('dioProvider'));
      expect(md, contains('// neat:route-entries'));

      // None of the features it doesn't have should appear.
      expect(md, isNot(contains('go_router_builder')));
      expect(md, isNot(contains('TypedGoRoute')));
      expect(md, isNot(contains('Drift')));
      expect(md, isNot(contains('Outbox')));
      expect(md, isNot(contains('app_shell')));
      expect(md, isNot(contains('infrastructure_providers')));
      expect(md, isNot(contains('chopperClientProvider')));
      expect(md, isNot(contains('envied')));
      expect(md, isNot(contains('MobX')));
      expect(md, isNot(contains('Hive')));
    },
  );

  test('no remote source: networking section says so, no client provider', () {
    const c = NeatContract(
      projectName: 'notes',
      architecture: 'feature_first',
      stateManagement: 'riverpod',
      navigation: 'go_router',
      httpClient: 'none',
      themeApproach: 'customM3',
      storageStrategy: 'offlineFirstRead',
    );
    final md = AgentsMdTemplate.generate(c);

    expect(md, isNot(contains('dioProvider')));
    expect(md, isNot(contains('chopperClientProvider')));
    expect(md, contains('No HTTP client is enabled'));
    // Offline read but NOT sync → no Outbox.
    expect(md, contains('packages/notes_database'));
    expect(md, isNot(contains('Outbox')));
  });

  group('packageSplit: the paths are the ones the generator writes', () {
    const split = NeatContract(
      projectName: 'shop',
      architecture: 'feature_first',
      stateManagement: 'riverpod',
      navigation: 'go_router_builder',
      httpClient: 'supabase',
      themeApproach: 'customM3',
      storageStrategy: 'offlineFirstSync',
      extractUiPackage: true,
      hasEnvied: true,
      generateAuth: true,
      generateI18n: true,
      generateOnboarding: true,
      generateStorage: true,
      packageSplit: true,
    );
    final md = AgentsMdTemplate.generate(split);

    test('a feature is a package, not a folder under lib/features', () {
      expect(
        md,
        contains('## Architecture (feature-first, one package per feature)'),
      );
      expect(md, contains('packages/<feature>/lib/\n'));
      expect(md, isNot(contains('lib/features/<feature>')));
      expect(md, contains('A feature never lives under `lib/features/`'));
      expect(md, contains('**A feature package depends on `core`'));
      expect(md, contains('| `packages/<feature>/**` |'));
      expect(md, contains('`packages/auth`'));
      expect(md, isNot(contains('features/auth')));
    });

    test('the shared base is read from the core package', () {
      for (final path in [
        'core/result/result.dart',
        'core/usecases/use_case.dart',
        'core/constants/app_route_path.dart',
        'core/network/supabase_provider.dart',
        'core/providers/infrastructure_providers.dart',
        'core/sync/sync_service.dart',
        'core/i18n/locale_store.dart',
        'i18n/strings.g.dart',
      ]) {
        expect(md, contains('`packages/core/lib/$path`'), reason: path);
      }
      // No mention of those folders as if they were in the app's own lib/.
      final misplaced = RegExp(
        r'(?<!packages/core/)lib/(core/(result|usecases|network|constants|providers|sync|i18n)|i18n)/',
      );
      expect(misplaced.allMatches(md).map((m) => m.group(0)), isEmpty);
    });

    test('the paragraph names only the pieces the project has', () {
      expect(
        md,
        contains(
          '(`Result`, `UseCase`, `AppRoutePath`, the network client, the '
          'sync engine, the translations)',
        ),
      );
    });

    test('what stays in the app is still named as the app\'s', () {
      expect(md, contains('`lib/core/router/routes.dart`'));
      expect(md, contains('`lib/core/bootstrap.dart`'));
      expect(md, contains('`lib/core/storage/storage_service.dart`'));
      expect(md, contains('`lib/core/onboarding/onboarding_page.dart`'));
      expect(md, contains('→ `lib/core/env/`'));
    });

    test('the tree says what the core package and the app each hold', () {
      expect(
        md,
        contains(
          'packages/core/lib/core/  # result, usecases, network, sync, '
          'providers, i18n, theme mode',
        ),
      );
      expect(
        md,
        contains(
          'lib/core/                # the app: bootstrap, router, env, '
          'onboarding, storage',
        ),
      );
    });

    test('translations are regenerated inside the core package', () {
      expect(md, contains('`dart run slang` **inside `packages/core`**'));
      expect(md, contains('`packages/core/lib/i18n/`'));
    });

    test('adding a feature by hand means a package in the workspace', () {
      expect(md, contains('Mirror an existing feature package'));
      expect(md, contains('`resolution: workspace`'));
      expect(md, contains('under `workspace:` and `dependencies:`'));
    });

    test('the visual system is the UI package, codegen is per package', () {
      expect(md, contains('| `packages/shop_ui/**` | Visual system |'));
      expect(md, isNot(contains('`lib/core/theme/**`')));
      expect(md, contains('# build_runner runs per package'));
      expect(
        md,
        contains(
          '# (packages/<feature>, packages/core, packages/shop_database)',
        ),
      );
    });

    test('a Firebase project finds its provider in the core package', () {
      final firebase = AgentsMdTemplate.generate(
        split.copyWith(httpClient: 'firebase'),
      );
      expect(
        firebase,
        contains('`packages/core/lib/core/network/firebase_provider.dart`'),
      );
      expect(firebase, isNot(contains('`lib/core/network/firebase_provider')));
    });

    test('a leaner split project only lists what it has', () {
      final lean = AgentsMdTemplate.generate(
        const NeatContract(
          projectName: 'blog',
          architecture: 'feature_first',
          stateManagement: 'riverpod',
          navigation: 'go_router',
          httpClient: 'dio',
          themeApproach: 'customM3',
          storageStrategy: 'remoteOnly',
          packageSplit: true,
        ),
      );
      expect(
        lean,
        contains(
          'packages/core/lib/core/  # result, usecases, network, theme mode',
        ),
      );
      expect(
        lean,
        contains('lib/core/                # the app: bootstrap, router'),
      );
      expect(
        lean,
        contains('(`Result`, `UseCase`, `AppRoutePath`, the network client)'),
      );
      expect(lean, contains('`packages/core/lib/core/network/`'));
      expect(lean, isNot(contains('SyncService')));
      expect(lean, isNot(contains('strings.g.dart')));
      expect(lean, isNot(contains('lib/core/onboarding')));
      expect(lean, isNot(contains('packages/blog_database')));
    });
  });

  group('a flat project keeps its lib/ paths', () {
    const flat = NeatContract(
      projectName: 'shop',
      architecture: 'feature_first',
      stateManagement: 'riverpod',
      navigation: 'go_router_builder',
      httpClient: 'supabase',
      themeApproach: 'customM3',
      storageStrategy: 'offlineFirstSync',
      generateAuth: true,
      generateI18n: true,
    );
    final md = AgentsMdTemplate.generate(flat);

    test('features, core and translations live under lib/', () {
      expect(md, contains('## Architecture (feature-first)\n'));
      expect(md, contains('lib/features/<feature>/\n'));
      expect(md, contains('`lib/core/result/result.dart`'));
      expect(md, contains('`lib/core/usecases/use_case.dart`'));
      expect(md, contains('`lib/core/constants/app_route_path.dart`'));
      expect(md, contains('`lib/core/network/supabase_provider.dart`'));
      expect(md, contains('`lib/i18n/strings.g.dart`'));
      expect(md, contains('`features/auth`'));
      expect(md, contains('Mirror an existing feature under'));
      expect(md, contains('| `lib/features/<feature>/**` |'));
      expect(md, isNot(contains('packages/core')));
      expect(md, isNot(contains('one package per feature')));
      expect(md, isNot(contains('inside `packages/core`')));
      expect(md, isNot(contains('# build_runner runs per package')));
    });

    test(
      'the visual system is lib/core/theme, or the UI package once extracted',
      () {
        expect(md, contains('| `lib/core/theme/**` | Visual system |'));
        final extracted = AgentsMdTemplate.generate(
          flat.copyWith(extractUiPackage: true),
        );
        expect(
          extracted,
          contains('| `packages/shop_ui/**` | Visual system |'),
        );
        expect(extracted, isNot(contains('`lib/core/theme/**`')));
      },
    );
  });
}
