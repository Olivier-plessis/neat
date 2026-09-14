import 'dart:io';

import 'package:neat/features/generation/domain/services/templates/core_package_templates.dart';
import 'package:neat/features/generation/domain/services/templates/dart/auth_templates.dart';
import 'package:neat/features/generation/domain/usecases/writers/generation_io.dart';

/// Writes the opt-in Auth feature (login/signup/forgot-password + the
/// go_router guard) — split out of `LaunchGenerationUsecase` (see
/// ROADMAP.md for the per-domain writer split).
///
/// [authPackageName] set when packageSplit is on: Auth (screens included)
/// becomes its own workspace package (`packages/auth/`, package-root layout
/// like any other split feature) instead of `lib/features/auth/`, depending
/// on [corePackageName] for Result/Failure/UseCase rather than duplicating
/// them the way wesioo's standalone `authentication` package does (see
/// ROADMAP.md §6a).
abstract final class AuthWriter {
  static Future<void> write({
    required Directory projectDir,
    required String lib,
    required String packageName,
    required String featureName,
    String backend = 'supabase',
    bool oauth = false,
    String? corePackageName,
    String? authPackageName,
    bool hasOnboarding = false,
    bool hasFirstFeature = true,
  }) async {
    final a = authPackageName != null
        ? '${projectDir.path}/packages/$authPackageName/lib'
        : '$lib/features/auth';
    if (authPackageName != null) {
      await writeFile(
        '${projectDir.path}/packages/$authPackageName/pubspec.yaml',
        CorePackageTemplates.featurePackagePubspec(
          featurePackageName: authPackageName,
          corePackageName: corePackageName!,
          httpClient: backend,
          hasGoRouterBuilder: true, // generateAuth already requires it
        ),
      );
    }
    await writeFile(
      '$a/domain/repositories/i_auth_repository.dart',
      AuthTemplates.iAuthRepository(
        packageName: packageName,
        oauth: oauth,
        corePackageName: corePackageName,
      ),
    );
    await writeFile(
      '$a/data/repositories/auth_repository_impl.dart',
      AuthTemplates.authRepositoryImpl(
        packageName: packageName,
        backend: backend,
        oauth: oauth,
        corePackageName: corePackageName,
        authPackageName: authPackageName,
      ),
    );
    await writeFile(
      '$a/presentation/providers/auth_provider.dart',
      AuthTemplates.authProvider(
        packageName: packageName,
        backend: backend,
        corePackageName: corePackageName,
      ),
    );
    await writeFile(
      '$a/data/repositories/auth_repository_providers.dart',
      AuthTemplates.authRepositoryProviders(
        packageName: packageName,
        backend: backend,
        corePackageName: corePackageName,
        authPackageName: authPackageName,
      ),
    );
    await writeFile(
      '$a/presentation/screens/login_screen.dart',
      AuthTemplates.loginScreen(
        packageName: packageName,
        oauth: oauth,
        corePackageName: corePackageName,
        authPackageName: authPackageName,
      ),
    );
    await writeFile(
      '$a/presentation/screens/signup_screen.dart',
      AuthTemplates.signupScreen(
        packageName: packageName,
        corePackageName: corePackageName,
        authPackageName: authPackageName,
      ),
    );
    await writeFile(
      '$a/presentation/screens/forgot_password_screen.dart',
      AuthTemplates.forgotPasswordScreen(
        packageName: packageName,
        corePackageName: corePackageName,
        authPackageName: authPackageName,
      ),
    );
    await writeFile(
      '$a/presentation/routes/auth_routes.dart',
      AuthTemplates.authRoutesBuilder(
        packageName: packageName,
        corePackageName: corePackageName,
        authPackageName: authPackageName,
      ),
    );

    // The go_router guard. Logged-in users on an auth route go to the first
    // feature's route ('/'). router_notifier.dart always stays app-level.
    final homeRoute = homeRouteExpr(
      featureName: featureName,
      hasFirstFeature: hasFirstFeature,
    );
    await writeFile(
      '$lib/core/router/router_notifier.dart',
      AuthTemplates.routerNotifier(
        packageName: packageName,
        homeRoute: homeRoute,
        backend: backend,
        authPackageName: authPackageName,
        hasOnboarding: hasOnboarding,
        corePackageName: corePackageName,
      ),
    );

    // Aggregate the auth routes into the shared route table (at the anchors).
    final authRoutesImport = authPackageName != null
        ? "import 'package:$authPackageName/presentation/routes/auth_routes.dart' as auth;"
        : "import 'package:$packageName/features/auth/presentation/routes/auth_routes.dart' as auth;";
    final routes = File('$lib/core/router/routes.dart');
    if (routes.existsSync()) {
      var s = await routes.readAsString();
      s = insertBeforeAnchor(s, '// neat:route-imports', authRoutesImport);
      s = insertBeforeAnchor(
        s,
        '// neat:route-entries',
        r'  ...auth.$appRoutes,',
      );
      await routes.writeAsString(s);
    }

    // Supabase's confirmation/reset emails deep-link back into the app (see
    // authRepositoryImpl's `_emailRedirectTo`, '<packageName>://login-callback').
    // That only works if the platform actually knows the scheme, so register
    // it natively — the one piece of this NEAT can't leave to docs alone.
    // Firebase's equivalent (ActionCodeSettings + Dynamic Links) is a
    // differently-shaped feature, out of scope here.
    if (backend == 'supabase') {
      await _patchNativeDeepLinks(projectDir, packageName);
    }
  }

