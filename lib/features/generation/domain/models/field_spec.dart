/// The shape of an inferred field.
enum FieldKind {
  /// A primitive: String / int / double / bool / DateTime.
  scalar,

  /// A nested JSON object → its own generated sub-class.
  object,

  /// A JSON array → `List<element>` (element is itself scalar or object).
  list,
}

/// One field of a feature's entity/model, inferred from a pasted JSON response
/// or the default `id`/`name` placeholder.
///
/// Pure value object (no Flutter/codegen) so the inferencer, the templates and
/// the presentation layer can all share it. Recursive: [object] fields carry
/// [children]; [list] fields carry an [element] spec.
class FieldSpec {
  const FieldSpec({
    required this.jsonKey,
    required this.dartName,
    this.dartType = 'String',
    this.nullable = false,
    this.isId = false,
    this.kind = FieldKind.scalar,
    this.objectName = '',
    this.children = const [],
    this.element,
  });

  /// The original JSON key (e.g. `created_at`).
  final String jsonKey;

  /// The Dart identifier (e.g. `createdAt`).
  final String dartName;

  /// For [FieldKind.scalar]: one of String/int/double/bool/DateTime. Ignored for
  /// object/list (their type is derived from [objectName] / [element] per layer).
  final String dartType;

  final bool nullable;

  /// The entity's primary key — always a `String` scalar (CRUD keys on it).
  final bool isId;

  final FieldKind kind;

  /// For [FieldKind.object]: the PascalCase base name of the generated sub-class
  /// (e.g. `Rating` → `RatingEntity` / `RatingModel`).
  final String objectName;

  /// For [FieldKind.object]: the nested fields.
  final List<FieldSpec> children;

  /// For [FieldKind.list]: the element spec (scalar or object).
  final FieldSpec? element;

  bool get isScalar => kind == FieldKind.scalar;
  bool get isComplex => kind != FieldKind.scalar;

  /// The scalar Dart type with its nullability suffix (e.g. `String?`). Only
  /// meaningful for scalars — complex types resolve per layer in field_codegen.
  String get type => nullable ? '$dartType?' : dartType;

  /// True when the Dart identifier differs from the JSON key → the model needs a
  /// `@JsonKey(name: '<jsonKey>')` (json_serializable) / an explicit map read.
  bool get needsJsonKey => jsonKey != dartName;

  FieldSpec copyWith({
    String? jsonKey,
    String? dartName,
    String? dartType,
    bool? nullable,
    bool? isId,
    FieldKind? kind,
    String? objectName,
    List<FieldSpec>? children,
    FieldSpec? element,
  }) {
    return FieldSpec(
      jsonKey: jsonKey ?? this.jsonKey,
      dartName: dartName ?? this.dartName,
      dartType: dartType ?? this.dartType,
      nullable: nullable ?? this.nullable,
      isId: isId ?? this.isId,
      kind: kind ?? this.kind,
      objectName: objectName ?? this.objectName,
      children: children ?? this.children,
      element: element ?? this.element,
    );
  }

  /// The default field set when no JSON is provided — preserves NEAT's historic
  /// `id`/`name` placeholder so a feature still generates with zero input.
  static const List<FieldSpec> idName = [
    FieldSpec(jsonKey: 'id', dartName: 'id', isId: true),
    FieldSpec(jsonKey: 'name', dartName: 'name'),
  ];

  /// The scalar Dart types the inferencer can produce (also the UI dropdown).
  static const supportedTypes = ['String', 'int', 'double', 'bool', 'DateTime'];

  /// The FakeStore Products schema (`GET https://fakestoreapi.com/products`) —
  /// NEAT's worked-example feature. Exercises a nested object (`rating`), so
  /// it also doubles as a real-world Phase 1.5 regression fixture.
  static const List<FieldSpec> fakeStoreProduct = [
    FieldSpec(jsonKey: 'id', dartName: 'id', isId: true),
    FieldSpec(jsonKey: 'title', dartName: 'title'),
    FieldSpec(jsonKey: 'price', dartName: 'price', dartType: 'double'),
    FieldSpec(jsonKey: 'description', dartName: 'description'),
    FieldSpec(jsonKey: 'category', dartName: 'category'),
    FieldSpec(jsonKey: 'image', dartName: 'image'),
    FieldSpec(
      // Nullable: confirmed against the real API — GET returns `rating`, but
      // POST/PUT responses omit it entirely. A non-nullable field here would
      // crash the create/update JSON decode with a `Null is not a subtype of
      // Map` cast error the moment a write actually round-trips.
      jsonKey: 'rating',
      dartName: 'rating',
      nullable: true,
      kind: FieldKind.object,
      objectName: 'Rating',
      children: [
        FieldSpec(jsonKey: 'rate', dartName: 'rate', dartType: 'double'),
        FieldSpec(jsonKey: 'count', dartName: 'count', dartType: 'int'),
      ],
    ),
  ];

  @override
  bool operator ==(Object other) =>
      other is FieldSpec &&
      other.jsonKey == jsonKey &&
      other.dartName == dartName &&
      other.dartType == dartType &&
      other.nullable == nullable &&
      other.isId == isId &&
      other.kind == kind &&
      other.objectName == objectName &&
      _listEq(other.children, children) &&
      other.element == element;

  @override
  int get hashCode => Object.hash(
        jsonKey,
        dartName,
        dartType,
        nullable,
        isId,
        kind,
        objectName,
        Object.hashAll(children),
        element,
      );

  static bool _listEq(List<FieldSpec> a, List<FieldSpec> b) {
    if (a.length != b.length) return false;
    for (final (i, item) in a.indexed) {
      if (item != b[i]) return false;
    }
    return true;
  }

  @override
  String toString() => 'FieldSpec($dartName: ${kind.name}${isId ? ', id' : ''})';
}
