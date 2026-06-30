import 'dart:convert';

import 'package:neat/features/generation/domain/models/field_spec.dart';

/// The outcome of inferring an entity from a pasted JSON sample: the [fields]
/// to generate plus human-readable [warnings] surfaced in the UI (the inference
/// is best-effort from a single sample, so the user can review/edit).
typedef InferenceResult = ({List<FieldSpec> fields, List<String> warnings});

/// Infers a **flat** entity (scalar fields only) from a single JSON response.
///
/// V1 scope (Phase 1): top-level object (or the first element of a top-level
/// array). Nested objects/arrays are dropped with a warning. A `String` `id`
/// is always guaranteed (synthesised or coerced) because NEAT's CRUD is
/// id-centric. Semantic correctness (nullability, int vs double) is best-effort
/// and editable in the preview.
class JsonEntityInferencer {
  const JsonEntityInferencer();

  InferenceResult infer(String raw) {
    if (raw.trim().isEmpty) {
      return (fields: FieldSpec.idName, warnings: const []);
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      return (
        fields: FieldSpec.idName,
        warnings: const ['Invalid JSON — kept the default id/name fields.'],
      );
    }

    final warnings = <String>[];

    // A top-level array → infer from its first element (a "list of X" response).
    Object? sample = decoded;
    if (sample is List) {
      if (sample.isEmpty) {
        return (
          fields: FieldSpec.idName,
          warnings: const ['Empty JSON array — kept the default id/name fields.'],
        );
      }
      sample = sample.first;
    }

    if (sample is! Map) {
      return (
        fields: FieldSpec.idName,
        warnings: const ['JSON is not an object — kept the default id/name fields.'],
      );
    }

    final fields = <FieldSpec>[];
    final usedNames = <String>{};

    sample.forEach((key, value) {
      final jsonKey = key.toString();
      final isId = jsonKey == 'id';

      // Complex (nested object / array) → not representable in a flat V1 entity.
      if (!isId && (value is Map || value is List)) {
        warnings.add('"$jsonKey": nested ${value is List ? 'array' : 'object'} '
            'dropped (flat entities only for now).');
        return;
      }

      final dartName = _uniqueDartName(jsonKey, usedNames, warnings);

      if (isId) {
        if (value != null && value is! String) {
          warnings.add('"id" was ${_typeName(value as Object)} → coerced to String '
              '(NEAT keys CRUD on String ids).');
        }
        fields.add(FieldSpec(
          jsonKey: jsonKey,
          dartName: dartName,
          dartType: 'String',
          isId: true,
        ));
        return;
      }

      if (value == null) {
        warnings.add('"$jsonKey": null in the sample → typed as String? (edit if needed).');
        fields.add(FieldSpec(
          jsonKey: jsonKey,
          dartName: dartName,
          dartType: 'String',
          nullable: true,
        ));
        return;
      }

      fields.add(FieldSpec(
        jsonKey: jsonKey,
        dartName: dartName,
        dartType: _scalarType(value as Object),
      ));
    });

    // Guarantee a String id (the CRUD contract requires it).
    if (!fields.any((f) => f.isId)) {
      fields.insert(
        0,
        const FieldSpec(jsonKey: 'id', dartName: 'id', dartType: 'String', isId: true),
      );
      warnings.add('No "id" in the JSON → added a String id (required for CRUD).');
    }

    return (fields: fields, warnings: warnings);
  }

  /// Maps a non-null scalar JSON value to a Dart type. ISO-8601-looking strings
  /// become `DateTime` (json_serializable parses them; the plain model uses
  /// `DateTime.parse`).
  String _scalarType(Object value) {
    if (value is bool) return 'bool';
    if (value is int) return 'int';
    if (value is double) return 'double';
    if (value is num) return value is int ? 'int' : 'double';
    if (value is String) return _looksIso8601(value) ? 'DateTime' : 'String';
    return 'String';
  }

  String _typeName(Object value) => switch (value) {
        bool() => 'bool',
        int() => 'int',
        double() => 'double',
        _ => 'String',
      };

  /// Loose ISO-8601 date / datetime check (`2024-01-31` or `2024-01-31T...`).
  bool _looksIso8601(String s) =>
      RegExp(r'^\d{4}-\d{2}-\d{2}([T ]\d{2}:\d{2}.*)?$').hasMatch(s);

  /// Converts a JSON key to a unique, valid lowerCamelCase Dart identifier,
  /// escaping reserved words and de-duplicating collisions.
  String _uniqueDartName(String jsonKey, Set<String> used, List<String> warnings) {
    var name = _toDartIdentifier(jsonKey);
    if (_dartReserved.contains(name)) {
      warnings.add('"$jsonKey" is a Dart keyword → renamed to "${name}Field".');
      name = '${name}Field';
    }
    if (used.contains(name)) {
      var n = 2;
      while (used.contains('$name$n')) {
        n++;
      }
      name = '$name$n';
    }
    used.add(name);
    return name;
  }

  /// `created_at` / `created-at` / `Created At` → `createdAt`; prefixes a leading
  /// digit; falls back to `field` for empty/garbage keys.
  String _toDartIdentifier(String key) {
    final parts = key.split(RegExp(r'[^a-zA-Z0-9]+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'field';
    final buf = StringBuffer();
    for (var i = 0; i < parts.length; i++) {
      final w = parts[i];
      buf.write(i == 0 ? w[0].toLowerCase() + w.substring(1) : w[0].toUpperCase() + w.substring(1));
    }
    var id = buf.toString();
    if (RegExp(r'^[0-9]').hasMatch(id)) id = 'n$id';
    return id;
  }

  static const _dartReserved = <String>{
    'abstract', 'as', 'assert', 'async', 'await', 'break', 'case', 'catch',
    'class', 'const', 'continue', 'covariant', 'default', 'deferred', 'do',
    'dynamic', 'else', 'enum', 'export', 'extends', 'extension', 'external',
    'factory', 'false', 'final', 'finally', 'for', 'function', 'get', 'hide',
    'if', 'implements', 'import', 'in', 'interface', 'is', 'late', 'library',
    'mixin', 'new', 'null', 'on', 'operator', 'part', 'required', 'rethrow',
    'return', 'set', 'show', 'static', 'super', 'switch', 'sync', 'this',
    'throw', 'true', 'try', 'typedef', 'var', 'void', 'while', 'with', 'yield',
  };
}
