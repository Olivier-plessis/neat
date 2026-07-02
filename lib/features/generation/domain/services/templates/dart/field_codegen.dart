import 'package:neat/features/generation/domain/models/field_spec.dart';

/// Codegen helpers that turn a [FieldSpec] (scalar / object / list, recursive)
/// into the Dart fragments the entity / model / Drift / presentation templates
/// need. Centralised so every surface renders a field identically.
///
/// Complex fields (object/list) resolve to layer-specific types ([entityType] /
/// [modelType]) and are stored as serialised JSON in the Drift cache.
extension FieldCodegen on FieldSpec {
  /// The field's type in the **entity** layer (e.g. `RatingEntity`,
  /// `List<ItemEntity>`, `String?`).
  String get entityType => _layerType('Entity');

  /// The field's type in the **model** layer (e.g. `RatingModel`).
  String get modelType => _layerType('Model');

  String _layerType(String suffix) {
    final base = switch (kind) {
      FieldKind.scalar => dartType,
      FieldKind.object => '$objectName$suffix',
      FieldKind.list => 'List<${element!._layerType(suffix)}>',
    };
    return nullable ? '$base?' : base;
  }

  /// `@JsonKey(name: 'json_key')` when the Dart name was renamed; empty
  /// otherwise. The caller places it (indentation differs per context).
  String get jsonKeyAnnotation => needsJsonKey ? "@JsonKey(name: '$jsonKey')" : '';

  /// The id is always typed `String` in NEAT's contract (CRUD/Drift/realtime all
  /// key on it), but a real API may emit an int/num id (e.g. FakeStore). A plain
  /// `as String` cast then throws at runtime — silently, if the caller wraps it
  /// in a broad try/catch (the offline-first repository does, to fall back to
  /// cache on network errors). So the id always converts leniently instead.
  String get idFromJsonName => '_idFromJson';

  /// A hand-written `fromJson` read for the plain (no json_serializable) model.
  String fromJsonExpr() {
    final raw = "json['$jsonKey']";
    if (isId) return '$raw.toString()';
    switch (kind) {
      case FieldKind.scalar:
        return _scalarFromJson(raw, dartType, nullable);
      case FieldKind.object:
        final ctor = '${objectName}Model.fromJson';
        return nullable
            ? '$raw == null ? null : $ctor($raw as Map<String, dynamic>)'
            : '$ctor($raw as Map<String, dynamic>)';
      case FieldKind.list:
        final mapExpr = '($raw as List).map((e) => ${_elementFromJson('e')}).toList()';
        return nullable ? '$raw == null ? null : $mapExpr' : mapExpr;
    }
  }

  /// fromJson for a list element ([e] is the loop variable).
  String _elementFromJson(String e) {
    final el = element!;
    return switch (el.kind) {
      FieldKind.object => '${el.objectName}Model.fromJson($e as Map<String, dynamic>)',
      FieldKind.scalar => _scalarFromJson(e, el.dartType, false),
      FieldKind.list => e, // nested lists-of-lists not inferred in V1.5
    };
  }

  static String _scalarFromJson(String raw, String type, bool nullable) {
    if (nullable) {
      return switch (type) {
        'int' => '($raw as num?)?.toInt()',
        'double' => '($raw as num?)?.toDouble()',
        'DateTime' => '$raw == null ? null : DateTime.parse($raw as String)',
        _ => '$raw as $type?',
      };
    }
    return switch (type) {
      'int' => '($raw as num).toInt()',
      'double' => '($raw as num).toDouble()',
      'DateTime' => 'DateTime.parse($raw as String)',
      _ => '$raw as $type',
    };
  }

  /// A `toJson` map entry value (e.g. `rating.toJson()`, `createdAt.toIso8601String()`).
  String toJsonValue() {
    switch (kind) {
      case FieldKind.scalar:
        if (dartType == 'DateTime') {
          return nullable ? '$dartName?.toIso8601String()' : '$dartName.toIso8601String()';
        }
        return dartName;
      case FieldKind.object:
        return nullable ? '$dartName?.toJson()' : '$dartName.toJson()';
      case FieldKind.list:
        final el = element!;
        final inner = switch (el.kind) {
          FieldKind.object => '(e) => e.toJson()',
          FieldKind.scalar => el.dartType == 'DateTime' ? '(e) => e.toIso8601String()' : null,
          FieldKind.list => null,
        };
        if (inner == null) return dartName; // list of plain scalars
        return nullable
            ? '$dartName?.map($inner).toList()'
            : '$dartName.map($inner).toList()';
    }
  }

  /// The `entity.field → model.field` expression for `Model.fromEntity()`
  /// ([e] is the entity variable). Deep-converts nested objects/lists.
  String fromEntityValue(String e) {
    final ref = '$e.$dartName';
    switch (kind) {
      case FieldKind.scalar:
        return ref;
      case FieldKind.object:
        // `$ref` is a property access (e.g. `e.rating`), not a local — Dart
        // doesn't promote it from the `== null` check, hence the explicit `!`.
        return nullable
            ? '$ref == null ? null : ${objectName}Model.fromEntity($ref!)'
            : '${objectName}Model.fromEntity($ref)';
      case FieldKind.list:
        if (element!.kind == FieldKind.object) {
          final m = '${element!.objectName}Model.fromEntity';
          return nullable ? '$ref?.map($m).toList()' : '$ref.map($m).toList()';
        }
        return ref;
    }
  }

