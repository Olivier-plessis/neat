import 'package:flutter_test/flutter_test.dart';
import 'package:neat/features/generation/domain/services/templates/core_templates.dart';
import 'package:neat/features/generation/domain/services/templates/dart/core_dart_templates.dart';
import 'package:neat/features/generation/domain/services/templates/dart/data_templates.dart';
import 'package:neat/features/generation/domain/services/templates/dart/domain_templates.dart';

/// Regression coverage for the error-handling architecture aligned on architecture-reference:
/// repositories throw, UseCase.call() is the only place that catches (via
/// NetworkErrorHandler → a structured Failure) — except offline-first reads,
/// which keep their own network→cache fallback. See full_generation_integration_test.dart
/// for the executable, end-to-end proof across every httpClient/storage combo.
void main() {
  const pkg = 'demo';
  const feature = 'home';

  group('core/result/result.dart', () {
    final out = CoreDartTemplates.coreResultDart(packageName: pkg);

    test('failure is a Failure, not a String', () {
      expect(
        out,
        contains('factory Result.failure(Failure failure) = _Failure<T>;'),
      );
      expect(out, contains("import 'package:demo/core/error/failure.dart';"));
    });

    test('getOrThrow throws the Failure itself, not a wrapped Exception', () {
      expect(
        out,
        contains(
          'T getOrThrow() => fold(onSuccess: (v) => v, onFailure: (f) => throw f);',
        ),
      );
    });
  });

  group('core/usecases/use_case.dart', () {
    final out = CoreDartTemplates.coreUsecaseDart(packageName: pkg);

    test(
      'call() is the only try/catch — execute() is not wrapped by itself',
      () {
        expect(out, contains('Future<Result<T>> call(Params params) async {'));
        expect(out, contains('return Result.success(await execute(params));'));
        expect(
          out,
          contains('return Result.failure(NetworkErrorHandler.handle(e));'),
        );
      },
    );

    test('call() logs what it caught, with the stack trace — the screen only '
        'gets a generic Failure, so the cause would be written nowhere', () {
      expect(out, contains('} catch (e, stackTrace) {'));
      expect(
        out,
        contains(
          r"AppLogger.e('$runtimeType failed', error: e, stackTrace: stackTrace);",
        ),
        reason:
            r'$runtimeType must reach the generated file as-is (the template '
            'escapes it), not be interpolated by the generator',
      );
      expect(
        out,
        contains("import 'package:demo/core/utils/app_logger.dart';"),
      );
    });

    test('a Failure thrown on purpose is not logged — only the unexpected, '
        'and the log comes before the mapping', () {
      expect(out, contains('if (e is! Failure) {'));
      expect(out, contains("import 'package:demo/core/error/failure.dart';"));
      final guard = out.indexOf('if (e is! Failure) {');
      final log = out.indexOf('AppLogger.e(');
      final mapping = out.indexOf('NetworkErrorHandler.handle(e)');
      expect(guard, lessThan(log));
      expect(log, lessThan(mapping));
      expect(
        'AppLogger.e('.allMatches(out).length,
        1,
        reason: 'the log is written once, not duplicated',
      );
    });

    test('packageSplit: UseCase sits in the core package, which also holds '
        'Failure and AppLogger — every import points there', () {
      final split = CoreDartTemplates.coreUsecaseDart(packageName: 'demo_core');
      expect(
        split,
        contains("import 'package:demo_core/core/error/failure.dart';"),
      );
      expect(
        split,
        contains("import 'package:demo_core/core/utils/app_logger.dart';"),
      );
      expect(
        split,
        contains(
          "import 'package:demo_core/core/network/network_error_handler.dart';",
        ),
      );
      expect(
        split,
        contains("import 'package:demo_core/core/result/result.dart';"),
      );
      expect(split, isNot(contains('package:demo/')));
      expect(split, contains('if (e is! Failure) {'));
      expect(split, contains('AppLogger.e('));
    });

    test('imports are sorted, as the generated project\'s lints expect', () {
      final imports = RegExp(
        "^import '(.+)';",
        multiLine: true,
      ).allMatches(out).map((m) => m.group(1)!).toList();
      expect(imports, [...imports]..sort());
      expect(imports, hasLength(4));
    });

    test(
      'NoParamsUseCase is UseCase<Unit, T> — execute takes a Unit param',
      () {
        expect(
          out,
          contains(
            'abstract class NoParamsUseCase<T> extends UseCase<Unit, T> {',
          ),
        );
        expect(out, contains('Future<T> execute(Unit params);'));
        expect(out, contains('final class Unit {'));
      },
    );
  });

  group('CoreTemplates.networkErrorHandler', () {
    test('dio: maps DioException, no chopper/supabase/firebase imports', () {
      final out = CoreTemplates.networkErrorHandler(
        packageName: pkg,
        httpClient: 'dio',
      );
      expect(out, contains("import 'package:dio/dio.dart';"));
      expect(
        out,
        contains('if (error is DioException) return _handleDioError(error);'),
      );
      expect(out, isNot(contains('ChopperApiException')));
      expect(out, isNot(contains('PostgrestException')));
    });

    test('chopper: maps ChopperApiException with a status-code switch', () {
      final out = CoreTemplates.networkErrorHandler(
        packageName: pkg,
        httpClient: 'chopper',
      );
      expect(
        out,
        contains(
          'if (error is ChopperApiException) return _handleChopperError(error);',
        ),
      );
      expect(
        out,
        contains(
          'static Failure _handleChopperError(ChopperApiException error)',
        ),
      );
    });

    test('chopper without riverpod (Bloc/Cubit): still maps ChopperApiException '
        '— chopper_model_converter.dart is plain Dart, generated regardless of '
        'state management (real bug, found via a real generated project)', () {
      final out = CoreTemplates.networkErrorHandler(
        packageName: pkg,
        httpClient: 'chopper',
        hasRiverpod: false,
      );
      expect(
        out,
        contains(
          'if (error is ChopperApiException) return _handleChopperError(error);',
        ),
      );
      expect(
        out,
        contains(
          'static Failure _handleChopperError(ChopperApiException error)',
        ),
      );
    });

    test('supabase: maps AuthException + PostgrestException', () {
      final out = CoreTemplates.networkErrorHandler(
        packageName: pkg,
        httpClient: 'supabase',
      );
      expect(out, contains('if (error is AuthException)'));
      expect(out, contains('if (error is PostgrestException)'));
    });

    test('firebase: maps FirebaseException via a code-based switch', () {
      final out = CoreTemplates.networkErrorHandler(
        packageName: pkg,
        httpClient: 'firebase',
      );
      expect(out, contains('if (error is FirebaseException)'));
      expect(out, contains("'permission-denied' =>"));
    });

    test(
      'no http client: still generated, with a bare Failure passthrough + fallback',
      () {
        final out = CoreTemplates.networkErrorHandler(
          packageName: pkg,
          httpClient: '',
        );
        expect(out, contains('class NetworkErrorHandler'));
        expect(out, contains('if (error is Failure) return error;'));
        expect(
          out,
          contains("Failure(message: 'An unexpected error occurred.'"),
        );
      },
    );
  });

  group('DomainTemplates.featureIRepository', () {
    test('remote-only: reads are raw (no Result)', () {
      final out = DomainTemplates.featureIRepository(
        featureName: feature,
        packageName: pkg,
        hasHttpClient: true,
      );
      expect(out, contains('Future<List<HomeEntity>> getAll();'));
      expect(out, contains('Future<HomeEntity> getById(String id);'));
      expect(out, contains('Future<HomeEntity> create(HomeEntity entity);'));
      expect(out, isNot(contains('Result<')));
    });

    test('offline-first: reads return Result<T>; writes stay raw', () {
      final out = DomainTemplates.featureIRepository(
        featureName: feature,
        packageName: pkg,
        hasHttpClient: true,
        offlineFirst: true,
      );
      expect(out, contains('Future<Result<List<HomeEntity>>> getAll();'));
      expect(out, contains('Future<Result<HomeEntity>> getById(String id);'));
      expect(
        out,
        contains('Future<HomeEntity> create(HomeEntity entity);'),
        reason:
            'writes have no fallback strategy — they follow the generic throw/call() model',
      );
    });
  });

  group('DomainTemplates.featureGetUsecase', () {
    test('non-offline-first: raw passthrough, no Result import', () {
      final out = DomainTemplates.featureGetUsecase(
        featureName: feature,
        packageName: pkg,
      );
      expect(
        out,
        contains(
          'class GetHomeUsecase extends NoParamsUseCase<List<HomeEntity>> {',
        ),
      );
      expect(
        out,
        contains(
          'Future<List<HomeEntity>> execute(Unit _) => _repository.getAll();',
        ),
      );
      expect(out, isNot(contains('core/result/result.dart')));
    });

    test(
      'offline-first: unwraps the repository\'s Result via getOrThrow()',
      () {
        final out = DomainTemplates.featureGetUsecase(
          featureName: feature,
          packageName: pkg,
          offlineFirst: true,
        );
        expect(out, contains('final result = await _repository.getAll();'));
        expect(out, contains('return result.getOrThrow();'));
        // No Result import needed here: getOrThrow() is a plain instance method
        // (not an extension) on the sealed Result<T> class, resolvable via the
        // inferred type without importing result.dart directly — a real
        // unused_import warning was found across every offline-first
        // integration test until this was removed (see ROADMAP.md).
        expect(out, isNot(contains('core/result/result.dart')));
      },
    );
  });

  group('DomainTemplates.featureCrudUsecases', () {
    test('write usecases forward raw types — no Result wrapping', () {
      final out = DomainTemplates.featureCrudUsecases(
        featureName: feature,
        packageName: pkg,
      );
      expect(
        out,
        contains(
          'class CreateHomeUsecase extends UseCase<HomeEntity, HomeEntity> {',
        ),
      );
      expect(
        out,
        contains('class DeleteHomeUsecase extends UseCase<String, bool> {'),
      );
      expect(out, isNot(contains('Result<')));
    });
  });

  group('DataTemplates.featureRepositoryImpl', () {
    test('remote-only: no bare catch — throws, no try/catch boilerplate', () {
      final out = DataTemplates.featureRepositoryImpl(
        featureName: feature,
        packageName: pkg,
        hasHttpClient: true,
        httpClient: 'dio',
      );
      expect(out, isNot(contains('catch (')));
      expect(out, contains('Future<List<HomeEntity>> getAll() async {'));
    });

    test('chopper: unwraps via unwrapChopperResponse, not a blind .body!', () {
      final out = DataTemplates.featureRepositoryImpl(
        featureName: feature,
        packageName: pkg,
        hasHttpClient: true,
        httpClient: 'chopper',
      );
      expect(out, contains('unwrapChopperResponse(await _remote.getAll())'));
      expect(out, isNot(contains('.body!')));
    });

    test(
      'offline-first reads keep Result + AppLogger fallback (a deliberate strategy)',
      () {
        final out = DataTemplates.featureRepositoryImpl(
          featureName: feature,
          packageName: pkg,
          hasHttpClient: true,
          httpClient: 'dio',
          offlineFirst: true,
        );
        expect(
          out,
          contains('Future<Result<List<HomeEntity>>> getAll() async {'),
        );
        expect(out, contains('AppLogger.w('));
        expect(
          out,
          contains(
            "Result.failure(const Failure(message: 'Not available offline.'))",
          ),
        );
      },
    );

    test('offline-first non-sync writes throw instead of catching', () {
      final out = DataTemplates.featureRepositoryImpl(
        featureName: feature,
        packageName: pkg,
        hasHttpClient: true,
        httpClient: 'dio',
        offlineFirst: true,
      );
      expect(
        out,
        contains('Future<HomeEntity> create(HomeEntity entity) async {'),
      );
      expect(out, contains("throw const Failure(message: 'No connection.');"));
    });

    test(
      'offline-first sync-mode writes return the raw entity (optimistic, no Result)',
      () {
        final out = DataTemplates.featureRepositoryImpl(
          featureName: feature,
          packageName: pkg,
          hasHttpClient: true,
          httpClient: 'dio',
          offlineFirst: true,
          hasSync: true,
        );
        expect(
          out,
          contains('Future<HomeEntity> create(HomeEntity entity) async {'),
        );
        expect(out, contains('return entity;'));
      },
    );
  });
}
