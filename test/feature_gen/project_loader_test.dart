import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:neat/core/contract/neat_contract.dart';
import 'package:neat/features/feature_gen/domain/services/project_loader.dart';

void main() {
  late Directory tempRoot;
  const loader = ProjectLoader();

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('neat_loader_');
  });

  tearDown(() async {
    if (tempRoot.existsSync()) await tempRoot.delete(recursive: true);
  });

  void writeContract(NeatContract c) {
    File('${tempRoot.path}/.neat.json')
        .writeAsStringSync(jsonEncode(c.toJson()));
  }

  void makeFeatures(List<String> names) {
    for (final n in names) {
      Directory('${tempRoot.path}/lib/features/$n').createSync(recursive: true);
    }
  }

  const contract = NeatContract(
    projectName: 'demo',
    architecture: 'feature_first',
    stateManagement: 'riverpod',
    navigation: 'go_router',
    httpClient: 'chopper',
    themeApproach: 'customM3',
    storageStrategy: 'offlineFirstSync',
  );

  test('loads the contract and lists features from disk (sorted)', () async {
    writeContract(contract);
    makeFeatures(['home', 'auth', 'profile']);

    final project = await loader.load(tempRoot.path);

    expect(project, isNotNull);
    expect(project!.contract.projectName, 'demo');
    expect(project.contract.httpClient, 'chopper');
    expect(project.contract.storageStrategy, 'offlineFirstSync');
    expect(project.features, ['auth', 'home', 'profile']); // sorted, from disk
  });

  test('returns null when there is no .neat.json (not a NEAT project)', () async {
    makeFeatures(['home']);
    expect(await loader.load(tempRoot.path), isNull);
  });

  test('returns null on a malformed contract', () async {
    File('${tempRoot.path}/.neat.json').writeAsStringSync('{ not valid json');
    expect(await loader.load(tempRoot.path), isNull);
  });

  test('no lib/features yet → empty feature list', () async {
    writeContract(contract);
    final project = await loader.load(tempRoot.path);
    expect(project, isNotNull);
    expect(project!.features, isEmpty);
  });

  test('scanFeatures ignores hidden dirs', () async {
    Directory('${tempRoot.path}/lib/features/home').createSync(recursive: true);
    Directory('${tempRoot.path}/lib/features/.DS_cache').createSync(recursive: true);
    expect(loader.scanFeatures(tempRoot.path, contract), ['home']);
  });

  test('packageSplit: scans packages/ for <projectName>_<feature>, excluding core/ui/local_storage',
      () async {
    final split = contract.copyWith(packageSplit: true);
    writeContract(split);
    for (final pkg in ['demo_core', 'demo_local_storage', 'demo_ui', 'demo_home', 'demo_orders']) {
      Directory('${tempRoot.path}/packages/$pkg').createSync(recursive: true);
    }
    final project = await loader.load(tempRoot.path);
    expect(project, isNotNull);
    expect(project!.features, ['home', 'orders']);
  });
}
