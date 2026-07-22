import 'package:flutter/material.dart';
import 'package:neat/features/feature_gen/domain/models/feature_gen_options.dart';
import 'package:neat/features/feature_gen/presentation/widgets/entity_fields_editor.dart';
import 'package:neat/features/feature_gen/presentation/widgets/field_edit_utils.dart';
import 'package:neat/features/generation/domain/models/field_spec.dart';
import 'package:neat/features/generation/domain/services/json_entity_inferencer.dart';
import 'package:neat_ui/neat_ui.dart';

/// Step 3 (Entity + CRUD mode only): the feature's one entity — either typed
/// by hand or inferred from a pasted JSON sample (see EntityFieldsEditor).
class EntityFieldsStep extends StatelessWidget {
  const EntityFieldsStep({required this.opts, required this.onChanged, super.key});

  final FeatureGenOptions opts;
  final ValueChanged<FeatureGenOptions> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: .start,
      children: [
        const SectionHeader(icon: Icons.data_object, label: 'Entity Fields'),
        10.gapH,
        EntityFieldsEditor(
          json: opts.json,
          fields: opts.fields,
          warnings: opts.fieldWarnings,
          onInfer: (j) {
            if (j.trim().isEmpty) {
              onChanged(
                opts.copyWith(
                  json: '',
                  fields: FieldSpec.idName,
                  fieldWarnings: const [],
                  listEnvelopeKey: '',
                  envelopeFields: const [],
                ),
              );
              return;
            }
            final r = const JsonEntityInferencer().infer(j);
            onChanged(
              opts.copyWith(
                json: j,
                fields: r.fields,
                fieldWarnings: r.warnings,
                listEnvelopeKey: r.envelopeKey ?? '',
                envelopeFields: r.envelopeFields,
              ),
            );
          },
          onReset: () => onChanged(
            opts.copyWith(
              json: '',
              fields: FieldSpec.idName,
              fieldWarnings: const [],
              listEnvelopeKey: '',
              envelopeFields: const [],
            ),
          ),
          onAddField: () {
            final used = opts.fields.map((f) => f.dartName).toSet();
            var n = 'field';
            for (var i = 1; used.contains(n); i++) {
              n = 'field$i';
            }
            onChanged(
              opts.copyWith(
                fields: [
                  ...opts.fields,
                  FieldSpec(jsonKey: n, dartName: n),
                ],
              ),
            );
          },
          onName: (i, v) => onChanged(
            opts.copyWith(fields: editField(opts.fields, i, (f) => f.copyWith(dartName: v.trim()))),
          ),
          onType: (i, v) => onChanged(
            opts.copyWith(
              fields: editField(opts.fields, i, (f) => f.isId ? f : f.copyWith(dartType: v)),
            ),
          ),
          onNullable: (i, v) => onChanged(
            opts.copyWith(
              fields: editField(opts.fields, i, (f) => f.isId ? f : f.copyWith(nullable: v)),
            ),
          ),
          onRemove: (i) {
            if (opts.fields[i].isId) return;
            onChanged(opts.copyWith(fields: [...opts.fields]..removeAt(i)));
          },
          onChildrenChanged: (i, children) => onChanged(
            opts.copyWith(
              fields: editField(
                opts.fields,
                i,
                (f) => f.kind == FieldKind.list
                    ? f.copyWith(element: f.element!.copyWith(children: children))
                    : f.copyWith(children: children),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
