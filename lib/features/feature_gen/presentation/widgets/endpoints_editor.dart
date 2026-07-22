import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:neat/features/feature_gen/presentation/widgets/entity_fields_editor.dart';
import 'package:neat/features/feature_gen/presentation/widgets/field_edit_utils.dart';
import 'package:neat/features/generation/domain/models/endpoint_spec.dart';
import 'package:neat/features/generation/domain/models/field_spec.dart';
import 'package:neat/features/generation/domain/services/json_entity_inferencer.dart';
import 'package:neat_ui/neat_ui.dart';

/// The list of [EndpointSpec]s for a "Custom Endpoints" feature — add/remove,
/// and per-endpoint name/method/path + request/response bodies (each reusing
/// [EntityFieldsEditor] as-is: it already works from any named field list,
/// nothing about it is entity-specific). Fully "controlled": all state lives
/// in [endpoints], bubbled up via [onChange] — matches every other field on
/// this screen. Only the expand/collapse of each endpoint's card is local,
/// ephemeral UI state (via [ExpansionTile]), never persisted.
class EndpointsEditor extends StatelessWidget {
  const EndpointsEditor({
    required this.endpoints,
    required this.enabled,
    required this.onChange,
    super.key,
  });

  final List<EndpointSpec> endpoints;
  final bool enabled;
  final ValueChanged<List<EndpointSpec>> onChange;

