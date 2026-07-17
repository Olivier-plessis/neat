import 'package:flutter/material.dart';
import 'package:neat/features/feature_gen/domain/models/feature_gen_options.dart';
import 'package:neat/features/feature_gen/presentation/widgets/endpoints_editor.dart';
import 'package:neat_ui/neat_ui.dart';

/// Step 2 (Custom Endpoints mode): N arbitrary REST calls, each typed
/// independently — see EndpointsEditor's own doc.
class EndpointsStep extends StatelessWidget {
  const EndpointsStep({
    required this.opts,
    required this.onChanged,
    required this.enabled,
    super.key,
  });

  final FeatureGenOptions opts;
  final ValueChanged<FeatureGenOptions> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: .start,
      children: [
        const SectionHeader(icon: Icons.api_outlined, label: 'Endpoints'),
        10.gapH,
        EndpointsEditor(
          endpoints: opts.endpoints,
          enabled: enabled,
          onChange: (eps) => onChanged(opts.copyWith(endpoints: eps)),
        ),
      ],
    );
  }
}
