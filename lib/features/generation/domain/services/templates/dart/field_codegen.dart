import 'package:neat/features/generation/domain/models/field_spec.dart';
import 'package:neat/features/generation/domain/services/templates/dart/_template_utils.dart';

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
      // The domain holds the enum; the DTO (and the Drift row) its plain text.
      FieldKind.enumeration => suffix == 'Entity' ? resolvedEnumName : 'String',
    };
    return nullable ? '$base?' : base;
  }

  /// [enumName], or — before generation has resolved it (see
  /// [resolveEnumNames]) — the PascalCase JSON key, so a template called
  /// directly still renders something that compiles.
  String get resolvedEnumName =>
      enumName.isNotEmpty ? enumName : pascal(jsonKey);

  /// The generated enum's file name (without `.dart`): `worksite_status`.
  String get enumFileName => snakeCase(resolvedEnumName);

  /// `@JsonKey(name: 'json_key')` when the Dart name was renamed; empty
  /// otherwise. The caller places it (indentation differs per context).
  String get jsonKeyAnnotation =>
      needsJsonKey ? "@JsonKey(name: '$jsonKey')" : '';

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
      case FieldKind.enumeration:
        return _scalarFromJson(raw, 'String', nullable);
      case FieldKind.object:
        final ctor = '${objectName}Model.fromJson';
        return nullable
            ? '$raw == null ? null : $ctor($raw as Map<String, dynamic>)'
            : '$ctor($raw as Map<String, dynamic>)';
      case FieldKind.list:
        final mapExpr =
            '($raw as List).map((e) => ${_elementFromJson('e')}).toList()';
        return nullable ? '$raw == null ? null : $mapExpr' : mapExpr;
    }
  }

  /// fromJson for a list element ([e] is the loop variable).
  String _elementFromJson(String e) {
    final el = element!;
    return switch (el.kind) {
      FieldKind.object =>
        '${el.objectName}Model.fromJson($e as Map<String, dynamic>)',
      FieldKind.scalar => _scalarFromJson(e, el.dartType, false),
      FieldKind.enumeration => _scalarFromJson(e, 'String', false),
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
          return nullable
              ? '$dartName?.toIso8601String()'
              : '$dartName.toIso8601String()';
        }
        return dartName;
      case FieldKind.enumeration:
        return dartName; // the model holds the enum's text already
      case FieldKind.object:
        return nullable ? '$dartName?.toJson()' : '$dartName.toJson()';
      case FieldKind.list:
        final el = element!;
        final inner = switch (el.kind) {
          FieldKind.object => '(e) => e.toJson()',
          FieldKind.scalar =>
            el.dartType == 'DateTime' ? '(e) => e.toIso8601String()' : null,
          FieldKind.enumeration || FieldKind.list => null,
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
      case FieldKind.enumeration:
        return nullable ? '$ref?.value' : '$ref.value';
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
      case FieldKind.enumeration:
        // `fromValue` falls back to the first value for text this version
        // doesn't know. `$dartName!`: a public field isn't promoted by the
        // null check, same as the object case's explicit `!` above.
        return nullable
            ? '$dartName == null ? null : $resolvedEnumName.fromValue($dartName!)'
            : '$resolvedEnumName.fromValue($dartName)';
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
      FieldKind.list =>
        element!.kind == FieldKind.object
            ? 'jsonEncode($ref$bang.map((e) => e.toJson()).toList())'
            : 'jsonEncode($ref$bang)',
      FieldKind.scalar || FieldKind.enumeration => ref,
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
      FieldKind.list =>
        element!.kind == FieldKind.object
            ? '(jsonDecode($ref${nullable ? '!' : ''}) as List).map((e) => ${element!.objectName}Model.fromJson(e as Map<String, dynamic>)).toList()'
            : '(jsonDecode($ref${nullable ? '!' : ''}) as List).cast<${element!.dartType}>()',
      FieldKind.scalar || FieldKind.enumeration => ref,
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
      case FieldKind.enumeration:
        return enumValues.isEmpty
            ? '$resolvedEnumName.values.first'
            : '$resolvedEnumName.${enumMemberName(enumValues.first)}';
      case FieldKind.object:
        final args = children
            .map((c) => '${c.dartName}: ${c.entityPlaceholder()}')
            .join(', ');
        return '${objectName}Entity($args)';
      case FieldKind.list:
        return 'const []';
    }
  }
}

