@Tags(['integration'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:neat/features/architecture/domain/models/architecture_state.dart';
import 'package:neat/features/cicd/domain/models/cicd_state.dart';
import 'package:neat/features/dependencies/domain/models/pub_package.dart';
import 'package:neat/features/generation/domain/usecases/launch_generation_usecase.dart';
import 'package:neat/features/identity/domain/models/identity_state.dart';
import 'package:neat/features/theme_engine/domain/models/theme_engine_state.dart';

/// A generated project has a dark mode that works, and keeps the theme mode the
/// person chose. `flutter analyze` cannot say that: the generated code compiled
/// before too, with every neutral colour a light constant. So this generates a
/// real project, analyzes it, and runs a probe test *inside* it that pumps the
/// generated theme and components in dark.
///
/// Slow (pub get + build_runner + analyze + test) and network-dependent, so it
/// is excluded from the default suite: `flutter test --tags integration`.
void main() {
  final packages = <PubPackage>[
    _dep('hooks_riverpod', '3.4.3'),
    _dep('flutter_hooks', '0.21.3+1'),
    _dep('riverpod_annotation', '4.0.7'),
    _dep('json_annotation', '4.11.0'),
    _dep('freezed_annotation', '3.1.0'),
    _dep('dio', '5.9.2'),
    _dep('go_router', '17.5.0'),
    _dev('riverpod_generator', '4.0.9'),
    _dev('riverpod_lint', '3.1.9'),
    _dev('json_serializable', '6.14.1'),
    _dev('build_runner', '2.16.2'),
    _dev('freezed', '4.0.2'),
    _dev('go_router_builder', '4.5.0'),
  ];

  late Directory tempRoot;

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('neat_dark_');
  });

  tearDown(() async {
    if (tempRoot.existsSync()) await tempRoot.delete(recursive: true);
  });

  /// Whole-workspace `flutter analyze`: no error, no warning.
  Future<void> expectCleanAnalyze(Directory projectDir) async {
    final analyze = await Process.run('flutter', [
      'analyze',
      '--no-pub',
    ], workingDirectory: projectDir.path);
    final out = '${analyze.stdout}\n${analyze.stderr}';
    expect(
      RegExp(r'(\d+ issues? found|No issues found)').hasMatch(out),
      isTrue,
      reason: 'flutter analyze did not run as expected:\n$out',
    );
    final problems = const LineSplitter()
        .convert(out)
        .where(
          (l) =>
              (l.contains(' error •') || l.contains(' warning •')) &&
              !l.contains('• build/'),
        )
        .toList();
    expect(
      problems,
      isEmpty,
      reason: 'analyze reported:\n${problems.join('\n')}\n\n$out',
    );
  }

  Future<Directory> generate({
    required String projectName,
    required ArchitectureState architecture,
    required ThemeEngineState theme,
  }) async {
    final logs = <String>[];
    try {
      await const LaunchGenerationUsecase().execute(
        identity: IdentityState(
          name: projectName,
          organization: 'com.neat.test',
          projectPath: tempRoot.path,
          description: 'NEAT dark mode integration test',
          targetPlatforms: const ['macos'],
        ),
        packages: packages,
        architecture: architecture,
        cicd: const CicdState(),
        theme: theme,
        onLog: logs.add,
      );
    } catch (e) {
      fail('Generation threw:\n$e\n\n--- logs ---\n${logs.join('\n')}');
    }
    return Directory('${tempRoot.path}/$projectName');
  }

  test('a generated project wears the dark neutrals, keeps its theme mode, and '
      'analyzes cleanly (UI package extracted)', () async {
    const projectName = 'neat_dark_test';
    const uiPkg = '${projectName}_ui';
    final projectDir = await generate(
      projectName: projectName,
      architecture: const ArchitectureState(
        firstFeatureName: 'user_profile',
        generateI18n: true,
      ),
      theme: const ThemeEngineState(
        approach: ThemeApproach.customM3,
        components: {
          AppComponent.button,
          AppComponent.card,
          AppComponent.textField,
        },
        generateWidgetbook: true,
      ),
    );
    String read(String p) => File('${projectDir.path}/$p').readAsStringSync();

    // The theme and the components read the neutrals from the extension.
    final extensions = read(
      'packages/$uiPkg/lib/core/theme/app_theme_extensions.dart',
    );
    expect(extensions, contains('static const AppColors dark = AppColors('));
    expect(extensions, contains('AppColors get colors =>'));
    final theme = read('packages/$uiPkg/lib/core/theme/app_theme.dart');
    expect(theme, contains('_build(Brightness.dark, AppColors.dark)'));
    for (final component in ['app_button', 'app_card', 'app_text_field']) {
      expect(
        read('packages/$uiPkg/lib/components/$component.dart'),
        isNot(
          contains(
            RegExp(
              r'Palette\.(textPrimary|textSecondary|divider|surface|background)',
            ),
          ),
        ),
        reason: '$component names a light constant',
      );
    }
    expect(
      read('packages/$uiPkg/lib/$uiPkg.dart'),
      contains("export 'core/theme/app_theme_extensions.dart';"),
    );

    // The mode is kept: the controller, its dependency, and the start-up load.
    final controller = read('lib/core/theme/theme_mode_controller.dart');
    expect(controller, contains('Future<void> load() async'));
    expect(controller, contains("static const _prefsKey = 'theme_mode';"));
    expect(read('pubspec.yaml'), contains('shared_preferences:'));
    expect(read('pubspec.yaml'), contains('flutter_screenutil:'));
    final bootstrap = read('lib/core/bootstrap.dart');
    expect(bootstrap, contains('themeModeControllerProvider.notifier).load()'));
    // (The formatter may break the call over lines once TranslationProvider
    // wraps it, with i18n.)
    expect(
      bootstrap,
      contains(RegExp(r'UncontrolledProviderScope\(\s*container: container')),
    );

    // The picker: next to the controller, with the app's own translations, and
    // in the first page's app bar in place of the one-tap toggle.
    final switcher = read('lib/core/theme/theme_mode_switcher.dart');
    expect(
      switcher,
      contains("import 'package:$projectName/i18n/strings.g.dart';"),
    );
    expect(switcher, contains('context.t.themeMode.light'));
    expect(read('lib/i18n/en.i18n.json'), contains('"themeMode"'));
    final page = read(
      'lib/features/user_profile/presentation/pages/user_profile_page.dart',
    );
    expect(page, contains('ThemeModeSwitcher('));
    expect(page, contains('LanguageSwitcher()'));
    expect(page, isNot(contains('.toggle()')));

    // A probe test in the generated project: the real theme, the real
    // components, the real controller.
    final probe = File('${projectDir.path}/test/dark_mode_probe_test.dart');
    await probe.create(recursive: true);
    await probe.writeAsString('''
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:$projectName/core/theme/theme_mode_controller.dart';
import 'package:$projectName/core/theme/theme_mode_switcher.dart';
import 'package:$projectName/i18n/strings.g.dart';
import 'package:$uiPkg/$uiPkg.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('the theme mode is light, kept when chosen, and restored by load()', () async {
    final first = ProviderContainer();
    addTearDown(first.dispose);
    expect(first.read(themeModeControllerProvider), ThemeMode.light);

    await first.read(themeModeControllerProvider.notifier).setDark();
    expect(first.read(themeModeControllerProvider), ThemeMode.dark);

    // The next start: a new container, which loads what was kept.
    final next = ProviderContainer();
    addTearDown(next.dispose);
    await next.read(themeModeControllerProvider.notifier).load();
    expect(next.read(themeModeControllerProvider), ThemeMode.dark);

    await next.read(themeModeControllerProvider.notifier).toggle();
    final after = ProviderContainer();
    addTearDown(after.dispose);
    await after.read(themeModeControllerProvider.notifier).load();
    expect(after.read(themeModeControllerProvider), ThemeMode.light);
  });

  test('a mode that is not one falls back to light', () async {
    SharedPreferences.setMockInitialValues({'theme_mode': 'sepia'});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(themeModeControllerProvider.notifier).load();

    expect(container.read(themeModeControllerProvider), ThemeMode.light);
  });

  Future<BuildContext> pumpIn(WidgetTester tester, ThemeMode mode) async {
    late BuildContext inner;
    // The generated text styles are sized with ScreenUtil, as the app's own
    // App widget sets it up: a theme can only be made inside it.
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (context, _) => MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: mode,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                inner = context;
                return const AppCard(child: Text('card'));
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return inner;
  }

  testWidgets('in dark, the page, the cards and the colours are the dark ones', (tester) async {
    final context = await pumpIn(tester, ThemeMode.dark);

    expect(Theme.of(context).brightness, Brightness.dark);
    expect(Theme.of(context).scaffoldBackgroundColor, AppColors.dark.background);
    expect(context.colors, AppColors.dark);
    final card = tester.widget<Container>(
      find.descendant(of: find.byType(AppCard), matching: find.byType(Container)).first,
    );
    expect((card.decoration! as BoxDecoration).color, AppColors.dark.surface);
    expect(Theme.of(context).textTheme.bodyLarge?.color, AppColors.dark.textPrimary);
  });

  testWidgets('the switcher offers the three modes, by name, and reports the choice', (tester) async {
    ThemeMode? chosen;
    await tester.pumpWidget(
      TranslationProvider(
        child: MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              actions: [
                ThemeModeSwitcher(mode: ThemeMode.light, onChanged: (mode) => chosen = mode),
              ],
            ),
          ),
        ),
      ),
    );
    // The button shows the mode being worn.
    expect(find.byIcon(Icons.light_mode_outlined), findsOneWidget);

    await tester.tap(find.byType(PopupMenuButton<ThemeMode>));
    await tester.pumpAndSettle();
    expect(find.text('Light'), findsOneWidget);
    expect(find.text('Dark'), findsOneWidget);
    expect(find.text('System'), findsOneWidget);

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(chosen, ThemeMode.dark);
  });

  testWidgets('in light, they are the light ones, unchanged', (tester) async {
    final context = await pumpIn(tester, ThemeMode.light);

    expect(Theme.of(context).brightness, Brightness.light);
    expect(Theme.of(context).scaffoldBackgroundColor, AppColors.light.background);
    expect(context.colors, AppColors.light);
    final card = tester.widget<Container>(
      find.descendant(of: find.byType(AppCard), matching: find.byType(Container)).first,
    );
    expect((card.decoration! as BoxDecoration).color, AppColors.light.surface);
  });
}
''');
    final run = await Process.run('flutter', [
      'test',
      'test/dark_mode_probe_test.dart',
    ], workingDirectory: projectDir.path);
    expect(
      run.exitCode,
      0,
      reason:
          'the dark mode probe failed in the generated project:\n${run.stdout}\n${run.stderr}',
    );

    await expectCleanAnalyze(projectDir);
  }, timeout: const Timeout(Duration(minutes: 15)));

  test('a packageSplit project keeps the theme mode in its core package, and '
      'analyzes cleanly', () async {
    const projectName = 'neat_dark_split_test';
    final projectDir = await generate(
      projectName: projectName,
      architecture: const ArchitectureState(packageSplit: true),
      theme: const ThemeEngineState(
        approach: ThemeApproach.customM3,
        components: {AppComponent.button, AppComponent.card},
      ),
    );
    String read(String p) => File('${projectDir.path}/$p').readAsStringSync();

    // The controller lives in core (once), with its dependency.
    expect(
      File(
        '${projectDir.path}/lib/core/theme/theme_mode_controller.dart',
      ).existsSync(),
      isFalse,
      reason: 'single-sourced in core',
    );
    final controller = read(
      'packages/core/lib/core/theme/theme_mode_controller.dart',
    );
    expect(controller, contains('Future<void> load() async'));
    expect(controller, contains("import '../utils/app_logger.dart';"));
    expect(
      File(
        '${projectDir.path}/packages/core/lib/core/utils/app_logger.dart',
      ).existsSync(),
      isTrue,
    );
    expect(read('packages/core/pubspec.yaml'), contains('shared_preferences:'));

    // The picker is single-sourced there too (no i18n here: English names), and
    // the split feature's page reads it from core.
    final switcher = read(
      'packages/core/lib/core/theme/theme_mode_switcher.dart',
    );
    expect(switcher, contains("ThemeMode.light => 'Light',"));
    expect(switcher, isNot(contains('strings.g.dart')));
    expect(
      File(
        '${projectDir.path}/lib/core/theme/theme_mode_switcher.dart',
      ).existsSync(),
      isFalse,
      reason: 'single-sourced in core',
    );
    final page =
        Directory('${projectDir.path}/packages/home/lib/presentation/pages')
            .listSync()
            .whereType<File>()
            .singleWhere((f) => f.path.endsWith('_page.dart'));
    final pageSrc = page.readAsStringSync();
    expect(
      pageSrc,
      contains("import 'package:core/core/theme/theme_mode_switcher.dart';"),
    );
    expect(pageSrc, contains('ThemeModeSwitcher('));

    // The app's bootstrap loads it from core.
    final bootstrap = read('lib/core/bootstrap.dart');
    expect(
      bootstrap,
      contains("import 'package:core/core/theme/theme_mode_controller.dart';"),
    );
    expect(bootstrap, contains('themeModeControllerProvider.notifier).load()'));

    // The theme (in the UI package) and the neutrals in it.
    final themeFiles = Directory('${projectDir.path}/packages')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('app_theme_extensions.dart'))
        .toList();
    expect(themeFiles, hasLength(1));
    expect(
      themeFiles.single.readAsStringSync(),
      contains('static const AppColors dark = AppColors('),
    );

    await expectCleanAnalyze(projectDir);
  }, timeout: const Timeout(Duration(minutes: 15)));
}

PubPackage _dep(String name, String version) =>
    PubPackage(name: name, version: version, description: '');

PubPackage _dev(String name, String version) =>
    PubPackage(name: name, version: version, description: '', isDev: true);
