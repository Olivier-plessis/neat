/// Templates for the opt-in Supabase **auth** feature: repository + providers,
/// login / signup / forgot-password screens, the route table, and the go_router
/// guard (`RouterNotifier`). Generated only when the user enables auth on a
/// Supabase backend.
class AuthTemplates {
  AuthTemplates._();

  // ── domain/repositories/i_auth_repository.dart ────────────────────────────
  static String iAuthRepository({required String packageName, bool oauth = false}) {
    final oauthContract = oauth
        ? '\n  Future<Result<bool>> signInWithGoogle();'
            '\n  Future<Result<bool>> signInWithApple();'
        : '';
    return '''import 'package:$packageName/core/result/result.dart';

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
  static String authRepositoryImpl({
    required String packageName,
    String backend = 'supabase',
    bool oauth = false,
  }) {
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
import 'package:$packageName/core/result/result.dart';
import 'package:$packageName/features/auth/domain/repositories/i_auth_repository.dart';

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
      return Result.failure(e.message ?? e.code);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }
}
''';
    }
    return '''import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:$packageName/core/result/result.dart';
import 'package:$packageName/features/auth/domain/repositories/i_auth_repository.dart';

class AuthRepositoryImpl implements IAuthRepository {
  const AuthRepositoryImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<Result<bool>> signIn({required String email, required String password}) =>
      _guard(() => _client.auth.signInWithPassword(email: email, password: password));

  @override
  Future<Result<bool>> signUp({required String email, required String password}) =>
      _guard(() => _client.auth.signUp(email: email, password: password));

  @override
  Future<Result<bool>> signOut() => _guard(() => _client.auth.signOut());

  @override
  Future<Result<bool>> sendPasswordReset(String email) =>
      _guard(() => _client.auth.resetPasswordForEmail(email));

  Future<Result<bool>> _guard(Future<void> Function() action) async {
    try {
      await action();
      return Result.success(true);
    } on AuthException catch (e) {
      return Result.failure(e.message);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }
}
''';
  }

  // ── presentation/providers/auth_provider.dart ─────────────────────────────
  static String authProvider({required String packageName, String backend = 'supabase'}) {
    if (backend == 'firebase') {
      return '''import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:$packageName/core/network/firebase_provider.dart';

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
import 'package:$packageName/core/network/supabase_provider.dart';

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

  // ── presentation/providers/auth_providers.dart (DI) ───────────────────────
  static String authDi({required String packageName, String backend = 'supabase'}) {
    final isFirebase = backend == 'firebase';
    final providerImport = isFirebase
        ? "import 'package:$packageName/core/network/firebase_provider.dart';"
        : "import 'package:$packageName/core/network/supabase_provider.dart';";
    final clientProvider = isFirebase ? 'firebaseAuthProvider' : 'supabaseClientProvider';
    return '''import 'package:riverpod_annotation/riverpod_annotation.dart';
$providerImport
import 'package:$packageName/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:$packageName/features/auth/domain/repositories/i_auth_repository.dart';

part 'auth_providers.g.dart';

@Riverpod(keepAlive: true)
IAuthRepository authRepository(Ref ref) =>
    AuthRepositoryImpl(ref.watch($clientProvider));
''';
  }

  // ── core/router/router_notifier.dart (go_router guard) ────────────────────
  static String routerNotifier({
    required String packageName,
    required String homeRoute,
    String backend = 'supabase',
  }) =>
      '''import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:${backend == 'firebase' ? 'firebase_auth/firebase_auth.dart' : 'supabase_flutter/supabase_flutter.dart'}';
import 'package:$packageName/core/constants/app_route_path.dart';
import 'package:$packageName/features/auth/presentation/providers/auth_provider.dart';

part 'router_notifier.g.dart';

/// Drives go_router redirects from the auth state. It is a [Listenable] so the
/// router refreshes whenever the user signs in or out.
@Riverpod(keepAlive: true)
class RouterNotifier extends _\$RouterNotifier implements Listenable {
  VoidCallback? _listener;

  @override
  User? build() {
    ref.listen(authControllerProvider, (_, next) {
      state = next;
      _listener?.call();
    });
    return ref.read(authControllerProvider);
  }

  /// Unauthenticated users are sent to /login (except on auth routes);
  /// authenticated users on an auth route are sent home.
  String? redirect(BuildContext context, GoRouterState routerState) {
    final loggedIn = state != null;
    final loc = routerState.matchedLocation;
    final onAuthRoute = loc == AppRoutePath.login ||
        loc == AppRoutePath.signup ||
        loc == AppRoutePath.forgotPassword;

    if (!loggedIn && !onAuthRoute) return AppRoutePath.login;
    if (loggedIn && onAuthRoute) return $homeRoute;
    return null;
  }

  @override
  void addListener(VoidCallback listener) => _listener = listener;

  @override
  void removeListener(VoidCallback listener) => _listener = null;
}
''';

  // ── presentation/screens ──────────────────────────────────────────────────
  static String loginScreen({required String packageName, bool oauth = false}) => _authForm(
        packageName: packageName,
        className: 'LoginScreen',
        title: 'Sign in',
        action: 'signIn',
        buttonLabel: 'Sign in',
        withPassword: true,
        oauth: oauth,
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

  static String signupScreen({required String packageName}) => _authForm(
        packageName: packageName,
        className: 'SignupScreen',
        title: 'Create account',
        action: 'signUp',
        buttonLabel: 'Sign up',
        withPassword: true,
        footer: '''
            TextButton(
              onPressed: () => context.go(AppRoutePath.login),
              child: const Text('I already have an account'),
            ),''',
      );

  static String forgotPasswordScreen({required String packageName}) => _authForm(
        packageName: packageName,
        className: 'ForgotPasswordScreen',
        title: 'Reset password',
        action: 'sendPasswordReset',
        buttonLabel: 'Send reset link',
        withPassword: false,
        footer: '''
            TextButton(
              onPressed: () => context.go(AppRoutePath.login),
              child: const Text('Back to sign in'),
            ),''',
      );

  /// Shared email(+password) form used by the three auth screens.
  static String _authForm({
    required String packageName,
    required String className,
    required String title,
    required String action,
    required String buttonLabel,
    required bool withPassword,
    required String footer,
    bool oauth = false,
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
                          onFailure: (message) => error.value = message,
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
                          onFailure: (message) => error.value = message,
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
    return '''import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:$packageName/core/constants/app_route_path.dart';
import 'package:$packageName/features/auth/presentation/providers/auth_providers.dart';

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
        onFailure: (message) => error.value = message,
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
  static String authRoutesBuilder({required String packageName}) =>
      '''import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:$packageName/core/constants/app_route_path.dart';
import 'package:$packageName/features/auth/presentation/screens/login_screen.dart';
import 'package:$packageName/features/auth/presentation/screens/signup_screen.dart';
import 'package:$packageName/features/auth/presentation/screens/forgot_password_screen.dart';

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