  void _update(int index, EndpointSpec Function(EndpointSpec) f) {
    final next = [...endpoints];
    next[index] = f(next[index]);
    onChange(next);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (i, endpoint) in endpoints.indexed) ...[
          _EndpointRow(
            key: ValueKey(i),
            endpoint: endpoint,
            enabled: enabled,
            onName: (v) => _update(i, (e) => e.copyWith(name: v.trim())),
            onMethod: (m) => _update(i, (e) => e.copyWith(method: m)),
            onPath: (v) => _update(i, (e) => e.copyWith(path: v.trim())),
            onRequestInfer: (j) {
              if (j.trim().isEmpty) {
                _update(
                  i,
                  (e) => e.copyWith(
                    requestJson: '',
                    requestFields: const [],
                    requestWarnings: const [],
                  ),
                );
                return;
              }
              final r = const JsonEntityInferencer().infer(j, requireId: false);
              _update(
                i,
                (e) => e.copyWith(
                  requestJson: j,
                  requestFields: r.fields,
                  requestWarnings: r.warnings,
                ),
              );
            },
            onRequestReset: () => _update(
              i,
              (e) =>
                  e.copyWith(requestJson: '', requestFields: const [], requestWarnings: const []),
            ),
            onRequestAddField: () => _update(i, (e) {
              final used = e.requestFields.map((f) => f.dartName).toSet();
              var n = 'field';
              for (var k = 1; used.contains(n); k++) {
                n = 'field$k';
              }
              return e.copyWith(
                requestFields: [
                  ...e.requestFields,
                  FieldSpec(jsonKey: n, dartName: n),
                ],
              );
            }),
            onRequestName: (fi, v) => _update(
              i,
              (e) => e.copyWith(
                requestFields: editField(
                  e.requestFields,
                  fi,
                  (f) => f.copyWith(dartName: v.trim()),
                ),
              ),
            ),
            onRequestType: (fi, v) => _update(
              i,
              (e) => e.copyWith(
                requestFields: editField(e.requestFields, fi, (f) => f.copyWith(dartType: v)),
              ),
            ),
            onRequestNullable: (fi, v) => _update(
              i,
              (e) => e.copyWith(
                requestFields: editField(e.requestFields, fi, (f) => f.copyWith(nullable: v)),
              ),
            ),
            onRequestRemove: (fi) =>
                _update(i, (e) => e.copyWith(requestFields: [...e.requestFields]..removeAt(fi))),
            onRequestChildrenChanged: (fi, children) => _update(
              i,
              (e) => e.copyWith(
                requestFields: editField(
                  e.requestFields,
                  fi,
                  (f) => f.kind == FieldKind.list
                      ? f.copyWith(element: f.element!.copyWith(children: children))
                      : f.copyWith(children: children),
                ),
              ),
            ),
            onResponseInfer: (j) {
              if (j.trim().isEmpty) {
                _update(
                  i,
                  (e) => e.copyWith(
                    responseJson: '',
                    responseFields: const [],
                    responseWarnings: const [],
                  ),
                );
                return;
              }
              final r = const JsonEntityInferencer().infer(j, requireId: false);
              _update(
                i,
                (e) => e.copyWith(
                  responseJson: j,
                  responseFields: r.fields,
                  responseWarnings: r.warnings,
                ),
              );
            },
            onResponseReset: () => _update(
              i,
              (e) => e.copyWith(
                responseJson: '',
                responseFields: const [],
                responseWarnings: const [],
              ),
            ),
            onResponseAddField: () => _update(i, (e) {
              final used = e.responseFields.map((f) => f.dartName).toSet();
              var n = 'field';
              for (var k = 1; used.contains(n); k++) {
                n = 'field$k';
              }
              return e.copyWith(
                responseFields: [
                  ...e.responseFields,
                  FieldSpec(jsonKey: n, dartName: n),
                ],
              );
            }),
            onResponseName: (fi, v) => _update(
              i,
              (e) => e.copyWith(
                responseFields: editField(
                  e.responseFields,
                  fi,
                  (f) => f.copyWith(dartName: v.trim()),
                ),
              ),
            ),
            onResponseType: (fi, v) => _update(
              i,
              (e) => e.copyWith(
                responseFields: editField(e.responseFields, fi, (f) => f.copyWith(dartType: v)),
              ),
            ),
            onResponseNullable: (fi, v) => _update(
              i,
              (e) => e.copyWith(
                responseFields: editField(e.responseFields, fi, (f) => f.copyWith(nullable: v)),
              ),
            ),
            onResponseRemove: (fi) =>
                _update(i, (e) => e.copyWith(responseFields: [...e.responseFields]..removeAt(fi))),
            onResponseChildrenChanged: (fi, children) => _update(
              i,
              (e) => e.copyWith(
                responseFields: editField(
                  e.responseFields,
                  fi,
                  (f) => f.kind == FieldKind.list
                      ? f.copyWith(element: f.element!.copyWith(children: children))
                      : f.copyWith(children: children),
                ),
              ),
            ),
            onRemove: () => onChange([...endpoints]..removeAt(i)),
          ),
          10.gapH,
        ],
        OutlinedButton.icon(
          onPressed: enabled
              ? () {
                  var n = 'endpoint';
                  final used = endpoints.map((e) => e.name).toSet();
                  for (var k = 1; used.contains(n); k++) {
                    n = 'endpoint$k';
                  }
                  onChange([...endpoints, EndpointSpec(name: n)]);
                }
              : null,
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Add endpoint'),
          style: OutlinedButton.styleFrom(
            foregroundColor: context.neatColors.colorPrimaryCyan,
            side: BorderSide(color: context.neatColors.colorPrimaryCyan),
          ),
        ),
      ],
    );
  }
}

class _EndpointRow extends HookWidget {
  const _EndpointRow({
    required this.endpoint,
    required this.enabled,
    required this.onName,
    required this.onMethod,
    required this.onPath,
    required this.onRequestInfer,
    required this.onRequestReset,
    required this.onRequestAddField,
    required this.onRequestName,
    required this.onRequestType,
    required this.onRequestNullable,
    required this.onRequestRemove,
    required this.onRequestChildrenChanged,
    required this.onResponseInfer,
    required this.onResponseReset,
    required this.onResponseAddField,
    required this.onResponseName,
    required this.onResponseType,
    required this.onResponseNullable,
    required this.onResponseRemove,
    required this.onResponseChildrenChanged,
    required this.onRemove,
    super.key,
  });

