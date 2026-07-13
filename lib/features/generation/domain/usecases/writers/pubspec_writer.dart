import 'dart:io';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:neat/features/dependencies/domain/models/pub_package.dart';

/// Writes the root `pubspec.yaml`: merges every selected + auto-injected
/// dependency into the `flutter create` scaffold, plus the workspace
/// `path:`/`workspace:` blocks for packageSplit — split out of
/// `LaunchGenerationUsecase` (see ROADMAP.md for the per-domain writer
/// split).
abstract final class PubspecWriter {
  static Future<void> write(
    Directory projectDir,
    List<PubPackage> packages, {
    bool withWidgetbook = false,
    bool addScreenUtil = true,
    List<String> pathPackages = const [],
    List<String> extraWorkspaceMembers = const [],
    bool addConnectivity = false,
    bool addSkeletonizer = false,
    bool addBranding = false,
    bool addImagePicker = false,
    bool addFirebaseCore = false,
    bool addFirebaseAuth = false,
    bool addFirebaseStorage = false,
    bool addSlang = false,
    bool addOnboarding = false,
    bool addSentry = false,
  }) async {
    final pubspecFile = File('${projectDir.path}/pubspec.yaml');
    if (!pubspecFile.existsSync()) return;

    final original = await pubspecFile.readAsString();
    final content = buildPubspecContent(
      original,
      packages,
      withWidgetbook: withWidgetbook,
      addScreenUtil: addScreenUtil,
      pathPackages: pathPackages,
      extraWorkspaceMembers: extraWorkspaceMembers,
      addConnectivity: addConnectivity,
      addSkeletonizer: addSkeletonizer,
      addBranding: addBranding,
      addImagePicker: addImagePicker,
      addFirebaseCore: addFirebaseCore,
      addFirebaseAuth: addFirebaseAuth,
      addFirebaseStorage: addFirebaseStorage,
      addSlang: addSlang,
      addOnboarding: addOnboarding,
      addSentry: addSentry,
    );

    await pubspecFile.writeAsString(content);
  }