/// A database text as a Dart enum member: `in_progress` → `inProgress`. Digits
/// can't start an identifier, and a few words are taken (Dart keywords, plus
/// the names the generated enum or `Enum` itself declares) — those get a
/// `Value` suffix so the member is always valid and never shadows `value`.
String enumMemberName(String value) {
  final cleaned = value.trim().toLowerCase().replaceAll(
    RegExp(r'[^a-z0-9]+'),
    '_',
  );
  var member = camel(cleaned.replaceAll(RegExp(r'^_+|_+$'), ''));
  if (member.isEmpty) member = 'empty';
  if (RegExp(r'^[0-9]').hasMatch(member)) member = 'v$member';
  return _reservedMembers.contains(member) ? '${member}Value' : member;
}

const _reservedMembers = {
  // Dart keywords + built-in identifiers that can't (or shouldn't) name a member.
  'abstract', 'as', 'assert', 'async', 'await', 'break', 'case', 'catch',
  'class', 'const', 'continue', 'covariant', 'default', 'deferred', 'do',
  'dynamic', 'else', 'enum', 'export', 'extends', 'extension', 'external',
  'factory', 'false', 'final', 'finally', 'for', 'get', 'if', 'implements',
  'import', 'in', 'interface', 'is', 'late', 'library', 'mixin', 'new', 'null',
  'on', 'operator', 'part', 'required', 'rethrow', 'return', 'set', 'static',
  'super', 'switch', 'sync', 'this', 'throw', 'true', 'try', 'typedef', 'var',
  'void', 'while', 'with', 'yield',
  // Declared by the generated enum / every Dart enum.
  'value', 'values', 'fromValue', 'index', 'name', 'hashCode', 'runtimeType',
  'toString', 'noSuchMethod',
};

/// `WorksiteStatus` → `worksite_status`.
String snakeCase(String pascalCase) => pascalCase
    .replaceAllMapped(RegExp(r'(?<=[a-z0-9])([A-Z])'), (m) => '_${m[1]}')
    .toLowerCase();

/// Every distinct enum reachable from [fields] (top-level, inside nested
/// objects, and list elements), by [FieldSpec.resolvedEnumName] — one generated
/// Dart enum file each. Call after [resolveEnumNames].
List<FieldSpec> collectEnumSpecs(List<FieldSpec> fields) {
  final out = <FieldSpec>[];
  final seen = <String>{};
  void visit(FieldSpec f) {
    switch (f.kind) {
      case FieldKind.enumeration:
        if (seen.add(f.resolvedEnumName)) out.add(f);
      case FieldKind.object:
        f.children.forEach(visit);
      case FieldKind.list:
        if (f.element != null) visit(f.element!);
      case FieldKind.scalar:
        break;
    }
  }

  fields.forEach(visit);
  return out;
}

/// Gives every blank-named enum field its class name: `<Feature><Field>`
/// (`worksite` + `status` → `WorksiteStatus`). Done at generation time rather
/// than when the field is edited, so renaming the feature never leaves a stale
/// name behind. Two enums that would share a name but not their values get a
/// numeric suffix (`…2`) so they never silently overwrite each other.
List<FieldSpec> resolveEnumNames(String featureName, List<FieldSpec> fields) {
  final taken = <String, List<String>>{};
  String claim(String base, List<String> values) {
    var name = base;
    for (
      var n = 2;
      taken.containsKey(name) && !_sameValues(taken[name]!, values);
      n++
    ) {
      name = '$base$n';
    }
    taken[name] = values;
    return name;
  }

  FieldSpec visit(FieldSpec f) => switch (f.kind) {
    FieldKind.enumeration => f.copyWith(
      enumName: claim(
        f.enumName.isNotEmpty
            ? f.enumName
            : '${pascal(featureName)}${pascal(f.jsonKey)}',
        f.enumValues,
      ),
    ),
    FieldKind.object => f.copyWith(children: f.children.map(visit).toList()),
    FieldKind.list =>
      f.element == null ? f : f.copyWith(element: visit(f.element!)),
    FieldKind.scalar => f,
  };
  return fields.map(visit).toList();
}

bool _sameValues(List<String> a, List<String> b) =>
    a.length == b.length &&
    [for (final (i, v) in a.indexed) v == b[i]].every((same) => same);

/// All distinct object specs reachable from [fields] (object fields + list
/// element objects), recursively — one generated sub-class per entry. Dedupes
/// by [FieldSpec.objectName] (first wins).
List<FieldSpec> collectObjectSpecs(List<FieldSpec> fields) {
  final out = <FieldSpec>[];
  final seen = <String>{};
  void visit(List<FieldSpec> fs) {
    for (final f in fs) {
      switch (f.kind) {
        case FieldKind.scalar || FieldKind.enumeration:
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
    if (f.isScalar &&
        f.dartType == 'String' &&
        preferred.contains(f.dartName.toLowerCase())) {
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
