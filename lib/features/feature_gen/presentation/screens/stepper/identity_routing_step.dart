import 'package:flutter/material.dart';
import 'package:neat/features/feature_gen/domain/models/feature_gen_options.dart';
import 'package:neat/features/feature_gen/presentation/utils/field_decoration.dart';
import 'package:neat/features/feature_gen/presentation/widgets/feature_shape_row.dart';
import 'package:neat/features/feature_gen/presentation/widgets/layer_toggle.dart';
import 'package:neat/features/feature_gen/presentation/widgets/parent_routing_selector.dart';
import 'package:neat/features/feature_gen/presentation/widgets/routing_row.dart';
import 'package:neat/features/feature_gen/presentation/widgets/shell_branch_fields.dart';
import 'package:neat_ui/neat_ui.dart';

/// Step 1: feature name, optional Feature Shape choice (Entity+CRUD vs Custom
/// Endpoints — only when the stack can support it), and Navigation & Routing
/// (root/child/shell, parent selection, shell branch icon+label).
class IdentityRoutingStep extends StatelessWidget {
  const IdentityRoutingStep({
    required this.opts,
    required this.onChanged,
    required this.nameCtrl,
    required this.labelCtrl,
    required this.nameError,
    required this.enabled,
    required this.canCustomEndpoints,
    required this.hasNav,
    required this.routingEnabled,
    required this.needsParent,
    required this.parentMissing,
    required this.features,
    super.key,
  });

  final FeatureGenOptions opts;
  final ValueChanged<FeatureGenOptions> onChanged;
  final TextEditingController nameCtrl;
  final TextEditingController labelCtrl;
  final String? nameError;
  final bool enabled;
  final bool canCustomEndpoints;
  final bool hasNav;
  final bool routingEnabled;
  final bool needsParent;
  final bool parentMissing;
  final List<String> features;

  @override
  Widget build(BuildContext context) {
    final isShell = opts.routing == FeatureRouting.shell;

    return Column(
      crossAxisAlignment: .start,
      children: [
        // "Custom Endpoints" (ROADMAP.md §7 Phase 2) — an opt-in alternative
        // to Entity + CRUD, only offered when the project's stack can
        // actually support it (chopper, non-packageSplit).
        const SectionHeader(icon: Icons.edit_note, label: 'Feature Identity'),
        10.gapH,
        TextField(
          controller: nameCtrl,
          enabled: enabled,
          style: const TextStyle(color: Colors.white),
          decoration: fieldDecoration('e.g. user_profile, auth_login', nameError, context),
        ),
        if (canCustomEndpoints) ...[
          10.gapH,
          const SectionHeader(icon: Icons.api_outlined, label: 'Feature Shape'),
          10.gapH,
          FeatureShapeRow(
            useCustomEndpoints: opts.useCustomEndpoints,
            enabled: enabled,
            onSelect: (v) => onChanged(opts.copyWith(useCustomEndpoints: v)),
          ),
          24.gapH,
        ],
        if (hasNav) ...[
          24.gapH,
          const SectionHeader(icon: Icons.alt_route, label: 'Navigation & Routing'),
          10.gapH,
          RoutingRow(
            selected: opts.routing,
            enabled: enabled,
            routingEnabled: routingEnabled,
            onSelect: (r) => onChanged(opts.copyWith(routing: r)),
          ),
          if (needsParent) ...[
            24.gapH,
            ParentRoutingSelector(
              features: features,
              selected: opts.parentFeature.isEmpty ? null : opts.parentFeature,
              enabled: enabled,
              error: parentMissing ? 'Choose the parent feature.' : null,
              onSelect: (f) => onChanged(opts.copyWith(parentFeature: f ?? '')),
            ),
            if (opts.parentFeature.isNotEmpty) ...[
              4.gapH,
              LayerToggle(
                title: 'Merge into parent',
                subtitle:
                    'Nests this feature inside "${opts.parentFeature}" '
                    '(its own entity/repository/datasource, in a '
                    '"${opts.name.isEmpty ? 'feature_name' : opts.name}/" '
                    'subfolder per layer) instead of a separate feature — '
                    'no new package, workspace member, or path: dependency. '
                    'Works for a shell-branch parent too (imports the page '
                    'directly, skipping the shell page registry).',
                value: opts.mergeIntoParent,
                enabled: enabled,
                onChanged: (v) => onChanged(opts.copyWith(mergeIntoParent: v)),
              ),
            ],
          ],
          if (isShell) ...[
            24.gapH,
            ShellBranchFields(
              icon: opts.shellIcon,
              labelCtrl: labelCtrl,
              labelHint: opts.effectiveShellLabel,
              enabled: enabled,
              onIcon: (i) => onChanged(opts.copyWith(shellIcon: i)),
            ),
          ],
        ],
      ],
    );
  }
}
