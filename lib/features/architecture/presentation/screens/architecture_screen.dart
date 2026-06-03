import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:neat/core/theme/app_theme.dart';
import 'package:neat/features/architecture/domain/usecases/generate_tree_usecase.dart';
import 'package:neat/features/architecture/presentation/providers/architecture_provider.dart';
import 'package:neat/features/dependencies/presentation/providers/dependencies_provider.dart';

class ArchitectureScreen extends ConsumerWidget {
  const ArchitectureScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(architectureProvider);
    final notifier = ref.read(architectureProvider.notifier);
    final hasRiverpod = ref.watch(
      selectedPackagesProvider.select((list) => list.any((p) => p.name.contains('riverpod'))),
    );
    final hasBloc = ref.watch(
      selectedPackagesProvider.select((list) => list.any((p) => p.name.contains('bloc'))),
    );
    final tree = const GenerateTreeUsecase().execute(
      state,
      hasRiverpod: hasRiverpod,
      hasBloc: hasBloc,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Architecture Setup',
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 8),
        Text(
          'Choose how your project will be structured and which architectural bricks to include.',
          style: TextStyle(color: Colors.grey[400], fontSize: 14),
        ),
        const SizedBox(height: 24),

        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Colonne gauche ────────────────────────────────────────────
              Expanded(
                flex: 6,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionHeader(icon: Icons.bookmark_added_outlined, label: 'First Feature'),
                      const SizedBox(height: 12),
                      _FeatureNameField(
                        initialValue: state.firstFeatureName,
                        errorText: state.validateFirstFeatureName(),
                        onChanged: notifier.setFirstFeatureName,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Generated at lib/features/${state.firstFeatureName.isEmpty ? '...' : state.firstFeatureName}/',
                        style: TextStyle(
                          color: AppTheme.colorPrimaryCyan.withValues(alpha: 0.7),
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(height: 28),

                      _SectionHeader(icon: Icons.view_quilt_outlined, label: 'Structural Pattern'),
                      const SizedBox(height: 12),
                      IntrinsicHeight(
                        child: Row(
                          children: [
                            Expanded(
                              child: _PatternCard(
                                title: 'Feature-First',
                                description:
                                    'Organizes code by functional features. Recommended for scalability and team collaboration.',
                                isSelected: state.pattern == StructuralPattern.featureFirst,
                                isRecommended: true,
                                onTap: () => notifier.setPattern(StructuralPattern.featureFirst),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _PatternCard(
                                title: 'Layer-First',
                                description:
                                    'Traditional approach organizing by architectural layers (Data, Domain, Presentation) globally.',
                                isSelected: state.pattern == StructuralPattern.layerFirst,
                                isRecommended: false,
                                onTap: () => notifier.setPattern(StructuralPattern.layerFirst),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),
                      _SectionHeader(
                        icon: Icons.layers_outlined,
                        label: 'Clean Architecture Layers',
                      ),
                      const SizedBox(height: 12),
                      _ToggleTile(
                        title: 'Include Data Mappers',
                        description: 'Generate dedicated DTO to Domain Entity mappers.',
                        value: state.includeMappers,
                        onChanged: notifier.toggleMappers,
                      ),
                      const SizedBox(height: 8),
                      if (hasRiverpod)
                        _ToggleTile(
                          title: 'Use @riverpod annotation syntax',
                          description:
                              'Génère `@riverpod class MyNotifier extends _\$MyNotifier` au lieu du setup manuel NotifierProvider.',
                          value: state.useRiverpodAnnotations,
                          onChanged: notifier.toggleRiverpodAnnotations,
                        ),
                      if (hasRiverpod && hasBloc) const SizedBox(height: 8),
                      if (hasBloc)
                        _ToggleTile(
                          title: 'Use Cubit instead of full BLoC',
                          description:
                              'Génère des `Cubit<State>` (sans Events) plutôt que des `Bloc<Event, State>` complets.',
                          value: state.useCubit,
                          onChanged: notifier.toggleCubit,
                        ),

                      const SizedBox(height: 28),
                      _SectionHeader(
                        icon: Icons.bug_report_outlined,
                        label: 'Testing Architecture',
                      ),
                      const SizedBox(height: 12),
                      _ToggleTile(
                        title: 'Mirror Structure in /test',
                        description:
                            'Automatically create matching directory structures for unit and widget tests.',
                        value: state.mirrorTestStructure,
                        onChanged: notifier.toggleMirrorTest,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 24),

              // ── Colonne droite : tree preview ─────────────────────────────
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                          'FOLDER STRUCTURE PREVIEW',
                          style: TextStyle(
                            color: AppTheme.colorPrimaryCyan,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D0D0F),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Barre titre style terminal
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: const BoxDecoration(
                                color: Color(0xFF18181C),
                                borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                              ),
                              child: Row(
                                children: [
                                  _TrafficDot(color: const Color(0xFFFF5F57)),
                                  const SizedBox(width: 6),
                                  _TrafficDot(color: const Color(0xFFFFBD2E)),
                                  const SizedBox(width: 6),
                                  _TrafficDot(color: const Color(0xFF28C840)),
                                  const SizedBox(width: 16),
                                  Text(
                                    'preview.tree',
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 12,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Flexible(
                              child: SizedBox(
                                width: MediaQuery.sizeOf(context).width,
                                child: SingleChildScrollView(
                                  physics: BouncingScrollPhysics(),
                                  padding: const EdgeInsets.all(16),
                                  child: Text(
                                    tree,
                                    style: const TextStyle(
                                      color: Color(0xFF9ECE6A),
                                      fontFamily: 'monospace',
                                      fontSize: 12,
                                      height: 1.7,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
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
}

// ── Section header ────────────────────────────────────────────────────────────

// ── First feature name field ──────────────────────────────────────────────────

class _FeatureNameField extends StatefulWidget {
  const _FeatureNameField({
    required this.initialValue,
    required this.errorText,
    required this.onChanged,
  });

  final String initialValue;
  final String? errorText;
  final ValueChanged<String> onChanged;

  @override
  State<_FeatureNameField> createState() => _FeatureNameFieldState();
}

class _FeatureNameFieldState extends State<_FeatureNameField> {
  late final TextEditingController _ctrl = TextEditingController(text: widget.initialValue);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _ctrl,
      onChanged: widget.onChanged,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: 'e.g. home, dashboard, auth',
        errorText: widget.errorText,
      ),
    );
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
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

// ── Pattern card ──────────────────────────────────────────────────────────────

class _PatternCard extends StatelessWidget {
  const _PatternCard({
    required this.title,
    required this.description,
    required this.isSelected,
    required this.isRecommended,
    required this.onTap,
  });

  final String title;
  final String description;
  final bool isSelected;
  final bool isRecommended;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0E1A1A) : const Color(0xFF18181C),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.colorPrimaryCyan : Colors.white10,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.layers,
                  color: isSelected ? AppTheme.colorPrimaryCyan : Colors.grey[600],
                  size: 22,
                ),
                const Spacer(),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? AppTheme.colorPrimaryCyan : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? AppTheme.colorPrimaryCyan : Colors.white24,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 12, color: Color(0xFF0E0E0E))
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? AppTheme.colorPrimaryCyan : Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(description, style: TextStyle(color: Colors.grey[500], fontSize: 12, height: 1.5)),
            if (isRecommended) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.colorPrimaryCyan.withValues(alpha: 0.5)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'RECOMMENDED',
                  style: TextStyle(
                    color: AppTheme.colorPrimaryCyan,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Toggle tile ───────────────────────────────────────────────────────────────

class _ToggleTile extends StatelessWidget {
  const _ToggleTile({
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF18181C),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(description, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: () => onChanged(!value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48,
              height: 28,
              decoration: BoxDecoration(
                color: value ? AppTheme.colorPrimaryCyan.withValues(alpha: 0.15) : Colors.white10,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: value ? AppTheme.colorPrimaryCyan : Colors.white12,
                  width: 1.5,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedAlign(
                    duration: const Duration(milliseconds: 200),
                    alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(3),
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: value ? AppTheme.colorPrimaryCyan : Colors.grey[700],
                          shape: BoxShape.circle,
                        ),
                        child: value
                            ? const Icon(Icons.check, size: 11, color: Color(0xFF0E0E0E))
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Traffic light dot ─────────────────────────────────────────────────────────

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
