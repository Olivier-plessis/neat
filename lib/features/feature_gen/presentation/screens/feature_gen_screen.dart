import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:neat/core/theme/app_theme.dart';
import 'package:neat/features/feature_gen/domain/models/feature_gen_state.dart';
import 'package:neat/features/feature_gen/presentation/providers/feature_gen_provider.dart';

class FeatureGenScreen extends ConsumerWidget {
  const FeatureGenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(featureGenProvider);
    final notifier = ref.read(featureGenProvider.notifier);

    return Column(
      crossAxisAlignment: .start,
      children: [
        const Text(
          'Feature Workshop',
          style: TextStyle(fontSize: 32, fontWeight: .bold, color: Colors.white),
        ),
        const SizedBox(height: 8),
        Text(
          'Generate production-ready features for your existing project. Select layers and routing strategy.',
          style: TextStyle(color: Colors.grey[400], fontSize: 14),
        ),
        const SizedBox(height: 24),

        Expanded(
          child: Row(
            crossAxisAlignment: .start,
            children: [
              // ── Left: Configuration ────────────────────────────────────────
              Expanded(
                flex: 6,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: .start,
                    children: [
                      _SectionHeader(icon: Icons.edit_note_outlined, label: 'Feature Identity'),
                      const SizedBox(height: 12),
                      TextField(
                        onChanged: notifier.setName,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'e.g. user_profile, auth_login',
                          errorText: state.validateName(),
                        ),
                      ),

                      const SizedBox(height: 32),
                      _SectionHeader(icon: Icons.alt_route_outlined, label: 'Navigation & Routing'),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _RoutingCard(
                              title: 'Root Route',
                              description: '/${state.name.isEmpty ? 'feature' : state.name}',
                              isSelected: state.routing == FeatureRouting.root,
                              onTap: () => notifier.setRouting(FeatureRouting.root),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _RoutingCard(
                              title: 'Child Route',
                              description: 'Sub-route of another feature',
                              isSelected: state.routing == FeatureRouting.child,
                              onTap: () => notifier.setRouting(FeatureRouting.child),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _RoutingCard(
                              title: 'Shell Branch',
                              description: 'For Bottom Nav or Side rails',
                              isSelected: state.routing == FeatureRouting.shell,
                              onTap: () => notifier.setRouting(FeatureRouting.shell),
                            ),
                          ),
                        ],
                      ),
                      if (state.routing == FeatureRouting.child) ...[
                        const SizedBox(height: 16),
                        TextField(
                          onChanged: notifier.setParentFeature,
                          decoration: const InputDecoration(
                            hintText: 'Parent feature name (e.g. dashboard)',
                            labelText: 'PARENT FEATURE',
                            labelStyle: TextStyle(fontSize: 10, letterSpacing: 1),
                          ),
                        ),
                      ],

                      const SizedBox(height: 32),
                      _SectionHeader(icon: Icons.layers_outlined, label: 'Architecture Layers'),
                      const SizedBox(height: 12),
                      _LayerToggle(
                        label: 'Remote Data Source',
                        description: 'Generates Retrofit client and API interface.',
                        value: state.includeRemoteDataSource,
                        onChanged: notifier.toggleRemoteDataSource,
                      ),
                      _LayerToggle(
                        label: 'Local Data Source',
                        description: 'Generates local cache / Secure storage logic.',
                        value: state.includeLocalDataSource,
                        onChanged: notifier.toggleLocalDataSource,
                      ),
                      _LayerToggle(
                        label: 'Domain UseCase',
                        description: 'Business logic class with Result<T> return type.',
                        value: state.includeUseCase,
                        onChanged: notifier.toggleUseCase,
                      ),
                      _LayerToggle(
                        label: 'Data Mapper',
                        description: 'Extension for DTO to Entity conversion.',
                        value: state.includeMapper,
                        onChanged: notifier.toggleMapper,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 24),

              // ── Right: Tree Preview ────────────────────────────────────────
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: .start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.remove_red_eye_outlined,
                          color: AppTheme.colorPrimaryCyan,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'BLUEPRINT OVERVIEW',
                          style: TextStyle(
                            color: AppTheme.colorPrimaryCyan,
                            fontSize: 11,
                            fontWeight: .bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A0A0C),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Column(
                          crossAxisAlignment: .start,
                          children: [
                            // Terminal Title Bar
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: const BoxDecoration(
                                color: Color(0xFF141416),
                                borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                              ),
                              child: Row(
                                children: [
                                  const _TrafficDot(color: Color(0xFFFF5F57)),
                                  const SizedBox(width: 6),
                                  const _TrafficDot(color: Color(0xFFFFBD2E)),
                                  const SizedBox(width: 6),
                                  const _TrafficDot(color: Color(0xFF28C840)),
                                  const SizedBox(width: 16),
                                  Text(
                                    'feature.tree',
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 12,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.all(16),
                                child: Text(
                                  _buildFeatureTree(state),
                                  style: const TextStyle(
                                    color: Color(0xFF9ECE6A),
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                    height: 1.7,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: state.validateName() == null ? () {} : null,
                        icon: const Icon(Icons.auto_awesome_outlined, size: 18),
                        label: const Text(
                          'GENERATE FEATURE',
                          style: TextStyle(fontWeight: .bold, letterSpacing: 1),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  String _buildFeatureTree(FeatureGenState state) {
    final name = state.name.isEmpty ? 'feature_name' : state.name;
    final lines = <String>[];
    lines.add('lib/features/$name/');
    lines.add('├── data/');
    if (state.includeRemoteDataSource || state.includeLocalDataSource) {
      lines.add('│   ├── datasources/');
      if (state.includeRemoteDataSource) lines.add('│   │   └── ${name}_api_client.dart');
    }
    lines.add('│   ├── dto/');
    if (state.includeMapper) lines.add('│   ├── mappers/');
    lines.add('│   └── repositories/');

    lines.add('├── domain/');
    lines.add('│   ├── models/');
    lines.add('│   ├── repositories/');
    if (state.includeUseCase) lines.add('│   └── usecases/');

    lines.add('└── presentation/');
    lines.add('    ├── providers/');
    lines.add('    ├── routes/');
    lines.add('    ├── screens/');
    lines.add('    └── widgets/');

    return lines.join('\n');
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.colorPrimaryCyan, size: 18),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: .bold),
        ),
      ],
    );
  }
}

class _RoutingCard extends StatelessWidget {
  const _RoutingCard({
    required this.title,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.colorPrimaryCyan.withValues(alpha: 0.05)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppTheme.colorPrimaryCyan : Colors.white12,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: .start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: isSelected ? AppTheme.colorPrimaryCyan : Colors.white70,
                fontSize: 13,
                fontWeight: .bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(color: Colors.grey[600], fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _LayerToggle extends StatelessWidget {
  const _LayerToggle({
    required this.label,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        title: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
        subtitle: Text(description, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        activeColor: AppTheme.colorPrimaryCyan,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }
}

class _TrafficDot extends StatelessWidget {
  const _TrafficDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 11,
      height: 11,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
