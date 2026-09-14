/// Templates for the opt-in Supabase **auth** feature: repository + providers,
/// login / signup / forgot-password screens, the route table, and the go_router
/// guard (`RouterNotifier`). Generated only when the user enables auth on a
/// Supabase backend.
class AuthTemplates {
  AuthTemplates._();

  // ── domain/repositories/i_auth_repository.dart ────────────────────────────
  // corePackageName: Auth is generated once, always at the app level (never
  // split into its own workspace package — it's a single consumer, not a
  // shared singleton every feature package needs, unlike theme_mode_controller/
  // app_logger/i18n). But it still imports Result/Failure/the client-init
  // providers, which DO move into core when packageSplit is on, so those
  // specific imports redirect the same way every other core/-boundary
  // crossing in this file does.
  static String iAuthRepository({
    required String packageName,
    bool oauth = false,
    String? corePackageName,
  }) {
    final oauthContract = oauth
        ? '\n  Future<Result<bool>> signInWithGoogle();'
            '\n  Future<Result<bool>> signInWithApple();'
        : '';
    return '''import 'package:${corePackageName ?? packageName}/core/result/result.dart';

/// Authentication contract. Implementations map provider errors to [Result].
abstract interface class IAuthRepository {
  Future<Result<bool>> signIn({required String email, required String password});
  Future<Result<bool>> signUp({required String email, required String password});
  Future<Result<bool>> signOut();
  Future<Result<bool>> sendPasswordReset(String email);$oauthContract
}
''';
  }

  // ── data/repositories/auth_repository_impl.dart ───────────────────────────
  // corePackageName: see iAuthRepository's doc — same redirect rationale.
  // authPackageName: set when packageSplit is on — Auth becomes its own
  // workspace package (packages/auth/, package-root layout like any
  // other split feature, depending on core rather than duplicating
  // Result/Failure/UseCase the way wesioo's standalone `authentication`
  // package does). Same-feature self-references become relative imports —
  // identical technique to Phase 1 Step 2a's conversion for regular features.
  static String authRepositoryImpl({
    required String packageName,
    String backend = 'supabase',
    bool oauth = false,
    String? corePackageName,
    String? authPackageName,
  }) {
    final corePkg = corePackageName ?? packageName;
    final iAuthRepoImport = authPackageName != null
        ? "import '../../domain/repositories/i_auth_repository.dart';"
        : "import 'package:$packageName/features/auth/domain/repositories/i_auth_repository.dart';";
    if (backend == 'firebase') {
      // OAuth via Firebase's built-in provider flow (no extra SDKs). Works on
      // web/iOS/macOS/Android; on mobile it opens an OAuth web flow.
      final oauthMethods = oauth
          ? '''

  @override
  Future<Result<bool>> signInWithGoogle() =>
      _guard(() => _auth.signInWithProvider(GoogleAuthProvider()));

  @override
  Future<Result<bool>> signInWithApple() =>
      _guard(() => _auth.signInWithProvider(AppleAuthProvider()));'''
          : '';
      return '''import 'package:firebase_auth/firebase_auth.dart';
import 'package:$corePkg/core/error/failure.dart';
import 'package:$corePkg/core/result/result.dart';
$iAuthRepoImport

class AuthRepositoryImpl implements IAuthRepository {
  const AuthRepositoryImpl(this._auth);

  final FirebaseAuth _auth;

  @override
  Future<Result<bool>> signIn({required String email, required String password}) =>
      _guard(() => _auth.signInWithEmailAndPassword(email: email, password: password));

  @override
  Future<Result<bool>> signUp({required String email, required String password}) =>
      _guard(() => _auth.createUserWithEmailAndPassword(email: email, password: password));

  @override
  Future<Result<bool>> signOut() => _guard(_auth.signOut);

  @override
  Future<Result<bool>> sendPasswordReset(String email) =>
      _guard(() => _auth.sendPasswordResetEmail(email: email));$oauthMethods

  Future<Result<bool>> _guard(Future<void> Function() action) async {
    try {
      await action();
      return Result.success(true);
    } on FirebaseAuthException catch (e) {
      return Result.failure(Failure(message: e.message ?? e.code, code: e.code, originalError: e));
    } catch (e) {
      return Result.failure(Failure(message: e.toString(), originalError: e));
    }
  }
}
''';
    }
    return '''import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:$corePkg/core/error/failure.dart';
import 'package:$corePkg/core/result/result.dart';
$iAuthRepoImport

class AuthRepositoryImpl implements IAuthRepository {
  const AuthRepositoryImpl(this._client);

  final SupabaseClient _client;

  // Deep link the confirmation/reset emails send the user back to. Must be
  // registered as a redirect URL in the Supabase Dashboard (Authentication
  // → URL Configuration) — see docs/SUPABASE.md — or Supabase falls back to
  // opening it in a browser instead of the app.
  static const _emailRedirectTo = '$packageName://login-callback';

  @override
  Future<Result<bool>> signIn({required String email, required String password}) =>
      _guard(() => _client.auth.signInWithPassword(email: email, password: password));

  @override
  Future<Result<bool>> signUp({required String email, required String password}) =>
      _guard(() => _client.auth.signUp(
            email: email,
            password: password,
            emailRedirectTo: _emailRedirectTo,
          ));

  @override
  Future<Result<bool>> signOut() => _guard(() => _client.auth.signOut());

  @override
  Future<Result<bool>> sendPasswordReset(String email) => _guard(
        () => _client.auth.resetPasswordForEmail(email, redirectTo: _emailRedirectTo),
      );

  Future<Result<bool>> _guard(Future<void> Function() action) async {
    try {
      await action();
      return Result.success(true);
    } on AuthException catch (e) {
      return Result.failure(Failure(message: e.message, code: e.code, originalError: e));
    } catch (e) {
      return Result.failure(Failure(message: e.toString(), originalError: e));
    }
  }
}
''';
  }

