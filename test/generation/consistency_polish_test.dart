import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neat/core/contract/neat_contract.dart';
import 'package:neat/features/architecture/presentation/lines/crud_lines.dart';
import 'package:neat/features/feature_gen/domain/models/feature_gen_options.dart';
import 'package:neat/features/feature_gen/presentation/widgets/layer_toggle.dart';
import 'package:neat/features/generation/domain/models/field_spec.dart';
import 'package:neat/features/generation/domain/services/templates/agents_md_template.dart';
import 'package:neat/features/generation/domain/services/templates/core_package_templates.dart';
import 'package:neat/features/generation/domain/services/templates/core_templates.dart';
import 'package:neat/features/generation/domain/services/templates/dart/auth_templates.dart';
import 'package:neat/features/generation/domain/services/templates/dart/i18n_templates.dart';
import 'package:neat/features/generation/domain/services/templates/dart/presentation_templates.dart';
import 'package:neat/features/generation/domain/usecases/writers/i18n_writer.dart';
import 'package:neat/features/generation/domain/usecases/writers/pubspec_writer.dart';
import 'package:neat_ui/neat_ui.dart';

/// ROADMAP §5z — consistency and polish found building archy: the Workshop
/// honours `generateI18n`, feature packages follow the project SDK, the
/// Riverpod observer stops printing state, sign-up tells "confirm your email"
/// from "signed in", and the Workshop's preview/toggles stop lying.
void main() {
  group('D1 — the Workshop honours generateI18n', () {
    late Directory root;
    setUp(() => root = Directory.systemTemp.createTempSync('neat_i18n_test_'));
    tearDown(() => root.deleteSync(recursive: true));

    void seed(String dir, {bool csv = false}) {
      Directory(dir).createSync(recursive: true);
      File('$dir/en.i18n.json').writeAsStringSync(I18nTemplates.baseTranslations('home'));
      File('$dir/fr.i18n.json').writeAsStringSync(I18nTemplates.frTranslations('home'));
      if (csv) File('$dir/strings.i18n.csv').writeAsStringSync('key,en\n');
    }

    Map<String, dynamic> read(String path) =>
        jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

    test('adds title + empty under the feature key in every locale; keeps the rest', () async {
      seed('${root.path}/lib/i18n');
      final ok = await I18nWriter.addFeatureKeys(projectPath: root.path, featureName: 'worksite_item');
      expect(ok, isTrue);
      final en = read('${root.path}/lib/i18n/en.i18n.json');
      final fr = read('${root.path}/lib/i18n/fr.i18n.json');
      expect(en['worksiteItem'], {'title': 'WorksiteItem', 'empty': 'No items yet.'});
      expect((fr['worksiteItem'] as Map)['empty'], 'Rien à afficher pour le moment.');
      expect(en['home'], isNotNull, reason: 'existing keys are untouched');
      expect(en['appName'], 'My App');
    });

    test('packageSplit: the sources live in the core package', () async {
      seed('${root.path}/packages/core/lib/i18n');
      final ok = await I18nWriter.addFeatureKeys(
        projectPath: root.path,
        featureName: 'task',
        corePackageName: 'core',
      );
      expect(ok, isTrue);
      expect(read('${root.path}/packages/core/lib/i18n/en.i18n.json')['task'], isNotNull);
    });

    test('never overwrites a translation; fills only what the page reads', () async {
      seed('${root.path}/lib/i18n');
      File('${root.path}/lib/i18n/en.i18n.json').writeAsStringSync(
        jsonEncode({
          'task': {'title': 'My tasks'},
        }),
      );
      await I18nWriter.addFeatureKeys(projectPath: root.path, featureName: 'task');
      final task = read('${root.path}/lib/i18n/en.i18n.json')['task'] as Map;
      expect(task['title'], 'My tasks');
      expect(task['empty'], 'No items yet.');
    });

    test('a CSV-imported project, or no slang sources, is left alone (page stays plain)', () async {
      seed('${root.path}/lib/i18n', csv: true);
      expect(await I18nWriter.addFeatureKeys(projectPath: root.path, featureName: 'task'), isFalse);
      expect(read('${root.path}/lib/i18n/en.i18n.json')['task'], isNull);
      expect(
        await I18nWriter.addFeatureKeys(projectPath: '${root.path}/nowhere', featureName: 'task'),
        isFalse,
      );
    });

    test('the page reads context.t instead of hardcoding its strings', () {
      String page({required bool i18n}) => PresentationTemplates.featurePage(
        featureName: 'worksite',
        packageName: 'demo',
        hasRiverpod: true,
        useAnnotations: true,
        hasBloc: false,
        useCubit: false,
        dataList: true,
        i18n: i18n,
      );
      final on = page(i18n: true);
      expect(on, contains('Text(context.t.worksite.title)'));
      expect(on, contains('Text(context.t.worksite.empty)'));
      expect(on, isNot(contains("'No items yet.'")));
      final off = page(i18n: false);
      expect(off, contains("const Text('Worksite')"));
      expect(off, contains("'No items yet.'"));
    });

    test('the launch-time translations carry the empty key too', () {
      for (final t in [
        I18nTemplates.baseTranslations('home'),
        I18nTemplates.frTranslations('home'),
        I18nTemplates.deTranslations('home'),
        I18nTemplates.itTranslations('home'),
        I18nTemplates.spTranslations('home'),
      ]) {
        final home = (jsonDecode(t) as Map<String, dynamic>)['home'] as Map<String, dynamic>;
        expect(home['empty'], isA<String>());
      }
    });
  });

  group('D2 — feature packages follow the project SDK', () {
    test('reads the constraint from a flutter-create pubspec', () {
      const pubspec = 'name: demo\nenvironment:\n  sdk: ^3.13.2\n\ndependencies:\n  flutter:\n    sdk: flutter\n';
      expect(PubspecWriter.readSdkConstraint(pubspec), '^3.13.2');
      expect(PubspecWriter.readSdkConstraint('name: demo\n'), CorePackageTemplates.defaultSdkConstraint);
    });

    test('the feature package uses it (it used to be a hardcoded ^3.7.0)', () {
      final code = CorePackageTemplates.featurePackagePubspec(
        featurePackageName: 'worksite',
        corePackageName: 'core',
        sdkConstraint: '^3.13.2',
      );
      expect(code, contains('  sdk: ^3.13.2'));
      expect(code, isNot(contains('^3.7.0')));
    });

    test('depends on the extracted UI package only when there is one', () {
      expect(
        CorePackageTemplates.featurePackagePubspec(
          featurePackageName: 'worksite',
          corePackageName: 'core',
          uiPackage: 'demo_ui',
        ),
        contains('  demo_ui:\n    path: ../demo_ui'),
      );
      expect(
        CorePackageTemplates.featurePackagePubspec(featurePackageName: 'worksite', corePackageName: 'core'),
        isNot(contains('_ui')),
      );
    });
  });

  group('D3 — the Riverpod observer never logs state', () {
    final code = CoreTemplates.riverpodObserver(packageName: 'demo', useAnnotations: true);

    test('add / update log the provider name only', () {
      expect(code, contains(r"'add     ${context.provider.name ?? context.provider.runtimeType}'"));
      expect(code, contains(r"'update  ${context.provider.name ?? context.provider.runtimeType}'"));
    });

    test('no value is interpolated anywhere', () {
      expect(code, isNot(contains(r'$value')));
      expect(code, isNot(contains(r'$previousValue')));
      expect(code, isNot(contains(r'$newValue')));
      expect(code, isNot(contains('→')));
    });
  });

  group('D4 — sign-up tells "confirm your email" from "signed in"', () {
    test('the contract', () {
      final code = AuthTemplates.iAuthRepository(packageName: 'demo');
      expect(code, contains('enum SignUpOutcome {'));
      expect(code, contains('confirmationEmailSent,'));
      expect(code, contains('signedIn,'));
      expect(code, contains('Future<Result<SignUpOutcome>> signUp('));
      expect(code, contains('Future<Result<bool>> resendSignUpConfirmation(String email);'));
    });

    test('Supabase: no session after sign-up means a confirmation email was sent; resend uses OtpType.signup', () {
      final code = AuthTemplates.authRepositoryImpl(packageName: 'demo');
      expect(code, contains('response.session == null'));
      expect(code, contains('SignUpOutcome.confirmationEmailSent'));
      expect(code, contains('SignUpOutcome.signedIn'));
      expect(code, contains('type: OtpType.signup'));
      expect(code, contains('emailRedirectTo: _emailRedirectTo'));
      expect(code, contains('statusCode: int.tryParse(e.statusCode'));
    });

    test('Firebase signs in right away; resend re-sends the verification email', () {
      final code = AuthTemplates.authRepositoryImpl(packageName: 'demo', backend: 'firebase');
      expect(code, contains('return SignUpOutcome.signedIn;'));
      expect(code, contains('sendEmailVerification()'));
    });

    test('the sign-up screen reacts: a note + resend only when confirmation is pending', () {
      final screen = AuthTemplates.signupScreen(packageName: 'demo');
      expect(screen, contains("import 'package:demo/features/auth/domain/repositories/i_auth_repository.dart';"));
      expect(screen, contains('if (outcome == SignUpOutcome.confirmationEmailSent)'));
      expect(screen, contains('confirmationSent.value = true;'));
      expect(screen, contains('resendSignUpConfirmation(email.text.trim())'));
      expect(screen, contains(r"'${email.text.trim()}. Open it on this device to finish.'"));
      expect(screen, contains('Resend the email'));
    });

    test('split auth package: same-package relative import', () {
      final screen = AuthTemplates.signupScreen(
        packageName: 'demo',
        corePackageName: 'core',
        authPackageName: 'auth',
      );
      expect(screen, contains("import '../../domain/repositories/i_auth_repository.dart';"));
    });

    test('login and forgot-password screens are unchanged', () {
      for (final screen in [
        AuthTemplates.loginScreen(packageName: 'demo'),
        AuthTemplates.forgotPasswordScreen(packageName: 'demo'),
      ]) {
        expect(screen, contains('onSuccess: (_) {}'));
        expect(screen, isNot(contains('SignUpOutcome')));
        expect(screen, isNot(contains('confirmationSent')));
      }
    });
  });

  group('D5 — the Workshop preview tells the truth', () {
    const supabaseSplit = NeatContract(
      projectName: 'archy',
      architecture: 'feature_first',
      stateManagement: 'riverpod',
      navigation: 'go_router_builder',
      httpClient: 'supabase',
      themeApproach: 'customM3',
      storageStrategy: 'offlineFirstSync',
      packageSplit: true,
    );
    const options = FeatureGenOptions(
      name: 'worksite',
      fields: [
        FieldSpec(jsonKey: 'id', dartName: 'id', isId: true),
        FieldSpec(jsonKey: 'status', dartName: 'status', kind: FieldKind.enumeration, enumValues: ['a', 'b']),
      ],
    );

    test('packageSplit: packages/<name>/ with its pubspec and lib/, not lib/features/', () {
      final lines = crudLines('worksite', true, options, supabaseSplit);
      expect(lines.first, 'packages/worksite/');
      expect(lines, contains('├── pubspec.yaml'));
      expect(lines, contains('└── lib/'));
      expect(lines.any((l) => l.contains('lib/features')), isFalse);
      expect(lines, contains('    ├── data/'), reason: 'layers sit under lib/');
    });

    test('shows the Drift table + DAO, the migration and the enum file', () {
      final lines = crudLines('worksite', true, options, supabaseSplit);
      expect(lines, contains('packages/archy_database/lib/src/'));
      expect(lines, contains('├── table/worksite_table.dart'));
      expect(lines, contains('└── dao/worksite_dao.dart'));
      expect(lines, contains('supabase/migrations/'));
      expect(lines, contains('└── <timestamp>_create_worksites.sql'));
      expect(lines.any((l) => l.endsWith('worksite_status.dart')), isTrue);
    });

    test('the configured table name shows in the migration line', () {
      final lines = crudLines('person', true, options.copyWith(name: 'person', tableName: 'people'), supabaseSplit);
      expect(lines, contains('└── <timestamp>_create_people.sql'));
    });

    test('a flat REST remote-only project keeps its simple tree', () {
      const rest = NeatContract(
        projectName: 'shop',
        architecture: 'feature_first',
        stateManagement: 'riverpod',
        navigation: 'go_router',
        httpClient: 'dio',
        themeApproach: 'none',
        storageStrategy: 'remoteOnly',
      );
      final lines = crudLines('order', true, options.copyWith(name: 'order', fields: FieldSpec.idName), rest);
      expect(lines.first, 'lib/features/order/');
      expect(lines.any((l) => l.contains('_database') || l.contains('supabase')), isFalse);
    });

    testWidgets('a locked toggle paints as ON (a disabled switch used to look off)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: LayerToggle(title: 'Data Mapper', subtitle: 'always on', value: true, enabled: false, locked: true),
          ),
        ),
      );
      final sw = tester.widget<Switch>(find.byType(Switch));
      expect(sw.value, isTrue);
      final thumb = sw.thumbColor!.resolve({WidgetState.disabled, WidgetState.selected});
      expect(thumb, Palette.colorPrimaryCyan);
      expect(sw.trackColor!.resolve({WidgetState.disabled, WidgetState.selected}), isNotNull);
    });

    testWidgets('an ordinary toggle keeps the theme colours', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: LayerToggle(title: 'x', subtitle: 'y', value: true, enabled: true, onChanged: (_) {}),
          ),
        ),
      );
      final sw = tester.widget<Switch>(find.byType(Switch));
      expect(sw.thumbColor, isNull);
      expect(sw.trackColor, isNull);
    });
  });

  group('D6 — AGENTS.md documents enums, client ids and migrations', () {
    NeatContract contract({String client = 'supabase', String storage = 'offlineFirstSync'}) => NeatContract(
      projectName: 'archy',
      architecture: 'feature_first',
      stateManagement: 'riverpod',
      navigation: 'go_router_builder',
      httpClient: client,
      themeApproach: 'customM3',
      storageStrategy: storage,
    );

    test('Supabase + sync: all of it', () {
      final md = AgentsMdTemplate.generate(contract());
      expect(md, contains('domain enums** carrying their database text (`value`)'));
      expect(md, contains('fallback is the **first** value'));
      expect(md, contains('`enum` type'));
      expect(md, contains('`CHECK`'));
      expect(md, contains('client-side id'));
      expect(md, contains('`create` factory (uuid v4)'));
      expect(md, contains('Database-only columns (`owner_id`, `created_at`, `updated_at`)'));
      expect(md, contains('| `supabase/migrations/**` |'));
      expect(md, contains('**The database is described in `supabase/migrations/`**'));
    });

    test('no Supabase → no migration / database-only talk; no sync → no client ids', () {
      final md = AgentsMdTemplate.generate(contract(client: 'dio', storage: 'remoteOnly'));
      expect(md, contains('domain enums'));
      expect(md, isNot(contains('supabase/migrations')));
      expect(md, isNot(contains('owner_id')));
      expect(md, isNot(contains('client-side id')));
      expect(md, isNot(contains('`CHECK`')));
    });
  });
}
