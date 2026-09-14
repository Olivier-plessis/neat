import 'package:flutter_test/flutter_test.dart';
import 'package:neat/features/generation/domain/services/templates/dart/auth_templates.dart';

void main() {
  group('AuthTemplates.authRepositoryImpl — Supabase redirect wiring', () {
    test(
      'signUp / sendPasswordReset pass the packageName://login-callback '
      'redirect (real bug, found via a real generated project: without it, '
      "Supabase's confirmation/reset emails open a browser instead of "
      'deep-linking back into the app)',
      () {
        final code = AuthTemplates.authRepositoryImpl(packageName: 'demo_app');
        expect(
          code,
          contains("static const _emailRedirectTo = 'demo_app://login-callback';"),
        );
        expect(code, contains('emailRedirectTo: _emailRedirectTo'));
        expect(
          code,
          contains('resetPasswordForEmail(email, redirectTo: _emailRedirectTo)'),
        );
      },
    );

    test('firebase backend: no redirect wiring (different, out-of-scope mechanism)', () {
      final code = AuthTemplates.authRepositoryImpl(
        packageName: 'demo_app',
        backend: 'firebase',
      );
      expect(code, isNot(contains('emailRedirectTo')));
      expect(code, isNot(contains('_emailRedirectTo')));
      expect(code, isNot(contains('login-callback')));
    });
  });
}
