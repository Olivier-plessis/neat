import 'dart:convert';

import 'package:neat/features/generation/domain/models/field_spec.dart';

/// The outcome of inferring an entity from a pasted JSON sample: the [fields]
/// to generate plus human-readable [warnings] surfaced in the UI (the inference
/// is best-effort from a single sample, so the user can review/edit).
typedef InferenceResult = ({List<FieldSpec> fields, List<String> warnings});

/// Infers an entity from a single JSON response.
///
/// Phase 1.5 scope: top-level object (or the first element of a top-level array),
/// **with nested objects and lists** (scalars + objects), inferred recursively.
/// A `String` `id` is always guaranteed at the top level (CRUD is id-centric).
/// Semantic correctness (nullability, int vs double) is best-effort and editable.
class JsonEntityInferencer {
  const JsonEntityInferencer();

  /// [requireId] guarantees a String `id` field (CRUD is id-centric) —
  /// disable it for a request/response body with no natural id (e.g. a login
  /// response with just `token`/`expiresAt`; see ROADMAP.md §7 Phase 2). The
  /// recursive inference itself (scalars/objects/lists, key normalization) is
  /// unaffected either way.
  InferenceResult infer(String raw, {bool requireId = true}) {
    // Only the CRUD entity flow falls back to the id/name placeholder — a
    // request/response body with no natural id just has no fields at all.
    final fallback = requireId ? FieldSpec.idName : const <FieldSpec>[];
    final fallbackNote = requireId ? 'kept the default id/name fields' : 'kept an empty field list';

    if (raw.trim().isEmpty) {
      return (fields: fallback, warnings: const []);
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      return (fields: fallback, warnings: ['Invalid JSON — $fallbackNote.']);
    }

    final warnings = <String>[];

    Object? sample = decoded;
    if (sample is List) {
      if (sample.isEmpty) {
        return (fields: fallback, warnings: ['Empty JSON array — $fallbackNote.']);
      }
      sample = sample.first;
    }

    if (sample is! Map) {
      return (fields: fallback, warnings: ['JSON is not an object — $fallbackNote.']);
    }

    final fields = _childrenOf(sample, warnings, topLevel: true);

    // Guarantee a String id at the top level (the CRUD contract requires it).
    if (requireId && !fields.any((f) => f.isId)) {
      fields.insert(
        0,
        const FieldSpec(jsonKey: 'id', dartName: 'id', isId: true),
      );
      warnings.add('No "id" in the JSON → added a String id (required for CRUD).');
    }

    return (fields: fields, warnings: warnings);
  }

  /// Builds the field specs for a JSON object. Each scope de-duplicates Dart
  /// names independently. Only the [topLevel] object enforces the id rules.
  List<FieldSpec> _childrenOf(Map<dynamic, dynamic> map, List<String> warnings, {bool topLevel = false}) {
    final fields = <FieldSpec>[];
    final usedNames = <String>{};

    map.forEach((key, value) {
      final jsonKey = key.toString();
      final isId = topLevel && jsonKey == 'id';
      final dartName = _uniqueDartName(jsonKey, usedNames, warnings);

      if (isId) {
        if (value != null && value is! String) {
          warnings.add('"id" was ${_typeName(value as Object)} → coerced to String '
              '(NEAT keys CRUD on String ids).');
        }
        fields.add(FieldSpec(jsonKey: jsonKey, dartName: dartName, isId: true));
        return;
      }

      if (value == null) {
        warnings.add('"$jsonKey": null in the sample → typed as String? (edit if needed).');
        fields.add(FieldSpec(jsonKey: jsonKey, dartName: dartName, nullable: true));
        return;
      }

      fields.add(_specFor(jsonKey, dartName, value as Object, warnings));
    });

    return fields;
  }

  /// Infers a non-null value into a [FieldSpec] (scalar / object / list).
  FieldSpec _specFor(String jsonKey, String dartName, Object value, List<String> warnings) {
    if (value is Map) {
      return FieldSpec(
        jsonKey: jsonKey,
        dartName: dartName,
        kind: FieldKind.object,
        objectName: _pascal(dartName),
        children: _childrenOf(value, warnings),
      );
    }

    if (value is List) {
      if (value.isEmpty) {
        warnings.add('"$jsonKey": empty array → typed as List<String> (edit if needed).');
        return FieldSpec(
          jsonKey: jsonKey,
          dartName: dartName,
          kind: FieldKind.list,
          element: const FieldSpec(jsonKey: '', dartName: ''),
        );
      }
      final first = value.first;
      if (first is Map) {
        final elementName = _pascal(_singular(dartName));
        return FieldSpec(
          jsonKey: jsonKey,
          dartName: dartName,
          kind: FieldKind.list,
          element: FieldSpec(
            jsonKey: jsonKey,
            dartName: _camelLower(elementName),
            kind: FieldKind.object,
            objectName: elementName,
            children: _childrenOf(first, warnings),
          ),
        );
      }
      // List of scalars.
      return FieldSpec(
        jsonKey: jsonKey,
        dartName: dartName,
        kind: FieldKind.list,
        element: FieldSpec(jsonKey: '', dartName: '', dartType: _scalarType(first as Object)),
      );
    }

    // Scalar.
    return FieldSpec(jsonKey: jsonKey, dartName: dartName, dartType: _scalarType(value));
  }

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

  bool _looksIso8601(String s) =>
      RegExp(r'^\d{4}-\d{2}-\d{2}([T ]\d{2}:\d{2}.*)?$').hasMatch(s);

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

  String _toDartIdentifier(String key) {
    final parts = key.split(RegExp(r'[^a-zA-Z0-9]+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'field';
    final buf = StringBuffer();
    for (final (i, w) in parts.indexed) {
      buf.write(i == 0 ? w[0].toLowerCase() + w.substring(1) : w[0].toUpperCase() + w.substring(1));
    }
    var id = buf.toString();
    if (RegExp(r'^[0-9]').hasMatch(id)) id = 'n$id';
    return id;
  }

  /// `createdAt` → `CreatedAt` (PascalCase for a sub-class base name).
  String _pascal(String dartName) =>
      dartName.isEmpty ? dartName : dartName[0].toUpperCase() + dartName.substring(1);

  String _camelLower(String s) =>
      s.isEmpty ? s : s[0].toLowerCase() + s.substring(1);

  /// Naive singularisation for list-element class names (`items` → `item`,
  /// `categories` → `category`). Good enough for class naming; user-editable.
  String _singular(String s) {
    if (s.endsWith('ies') && s.length > 3) return '${s.substring(0, s.length - 3)}y';
    if (s.endsWith('ses') && s.length > 3) return s.substring(0, s.length - 2);
    if (s.endsWith('s') && !s.endsWith('ss') && s.length > 1) return s.substring(0, s.length - 1);
    return s;
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
