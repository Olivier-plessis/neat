import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:neat/features/generation/domain/usecases/writers/auth_writer.dart';

/// Covers AuthWriter's post-`flutter create` patch that registers the
/// `<packageName>://login-callback` scheme natively, so a Supabase
/// confirmation/reset email deep-links back into the app instead of opening
/// a browser (a real gap found via a real generated project — see
/// docs/SUPABASE.md and AuthTemplates.authRepositoryImpl's `_emailRedirectTo`).
///
/// Exercises the public `AuthWriter.write()` against a temp dir seeded with
/// stock `flutter create` output (not the full generation pipeline — no
/// `flutter create`/`pub get`/`analyze` involved, so this stays fast).
void main() {
  late Directory projectDir;

  setUp(() async {
    projectDir = await Directory.systemTemp.createTemp('neat_auth_writer_');
    // Minimal stand-ins for what `flutter create` actually produces.
    final manifest = File(
      '${projectDir.path}/android/app/src/main/AndroidManifest.xml',
    );
    await manifest.create(recursive: true);
    await manifest.writeAsString('''<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application android:label="demo_app" android:name="\${applicationName}" android:icon="@mipmap/ic_launcher">
        <activity android:name=".MainActivity" android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
    </application>
</manifest>
''');
    final infoPlist = File('${projectDir.path}/ios/Runner/Info.plist');
    await infoPlist.create(recursive: true);
    await infoPlist.writeAsString('''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleName</key>
	<string>demo_app</string>
	<key>LSRequiresIPhoneOS</key>
	<true/>
	<key>UILaunchStoryboardName</key>
	<string>LaunchScreen</string>
</dict>
</plist>
''');
  });

  tearDown(() async {
    if (projectDir.existsSync()) {
      await projectDir.delete(recursive: true);
    }
  });

  test(
    'Supabase backend: registers the login-callback scheme on both platforms',
    () async {
      await AuthWriter.write(
        projectDir: projectDir,
        lib: '${projectDir.path}/lib',
        packageName: 'demo_app',
        featureName: 'product',
      );

      final manifest = await File(
        '${projectDir.path}/android/app/src/main/AndroidManifest.xml',
      ).readAsString();
      expect(
        manifest,
        contains('<data android:scheme="demo_app" android:host="login-callback"/>'),
      );
      expect(manifest, contains('android:name="android.intent.action.VIEW"'));
      // The original launcher intent-filter is still there, untouched.
      expect(manifest, contains('android.intent.action.MAIN'));

      final infoPlist = await File(
        '${projectDir.path}/ios/Runner/Info.plist',
      ).readAsString();
      expect(infoPlist, contains('<key>CFBundleURLSchemes</key>'));
      expect(infoPlist, contains('<string>demo_app</string>'));
      expect(infoPlist, contains('<key>CFBundleURLTypes</key>'));
    },
  );

  test('re-running the patch does not duplicate the scheme', () async {
    for (var i = 0; i < 2; i++) {
      await AuthWriter.write(
        projectDir: projectDir,
        lib: '${projectDir.path}/lib',
        packageName: 'demo_app',
        featureName: 'product',
      );
    }

    final manifest = await File(
      '${projectDir.path}/android/app/src/main/AndroidManifest.xml',
    ).readAsString();
    expect('login-callback'.allMatches(manifest).length, 1);

    final infoPlist = await File(
      '${projectDir.path}/ios/Runner/Info.plist',
    ).readAsString();
    expect('CFBundleURLTypes'.allMatches(infoPlist).length, 1);
  });

  test(
    'Firebase backend: native files are left untouched (different, '
    'out-of-scope deep-link mechanism)',
    () async {
      await AuthWriter.write(
        projectDir: projectDir,
        lib: '${projectDir.path}/lib',
        packageName: 'demo_app',
        featureName: 'product',
        backend: 'firebase',
      );

      final manifest = await File(
        '${projectDir.path}/android/app/src/main/AndroidManifest.xml',
      ).readAsString();
      expect(manifest, isNot(contains('login-callback')));

      final infoPlist = await File(
        '${projectDir.path}/ios/Runner/Info.plist',
      ).readAsString();
      expect(infoPlist, isNot(contains('CFBundleURLTypes')));
    },
  );

  test(
    'missing platform directories: no-op instead of throwing (web/desktop-only target)',
    () async {
      // No android/ios dirs at all this time.
      final barePkg = await Directory.systemTemp.createTemp('neat_auth_bare_');
      addTearDown(() => barePkg.delete(recursive: true));

      await expectLater(
        AuthWriter.write(
          projectDir: barePkg,
          lib: '${barePkg.path}/lib',
          packageName: 'demo_app',
          featureName: 'product',
        ),
        completes,
      );
    },
  );
}
