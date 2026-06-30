import 'package:neat/features/generation/domain/models/field_spec.dart';

/// Codegen helpers that turn a [FieldSpec] into the Dart fragments the entity /
/// model / Drift / presentation templates need. Centralised so every surface
/// renders a field identically.
extension FieldCodegen on FieldSpec {
  /// Constructor / field declaration type, e.g. `String`, `int?`, `DateTime`.
  String get declType => type;

  /// `@JsonKey(name: 'json_key')` when the Dart name was renamed
  /// (json_serializable path); empty otherwise. The caller places it (the
  /// indentation differs between freezed factory params and field decls).
  String get jsonKeyAnnotation => needsJsonKey ? "@JsonKey(name: '$jsonKey')" : '';

  /// A hand-written `fromJson` read for the plain (no json_serializable) model,
  /// e.g. `json['price'] as double` / `DateTime.parse(json['created_at'] as String)`.
  String fromJsonExpr() {
    final raw = "json['$jsonKey']";
    if (nullable) {
      return switch (dartType) {
        'int' => '($raw as num?)?.toInt()',
        'double' => '($raw as num?)?.toDouble()',
        'DateTime' => '$raw == null ? null : DateTime.parse($raw as String)',
        _ => '$raw as $dartType?',
      };
    }
    return switch (dartType) {
      'int' => '($raw as num).toInt()',
      'double' => '($raw as num).toDouble()',
      'DateTime' => 'DateTime.parse($raw as String)',
      _ => '$raw as $dartType',
    };
  }

  /// A `toJson` map entry value, e.g. `createdAt.toIso8601String()`.
  String toJsonValue() {
    if (dartType == 'DateTime') {
      return nullable ? '$dartName?.toIso8601String()' : '$dartName.toIso8601String()';
    }
    return dartName;
  }

  /// A Drift column declaration line for `<feature>_local_storage`, e.g.
  /// `RealColumn get price => real()();`. Nullable fields get `.nullable()`.
  String driftColumnLine() {
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

  /// A synthetic value for the skeleton placeholder instance. Nullable fields
  /// use `null`; otherwise a type-appropriate dummy.
  String placeholderLiteral() {
    if (nullable) return 'null';
    return switch (dartType) {
      'int' => '0',
      'double' => '0.0',
      'bool' => 'false',
      'DateTime' => 'DateTime(2024)',
      _ => isId ? "'000000'" : "'Placeholder $dartName'",
    };
  }
}

/// Picks the field shown as the list tile's title: the first String-ish field
/// named name/title/label, else the first non-id String, else the id.
FieldSpec titleField(List<FieldSpec> fields) {
  const preferred = {'name', 'title', 'label'};
  for (final f in fields) {
    if (f.dartType == 'String' && preferred.contains(f.dartName.toLowerCase())) return f;
  }
  for (final f in fields) {
    if (!f.isId && f.dartType == 'String') return f;
  }
  return fields.firstWhere((f) => f.isId, orElse: () => fields.first);
}

/// The id field (always present after inference).
FieldSpec idField(List<FieldSpec> fields) =>
    fields.firstWhere((f) => f.isId, orElse: () => fields.first);
