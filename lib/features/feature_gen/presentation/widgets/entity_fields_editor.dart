import 'package:flutter/material.dart';
import 'package:neat/features/generation/domain/models/field_spec.dart';
import 'package:neat_ui/neat_ui.dart';

/// Paste-a-Response-JSON → editable entity fields. Presentational + callback
/// driven so it works from both the wizard (Architecture step) and the
/// Workshop's add-feature flow. The id row is locked (String, non-null, kept).
class EntityFieldsEditor extends StatefulWidget {
  const EntityFieldsEditor({
    required this.json,
    required this.fields,
    required this.warnings,
    required this.onInfer,
    required this.onReset,
    required this.onAddField,
    required this.onName,
    required this.onType,
    required this.onNullable,
    required this.onRemove,
    super.key,
  });

  final String json;
  final List<FieldSpec> fields;
  final List<String> warnings;
  final ValueChanged<String> onInfer;
  final VoidCallback onReset;
  final VoidCallback onAddField;
  final void Function(int index, String name) onName;
  final void Function(int index, String type) onType;
  final void Function(int index, bool nullable) onNullable;
  final void Function(int index) onRemove;

  @override
  State<EntityFieldsEditor> createState() => _EntityFieldsEditorState();
}

class _EntityFieldsEditorState extends State<EntityFieldsEditor> {
  late final TextEditingController _json = TextEditingController(text: widget.json);

  @override
  void dispose() {
    _json.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF131316),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Paste a Response JSON to infer the entity fields, or edit them below. '
            'The id is always present (CRUD keys on it).',
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _json,
            maxLines: 5,
            minLines: 3,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'monospace'),
            decoration: InputDecoration(
              hintText: '{ "id": 1, "title": "Tee", "price": 9.99, "created_at": "2024-01-31" }',
              hintStyle: TextStyle(color: Colors.grey[700], fontSize: 12, fontFamily: 'monospace'),
              isDense: true,
              contentPadding: const EdgeInsets.all(12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.white12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Palette.colorPrimaryCyan.withValues(alpha: 0.5)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              FilledButton.icon(
                onPressed: () => widget.onInfer(_json.text),
                icon: const Icon(Icons.auto_fix_high, size: 16),
                label: const Text('Infer fields'),
                style: FilledButton.styleFrom(
                  backgroundColor: Palette.colorPrimaryCyan,
                  foregroundColor: Colors.black,
                  iconColor: Colors.black,
                  minimumSize: const Size(0, 40),
                ),
              ),
              const SizedBox(width: 10),
              TextButton.icon(
                onPressed: () {
                  _json.clear();
                  widget.onReset();
                },
                icon: const Icon(Icons.restart_alt, size: 16),
                label: const Text('Reset'),
                style: TextButton.styleFrom(foregroundColor: Colors.white54),
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < widget.fields.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              // Keyed by index (not name) so typing in the name field doesn't
              // recreate the row and drop focus; the row syncs external changes
              // (infer/reset) via didUpdateWidget.
              child: _FieldRow(
                key: ValueKey('field_$i'),
                field: widget.fields[i],
                onName: (v) => widget.onName(i, v),
                onType: (v) => widget.onType(i, v),
                onNullable: (v) => widget.onNullable(i, v),
                onRemove: widget.fields[i].isId ? null : () => widget.onRemove(i),
              ),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: widget.onAddField,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add field'),
              style: TextButton.styleFrom(foregroundColor: Palette.colorPrimaryCyan),
            ),
          ),
          if (widget.warnings.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final w in widget.warnings)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, size: 13, color: Colors.amber[700]),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(w, style: TextStyle(color: Colors.amber[200], fontSize: 11)),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _FieldRow extends StatefulWidget {
  const _FieldRow({
    required this.field,
    required this.onName,
    required this.onType,
    required this.onNullable,
    required this.onRemove,
    super.key,
  });

  final FieldSpec field;
  final ValueChanged<String> onName;
  final ValueChanged<String> onType;
  final ValueChanged<bool> onNullable;
  final VoidCallback? onRemove;

  @override
  State<_FieldRow> createState() => _FieldRowState();
}

class _FieldRowState extends State<_FieldRow> {
  late final TextEditingController _name = TextEditingController(text: widget.field.dartName);

  @override
  void didUpdateWidget(_FieldRow old) {
    super.didUpdateWidget(old);
    // Re-seed only on external changes (infer/reset/remove shift), never while
    // the user types (then the value already matches).
    if (widget.field.dartName != _name.text) _name.text = widget.field.dartName;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final field = widget.field;
    final locked = field.isId;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0F),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextField(
              controller: _name,
              enabled: !locked,
              onChanged: widget.onName,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                // contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (locked)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                border: Border.all(color: Palette.colorPrimaryCyan.withValues(alpha: 0.5)),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'ID',
                style: TextStyle(
                  color: Palette.colorPrimaryCyan,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          const SizedBox(width: 10),
          SizedBox(
            width: 110,
            child: field.isScalar
                ? DropdownButton<String>(
                    value: field.dartType,
                    isDense: true,
                    isExpanded: true,
                    underline: const SizedBox.shrink(),
                    dropdownColor: const Color(0xFF1A1A1E),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    onChanged: locked ? null : (v) => v == null ? null : widget.onType(v),
                    items: [
                      for (final t in FieldSpec.supportedTypes)
                        DropdownMenuItem(value: t, child: Text(t)),
                    ],
                  )
                // Nested object/list fields aren't scalar-typed — their shape
                // comes from `children`/`element`, which this flat row can't
                // edit, so show what it is instead of a misleading dropdown.
                : Text(
                    field.kind == FieldKind.list ? 'List<${field.objectName}>' : field.objectName,
                    style: TextStyle(color: Colors.grey[500], fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
          ),
          const SizedBox(width: 8),
          Row(
            children: [
              Checkbox(
                value: field.nullable,
                onChanged: locked ? null : (v) => widget.onNullable(v ?? false),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                activeColor: Palette.colorPrimaryCyan,
              ),
              Text('null?', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
            ],
          ),
          SizedBox(
            width: 32,
            child: widget.onRemove == null
                ? null
                : IconButton(
                    icon: const Icon(Icons.close, size: 15, color: Colors.white38),
                    onPressed: widget.onRemove,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Remove field',
                  ),
          ),
        ],
      ),
    );
  }
}
