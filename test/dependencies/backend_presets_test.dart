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
}
