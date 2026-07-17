import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:neat/features/generation/domain/models/endpoint_spec.dart';
import 'package:neat_ui/neat_ui.dart';

/// One of the 5 fixed CRUD operations' name + method + path, editable — see
/// FeatureGenOptions.customizeEndpoints. Close to EndpointRow's own
/// name/method/path row (Custom Endpoints mode), minus the expansion and
/// request/response body editors: every operation shares the feature's one
/// entity already defined in Entity Fields, so there's nothing to expand.
/// The role [label] (e.g. "Get All") stays a fixed indicator alongside the
/// editable [name] — renaming which Dart method gets generated shouldn't
/// cost the user their bearings on which of the 5 operations a row is.
class CrudEndpointRow extends HookWidget {
  const CrudEndpointRow({
    required this.label,
    required this.name,
    required this.method,
    required this.path,
    required this.enabled,
    required this.onName,
    required this.onMethod,
    required this.onPath,
    super.key,
  });

  final String label;
  final String name;
  final HttpMethod method;
  final String path;
  final bool enabled;
  final ValueChanged<String> onName;
  final ValueChanged<HttpMethod> onMethod;
  final ValueChanged<String> onPath;

  @override
  Widget build(BuildContext context) {
    // Own controllers (created once per row, keyed by the parent's fixed
    // ValueKey per operation) so typing doesn't jump the cursor on every
    // rebuild — same pattern EndpointRow itself uses.
    final nameCtrl = useTextEditingController(text: name);
    final pathCtrl = useTextEditingController(text: path);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 62,
            child: Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
          ),
          8.gapW,
          Expanded(
            child: TextField(
              controller: nameCtrl,
              enabled: enabled,
              onChanged: onName,
              style: const TextStyle(color: Colors.white, fontSize: 12.5),
              decoration: const InputDecoration.collapsed(hintText: 'name'),
            ),
          ),
          8.gapW,
          SizedBox(
            width: 84,
            child: DropdownButtonHideUnderline(
              child: DropdownButton<HttpMethod>(
                value: method,
                isDense: true,
                isExpanded: true,
                dropdownColor: context.neatColors.colorSurfaceCard,
                style: TextStyle(color: context.neatColors.colorPrimaryCyan, fontSize: 12),
                onChanged: enabled ? (m) => onMethod(m ?? method) : null,
                items: HttpMethod.values
                    .map((m) => DropdownMenuItem(value: m, child: Text(m.name.toUpperCase())))
                    .toList(),
              ),
            ),
          ),
          8.gapW,
          Expanded(
            child: TextField(
              controller: pathCtrl,
              enabled: enabled,
              onChanged: onPath,
              style: const TextStyle(color: Colors.white, fontSize: 12.5),
              decoration: const .collapsed(hintText: '/resource'),
            ),
          ),
        ],
      ),
    );
  }
}
