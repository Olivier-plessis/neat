import 'package:flutter_test/flutter_test.dart';
import 'package:neat/features/generation/domain/models/field_spec.dart';
import 'package:neat/features/generation/domain/services/json_entity_inferencer.dart';

void main() {
  const sut = JsonEntityInferencer();

  FieldSpec field(List<FieldSpec> fs, String dartName) =>
      fs.firstWhere((f) => f.dartName == dartName);

  group('scalar type inference', () {
    test('maps String/int/double/bool to Dart types', () {
      final r = sut.infer('''
        {"id": "1", "title": "Tee", "price": 9.99, "stock": 12, "active": true}
      ''');
      expect(field(r.fields, 'title').dartType, 'String');
      expect(field(r.fields, 'price').dartType, 'double');
      expect(field(r.fields, 'stock').dartType, 'int');
      expect(field(r.fields, 'active').dartType, 'bool');
    });

    test('ISO-8601 strings become DateTime', () {
      final r = sut.infer('{"id": "1", "created_at": "2024-01-31T10:00:00Z", "day": "2024-01-31"}');
      expect(field(r.fields, 'createdAt').dartType, 'DateTime');
      expect(field(r.fields, 'day').dartType, 'DateTime');
    });

    test('plain strings stay String', () {
      final r = sut.infer('{"id": "1", "label": "2024 collection"}');
      expect(field(r.fields, 'label').dartType, 'String');
    });
  });

  group('id guarantee', () {
    test('coerces an int id to String with a warning', () {
      final r = sut.infer('{"id": 42, "name": "Ada"}');
      final id = field(r.fields, 'id');
      expect(id.dartType, 'String');
      expect(id.isId, isTrue);
      expect(id.nullable, isFalse);
      expect(r.warnings.any((w) => w.contains('coerced to String')), isTrue);
    });

    test('synthesises a String id when absent (placed first)', () {
      final r = sut.infer('{"title": "Tee"}');
      expect(r.fields.first.isId, isTrue);
      expect(r.fields.first.dartType, 'String');
      expect(r.warnings.any((w) => w.contains('added a String id')), isTrue);
    });

    test('exactly one id field', () {
      final r = sut.infer('{"id": "1", "name": "x"}');
      expect(r.fields.where((f) => f.isId).length, 1);
    });
  });

  group('nested / null handling (flat V1)', () {
    test('drops nested objects and arrays with warnings', () {
      final r = sut.infer('''
        {"id": "1", "name": "x", "rating": {"rate": 4.5}, "tags": ["a", "b"]}
      ''');
      expect(r.fields.any((f) => f.dartName == 'rating'), isFalse);
      expect(r.fields.any((f) => f.dartName == 'tags'), isFalse);
      expect(r.warnings.where((w) => w.contains('dropped')).length, 2);
    });

    test('null value → nullable String with a warning', () {
      final r = sut.infer('{"id": "1", "deletedAt": null}');
      final f = field(r.fields, 'deletedAt');
      expect(f.dartType, 'String');
      expect(f.nullable, isTrue);
      expect(r.warnings.any((w) => w.contains('null in the sample')), isTrue);
    });
  });

  group('key normalisation', () {
    test('snake_case → camelCase and flags @JsonKey need', () {
      final r = sut.infer('{"id": "1", "created_at": "2024-01-31"}');
      final f = field(r.fields, 'createdAt');
      expect(f.jsonKey, 'created_at');
      expect(f.needsJsonKey, isTrue);
    });

    test('matching key needs no @JsonKey', () {
      final r = sut.infer('{"id": "1", "title": "x"}');
      expect(field(r.fields, 'title').needsJsonKey, isFalse);
    });

    test('reserved words are escaped', () {
      final r = sut.infer('{"id": "1", "class": "premium"}');
      expect(r.fields.any((f) => f.dartName == 'classField'), isTrue);
      expect(r.warnings.any((w) => w.contains('keyword')), isTrue);
    });

    test('kebab-case and spaces normalise', () {
      final r = sut.infer('{"id": "1", "is-active": true, "first name": "Ada"}');
      expect(r.fields.any((f) => f.dartName == 'isActive'), isTrue);
      expect(r.fields.any((f) => f.dartName == 'firstName'), isTrue);
    });
  });

  group('input shapes', () {
    test('top-level array infers from the first element', () {
      final r = sut.infer('[{"id": "1", "title": "a"}, {"id": "2"}]');
      expect(r.fields.any((f) => f.dartName == 'title'), isTrue);
    });

    test('invalid JSON falls back to id/name', () {
      final r = sut.infer('{not json');
      expect(r.fields, FieldSpec.idName);
      expect(r.warnings.single, contains('Invalid JSON'));
    });

    test('empty input falls back to id/name silently', () {
      final r = sut.infer('   ');
      expect(r.fields, FieldSpec.idName);
      expect(r.warnings, isEmpty);
    });

    test('empty array falls back to id/name', () {
      final r = sut.infer('[]');
      expect(r.fields, FieldSpec.idName);
    });
  });
}