  // ── presentation/providers/auth_provider.dart ─────────────────────────────
  // corePackageName: see iAuthRepository's doc — same redirect rationale
  // (the client-init provider moves into core when packageSplit is on).
  static String authProvider({
    required String packageName,
    String backend = 'supabase',
    String? corePackageName,
  }) {
    final corePkg = corePackageName ?? packageName;
    if (backend == 'firebase') {
      return '''import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:$corePkg/core/network/firebase_provider.dart';

part 'auth_provider.g.dart';

/// The current authenticated user (null when signed out). Rebuilds on every
/// Firebase auth change, so the router guard reacts automatically.
@Riverpod(keepAlive: true)
class AuthController extends _\$AuthController {
  @override
  User? build() {
    final auth = ref.watch(firebaseAuthProvider);
    final sub = auth.authStateChanges().listen((user) => state = user);
    ref.onDispose(sub.cancel);
    return auth.currentUser;
  }
}
''';
    }
    return '''import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:$corePkg/core/network/supabase_provider.dart';

part 'auth_provider.g.dart';

/// The current authenticated user (null when signed out). Rebuilds on every
/// Supabase auth change, so the router guard reacts automatically.
@Riverpod(keepAlive: true)
class AuthController extends _\$AuthController {
  @override
  User? build() {
    final client = ref.watch(supabaseClientProvider);
    final sub = client.auth.onAuthStateChange.listen((_) {
      state = client.auth.currentUser;
    });
    ref.onDispose(sub.cancel);
    return client.auth.currentUser;
  }
}
''';
  }

  // ── data/repositories/auth_repository_providers.dart (repository-level DI) ─

  /// Wires `IAuthRepository` (abstract) to `AuthRepositoryImpl` (concrete).
  /// Lives in `data/` — not `presentation/` — since it's built from a concrete
  /// Data class; presentation only ever reads the abstract-typed provider.
  /// corePackageName: see iAuthRepository's doc — same redirect rationale.
  /// authPackageName: see authRepositoryImpl's doc — same relative-import
  /// conversion for same-feature self-references.
  static String authRepositoryProviders({
    required String packageName,
    String backend = 'supabase',
    String? corePackageName,
    String? authPackageName,
  }) {
    final isFirebase = backend == 'firebase';
    final corePkg = corePackageName ?? packageName;
    final providerImport = isFirebase
        ? "import 'package:$corePkg/core/network/firebase_provider.dart';"
        : "import 'package:$corePkg/core/network/supabase_provider.dart';";
    final clientProvider = isFirebase ? 'firebaseAuthProvider' : 'supabaseClientProvider';
    final selfImports = authPackageName != null
        ? "import 'auth_repository_impl.dart';\n"
            "import '../../domain/repositories/i_auth_repository.dart';"
        : "import 'package:$packageName/features/auth/data/repositories/auth_repository_impl.dart';\n"
            "import 'package:$packageName/features/auth/domain/repositories/i_auth_repository.dart';";
    return '''import 'package:riverpod_annotation/riverpod_annotation.dart';
$providerImport
$selfImports

part 'auth_repository_providers.g.dart';

@Riverpod(keepAlive: true)
IAuthRepository authRepository(Ref ref) =>
    AuthRepositoryImpl(ref.watch($clientProvider));
''';
  }

