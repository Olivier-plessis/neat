/// One field of a feature's entity/model, either inferred from a pasted JSON
/// response or the default `id`/`name` placeholder.
///
/// Pure value object (no Flutter/codegen) so the inferencer, the templates and
/// the presentation layer can all share it.
class FieldSpec {
  const FieldSpec({
    required this.jsonKey,
    required this.dartName,
    required this.dartType,
    this.nullable = false,
    this.isId = false,
  });

  /// The original JSON key (e.g. `created_at`).
  final String jsonKey;

  /// The Dart identifier (e.g. `createdAt`).
  final String dartName;

  /// One of: `String`, `int`, `double`, `bool`, `DateTime`. Nested
  /// objects/lists are not represented in V1 (they're dropped during inference).
  final String dartType;

  final bool nullable;

  /// The entity's primary key. NEAT's CRUD keys on a **String** id everywhere
  /// (Drift PK, `getById`, `delete(String id)`, realtime `primaryKey: ['id']`),
  /// so the inferencer always coerces the id field to `String`.
  final bool isId;

  /// The Dart type with its nullability suffix (e.g. `String?`).
  String get type => nullable ? '$dartType?' : dartType;

  /// True when the Dart identifier differs from the JSON key → the model needs
  /// a `@JsonKey(name: '<jsonKey>')` (json_serializable) / an explicit map read.
  bool get needsJsonKey => jsonKey != dartName;

  FieldSpec copyWith({
    String? jsonKey,
    String? dartName,
    String? dartType,
    bool? nullable,
    bool? isId,
  }) {
    return FieldSpec(
      jsonKey: jsonKey ?? this.jsonKey,
      dartName: dartName ?? this.dartName,
      dartType: dartType ?? this.dartType,
      nullable: nullable ?? this.nullable,
      isId: isId ?? this.isId,
    );
  }

  /// The default field set when no JSON is provided — preserves NEAT's historic
  /// `id`/`name` placeholder so a feature still generates with zero input.
  static const List<FieldSpec> idName = [
    FieldSpec(jsonKey: 'id', dartName: 'id', dartType: 'String', isId: true),
    FieldSpec(jsonKey: 'name', dartName: 'name', dartType: 'String'),
  ];

  /// The Dart types the inferencer can produce (also the UI dropdown options).
  static const supportedTypes = ['String', 'int', 'double', 'bool', 'DateTime'];

  @override
  bool operator ==(Object other) =>
      other is FieldSpec &&
      other.jsonKey == jsonKey &&
      other.dartName == dartName &&
      other.dartType == dartType &&
      other.nullable == nullable &&
      other.isId == isId;

  @override
  int get hashCode => Object.hash(jsonKey, dartName, dartType, nullable, isId);

  @override
  String toString() => 'FieldSpec($dartName: $type${isId ? ', id' : ''})';
}
