import 'package:flutter/material.dart';
import 'package:neat/features/feature_gen/presentation/widgets/routing_card.dart';

class FeatureShapeRow extends StatelessWidget {
  const FeatureShapeRow({
    required this.useCustomEndpoints,
    required this.enabled,
    required this.onSelect,
    super.key,
  });

  final bool useCustomEndpoints;
  final bool enabled;
  final ValueChanged<bool> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 12,
      children: [
        Expanded(
          child: RoutingCard(
            title: 'Entity + CRUD',
            subtitle: 'One entity, full CRUD (get/create/update/delete)',
            isSelected: !useCustomEndpoints,
            onTap: enabled ? () => onSelect(false) : null,
          ),
        ),
        Expanded(
          child: RoutingCard(
            title: 'Custom Endpoints',
            subtitle: 'N arbitrary REST calls, each typed independently',
            isSelected: useCustomEndpoints,
            onTap: enabled ? () => onSelect(true) : null,
          ),
        ),
      ],
    );
  }
}