  /// Registers the `<packageName>://login-callback` scheme natively, so a
  /// Supabase confirmation/reset email opens the app instead of a browser.
  /// No-op if the target platform wasn't generated (file doesn't exist) or
  /// the scheme is already there (re-run safety, like _patchAndroidFlavors).
  static Future<void> _patchNativeDeepLinks(
    Directory projectDir,
    String packageName,
  ) async {
    final manifest = File(
      '${projectDir.path}/android/app/src/main/AndroidManifest.xml',
    );
    if (manifest.existsSync()) {
      var src = await manifest.readAsString();
      if (!src.contains('login-callback')) {
        const filter =
            '            <!-- Supabase email confirmation / password reset deep link. -->\n'
            '            <intent-filter android:autoVerify="false">\n'
            '                <action android:name="android.intent.action.VIEW"/>\n'
            '                <category android:name="android.intent.category.DEFAULT"/>\n'
            '                <category android:name="android.intent.category.BROWSABLE"/>\n'
            '                <data android:scheme="SCHEME_PLACEHOLDER" android:host="login-callback"/>\n'
            '            </intent-filter>\n'
            '        </activity>';
        src = src.replaceFirst(
          '</activity>',
          filter.replaceFirst('SCHEME_PLACEHOLDER', packageName),
        );
        await manifest.writeAsString(src);
      }
    }

    final infoPlist = File('${projectDir.path}/ios/Runner/Info.plist');
    if (infoPlist.existsSync()) {
      var src = await infoPlist.readAsString();
      if (!src.contains('CFBundleURLTypes')) {
        final urlTypes =
            '\t<key>CFBundleURLTypes</key>\n'
            '\t<array>\n'
            '\t\t<dict>\n'
            '\t\t\t<key>CFBundleURLName</key>\n'
            '\t\t\t<string>$packageName.auth</string>\n'
            '\t\t\t<key>CFBundleURLSchemes</key>\n'
            '\t\t\t<array>\n'
            '\t\t\t\t<string>$packageName</string>\n'
            '\t\t\t</array>\n'
            '\t\t</dict>\n'
            '\t</array>\n'
            '\t<key>LSRequiresIPhoneOS</key>';
        src = src.replaceFirst(
          RegExp(r'<key>LSRequiresIPhoneOS</key>'),
          urlTypes,
        );
        await infoPlist.writeAsString(src);
      }
    }
  }
}
