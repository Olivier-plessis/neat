import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:neat/core/theme/app_theme.dart';
import 'package:neat/features/cicd/domain/usecases/generate_yaml_usecase.dart';
import 'package:neat/features/cicd/presentation/providers/cicd_provider.dart';
import 'package:neat/features/identity/presentation/providers/stepper_provider.dart';

class CicdScreen extends HookConsumerWidget {
  const CicdScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cicdProvider);
    final notifier = ref.read(cicdProvider.notifier);
    final files = const GenerateYamlUsecase().execute(state);
    final previewIndex = useState(0);

    // Reset tab index when file count changes
    if (previewIndex.value >= files.length && files.isNotEmpty) {
      previewIndex.value = files.length - 1;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'CI/CD Pipeline Engine',
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 8),
        Text(
          'Select your CI runners and CD delivery tools. Combine them freely — NEAT generates every config file.',
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
                      _SectionHeader(label: 'CI Runners'),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _ToolCard(
                              icon: Icons.hub_outlined,
                              title: 'GitHub Actions',
                              description: 'Workflows YAML dans `.github/workflows/`.',
                              tags: const ['ubuntu-latest', 'macos-latest'],
                              badge: 'CI',
                              badgeColor: const Color(0xFF2E7D32),
                              isSelected: state.isSelected(CiTool.githubActions),
                              onTap: () => notifier.toggleTool(CiTool.githubActions),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ToolCard(
                              icon: Icons.view_quilt_outlined,
                              title: 'GitLab CI',
                              description: 'Configuration `.gitlab-ci.yml` avec runners dédiés.',
                              tags: const ['flutter-docker', 'shared-runner'],
                              badge: 'CI',
                              badgeColor: const Color(0xFF2E7D32),
                              isSelected: state.isSelected(CiTool.gitlabCi),
                              onTap: () => notifier.toggleTool(CiTool.gitlabCi),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ToolCard(
                              icon: Icons.auto_fix_high_outlined,
                              title: 'Codemagic',
                              description: 'CI/CD mobile-first, `codemagic.yaml` tout-en-un.',
                              tags: const ['mac-mini-m1', 'linux'],
                              badge: 'CI/CD',
                              badgeColor: const Color(0xFF1565C0),
                              isSelected: state.isSelected(CiTool.codemagic),
                              onTap: () => notifier.toggleTool(CiTool.codemagic),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                      _SectionHeader(label: 'CD & Delivery'),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _ToolCard(
                              icon: Icons.rocket_launch_outlined,
                              title: 'Fastlane',
                              description:
                                  'Automatise la signature et la publication sur App Store & Play Store.',
                              tags: const ['App Store', 'Play Store'],
                              badge: 'CD',
                              badgeColor: const Color(0xFF6A1B9A),
                              isSelected: state.isSelected(CiTool.fastlane),
                              onTap: () => notifier.toggleTool(CiTool.fastlane),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ToolCard(
                              icon: Icons.system_update_outlined,
                              title: 'Shorebird',
                              description:
                                  'Déploiement OTA (over-the-air) sans passer par les stores.',
                              tags: const ['OTA', 'CodePush'],
                              badge: 'OTA',
                              badgeColor: const Color(0xFFB71C1C),
                              isSelected: state.isSelected(CiTool.shorebird),
                              onTap: () => notifier.toggleTool(CiTool.shorebird),
                            ),
                          ),
                          const Expanded(child: SizedBox()),
                        ],
                      ),

                      if (state.hasCiRunner) ...[
                        const SizedBox(height: 24),
                        _SectionHeader(label: 'Pipeline Stages'),
                        const SizedBox(height: 12),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: const Color(0xFF18181C),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Column(
                            children: [
                              _StageTile(
                                icon: Icons.manage_search_outlined,
                                title: 'Static Analysis & Linting',
                                description: 'flutter analyze + dart format avant chaque merge.',
                                value: state.runAnalyze,
                                onChanged: notifier.toggleAnalyze,
                              ),
                              const Divider(
                                color: Colors.white10,
                                height: 1,
                                indent: 20,
                                endIndent: 20,
                              ),
                              _StageTile(
                                icon: Icons.science_outlined,
                                title: 'Unit & Widget Testing',
                                description: 'flutter test avec rapport de couverture LCOV.',
                                value: state.runTests,
                                onChanged: notifier.toggleTests,
                              ),
                              const Divider(
                                color: Colors.white10,
                                height: 1,
                                indent: 20,
                                endIndent: 20,
                              ),
                              _StageTile(
                                icon: Icons.storefront_outlined,
                                title: 'Auto-deploy to stores',
                                description:
                                    'Déclenché sur les tags `v*.*.*` — utilise Fastlane ou Shorebird si sélectionné.',
                                value: state.autoDeploy,
                                onChanged: notifier.toggleAutoDeploy,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 24),

              // ── Colonne droite : preview ──────────────────────────────────
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 16,
                          decoration: BoxDecoration(
                            color: AppTheme.colorPrimaryCyan,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Generated Files',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (files.isNotEmpty) ...[
                          const Spacer(),
                          Text(
                            '${files.length} file${files.length > 1 ? 's' : ''}',
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (files.isEmpty)
                      Expanded(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D0D0F),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.description_outlined, color: Colors.white12, size: 40),
                                const SizedBox(height: 12),
                                Text(
                                  'Sélectionne au moins un outil\npour prévisualiser les fichiers.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey[700], fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else ...[
                      // Tabs fichiers
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: List.generate(files.length, (i) {
                            final selected = previewIndex.value == i;
                            return GestureDetector(
                              onTap: () => previewIndex.value = i,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? const Color(0xFF0D0D0F)
                                      : const Color(0xFF18181C),
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(6),
                                  ),
                                  border: Border.all(
                                    color: selected ? AppTheme.colorPrimaryCyan : Colors.white10,
                                    width: selected ? 1.5 : 1,
                                  ),
                                ),
                                child: Text(
                                  files[i].filename.split('/').last,
                                  style: TextStyle(
                                    color: selected ? AppTheme.colorPrimaryCyan : Colors.grey[600],
                                    fontSize: 11,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D0D0F),
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(10),
                              bottomRight: Radius.circular(10),
                              topRight: Radius.circular(10),
                            ),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: SingleChildScrollView(
                            child: Text(
                              files[previewIndex.value].content,
                              style: const TextStyle(
                                color: Color(0xFF9ECE6A),
                                fontFamily: 'monospace',
                                fontSize: 11.5,
                                height: 1.55,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            OutlinedButton.icon(
              onPressed: () =>
                  ref.read(currentStepProvider.notifier).setStep(NeatStep.architecture),
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('Back'),
              style: OutlinedButton.styleFrom(minimumSize: const Size(120, 48)),
            ),
            ElevatedButton(
              onPressed: () => ref.read(currentStepProvider.notifier).setStep(NeatStep.launch),
              style: ElevatedButton.styleFrom(minimumSize: const Size(160, 48)),
              child: const Row(
                children: [
                  Text('Next Step'),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, size: 16),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: AppTheme.colorPrimaryCyan,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

// ── Tool card (multi-select) ──────────────────────────────────────────────────

class _ToolCard extends StatelessWidget {
  const _ToolCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.tags,
    required this.badge,
    required this.badgeColor,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final List<String> tags;
  final String badge;
  final Color badgeColor;
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
          color: isSelected ? const Color(0xFF111A1A) : const Color(0xFF18181C),
          borderRadius: BorderRadius.circular(10),
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
                  icon,
                  color: isSelected ? AppTheme.colorPrimaryCyan : Colors.grey[600],
                  size: 18,
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: badgeColor.withValues(alpha: 0.5), width: 0.5),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(color: badgeColor, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? AppTheme.colorPrimaryCyan : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? AppTheme.colorPrimaryCyan : Colors.white24,
                      width: 1.5,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 10, color: Color(0xFF0E0E0E))
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(description, style: TextStyle(color: Colors.grey[600], fontSize: 11, height: 1.4)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: tags
                  .map(
                    (t) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF141416),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Text(t, style: const TextStyle(color: Colors.white54, fontSize: 10)),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Stage tile ────────────────────────────────────────────────────────────────

class _StageTile extends StatelessWidget {
  const _StageTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF141416),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.grey[500], size: 16),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(description, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: () => onChanged(!value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 26,
              decoration: BoxDecoration(
                color: value ? AppTheme.colorPrimaryCyan.withValues(alpha: 0.15) : Colors.white10,
                borderRadius: BorderRadius.circular(13),
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
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: value ? AppTheme.colorPrimaryCyan : Colors.grey[700],
                          shape: BoxShape.circle,
                        ),
                        child: value
                            ? const Icon(Icons.check, size: 10, color: Color(0xFF0E0E0E))
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
