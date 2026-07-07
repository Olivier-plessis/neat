import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:neat/features/dependencies/domain/constants/backend_presets.dart';
import 'package:neat/features/dependencies/domain/models/pub_package.dart';
import 'package:neat/features/dependencies/presentation/providers/dependencies_provider.dart';

void main() {
  group('backendOf', () {
    PubPackage pkg(String n) => PubPackage(name: n, version: '1.0.0', description: '');

    test('detects firebase, supabase, else rest', () {
      expect(backendOf([pkg('cloud_firestore')]), BackendKind.firebase);
      expect(backendOf([pkg('supabase_flutter')]), BackendKind.supabase);
      expect(backendOf([pkg('chopper')]), BackendKind.rest);
      expect(backendOf([]), BackendKind.rest);
    });

    test('firebase wins over supabase if both somehow present', () {
      expect(backendOf([pkg('supabase_flutter'), pkg('cloud_firestore')]), BackendKind.firebase);
    });
  });

  group('applyBackendPreset (manifest stays source of truth)', () {
    late ProviderContainer container;
    SelectedPackages notifier() => container.read(selectedPackagesProvider.notifier);
    List<String> names() =>
        container.read(selectedPackagesProvider).map((p) => p.name).toList();

    setUp(() => container = ProviderContainer());
    tearDown(() => container.dispose());

    test('REST preset adds chopper, no backend SDK', () {
      notifier().applyBackendPreset(presetFor(BackendKind.rest));
      expect(names(), contains('chopper'));
      expect(names(), isNot(contains('supabase_flutter')));
      expect(names(), isNot(contains('cloud_firestore')));
    });

    test('switching backends swaps the client and strips the previous one', () {
      notifier().applyBackendPreset(presetFor(BackendKind.rest));
      notifier().applyBackendPreset(presetFor(BackendKind.supabase));
      expect(names(), contains('supabase_flutter'));
      expect(names(), isNot(contains('chopper')));

      notifier().applyBackendPreset(presetFor(BackendKind.firebase));
      expect(names(), contains('cloud_firestore'));
      expect(names(), contains('firebase_core'));
      expect(names(), isNot(contains('supabase_flutter')));
    });

    test('keeps non-backend packages the user added when switching', () {
      notifier().applyBackendPreset(presetFor(BackendKind.rest));
      notifier().addAll([const PubPackage(name: 'flutter_svg', version: '2.0.0', description: '')]);
      notifier().applyBackendPreset(presetFor(BackendKind.firebase));
      expect(names(), contains('flutter_svg'));
      expect(names(), contains('cloud_firestore'));
    });
  });

  group('httpClientOf', () {
    PubPackage pkg(String n) => PubPackage(name: n, version: '1.0.0', description: '');

    test('detects dio, else defaults to chopper', () {
      expect(httpClientOf([pkg('dio')]), HttpClientKind.dio);
      expect(httpClientOf([pkg('chopper')]), HttpClientKind.chopper);
      expect(httpClientOf([]), HttpClientKind.chopper);
    });
  });

  group('applyHttpClientPreset (Infrastructure screen\'s client picker)', () {
    late ProviderContainer container;
    SelectedPackages notifier() => container.read(selectedPackagesProvider.notifier);
    List<String> names() =>
        container.read(selectedPackagesProvider).map((p) => p.name).toList();

    setUp(() => container = ProviderContainer());
    tearDown(() => container.dispose());

    test('switching to dio strips chopper, keeps the shared core packages', () {
      notifier().applyBackendPreset(presetFor(BackendKind.rest));
      notifier().applyHttpClientPreset(presetForHttpClient(HttpClientKind.dio));
      expect(names(), contains('dio'));
      expect(names(), isNot(contains('chopper')));
      expect(names(), isNot(contains('chopper_generator')));
      expect(names(), contains('hooks_riverpod'), reason: 'core packages stay untouched');
      expect(names(), contains('go_router'), reason: 'core packages stay untouched');
    });

    test('switching back to chopper strips dio', () {
      notifier().applyHttpClientPreset(presetForHttpClient(HttpClientKind.dio));
      notifier().applyHttpClientPreset(presetForHttpClient(HttpClientKind.chopper));
      expect(names(), contains('chopper'));
      expect(names(), isNot(contains('dio')));
    });
  });

  group('routingStyleOf', () {
    PubPackage pkg(String n) => PubPackage(name: n, version: '1.0.0', description: '');

    test('typed when go_router_builder is present, else manual by default', () {
      expect(routingStyleOf([pkg('go_router_builder')]), RoutingStyle.typed);
      expect(routingStyleOf([pkg('go_router')]), RoutingStyle.manual);
      expect(routingStyleOf([]), RoutingStyle.manual);
    });

    test('go_router_builder is not bundled into any default preset', () {
      // Regression: it used to live in _corePackages, so every preset always
      // carried it — packageSplit (which requires manual routing) could then
      // never be reached without the user manually deleting the package.
      for (final preset in [restPreset, supabasePreset, firebasePreset, dioPreset]) {
        expect(preset.map((p) => p.name), isNot(contains('go_router_builder')));
      }
    });
  });

  group('setRoutingStyle (Infrastructure screen\'s routing picker)', () {
    late ProviderContainer container;
    SelectedPackages notifier() => container.read(selectedPackagesProvider.notifier);
    List<String> names() =>
        container.read(selectedPackagesProvider).map((p) => p.name).toList();

    setUp(() => container = ProviderContainer());
    tearDown(() => container.dispose());

    test('defaults to manual — no go_router_builder out of the box', () {
      expect(names(), isNot(contains('go_router_builder')));
    });

    test('typed adds go_router_builder, manual removes it', () {
      notifier().setRoutingStyle(RoutingStyle.typed);
      expect(names(), contains('go_router_builder'));

      notifier().setRoutingStyle(RoutingStyle.manual);
      expect(names(), isNot(contains('go_router_builder')));
    });

    test('re-applying the current style is a no-op (idempotent)', () {
      notifier().setRoutingStyle(RoutingStyle.typed);
      notifier().setRoutingStyle(RoutingStyle.typed);
      expect(names().where((n) => n == 'go_router_builder').length, 1);
    });

    test('switching HTTP client keeps the routing style untouched', () {
      notifier().setRoutingStyle(RoutingStyle.typed);
      notifier().applyHttpClientPreset(presetForHttpClient(HttpClientKind.dio));
      expect(names(), contains('go_router_builder'),
          reason: 'routing style is orthogonal to the HTTP client preset swap');
    });
  });
}