  // ── core/router/router_notifier.dart (go_router guard) ────────────────────
  // router_notifier.dart itself always stays app-level (it's the router
  // guard, not a feature) — its own AppRoutePath import stays pointed at the
  // app's own copy (an app-internal reference, not a boundary crossing,
  // exactly like routesManual's own AppRoutePath use). Only the
  // auth_provider.dart import crosses into the auth package when split.
  static String routerNotifier({
    required String packageName,
    required String homeRoute,
    String backend = 'supabase',
    String? authPackageName,
    bool hasOnboarding = false,
    // router_notifier.dart itself always stays app-level (see below), but
    // when packageSplit is on its AppRoutePath import must still cross into
    // the shared core package — single-sourced there, not duplicated (same
    // redirect as CoreTemplates.appRouter's own doc).
    String? corePackageName,
  }) {
    final authProviderImport = authPackageName != null
        ? "import 'package:$authPackageName/presentation/providers/auth_provider.dart';"
        : "import 'package:$packageName/features/auth/presentation/providers/auth_provider.dart';";
    // Onboarding is always app-level (see OnboardingTemplates) — never
    // affected by authPackageName's split-package redirect.
    final onboardingImport = hasOnboarding
        ? "\nimport 'package:$packageName/core/onboarding/onboarding_seen_provider.dart';"
        : '';
    final onboardingListen = hasOnboarding
        ? '\n    ref.listen(onboardingSeenProvider, (_, __) => _listener?.call());'
        : '';
    // Checked first — shown before even asking to log in.
    final onboardingCheck = hasOnboarding
        ? '''
    final onboardingSeen = ref.read(onboardingSeenProvider);
    final onOnboarding = loc == AppRoutePath.onboarding;
    if (!onboardingSeen && !onOnboarding) return AppRoutePath.onboarding;
    if (onboardingSeen && onOnboarding) return $homeRoute;
'''
        : '';
    // Real bug, found via a real generated project: the onboarding route is
    // shown *before* login, but the login redirect below never exempted it —
    // an unonboarded, unauthenticated user on /onboarding (mid-flow, not yet
    // marked seen) fell through both onboarding checks above, then got
    // bounced to /login by this one, which bounced straight back to
    // /onboarding, forever: /onboarding => /login => /onboarding. onOnboarding
    // only exists as a variable when hasOnboarding is on (declared inside
    // onboardingCheck above), so the extra clause must be conditional too.
    final loginRedirectCondition = hasOnboarding
        ? '!loggedIn && !onAuthRoute && !onOnboarding'
        : '!loggedIn && !onAuthRoute';
    return '''import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:${backend == 'firebase' ? 'firebase_auth/firebase_auth.dart' : 'supabase_flutter/supabase_flutter.dart'}';
import 'package:${corePackageName ?? packageName}/core/constants/app_route_path.dart';
$authProviderImport$onboardingImport

part 'router_notifier.g.dart';

/// Drives go_router redirects from the auth state${hasOnboarding ? ' and onboarding' : ''}.
/// It is a [Listenable] so the router refreshes whenever ${hasOnboarding ? 'either changes' : 'the user signs in or out'}.
@Riverpod(keepAlive: true)
class RouterNotifier extends _\$RouterNotifier implements Listenable {
  VoidCallback? _listener;

  @override
  User? build() {
    ref.listen(authControllerProvider, (_, next) {
      state = next;
      _listener?.call();
    });$onboardingListen
    return ref.read(authControllerProvider);
  }

  /// Unauthenticated users are sent to /login (except on auth routes);
  /// authenticated users on an auth route are sent home.
  String? redirect(BuildContext context, GoRouterState routerState) {
    final loc = routerState.matchedLocation;
$onboardingCheck
    final loggedIn = state != null;
    final onAuthRoute = loc == AppRoutePath.login ||
        loc == AppRoutePath.signup ||
        loc == AppRoutePath.forgotPassword;

    if ($loginRedirectCondition) return AppRoutePath.login;
    if (loggedIn && onAuthRoute) return $homeRoute;
    return null;
  }

  @override
  void addListener(VoidCallback listener) => _listener = listener;

  @override
  void removeListener(VoidCallback listener) => _listener = null;
}
''';
  }

