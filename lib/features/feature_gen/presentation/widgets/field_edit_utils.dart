import 'package:neat/features/generation/domain/models/field_spec.dart';

/// [field] renamed to [name]. A field the user added by hand has its JSON key
/// equal to its Dart name (both start as `field1`), so the wire name follows the
/// rename — otherwise it would stay `field1` forever (and so would the column of
/// the Supabase migration, which is named after the JSON key). A field inferred
/// from a pasted JSON (`start_date` ↔ `startDate`) keeps its JSON key: renaming
/// the Dart identifier never changes what the API sends.
FieldSpec renameField(FieldSpec field, String name) =>
    field.jsonKey == field.dartName
    ? field.copyWith(dartName: name, jsonKey: name)
    : field.copyWith(dartName: name);

/// Returns a copy of [fields] with the entry at [index] transformed by [update].
List<FieldSpec> editField(
  List<FieldSpec> fields,
  int index,
  FieldSpec Function(FieldSpec) update,
) {
  if (index < 0 || index >= fields.length) return fields;
  final next = [...fields];
  next[index] = update(next[index]);
  return next;
}