  /// The `model.field → entity.field` expression in `toEntity()`.
  String toEntityValue() {
    switch (kind) {
      case FieldKind.scalar:
        return dartName;
      case FieldKind.object:
        return nullable ? '$dartName?.toEntity()' : '$dartName.toEntity()';
      case FieldKind.list:
        if (element!.kind == FieldKind.object) {
          return nullable
              ? '$dartName?.map((e) => e.toEntity()).toList()'
              : '$dartName.map((e) => e.toEntity()).toList()';
        }
        return dartName;
    }
  }

  /// A Drift column declaration. Scalars map to their native column; complex
  /// fields (object/list) are stored as serialised JSON in a `TextColumn`.
  String driftColumnLine() {
    if (isComplex) {
      final n = nullable ? '.nullable()' : '';
      return 'TextColumn get $dartName => text()$n();';
    }
    final builder = switch (dartType) {
      'int' => 'integer',
      'double' => 'real',
      'bool' => 'boolean',
      'DateTime' => 'dateTime',
      _ => 'text',
    };
    final column = switch (dartType) {
      'int' => 'IntColumn',
      'double' => 'RealColumn',
      'bool' => 'BoolColumn',
      'DateTime' => 'DateTimeColumn',
      _ => 'TextColumn',
    };
    final nullableCall = nullable ? '.nullable()' : '';
    return '$column get $dartName => $builder()$nullableCall();';
  }

  /// `model.field` → the value stored in a Drift row column. Complex fields are
  /// JSON-encoded; scalars pass through.
  String driftEncode(String modelVar) {
    final ref = '$modelVar.$dartName';
    if (!isComplex) return ref;
    final bang = nullable ? '!' : '';
    final encodeBody = switch (kind) {
      FieldKind.object => 'jsonEncode($ref$bang.toJson())',
      FieldKind.list => element!.kind == FieldKind.object
          ? 'jsonEncode($ref$bang.map((e) => e.toJson()).toList())'
          : 'jsonEncode($ref$bang)',
      FieldKind.scalar => ref,
    };
    return nullable ? '$ref == null ? null : $encodeBody' : encodeBody;
  }

  /// `row.field` → the model value rebuilt from a Drift column.
  String driftDecode(String rowVar) {
    final ref = '$rowVar.$dartName';
    if (!isComplex) return ref;
    final decodeBody = switch (kind) {
      FieldKind.object =>
        '${objectName}Model.fromJson(jsonDecode($ref${nullable ? '!' : ''}) as Map<String, dynamic>)',
      FieldKind.list => element!.kind == FieldKind.object
          ? '(jsonDecode($ref${nullable ? '!' : ''}) as List).map((e) => ${element!.objectName}Model.fromJson(e as Map<String, dynamic>)).toList()'
          : '(jsonDecode($ref${nullable ? '!' : ''}) as List).cast<${element!.dartType}>()',
      FieldKind.scalar => ref,
    };
    return nullable ? '$ref == null ? null : $decodeBody' : decodeBody;
  }

  /// A synthetic value for the skeleton placeholder instance (entity layer).
  String entityPlaceholder() {
    if (nullable) return 'null';
    switch (kind) {
      case FieldKind.scalar:
        return switch (dartType) {
          'int' => '0',
          'double' => '0.0',
          'bool' => 'false',
          'DateTime' => 'DateTime(2024)',
          _ => isId ? "'000000'" : "'Placeholder $dartName'",
        };
      case FieldKind.object:
        final args = children.map((c) => '${c.dartName}: ${c.entityPlaceholder()}').join(', ');
        return '${objectName}Entity($args)';
      case FieldKind.list:
        return 'const []';
    }
  }
}

/// All distinct object specs reachable from [fields] (object fields + list
/// element objects), recursively — one generated sub-class per entry. Dedupes
/// by [FieldSpec.objectName] (first wins).
List<FieldSpec> collectObjectSpecs(List<FieldSpec> fields) {
  final out = <FieldSpec>[];
  final seen = <String>{};
  void visit(List<FieldSpec> fs) {
    for (final f in fs) {
      switch (f.kind) {
        case FieldKind.scalar:
          break;
        case FieldKind.object:
          if (seen.add(f.objectName)) {
            out.add(f);
            visit(f.children);
          }
        case FieldKind.list:
          final el = f.element!;
          if (el.kind == FieldKind.object && seen.add(el.objectName)) {
            out.add(el);
            visit(el.children);
          }
      }
    }
  }

  visit(fields);
  return out;
}

/// Picks the field shown as the list tile's title: the first scalar String field
/// named name/title/label, else the first non-id scalar String, else the id.
FieldSpec titleField(List<FieldSpec> fields) {
  const preferred = {'name', 'title', 'label'};
  for (final f in fields) {
    if (f.isScalar && f.dartType == 'String' && preferred.contains(f.dartName.toLowerCase())) {
      return f;
    }
  }
  for (final f in fields) {
    if (!f.isId && f.isScalar && f.dartType == 'String') return f;
  }
  return fields.firstWhere((f) => f.isId, orElse: () => fields.first);
}

/// The id field (always present after inference).
FieldSpec idField(List<FieldSpec> fields) =>
    fields.firstWhere((f) => f.isId, orElse: () => fields.first);
