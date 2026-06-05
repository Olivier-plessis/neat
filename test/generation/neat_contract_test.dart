import 'package:flutter_test/flutter_test.dart';
import 'package:neat/core/contract/neat_contract.dart';

void main() {
  group('NeatContract', () {
    const contract = NeatContract(
      projectName: 'my_app',
      architecture: 'feature_first',
      stateManagement: 'riverpod',
      navigation: 'go_router_builder',
      httpClient: 'chopper',
      themeApproach: 'customM3',
      storageStrategy: 'offlineFirstSync',
      extractUiPackage: true,
      useScreenUtil: true,
      hasEnvied: true,
      components: ['button', 'card'],
    );

    test('round-trips through JSON', () {
      final restored = NeatContract.fromJson(contract.toJson());
      expect(restored, contract);
    });

    test('defaults schemaVersion to 1', () {
      expect(contract.schemaVersion, 1);
    });

    test('reads a hand-written contract', () {
      final json = {
        'projectName': 'demo',
        'architecture': 'feature_first',
        'stateManagement': 'riverpod',
        'navigation': 'go_router',
        'httpClient': 'dio',
        'themeApproach': 'flexColorScheme',
        'storageStrategy': 'remoteOnly',
      };
      final c = NeatContract.fromJson(json);
      expect(c.httpClient, 'dio');
      expect(c.themeApproach, 'flexColorScheme');
      // Missing optionals fall back to defaults.
      expect(c.useRiverpodAnnotations, isTrue);
      expect(c.extractUiPackage, isFalse);
      expect(c.components, isEmpty);
    });
  });
}