  // ── presentation/screens ──────────────────────────────────────────────────
  static String loginScreen({
    required String packageName,
    bool oauth = false,
    String? corePackageName,
    String? authPackageName,
  }) =>
      _authForm(
        packageName: packageName,
        className: 'LoginScreen',
        title: 'Sign in',
        action: 'signIn',
        buttonLabel: 'Sign in',
        withPassword: true,
        oauth: oauth,
        corePackageName: corePackageName,
        authPackageName: authPackageName,
        footer: '''
            TextButton(
              onPressed: () => context.go(AppRoutePath.signup),
              child: const Text('Create an account'),
            ),
            TextButton(
              onPressed: () => context.go(AppRoutePath.forgotPassword),
              child: const Text('Forgot password?'),
            ),''',
      );

  static String signupScreen({
    required String packageName,
    String? corePackageName,
    String? authPackageName,
  }) =>
      _authForm(
        packageName: packageName,
        className: 'SignupScreen',
        title: 'Create account',
        action: 'signUp',
        buttonLabel: 'Sign up',
        withPassword: true,
        corePackageName: corePackageName,
        authPackageName: authPackageName,
        footer: '''
            TextButton(
              onPressed: () => context.go(AppRoutePath.login),
              child: const Text('I already have an account'),
            ),''',
      );

  static String forgotPasswordScreen({
    required String packageName,
    String? corePackageName,
    String? authPackageName,
  }) =>
      _authForm(
        packageName: packageName,
        className: 'ForgotPasswordScreen',
        title: 'Reset password',
        action: 'sendPasswordReset',
        buttonLabel: 'Send reset link',
        withPassword: false,
        corePackageName: corePackageName,
        authPackageName: authPackageName,
        footer: '''
            TextButton(
              onPressed: () => context.go(AppRoutePath.login),
              child: const Text('Back to sign in'),
            ),''',
      );

