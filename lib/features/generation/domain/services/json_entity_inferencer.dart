import 'dart:convert';

import 'package:neat/features/generation/domain/models/field_spec.dart';

/// The outcome of inferring an entity from a pasted JSON sample: the [fields]
/// to generate plus human-readable [warnings] surfaced in the UI (the inference
/// is best-effort from a single sample, so the user can review/edit).
/// [envelopeKey] is set when the sample was a paginated list wrapper (e.g.
/// dummyjson's `{ "recipes": [...], "total": ... }`) — the JSON key the
/// entity's own list lives under. [envelopeFields] are the wrapper's own
/// sibling scalar fields (e.g. `total`/`skip`/`limit`) — together these let
/// generation build a typed `<Feature>ListModel` wrapper instead of decoding
/// `getAll()`'s response as a bare array.
typedef InferenceResult = ({
  List<FieldSpec> fields,
  List<String> warnings,
  String? envelopeKey,
  List<FieldSpec> envelopeFields,
});

/// Infers an entity from a single JSON response.
///
/// Phase 1.5 scope: top-level object (or the first element of a top-level array),
/// **with nested objects and lists** (scalars + objects), inferred recursively.
/// A `String` `id` is always guaranteed at the top level (CRUD is id-centric).
/// Semantic correctness (nullability, int vs double) is best-effort and editable.
///
/// Also detects a paginated list *wrapper* (e.g. dummyjson's
/// `{ "recipes": [...], "total": 100, "skip": 0, "limit": 30 }`) and infers
/// from the array's first element instead — otherwise the wrapper's own
/// total/skip/limit-style fields get inferred as if they were the entity's,
/// which is never what pasting a list endpoint's response is meant to do.
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
      return (fields: fallback, warnings: const [], envelopeKey: null, envelopeFields: const []);
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      return (
        fields: fallback,
        warnings: ['Invalid JSON — $fallbackNote.'],
        envelopeKey: null,
        envelopeFields: const [],
      );
    }

    final warnings = <String>[];

    Object? sample = decoded;
    String? envelopeKey;
    var envelopeFields = const <FieldSpec>[];
    if (sample is List) {
      if (sample.isEmpty) {
        return (
          fields: fallback,
          warnings: ['Empty JSON array — $fallbackNote.'],
          envelopeKey: null,
          envelopeFields: const [],
        );
      }
      sample = sample.first;
    } else if (sample is Map) {
      final envelope = _detectListEnvelope(sample);
      if (envelope != null) {
        warnings.add(
          'Detected a paginated list wrapper — inferred fields from '
          '"${envelope.key}[0]" instead of the top-level object.',
        );
        sample = envelope.value;
        envelopeKey = envelope.key;
        // Its own scalar siblings (total/skip/limit-style) — guaranteed
        // scalar-only by _detectListEnvelope's own guard, so this is always a
        // flat list, never object/list fields. Its own independent naming
        // scope, same as every other _childrenOf call (see that method's doc).
        envelopeFields = _childrenOf(envelope.siblings, warnings);
      }
    }

    if (sample is! Map) {
      return (
        fields: fallback,
        warnings: ['JSON is not an object — $fallbackNote.'],
        envelopeKey: null,
        envelopeFields: const [],
      );
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

    return (
      fields: fields,
      warnings: warnings,
      envelopeKey: envelopeKey,
      envelopeFields: envelopeFields,
    );
  }

  /// Detects a paginated list wrapper — e.g. dummyjson's `{ "recipes": [...],
  /// "total": 100, "skip": 0, "limit": 30 }` — and returns the array's first
  /// element (plus its key, for the warning message, and its scalar
  /// [siblings] — e.g. `total`/`skip`/`limit` — for building a typed wrapper
  /// model at generation time).
  ///
  /// Deliberately narrow to avoid false positives on a genuine entity that
  /// merely has one nested list-of-objects field alongside its own real
  /// properties: only fires when the object has no id of its own (see
  /// [_looksLikeIdKey] — a real entity almost always does, and if it somehow
  /// doesn't, the existing top-level id fallback still guarantees one either
  /// way) and every other top-level field is a plain scalar (no other nested
  /// object/array sitting next to the list — a real entity with a nested
  /// object would fail this).
  ({String key, Map<dynamic, dynamic> value, Map<dynamic, dynamic> siblings})?
  _detectListEnvelope(Map<dynamic, dynamic> map) {
    if (map.keys.any((k) => _looksLikeIdKey(k.toString()))) return null;

    String? arrayKey;
    Map<dynamic, dynamic>? firstElement;
    final siblings = <dynamic, dynamic>{};

    for (final entry in map.entries) {
      final value = entry.value;
      if (value is List) {
        if (value.isEmpty || value.first is! Map) return null;
        if (arrayKey != null) return null; // more than one array-of-objects field
        arrayKey = entry.key.toString();
        firstElement = value.first as Map;
      } else if (value is Map) {
        return null; // a nested object alongside the array — not a plain wrapper
      } else {
        siblings[entry.key] = value;
      }
    }

    if (arrayKey == null || firstElement == null) return null;
    return (key: arrayKey, value: firstElement, siblings: siblings);
  }

  /// Builds the field specs for a JSON object. Each scope de-duplicates Dart
  /// names independently. Only the [topLevel] object enforces the id rules.
  List<FieldSpec> _childrenOf(Map<dynamic, dynamic> map, List<String> warnings, {bool topLevel = false}) {
    final fields = <FieldSpec>[];
    final usedNames = <String>{};

    map.forEach((key, value) {
      final jsonKey = key.toString();
      final isId = topLevel && _looksLikeIdKey(jsonKey);
      final dartName = _uniqueDartName(jsonKey, usedNames, warnings);

      if (isId) {
        if (value != null && value is! String) {
          // The actual source key (e.g. "_id"), not a hardcoded "id" — a
          // Mongo-style sample would otherwise print a warning about a
          // field named "id" that doesn't exist in the pasted JSON at all.
          warnings.add('"$jsonKey" was ${_typeName(value as Object)} → coerced to String '
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

  /// Matches `id` and Mongo/Mongoose's own `_id` convention (any casing) —
  /// both name the same thing, the entity's own primary key. Deliberately
  /// narrow: a broader guess (`productId`, `uuid`, ...) risks promoting a
  /// foreign-key-shaped field to be treated as the entity's own id.
  bool _looksLikeIdKey(String jsonKey) {
    final lower = jsonKey.toLowerCase();
    return lower == 'id' || lower == '_id';
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
