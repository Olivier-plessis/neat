import 'package:flutter_test/flutter_test.dart';
import 'package:neat/features/generation/domain/models/field_spec.dart';
import 'package:neat/features/generation/domain/services/templates/dart/field_codegen.dart';

void main() {
  group('Drift column mapping', () {
    test('maps each scalar type to its column', () {
      expect(
        const FieldSpec(jsonKey: 'name', dartName: 'name').driftColumnLine(),
        'TextColumn get name => text()();',
      );
      expect(
        const FieldSpec(jsonKey: 'stock', dartName: 'stock', dartType: 'int').driftColumnLine(),
        'IntColumn get stock => integer()();',
      );
      expect(
        const FieldSpec(jsonKey: 'price', dartName: 'price', dartType: 'double').driftColumnLine(),
        'RealColumn get price => real()();',
      );
      expect(
        const FieldSpec(jsonKey: 'active', dartName: 'active', dartType: 'bool').driftColumnLine(),
        'BoolColumn get active => boolean()();',
      );
      expect(
        const FieldSpec(jsonKey: 'createdAt', dartName: 'createdAt', dartType: 'DateTime')
            .driftColumnLine(),
        'DateTimeColumn get createdAt => dateTime()();',
      );
    });

    test('nullable adds .nullable()', () {
      expect(
        const FieldSpec(jsonKey: 'note', dartName: 'note', nullable: true)
            .driftColumnLine(),
        'TextColumn get note => text().nullable()();',
      );
    });
  });

  group('fromJson / toJson', () {
    test('num coercion + DateTime parse (non-null)', () {
      expect(
        const FieldSpec(jsonKey: 'price', dartName: 'price', dartType: 'double').fromJsonExpr(),
        "(json['price'] as num).toDouble()",
      );
      expect(
        const FieldSpec(jsonKey: 'created_at', dartName: 'createdAt', dartType: 'DateTime')
            .fromJsonExpr(),
        "DateTime.parse(json['created_at'] as String)",
      );
    });

    test('nullable variants guard null', () {
      expect(
        const FieldSpec(jsonKey: 'qty', dartName: 'qty', dartType: 'int', nullable: true)
            .fromJsonExpr(),
        "(json['qty'] as num?)?.toInt()",
      );
      expect(
        const FieldSpec(jsonKey: 'at', dartName: 'at', dartType: 'DateTime', nullable: true)
            .fromJsonExpr(),
        "json['at'] == null ? null : DateTime.parse(json['at'] as String)",
      );
    });

    test('DateTime toJson serialises to ISO', () {
      expect(
        const FieldSpec(jsonKey: 'createdAt', dartName: 'createdAt', dartType: 'DateTime')
            .toJsonValue(),
        'createdAt.toIso8601String()',
      );
    });

    test('@JsonKey only when renamed', () {
      expect(
        const FieldSpec(jsonKey: 'created_at', dartName: 'createdAt')
            .jsonKeyAnnotation,
        "@JsonKey(name: 'created_at')",
      );
      expect(
        const FieldSpec(jsonKey: 'title', dartName: 'title').jsonKeyAnnotation,
        '',
      );
    });

    test('id always converts leniently — never an unsafe `as String` cast', () {
      // Real APIs (e.g. FakeStore) emit an int/num id. NEAT always types id as
      // String, but a plain `json['id'] as String` cast throws at runtime on an
      // int payload — silently, if the caller swallows the exception (the
      // offline-first repository does, to fall back to cache on network
      // errors). Regression for that bug: the id must convert, not cast.
      final id = const FieldSpec(jsonKey: 'id', dartName: 'id', isId: true).fromJsonExpr();
      expect(id, "json['id'].toString()");
      expect(id, isNot(contains('as String')));
    });
  });

  group('title field heuristic', () {
    test('prefers name/title/label', () {
      final fields = [
        const FieldSpec(jsonKey: 'id', dartName: 'id', isId: true),
        const FieldSpec(jsonKey: 'sku', dartName: 'sku'),
        const FieldSpec(jsonKey: 'title', dartName: 'title'),
      ];
      expect(titleField(fields).dartName, 'title');
    });

    test('falls back to first non-id String', () {
      final fields = [
        const FieldSpec(jsonKey: 'id', dartName: 'id', isId: true),
        const FieldSpec(jsonKey: 'sku', dartName: 'sku'),
      ];
      expect(titleField(fields).dartName, 'sku');
    });

    test('falls back to id when no String field', () {
      final fields = [
        const FieldSpec(jsonKey: 'id', dartName: 'id', isId: true),
        const FieldSpec(jsonKey: 'qty', dartName: 'qty', dartType: 'int'),
      ];
      expect(titleField(fields).dartName, 'id');
    });
  });

  group('placeholder literals', () {
    test('type-appropriate dummies, null when nullable', () {
      expect(const FieldSpec(jsonKey: 'id', dartName: 'id', isId: true).entityPlaceholder(), "'000000'");
      expect(const FieldSpec(jsonKey: 'qty', dartName: 'qty', dartType: 'int').entityPlaceholder(), '0');
      expect(const FieldSpec(jsonKey: 'p', dartName: 'p', dartType: 'double').entityPlaceholder(), '0.0');
      expect(const FieldSpec(jsonKey: 'a', dartName: 'a', dartType: 'bool').entityPlaceholder(), 'false');
      expect(const FieldSpec(jsonKey: 'n', dartName: 'n', nullable: true).entityPlaceholder(), 'null');
    });
  });
}