  final EndpointSpec endpoint;
  final bool enabled;
  final ValueChanged<String> onName;
  final ValueChanged<HttpMethod> onMethod;
  final ValueChanged<String> onPath;
  final ValueChanged<String> onRequestInfer;
  final VoidCallback onRequestReset;
  final VoidCallback onRequestAddField;
  final void Function(int, String) onRequestName;
  final void Function(int, String) onRequestType;
  final void Function(int, bool) onRequestNullable;
  final ValueChanged<int> onRequestRemove;
  final void Function(int, List<FieldSpec>) onRequestChildrenChanged;
  final ValueChanged<String> onResponseInfer;
  final VoidCallback onResponseReset;
  final VoidCallback onResponseAddField;
  final void Function(int, String) onResponseName;
  final void Function(int, String) onResponseType;
  final void Function(int, bool) onResponseNullable;
  final ValueChanged<int> onResponseRemove;
  final void Function(int, List<FieldSpec>) onResponseChildrenChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    // Own controllers (created once per row, keyed by the parent's
    // ValueKey(i)) so typing doesn't recreate them / jump the cursor on
    // every rebuild — same pattern Workshop itself uses for its own text
    // fields, just local to this row instead of lifted to the top.
    final nameCtrl = useTextEditingController(text: endpoint.name);
    final pathCtrl = useTextEditingController(text: endpoint.path);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.neatColors.colorSurfaceCard,
        borderRadius: .circular(10),
        border: .all(color: context.neatColors.surface10),
      ),
      // ExpansionTile's header is a ListTile, which paints its own
      // background/ink on the nearest Material ancestor — without this, that
      // ancestor is whatever Material sits behind this DecoratedBox's own
      // background, so the ink/splash would be invisible underneath it.
      child: Material(
        color: Colors.transparent,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: endpoint.name.startsWith('endpoint') && endpoint.path.isEmpty,
            title: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: nameCtrl,
                    enabled: enabled,
                    onChanged: onName,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const .collapsed(hintText: 'name, e.g. login'),
                  ),
                ),
                8.gapW,
                SizedBox(
                  width: 90,
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<HttpMethod>(
                      value: endpoint.method,
                      isDense: true,
                      dropdownColor: context.neatColors.colorSurfaceCard,
                      style: TextStyle(color: context.neatColors.colorPrimaryCyan, fontSize: 12),
                      onChanged: enabled ? (m) => onMethod(m ?? HttpMethod.get) : null,
                      items: HttpMethod.values
                          .map(
                            (m) => DropdownMenuItem(value: m, child: Text(m.name.toUpperCase())),
                          )
                          .toList(),
                    ),
                  ),
                ),
                8.gapW,
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: pathCtrl,
                    enabled: enabled,
                    onChanged: onPath,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const .collapsed(hintText: '/auth/login'),
                  ),
                ),
                IconButton(
                  onPressed: enabled ? onRemove : null,
                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.white54),
                  tooltip: 'Remove endpoint',
                ),
              ],
            ),
            childrenPadding: const .fromLTRB(14, 0, 14, 14),
            children: [
              Text(
                'Request body (optional)',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              8.gapH,
              EntityFieldsEditor(
                json: endpoint.requestJson,
                fields: endpoint.requestFields,
                warnings: endpoint.requestWarnings,
                onInfer: onRequestInfer,
                onReset: onRequestReset,
                onAddField: onRequestAddField,
                onName: onRequestName,
                onType: onRequestType,
                onNullable: onRequestNullable,
                onRemove: onRequestRemove,
                onChildrenChanged: onRequestChildrenChanged,
              ),
              16.gapH,
              Text(
                'Response body (optional)',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              8.gapH,
              EntityFieldsEditor(
                json: endpoint.responseJson,
                fields: endpoint.responseFields,
                warnings: endpoint.responseWarnings,
                onInfer: onResponseInfer,
                onReset: onResponseReset,
                onAddField: onResponseAddField,
                onName: onResponseName,
                onType: onResponseType,
                onNullable: onResponseNullable,
                onRemove: onResponseRemove,
                onChildrenChanged: onResponseChildrenChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
