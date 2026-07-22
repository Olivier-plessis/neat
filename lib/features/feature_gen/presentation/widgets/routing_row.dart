import 'package:flutter/material.dart';
import 'package:neat/features/feature_gen/domain/models/feature_gen_options.dart';
import 'package:neat/features/feature_gen/presentation/widgets/routing_card.dart';

class RoutingRow extends StatelessWidget {
  const RoutingRow({
    required this.selected,
    required this.enabled,
    required this.routingEnabled,
    required this.onSelect,
    super.key,
  });

  final FeatureRouting selected;
  final bool enabled;
  final bool routingEnabled;
  final ValueChanged<FeatureRouting> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 14,
      children: [
        Expanded(
          child: RoutingCard(
            title: 'Root Route',
            subtitle: '/feature',
            isSelected: selected == FeatureRouting.root,
            onTap: enabled ? () => onSelect(FeatureRouting.root) : null,
          ),
        ),
        Expanded(
          child: RoutingCard(
            title: 'Child Route',
            subtitle: 'Sub-route of another feature',
            isSelected: selected == FeatureRouting.child,
            comingSoon: !routingEnabled,
            onTap: enabled && routingEnabled ? () => onSelect(FeatureRouting.child) : null,
          ),
        ),
        Expanded(
          child: RoutingCard(
            title: 'Shell Branch',
            subtitle: 'Bottom-nav branch',
            isSelected: selected == FeatureRouting.shell,
            comingSoon: !routingEnabled,
            onTap: enabled && routingEnabled ? () => onSelect(FeatureRouting.shell) : null,
          ),
        ),
      ],
    );
  }
}
