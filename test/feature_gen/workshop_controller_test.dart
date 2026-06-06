import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:neat/core/contract/neat_contract.dart';
import 'package:neat/features/feature_gen/presentation/providers/workshop_controller.dart';

void main() {
  late Directory tempRoot;

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('neat_workshop_');
  });
  tearDown(() async {
    if (tempRoot.existsSync()) await tempRoot.delete(recursive: true);
  });

  test('openProject loads a NEAT project and exposes its stack + features', () async {
    File('${tempRoot.path}/.neat.json').writeAsStringSync(
      jsonEncode(
        const NeatContract(
          projectName: 'demo',
          architecture: 'feature_first',
          stateManagement: 'riverpod',
          navigation: 'go_router',
          httpClient: 'chopper',
          themeApproach: 'customM3',
          storageStrategy: 'offlineFirstSync',
        ).toJson(),
      ),
    );
    Directory('${tempRoot.path}/lib/features/home').createSync(recursive: true);

    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(workshopControllerProvider.notifier).openProject(tempRoot.path);

    final state = container.read(workshopControllerProvider);
    expect(state.error, isNull);
    expect(state.project, isNotNull);
    expect(state.project!.contract.httpClient, 'chopper');
    expect(state.project!.features, ['home']);
  });

  test('openProject on a non-NEAT folder sets an error, no project', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(workshopControllerProvider.notifier).openProject(tempRoot.path);

    final state = container.read(workshopControllerProvider);
    expect(state.project, isNull);
    expect(state.error, isNotNull);
  });

  test('close() resets the session', () async {
    File('${tempRoot.path}/.neat.json').writeAsStringSync(
      jsonEncode(
        const NeatContract(
          projectName: 'demo',
          architecture: 'feature_first',
          stateManagement: 'riverpod',
          navigation: 'go_router',
          httpClient: 'dio',
          themeApproach: 'none',
          storageStrategy: 'remoteOnly',
        ).toJson(),
      ),
    );

    final container = ProviderContainer();
    addTearDown(container.dispose);
    final ctrl = container.read(workshopControllerProvider.notifier);
    await ctrl.openProject(tempRoot.path);
    expect(container.read(workshopControllerProvider).project, isNotNull);

    ctrl.close();
    expect(container.read(workshopControllerProvider).project, isNull);
  });
}
