import 'package:flutter_test/flutter_test.dart';
import 'package:neat/features/generation/domain/models/field_spec.dart';
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

  group('listEnvelopeKey — getAll() decodes a typed <Feature>ListModel '
      'wrapper instead of a bare array (real bug: dummyjson-style responses '
      'throw "JsonConverter expected response body to be Iterable<Model>, '
      'but got Map" at runtime otherwise)', () {
    const envelopeFields = [
      FieldSpec(jsonKey: 'total', dartName: 'total', dartType: 'int'),
      FieldSpec(jsonKey: 'skip', dartName: 'skip', dartType: 'int'),
      FieldSpec(jsonKey: 'limit', dartName: 'limit', dartType: 'int'),
    ];

    test('featureModel: generates a RecipeListModel with a typed list field '
        '+ the wrapper\'s own scalar siblings — no fromEntity/toEntity (pure '
        'transport shape, not a domain concept)', () {
      final code = DataTemplates.featureModel(
        featureName: 'recipe',
        hasFreezed: true,
        hasJsonSerializable: true,
        listEnvelopeKey: 'recipes',
        envelopeFields: envelopeFields,
      );
      expect(code, contains('abstract class RecipeListModel with _\$RecipeListModel'));
      expect(code, contains('required List<RecipeModel> recipes,'));
      expect(code, contains('required int total,'));
      expect(code, contains('required int skip,'));
      expect(code, contains('required int limit,'));
      expect(
        code,
        contains(
          'factory RecipeListModel.fromJson(Map<String, dynamic> json) =>\n'
          '      _\$RecipeListModelFromJson(json);',
        ),
      );
      expect(code, isNot(contains('RecipeListModel.fromEntity')));
      expect(code, isNot(contains('RecipeListModel toEntity')));
    });

    test('featureModel: the wrapper\'s list field gets @JsonKey only when the '
        'envelope key needs renaming', () {
      final renamed = DataTemplates.featureModel(
        featureName: 'order',
        hasFreezed: true,
        hasJsonSerializable: true,
        listEnvelopeKey: 'order_list',
      );
      expect(renamed, contains("@JsonKey(name: 'order_list')"));
      expect(renamed, contains('required List<OrderModel> orderList,'));

      final plain = DataTemplates.featureModel(
        featureName: 'recipe',
        hasFreezed: true,
        hasJsonSerializable: true,
        listEnvelopeKey: 'recipes',
      );
      // No @JsonKey directly above the wrapper's list field specifically
      // (the entity's own `id` field always carries its own, unrelated,
      // @JsonKey(fromJson: ...) — this checks the wrapper class only).
      expect(
        plain,
        contains(
          'abstract class RecipeListModel with _\$RecipeListModel {\n'
          '  const factory RecipeListModel({\n'
          '    required List<RecipeModel> recipes,',
        ),
      );
    });

    test('featureModel: no envelope key generates no wrapper class at all', () {
      final code = DataTemplates.featureModel(featureName: 'recipe', hasFreezed: true, hasJsonSerializable: true);
      expect(code, isNot(contains('ListModel')));
    });

    test('chopper featureApiSource: getAll() returns Response<RecipeListModel>, '
        'not Response<List<Model>>', () {
      final code = DataTemplates.featureApiSource(
        featureName: 'recipe',
        httpClient: 'chopper',
        apiPath: '/recipes',
        listEnvelopeKey: 'recipes',
      );
      expect(code, contains('Future<Response<RecipeListModel>> getAll();'));
      expect(code, isNot(contains('Future<Response<List<RecipeModel>>> getAll();')));
      // The other 4 operations are untouched — only getAll()'s response is
      // ever a paginated wrapper.
      expect(code, contains('Future<Response<RecipeModel>> getById(@Path() String id);'));
    });

    test('chopper featureApiSource: no envelope key keeps the original bare '
        'array signature', () {
      final code = DataTemplates.featureApiSource(
        featureName: 'recipe',
        httpClient: 'chopper',
        apiPath: '/recipes',
      );
      expect(code, contains('Future<Response<List<RecipeModel>>> getAll();'));
    });

    test('chopper featureRepositoryImpl (remote-only): getAll() accesses the '
        'wrapper\'s list field — no manual Map casting', () {
      final code = DataTemplates.featureRepositoryImpl(
        featureName: 'recipe',
        packageName: 'demo',
        hasHttpClient: true,
        httpClient: 'chopper',
        listEnvelopeKey: 'recipes',
      );
      expect(code, contains('unwrapChopperResponse(await _remote.getAll()).recipes'));
      expect(code, isNot(contains('as Map<String, dynamic>')));
      expect(code, isNot(contains('.cast<Map<String, dynamic>>()')));
      // getById/create/update/delete are untouched — still the plain unwrap.
      expect(code, contains('unwrapChopperResponse(await _remote.getById(id))'));
    });

    test('chopper featureRepositoryImpl (offline-first): getAll() unwraps '
        'before caching', () {
      final code = DataTemplates.featureRepositoryImpl(
        featureName: 'recipe',
        packageName: 'demo',
        hasHttpClient: true,
        httpClient: 'chopper',
        offlineFirst: true,
        listEnvelopeKey: 'recipes',
      );
      expect(code, contains('unwrapChopperResponse(await _remote.getAll()).recipes'));
      expect(code, contains('await _local.cacheAll(fresh)'));
    });

    test('featureRepositoryProviders: registers both the entity Model\'s '
        'decoder and the wrapper ListModel\'s decoder', () {
      final code = DataTemplates.featureRepositoryProviders(
        featureName: 'recipe',
        packageName: 'demo',
        httpClient: 'chopper',
        offlineFirst: false,
        corePackageName: 'core',
        listEnvelopeKey: 'recipes',
      );
      expect(code, contains('chopperModelDecoders[RecipeModel] = RecipeModel.fromJson;'));
      expect(code, contains('chopperModelDecoders[RecipeListModel] = RecipeListModel.fromJson;'));
    });

    test('featureRepositoryProviders: no envelope key registers only the '
        'entity Model\'s decoder', () {
      final code = DataTemplates.featureRepositoryProviders(
        featureName: 'recipe',
        packageName: 'demo',
        httpClient: 'chopper',
        offlineFirst: false,
        corePackageName: 'core',
      );
      expect(code, isNot(contains('RecipeListModel')));
    });

    test('dio featureApiSource: getAll() decodes the typed wrapper then '
        'accesses its list field (self-contained, no repository change '
        'needed)', () {
      final code = DataTemplates.featureApiSource(
        featureName: 'recipe',
        httpClient: 'dio',
        apiPath: '/recipes',
        listEnvelopeKey: 'recipes',
      );
      expect(code, contains("_dio.get<Map<String, dynamic>>('/recipes')"));
      expect(code, contains('RecipeListModel.fromJson(response.data!).recipes'));
      expect(code, isNot(contains('_dio.get<List<dynamic>>')));
    });

    test('dio featureApiSource: no envelope key keeps the original bare '
        'array decode', () {
      final code = DataTemplates.featureApiSource(
        featureName: 'recipe',
        httpClient: 'dio',
        apiPath: '/recipes',
      );
      expect(code, contains("_dio.get<List<dynamic>>('/recipes')"));
    });
  });
}
