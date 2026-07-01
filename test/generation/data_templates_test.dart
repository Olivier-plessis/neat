import 'package:flutter_test/flutter_test.dart';
import 'package:neat/features/generation/domain/services/templates/dart/data_templates.dart';

void main() {
  group('featureRepositoryImpl — offline-first read failures are logged, not swallowed', () {
    // Regression: a silent `catch (_) {}` in getAll()/getById() made a 404,
    // a bad base URL, or a parse error look identical to "device is offline" —
    // the offline-first fallback returned an empty cache with zero visibility.
    // This bit twice in real generated projects before the fix.
    final code = DataTemplates.featureRepositoryImpl(
      featureName: 'product',
      packageName: 'demo',
      hasHttpClient: true,
      httpClient: 'chopper',
      offlineFirst: true,
    );

    test('getAll() logs the error before falling back to cache', () {
      expect(code, contains("AppLogger.w('product.getAll() failed"));
      expect(code, contains('error: e, stackTrace: st'));
    });

    test('getById() logs the error before falling back to cache', () {
      expect(code, contains("AppLogger.w('product.getById() failed"));
    });

    test('imports AppLogger', () {
      expect(code, contains("import 'package:demo/core/utils/app_logger.dart';"));
    });

    test('no bare catch (_) left in the read paths', () {
      expect(code, isNot(contains('catch (_)')));
    });
  });
}
