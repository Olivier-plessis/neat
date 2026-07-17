import 'package:neat/features/generation/domain/models/field_spec.dart';

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
