import 'package:flutter_test/flutter_test.dart';
import 'package:neat/features/generation/domain/services/templates/core_package_templates.dart';
import 'package:neat/features/generation/domain/services/templates/dart/auth_templates.dart';
import 'package:neat/features/generation/domain/services/templates/dart/core_dart_templates.dart';

/// Real bugs, found via a real generated project's CI pipeline (`flutter
/// analyze` → `dart format` → `flutter test --coverage`). Locally,
/// `depend_on_referenced_packages` / `unnecessary_underscores` are only
/// infos — but the generated CI's `flutter analyze` treats infos as fatal,
/// and `flutter test` fails outright with no `test/` directory.
void main() {
  group('CorePackageTemplates.featurePackagePubspec — declares what it imports', () {
    test('supabase: supabase_flutter, never a stray dio', () {
      final pubspec = CorePackageTemplates.featurePackagePubspec(
        featurePackageName: 'home',
        corePackageName: 'core',
        httpClient: 'supabase',
      );
      expect(pubspec, contains('supabase_flutter:'));
      expect(pubspec, isNot(contains('dio:')));
      expect(pubspec, isNot(contains('flutter_hooks:')));
    });

    test('firebase: cloud_firestore, never a stray dio', () {
      final pubspec = CorePackageTemplates.featurePackagePubspec(
        featurePackageName: 'home',
        corePackageName: 'core',
        httpClient: 'firebase',
      );
      expect(pubspec, contains('cloud_firestore:'));
      expect(pubspec, isNot(contains('firebase_auth:')));
      expect(pubspec, isNot(contains('dio:')));
    });

    test('auth package: flutter_hooks for its HookConsumerWidget screens', () {
      final supabase = CorePackageTemplates.featurePackagePubspec(
        featurePackageName: 'auth',
        corePackageName: 'core',
        httpClient: 'supabase',
        isAuthPackage: true,
      );
      expect(supabase, contains('supabase_flutter:'));
      expect(supabase, contains('flutter_hooks:'));

      final firebase = CorePackageTemplates.featurePackagePubspec(
        featurePackageName: 'auth',
        corePackageName: 'core',
        httpClient: 'firebase',
        isAuthPackage: true,
      );
      expect(firebase, contains('cloud_firestore:'));
      expect(firebase, contains('firebase_auth:'));
      expect(firebase, contains('flutter_hooks:'));
    });

    test('dio / chopper: unchanged', () {
      expect(
        CorePackageTemplates.featurePackagePubspec(
          featurePackageName: 'home',
          corePackageName: 'core',
        ),
        contains('dio:'),
      );
      final chopper = CorePackageTemplates.featurePackagePubspec(
        featurePackageName: 'home',
        corePackageName: 'core',
        httpClient: 'chopper',
      );
      expect(chopper, contains('chopper:'));
      expect(chopper, contains('chopper_generator:'));
      expect(chopper, isNot(contains('dio:')));
    });
  });

  test(
    'CorePackageTemplates.pubspec (firebase): firebase_core, which '
    "core's network_error_handler.dart imports directly",
    () {
      final pubspec = CorePackageTemplates.pubspec(
        corePackageName: 'core',
        httpClient: 'firebase',
      );
      expect(pubspec, contains('firebase_core:'));
      expect(pubspec, contains('cloud_firestore:'));
    },
  );

  test(
    'AuthTemplates.routerNotifier (hasOnboarding): wildcard `(_, _)`, never '
    '`(_, __)` (unnecessary_underscores)',
    () {
      final code = AuthTemplates.routerNotifier(
        packageName: 'demo_app',
        homeRoute: 'AppRoutePath.product',
        hasOnboarding: true,
      );
      expect(code, contains('ref.listen(onboardingSeenProvider, (_, _) =>'));
      expect(code, isNot(contains('__')));
    },
  );

  test('CoreDartTemplates.coreResultTest: a real test of the generated Result', () {
    final code = CoreDartTemplates.coreResultTest(packageName: 'core');
    expect(code, contains("import 'package:flutter_test/flutter_test.dart';"));
    expect(code, contains("import 'package:core/core/result/result.dart';"));
    expect(code, contains("import 'package:core/core/error/failure.dart';"));
    expect(code, contains('Result.success(42)'));
    expect(code, contains('throwsA(same(failure))'));
  });
}