  /// Pure pubspec assembly: takes the `flutter create` pubspec [original] and
  /// returns it with all selected + auto-injected dependencies merged in.
  ///
  /// Extracted from [write] so it can be unit-tested without touching
  /// the filesystem — guards against malformed-YAML regressions.
  @visibleForTesting
  static String buildPubspecContent(
    String original,
    List<PubPackage> packages, {
    bool withWidgetbook = false,
    bool addScreenUtil = true,
    List<String> pathPackages = const [],
    List<String> extraWorkspaceMembers = const [],
    bool addConnectivity = false,
    bool addSkeletonizer = false,
    bool addBranding = false,
    bool addImagePicker = false,
    bool addFirebaseCore = false,
    bool addFirebaseAuth = false,
    bool addFirebaseStorage = false,
    bool addSlang = false,
    bool addOnboarding = false,
    bool addSentry = false,
  }) {
    final deps = StringBuffer();
    final devDeps = StringBuffer();

    // Deduplicate by name — keepAlive state can accumulate duplicates across
    // multiple generation runs if the user applies a preset on a non-empty list.
    final seen = <String>{};
    final uniquePackages = packages.where((p) => seen.add(p.name)).toList();

    final hasGoRouterBuilder = uniquePackages.any(
      (p) => p.name == 'go_router_builder',
    );
    final hasGoRouterExplicit = uniquePackages.any(
      (p) => p.name == 'go_router',
    );

    for (final pkg in uniquePackages) {
      final line = '  ${pkg.name}: ^${pkg.version}\n';
      if (pkg.isDev) {
        devDeps.write(line);
      } else {
        deps.write(line);
      }
    }

    // go_router_builder is a dev dep but requires go_router as a runtime dep.
    // Auto-inject it when missing so the generated code compiles out of the box.
    if (hasGoRouterBuilder && !hasGoRouterExplicit) {
      deps.write('  go_router: ^17.2.3\n');
    }

    // Generated Cubit/Bloc code always imports package:flutter_bloc — inject
    // it when the user picked a bloc-family package that isn't flutter_bloc
    // itself (e.g. the plain, Flutter-less `bloc` package from a pub.dev
    // search) so the project still compiles.
    final hasBlocFamily = uniquePackages.any((p) => p.name.contains('bloc'));
    final hasFlutterBlocExplicit = uniquePackages.any(
      (p) => p.name == 'flutter_bloc',
    );
    if (hasBlocFamily && !hasFlutterBlocExplicit) {
      deps.write('  flutter_bloc: ^9.1.1\n');
    }

    // The generated typography uses google_fonts to apply the chosen font
    // family at runtime — inject it unless the user already added it.
    if (!uniquePackages.any((p) => p.name == 'google_fonts')) {
      deps.write('  google_fonts: ^8.1.0\n');
    }

    // AppLogger (observability) is always generated — inject the logger package.
    if (!uniquePackages.any((p) => p.name == 'logger')) {
      deps.write('  logger: ^2.7.0\n');
    }

    // Responsive sizing — added by default, skipped for web-only projects.
    if (addScreenUtil &&
        !uniquePackages.any((p) => p.name == 'flutter_screenutil')) {
      deps.write('  flutter_screenutil: ^5.9.3\n');
    }

    // Widgetbook catalog (dev-only) when opted in.
    if (withWidgetbook && !uniquePackages.any((p) => p.name == 'widgetbook')) {
      devDeps.write('  widgetbook: ^3.7.0\n');
    }

    // envied needs its generator (+ build_runner) to produce the .g.dart files.
    if (uniquePackages.any((p) => p.name == 'envied')) {
      if (!uniquePackages.any((p) => p.name == 'envied_generator')) {
        devDeps.write('  envied_generator: ^1.1.1\n');
      }
      if (!uniquePackages.any((p) => p.name == 'build_runner')) {
        devDeps.write('  build_runner: ^2.4.13\n');
      }
    }

    // connectivity_plus for the offline NetworkInfo brick.
    if (addConnectivity &&
        !uniquePackages.any((p) => p.name == 'connectivity_plus')) {
      deps.write('  connectivity_plus: ^7.1.1\n');
    }
    // skeletonizer for the generated list screen's loading placeholders.
    if (addSkeletonizer &&
        !uniquePackages.any((p) => p.name == 'skeletonizer')) {
      deps.write('  skeletonizer: ^2.1.3\n');
    }
    // image_picker for the Storage sample avatar upload widget.
    if (addImagePicker &&
        !uniquePackages.any((p) => p.name == 'image_picker')) {
      deps.write('  image_picker: ^1.1.2\n');
    }
    // Firebase: cloud_firestore is the user-selected marker; firebase_core is
    // required by it, and auth/storage are pulled in with their opt-ins.
    if (addFirebaseCore &&
        !uniquePackages.any((p) => p.name == 'firebase_core')) {
      deps.write('  firebase_core: ^3.8.1\n');
    }
    if (addFirebaseAuth &&
        !uniquePackages.any((p) => p.name == 'firebase_auth')) {
      deps.write('  firebase_auth: ^5.3.4\n');
    }
    if (addFirebaseStorage &&
        !uniquePackages.any((p) => p.name == 'firebase_storage')) {
      deps.write('  firebase_storage: ^12.4.0\n');
    }
    // slang i18n: runtime (slang + slang_flutter + flutter_localizations) +
    // shared_preferences for locale persistence. Codegen runs via the slang CLI
    // (`dart run slang`), not slang_build_runner — see _runSlang.
    if (addSlang) {
      if (!uniquePackages.any((p) => p.name == 'slang')) {
        deps.write('  slang: ^4.16.0\n');
      }
      if (!uniquePackages.any((p) => p.name == 'slang_flutter')) {
        deps.write('  slang_flutter: ^4.16.0\n');
      }
      if (!uniquePackages.any((p) => p.name == 'flutter_localizations')) {
        deps.write('  flutter_localizations:\n    sdk: flutter\n');
      }
      // Persist the chosen locale across restarts (LocaleStore).
      if (!uniquePackages.any((p) => p.name == 'shared_preferences')) {
        deps.write('  shared_preferences: ^2.3.3\n');
      }
    }
    // Onboarding: shared_preferences for the "seen it" flag — same package
    // LocaleStore uses for locale persistence, so guard against addSlang
    // already having added it (avoid a duplicate line).
    if (addOnboarding &&
        !addSlang &&
        !uniquePackages.any((p) => p.name == 'shared_preferences')) {
      deps.write('  shared_preferences: ^2.3.3\n');
    }
    // Sentry (CI/CD screen, opt-in): crash/error reporting, wrapped around
    // runApp in bootstrap() — see AppTemplates.bootstrap's hasSentry doc.
    if (addSentry && !uniquePackages.any((p) => p.name == 'sentry_flutter')) {
      deps.write('  sentry_flutter: ^9.5.0\n');
    }
    // Branding tooling: app icons + splash from the uploaded logo.
    if (addBranding) {
      if (!uniquePackages.any((p) => p.name == 'flutter_launcher_icons')) {
        devDeps.write('  flutter_launcher_icons: ^0.14.4\n');
      }
      if (!uniquePackages.any((p) => p.name == 'flutter_native_splash')) {
        devDeps.write('  flutter_native_splash: ^2.4.6\n');
      }
    }
    // Path deps on local workspace packages (e.g. <app>_ui, local_storage).
    for (final pkg in pathPackages) {
      deps.write('  $pkg:\n    path: packages/$pkg\n');
    }

    var content = original;

    if (deps.isNotEmpty) {
      content = content.replaceFirst(
        'dependencies:\n  flutter:\n    sdk: flutter',
        'dependencies:\n  flutter:\n    sdk: flutter\n$deps',
      );
    }
    if (devDeps.isNotEmpty) {
      content = content.replaceFirst(
        'dev_dependencies:\n  flutter_test:\n    sdk: flutter',
        'dev_dependencies:\n  flutter_test:\n    sdk: flutter\n$devDeps',
      );
    }

    // Declare the Dart workspace at the root (app = workspace root). Members
    // live under packages/ (or widgetbook/) and each carries `resolution: workspace`.
    final members = [
      ...pathPackages.map((p) => 'packages/$p'),
      ...extraWorkspaceMembers,
    ];
    if (members.isNotEmpty) {
      final block = members.map((m) => '  - $m').join('\n');
      content = '${content.trimRight()}\n\nworkspace:\n$block\n';
    }

    // drift_dev 2.34.0's query analyzer calls a `DartPlaceholder.when()` method
    // that sqlparser removed in 0.44.6 (a breaking change published under a
    // compatible `^0.44.0` constraint, so pub picks it up without a conflict —
    // the build just fails at codegen time). Override stays workspace-wide
    // here (a pub workspace resolves one version of everything) until
    // drift_dev bumps its own sqlparser constraint past the break.
    if (addConnectivity) {
      content =
          '${content.trimRight()}\n\n'
          'dependency_overrides:\n'
          '  sqlparser: ">=0.44.0 <0.44.6"\n';
    }

    return content;
  }
}
