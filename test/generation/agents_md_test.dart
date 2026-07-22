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

  test('minimal remote-only stack: omits offline/shell/builder sections entirely', () {
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
  });

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
}