  /// Shared email(+password) form used by the three auth screens.
  /// corePackageName/authPackageName: see authRepositoryImpl's doc — same
  /// redirect/relative-import rationale, applied to AppRoutePath and the
  /// self-referencing auth_repository_providers.dart import.
  static String _authForm({
    required String packageName,
    required String className,
    required String title,
    required String action,
    required String buttonLabel,
    required bool withPassword,
    required String footer,
    bool oauth = false,
    String? corePackageName,
    String? authPackageName,
  }) {
    // OAuth buttons (Google + Apple via Firebase's signInWithProvider). They
    // reuse the form's loading/error state.
    final oauthBlock = oauth
        ? '''
              const SizedBox(height: 16),
              const Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('or'),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: loading.value
                    ? null
                    : () async {
                        loading.value = true;
                        error.value = null;
                        final result =
                            await ref.read(authRepositoryProvider).signInWithGoogle();
                        loading.value = false;
                        result.fold(
                          onSuccess: (_) {},
                          onFailure: (failure) => error.value = failure.message,
                        );
                      },
                icon: const Icon(Icons.login),
                label: const Text('Continue with Google'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: loading.value
                    ? null
                    : () async {
                        loading.value = true;
                        error.value = null;
                        final result =
                            await ref.read(authRepositoryProvider).signInWithApple();
                        loading.value = false;
                        result.fold(
                          onSuccess: (_) {},
                          onFailure: (failure) => error.value = failure.message,
                        );
                      },
                icon: const Icon(Icons.apple),
                label: const Text('Continue with Apple'),
              ),'''
        : '';
    final pwdController = withPassword
        ? '    final password = useTextEditingController();\n'
        : '';
    final pwdField = withPassword
        ? '''
            const SizedBox(height: 12),
            TextField(
              controller: password,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),'''
        : '';
    final actionCall = withPassword
        ? '$action(email: email.text.trim(), password: password.text)'
        : '$action(email.text.trim())';
    final appRoutePathImport = authPackageName != null
        ? "import 'package:${corePackageName ?? packageName}/core/constants/app_route_path.dart';"
        : "import 'package:$packageName/core/constants/app_route_path.dart';";
    final authRepoProvidersImport = authPackageName != null
        ? "import '../../data/repositories/auth_repository_providers.dart';"
        : "import 'package:$packageName/features/auth/data/repositories/auth_repository_providers.dart';";
    return '''import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
$appRoutePathImport
$authRepoProvidersImport

class $className extends HookConsumerWidget {
  const $className({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final email = useTextEditingController();
$pwdController    final loading = useState(false);
    final error = useState<String?>(null);

    Future<void> submit() async {
      loading.value = true;
      error.value = null;
      final result = await ref.read(authRepositoryProvider).$actionCall;
      loading.value = false;
      result.fold(
        onSuccess: (_) {},
        onFailure: (failure) => error.value = failure.message,
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('$title')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(24),
            children: [
              TextField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
              ),$pwdField
              if (error.value != null) ...[
                const SizedBox(height: 12),
                Text(error.value!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: loading.value ? null : submit,
                child: loading.value
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('$buttonLabel'),
              ),$oauthBlock$footer
            ],
          ),
        ),
      ),
    );
  }
}
''';
  }

  // ── presentation/routes — go_router_builder (typed) ───────────────────────
  // corePackageName/authPackageName: same redirect/relative-import rationale
  // as _authForm's doc.
  static String authRoutesBuilder({
    required String packageName,
    String? corePackageName,
    String? authPackageName,
  }) {
    final appRoutePathImport = authPackageName != null
        ? "import 'package:${corePackageName ?? packageName}/core/constants/app_route_path.dart';"
        : "import 'package:$packageName/core/constants/app_route_path.dart';";
    final screenImports = authPackageName != null
        ? "import '../screens/login_screen.dart';\n"
            "import '../screens/signup_screen.dart';\n"
            "import '../screens/forgot_password_screen.dart';"
        : "import 'package:$packageName/features/auth/presentation/screens/login_screen.dart';\n"
            "import 'package:$packageName/features/auth/presentation/screens/signup_screen.dart';\n"
            "import 'package:$packageName/features/auth/presentation/screens/forgot_password_screen.dart';";
    return '''import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
$appRoutePathImport
$screenImports

part 'auth_routes.g.dart';

@TypedGoRoute<LoginRoute>(path: AppRoutePath.login)
class LoginRoute extends GoRouteData with \$LoginRoute {
  const LoginRoute();
  @override
  Widget build(BuildContext context, GoRouterState state) => const LoginScreen();
}

@TypedGoRoute<SignupRoute>(path: AppRoutePath.signup)
class SignupRoute extends GoRouteData with \$SignupRoute {
  const SignupRoute();
  @override
  Widget build(BuildContext context, GoRouterState state) => const SignupScreen();
}

@TypedGoRoute<ForgotPasswordRoute>(path: AppRoutePath.forgotPassword)
class ForgotPasswordRoute extends GoRouteData with \$ForgotPasswordRoute {
  const ForgotPasswordRoute();
  @override
  Widget build(BuildContext context, GoRouterState state) => const ForgotPasswordScreen();
}
''';
  }

  /// Plain go_router: three GoRoute entries to insert into the route table.
  static String authRoutesPlainEntries() => '''  GoRoute(
    path: AppRoutePath.login,
    builder: (context, state) => const LoginScreen(),
  ),
  GoRoute(
    path: AppRoutePath.signup,
    builder: (context, state) => const SignupScreen(),
  ),
  GoRoute(
    path: AppRoutePath.forgotPassword,
    builder: (context, state) => const ForgotPasswordScreen(),
  ),''';
}
