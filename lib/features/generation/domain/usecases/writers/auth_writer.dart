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
  }
}
