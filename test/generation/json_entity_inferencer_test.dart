import 'package:flutter_test/flutter_test.dart';
import 'package:neat/features/generation/domain/models/field_spec.dart';
import 'package:neat/features/generation/domain/services/json_entity_inferencer.dart';

// ignore_for_file: avoid_dynamic_calls

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
      expect(r.warnings.any((w) => w.contains('"id" was int → coerced to String')), isTrue);
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

    // Mongo/Mongoose's own convention — a very common real-world id key that
    // isn't literally "id".
    test('recognises "_id" as the id key — no duplicate synthetic id', () {
      final r = sut.infer('{"_id": 1, "title": "Jacket"}');
      expect(r.fields.where((f) => f.isId).length, 1);
      final id = field(r.fields, 'id');
      expect(id.jsonKey, '_id');
      expect(id.isId, isTrue);
      expect(id.dartType, 'String');
      // Names the real source key ("_id"), not a hardcoded "id" that isn't
      // actually in the pasted JSON.
      expect(r.warnings.any((w) => w.contains('"_id" was int → coerced to String')), isTrue);
      expect(r.warnings.any((w) => w.contains('added a String id')), isFalse);
    });

    test('"_id" is not treated as the id in a nested object', () {
      final r = sut.infer('{"id": "1", "category": {"_id": 1, "name": "women"}}');
      final category = field(r.fields, 'category');
      expect(category.children.where((f) => f.isId).length, 0);
    });
  });

  group('nested objects & lists (Phase 1.5)', () {
    test('nested object → object field with a sub-class name + children', () {
      final r = sut.infer('{"id": "1", "rating": {"rate": 4.5, "count": 120}}');
      final rating = field(r.fields, 'rating');
      expect(rating.kind, FieldKind.object);
      expect(rating.objectName, 'Rating');
      expect(rating.children.map((f) => f.dartName), containsAll(['rate', 'count']));
      expect(field(rating.children, 'rate').dartType, 'double');
      expect(field(rating.children, 'count').dartType, 'int');
    });

    test('list of scalars → list field with scalar element', () {
      final r = sut.infer('{"id": "1", "tags": ["a", "b"]}');
      final tags = field(r.fields, 'tags');
      expect(tags.kind, FieldKind.list);
      expect(tags.element!.kind, FieldKind.scalar);
      expect(tags.element!.dartType, 'String');
    });

    test('list of objects → list field with object element (singularised name)', () {
      final r = sut.infer('{"id": "1", "items": [{"sku": "A", "qty": 2}]}');
      final items = field(r.fields, 'items');
      expect(items.kind, FieldKind.list);
      expect(items.element!.kind, FieldKind.object);
      expect(items.element!.objectName, 'Item');
      expect(items.element!.children.map((f) => f.dartName), containsAll(['sku', 'qty']));
    });

    test('deeply nested objects recurse', () {
      final r = sut.infer('{"id": "1", "meta": {"author": {"name": "Ada"}}}');
      final meta = field(r.fields, 'meta');
      final author = field(meta.children, 'author');
      expect(author.kind, FieldKind.object);
      expect(field(author.children, 'name').dartType, 'String');
    });

    test('empty array → List<String> with a warning', () {
      final r = sut.infer('{"id": "1", "tags": []}');
      expect(field(r.fields, 'tags').element!.dartType, 'String');
      expect(r.warnings.any((w) => w.contains('empty array')), isTrue);
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

  group('paginated list wrapper', () {
    test('unwraps a dummyjson-style envelope and infers from the first item', () {
      final r = sut.infer('''
        {
          "recipes": [
            {"id": 1, "name": "Classic Margherita Pizza", "ingredients": ["Pizza dough"]}
          ],
          "total": 100,
          "skip": 0,
          "limit": 30
        }
      ''');
      expect(r.fields.any((f) => f.dartName == 'name'), isTrue);
      expect(r.fields.any((f) => f.dartName == 'ingredients'), isTrue);
      // The wrapper's own fields must not leak in as if they were the entity's.
      expect(r.fields.any((f) => f.dartName == 'recipes'), isFalse);
      expect(r.fields.any((f) => f.dartName == 'total'), isFalse);
      expect(r.fields.any((f) => f.dartName == 'skip'), isFalse);
      expect(r.fields.any((f) => f.dartName == 'limit'), isFalse);
      expect(r.warnings.any((w) => w.contains('paginated list wrapper')), isTrue);
      expect(r.warnings.any((w) => w.contains('recipes[0]')), isTrue);
      // Needed at generation time so getAll() can unwrap this same key
      // instead of decoding the response as a bare array.
      expect(r.envelopeKey, 'recipes');
      // The wrapper's own scalar siblings — used to generate a typed
      // <Feature>ListModel wrapper alongside the entity, instead of
      // discarding this pagination metadata.
      expect(r.envelopeFields.map((f) => f.dartName), ['total', 'skip', 'limit']);
      expect(r.envelopeFields.every((f) => f.dartType == 'int'), isTrue);
    });

    // Real-world regression: a "data" wrapper whose item uses Mongo's own
    // "_id" convention, plus a nested object ("categories") that also has
    // its own "_id" — must not be mistaken for the entity's own id, and
    // must not produce a duplicate synthetic id.
    test('unwraps a "data" envelope with pagination fields and a Mongo-style "_id" item', () {
      final r = sut.infer('''
        {
          "data": [
            {
              "_id": 1,
              "title": "Long sleeve Jacket",
              "isNew": true,
              "oldPrice": "200",
              "price": 150,
              "size": ["S", "M", "L"],
              "categories": {"_id": 1, "name": "women", "type": "jacket"},
              "rating": 4
            }
          ],
          "totalProducts": 30,
          "totalPages": 2,
          "currentPage": 1,
          "perPage": 20
        }
      ''');
      expect(r.fields.where((f) => f.isId).length, 1);
      final id = field(r.fields, 'id');
      expect(id.jsonKey, '_id');
      expect(r.fields.any((f) => f.dartName == 'title'), isTrue);
      expect(r.fields.any((f) => f.dartName == 'data'), isFalse);
      expect(r.fields.any((f) => f.dartName == 'totalProducts'), isFalse);
      expect(r.fields.any((f) => f.dartName == 'totalPages'), isFalse);
      expect(r.fields.any((f) => f.dartName == 'currentPage'), isFalse);
      expect(r.fields.any((f) => f.dartName == 'perPage'), isFalse);
      // The nested "categories._id" is real data, not a second entity id.
      final categories = field(r.fields, 'categories');
      expect(categories.children.where((f) => f.isId).length, 0);
      expect(r.envelopeKey, 'data');
      expect(r.envelopeFields.map((f) => f.dartName), [
        'totalProducts',
        'totalPages',
        'currentPage',
        'perPage',
      ]);
    });

    test('unwraps a bare wrapper with no sibling metadata fields at all', () {
      final r = sut.infer('{"items": [{"id": "1", "sku": "A"}]}');
      expect(r.fields.any((f) => f.dartName == 'sku'), isTrue);
      expect(r.fields.any((f) => f.dartName == 'items'), isFalse);
      expect(r.envelopeKey, 'items');
      // No sibling metadata at all — the wrapper model still generates, just
      // with only the list field.
      expect(r.envelopeFields, isEmpty);
    });

    test('does not unwrap when the object already has its own id', () {
      final r = sut.infer('{"id": "1", "name": "Team A", "members": [{"name": "Alice"}]}');
      expect(r.fields.any((f) => f.dartName == 'name'), isTrue);
      expect(r.fields.any((f) => f.dartName == 'members'), isTrue);
      expect(r.warnings.any((w) => w.contains('paginated list wrapper')), isFalse);
      expect(r.envelopeKey, isNull);
      expect(r.envelopeFields, isEmpty);
    });

    test('does not unwrap when a nested object sits alongside the array', () {
      final r = sut.infer('''
        {"items": [{"sku": "A"}], "meta": {"author": "Ada"}}
      ''');
      expect(r.fields.any((f) => f.dartName == 'items'), isTrue);
      expect(r.fields.any((f) => f.dartName == 'meta'), isTrue);
      expect(r.warnings.any((w) => w.contains('paginated list wrapper')), isFalse);
      expect(r.envelopeKey, isNull);
      expect(r.envelopeFields, isEmpty);
    });

    test('does not unwrap when there are two array-of-objects fields (ambiguous)', () {
      final r = sut.infer('''
        {"items": [{"sku": "A"}], "categories": [{"name": "X"}]}
      ''');
      expect(r.fields.any((f) => f.dartName == 'items'), isTrue);
      expect(r.fields.any((f) => f.dartName == 'categories'), isTrue);
      expect(r.warnings.any((w) => w.contains('paginated list wrapper')), isFalse);
      expect(r.envelopeKey, isNull);
      expect(r.envelopeFields, isEmpty);
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

  // requireId: false — ROADMAP.md §7 Phase 2 (custom endpoint request/response
  // bodies have no natural id, unlike CRUD entities).
  group('requireId: false (endpoint request/response bodies)', () {
    test('no id is synthesised when the sample has none', () {
      final r = sut.infer('{"token": "abc", "expiresAt": "2024-01-31T10:00:00Z"}', requireId: false);
      expect(r.fields.any((f) => f.isId), isFalse);
      expect(r.fields.any((f) => f.dartName == 'token'), isTrue);
      expect(r.fields.any((f) => f.dartName == 'expiresAt'), isTrue);
    });

    test('a literal "id" field in the sample is still kept (just not forced)', () {
      final r = sut.infer('{"id": 42, "token": "abc"}', requireId: false);
      final id = r.fields.firstWhere((f) => f.dartName == 'id');
      expect(id.isId, isTrue);
      expect(id.dartType, 'String');
    });

    test('empty input falls back to an empty field list, not id/name', () {
      final r = sut.infer('', requireId: false);
      expect(r.fields, isEmpty);
      expect(r.warnings, isEmpty);
    });

    test('invalid JSON falls back to an empty field list, not id/name', () {
      final r = sut.infer('{not json', requireId: false);
      expect(r.fields, isEmpty);
      expect(r.warnings.single, contains('Invalid JSON'));
    });

    test('default requireId (unset) still guarantees an id — existing behavior untouched', () {
      final r = sut.infer('{"token": "abc"}');
      expect(r.fields.any((f) => f.isId), isTrue);
    });
  });
}
