import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:neat/core/theme/app_theme.dart';
import 'package:neat/features/architecture/domain/models/architecture_state.dart';
import 'package:neat/features/architecture/presentation/providers/architecture_provider.dart';
import 'package:neat/features/cicd/domain/models/cicd_state.dart';
import 'package:neat/features/cicd/presentation/providers/cicd_provider.dart';
import 'package:neat/features/dependencies/domain/models/pub_package.dart';
import 'package:neat/features/dependencies/presentation/providers/dependencies_provider.dart';
import 'package:neat/features/feature_gen/presentation/providers/workshop_controller.dart';
import 'package:neat/features/generation/domain/usecases/launch_generation_usecase.dart';
import 'package:neat/features/hub/presentation/providers/recent_projects_provider.dart';
import 'package:neat/features/identity/domain/models/identity_state.dart';
import 'package:neat/features/identity/presentation/providers/identity_provider.dart';
import 'package:neat/features/identity/presentation/providers/stepper_provider.dart';
import 'package:neat/features/theme_engine/presentation/providers/theme_engine_provider.dart';

class LaunchScreen extends HookConsumerWidget {
  const LaunchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final identity = ref.watch(identityProvider);
    final packages = ref.watch(selectedPackagesProvider);
    final architecture = ref.watch(architectureProvider);
    final cicd = ref.watch(cicdProvider);
    final theme = ref.watch(themeEngineProvider);

    // isGenerating lives in the shared provider so main_layout can lock the Back button
    final isGeneratingNotifier = ref.read(isGeneratingProvider.notifier);
    final isGenerating = ref.watch(isGeneratingProvider);
    final hasFinished = useState(false);
    final errorMessage = useState<String?>(null);
    final logs = useState<List<String>>(_initialLogs(identity));
    final scrollController = useScrollController();

    void appendLog(String line) {
      logs.value = [...logs.value, line];
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (scrollController.hasClients) {
          scrollController.animateTo(
            scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
          );
        }
      });
    }

    Future<void> generate() async {
      isGeneratingNotifier.set(true);
      hasFinished.value = false;
      errorMessage.value = null;
      logs.value = ['neat@shell:~\$ generate --project ${identity.name}', ''];

      try {
        await const LaunchGenerationUsecase().execute(
          identity: identity,
          packages: packages,
          architecture: architecture,
          cicd: cicd,
          theme: theme,
          onLog: appendLog,
        );
        hasFinished.value = true;
        // Surface the freshly generated project in the Hub's recent list.
        await ref.read(recentProjectsProvider.notifier).register(
              path: '${identity.projectPath}/${identity.name}',
              name: identity.name,
            );
      } catch (e) {
        errorMessage.value = e.toString();
        appendLog('[✗] Generation failed: $e');
      } finally {
        isGeneratingNotifier.set(false);
      }
    }

    final canGenerate = identity.name.isNotEmpty && identity.projectPath.isNotEmpty;

    // After a successful generation: load the just-created project into the
    // Workshop (no app restart) so the user can add a feature straight away.
    Future<void> addFeature() async {
      final workshop = ref.read(workshopControllerProvider.notifier);
      await workshop.openProject('${identity.projectPath}/${identity.name}');
      if (ref.read(workshopControllerProvider).project != null) {
        ref.read(currentStepProvider.notifier).setStep(NeatStep.featureGen);
      }
    }

    void backToHome() => ref.read(currentStepProvider.notifier).setStep(NeatStep.hub);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ready for Launch',
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 8),
        Text(
          'Review your configuration before initiating the generation sequence. The process will\nscaffold your complete Flutter architecture.',
          style: TextStyle(color: Colors.grey[400], fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 24),

        // ── Ligne principale ──────────────────────────────────────────────
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Panneau config (gauche)
              Expanded(
                flex: 6,
                child: _ConfigPanel(
                  identity: identity,
                  packages: packages,
                  architecture: architecture,
                  cicd: cicd,
                ),
              ),
              const SizedBox(width: 20),
              // Panneau action (droite)
              Expanded(
                flex: 4,
                child: _ActionPanel(
                  isGenerating: isGenerating,
                  hasFinished: hasFinished.value,
                  hasError: errorMessage.value != null,
                  canGenerate: canGenerate,
                  onGenerate: generate,
                  onAddFeature: addFeature,
                  onBackToHome: backToHome,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ── Terminal output ───────────────────────────────────────────────
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A0C),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: const BoxDecoration(
                  color: Color(0xFF141416),
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

                    const Text(
                      'System Output',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    if (isGenerating)
                      const SizedBox(
                        width: 10,
                        height: 10,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: AppTheme.colorPrimaryCyan,
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(14),
                  itemCount: logs.value.length,
                  itemBuilder: (_, i) {
                    final line = logs.value[i];
                    return Text(
                      line,
                      style: TextStyle(
                        color: _lineColor(line),
                        fontFamily: 'monospace',
                        fontSize: 12,
                        height: 1.6,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),
      ],
    );
  }

  Color _lineColor(String line) {
    if (line.startsWith('[✓')) return const Color(0xFF4CAF50);
    if (line.startsWith('[✗')) return Colors.redAccent;
    if (line.startsWith('[▶')) return AppTheme.colorPrimaryCyan;
    if (line.startsWith('neat@')) return Colors.grey;
    return const Color(0xFF9ECE6A);
  }

  List<String> _initialLogs(IdentityState identity) => [
    'neat@shell:~\$ system status',
    if (identity.name.isNotEmpty) '[OK] Identity verified.' else '[WARN] Project name not set.',
    '[OK] Dependency graph loaded.',
    '[OK] Architecture pattern defined.',
    '',
    '> Ready. Awaiting execution command...',
  ];
}

// ── Config panel ──────────────────────────────────────────────────────────────

class _ConfigPanel extends StatelessWidget {
  const _ConfigPanel({
    required this.identity,
    required this.packages,
    required this.architecture,
    required this.cicd,
  });

  final IdentityState identity;
  final List<PubPackage> packages;
  final ArchitectureState architecture;
  final CicdState cicd;

  @override
  Widget build(BuildContext context) {
    final deps = packages.where((p) => !p.isDev).toList();
    final devDeps = packages.where((p) => p.isDev).toList();
    final cicdTools = cicd.selectedTools.map(_toolLabel).join(' + ');

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF141416),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.tune, color: AppTheme.colorPrimaryCyan, size: 16),
                const SizedBox(width: 8),
                const Text(
                  'System Configuration',
                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Identity
            _ConfigSection(
              label: 'PROJECT IDENTITY',
              children: [_IdentityRow(name: identity.name, org: identity.organization)],
            ),
            const SizedBox(height: 20),

            // Platforms
            _ConfigSection(
              label: 'TARGET PLATFORMS',
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: identity.targetPlatforms
                      .map((p) => _Chip(label: p[0].toUpperCase() + p.substring(1)))
                      .toList(),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Dependencies
            if (packages.isNotEmpty)
              _ConfigSection(
                label: 'CORE DEPENDENCIES',
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      ...deps.take(6).map((p) => _Chip(label: '${p.name}: ^${p.version}')),
                      if (deps.length > 6) _Chip(label: '+${deps.length - 6} more', muted: true),
                      ...devDeps
                          .take(3)
                          .map((p) => _Chip(label: '${p.name}: ^${p.version}', dev: true)),
                      if (devDeps.length > 3)
                        _Chip(label: '+${devDeps.length - 3} dev', muted: true),
                    ],
                  ),
                ],
              ),
            if (packages.isNotEmpty) const SizedBox(height: 20),

            // CI/CD
            if (cicd.selectedTools.isNotEmpty)
              _ConfigSection(
                label: 'CI/CD PIPELINE',
                children: [
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: const BoxDecoration(
                          color: AppTheme.colorPrimaryCyan,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          cicdTools,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontFamily: 'monospace',
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

            // Validation warning
            if (identity.name.isEmpty || identity.projectPath.isEmpty) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_outlined, color: Colors.orange, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        identity.name.isEmpty
                            ? 'Project name is required (step Identity).'
                            : 'Destination path is required (step Identity).',
                        style: const TextStyle(color: Colors.orange, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _toolLabel(CiTool t) => switch (t) {
    CiTool.githubActions => 'GitHub Actions',
    CiTool.gitlabCi => 'GitLab CI',
    CiTool.codemagic => 'Codemagic',
    CiTool.fastlane => 'Fastlane',
    CiTool.shorebird => 'Shorebird',
  };
}

class _ConfigSection extends StatelessWidget {
  const _ConfigSection({required this.label, required this.children});

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1.2),
        ),
        const SizedBox(height: 10),
        ...children,
      ],
    );
  }
}

class _IdentityRow extends StatelessWidget {
  const _IdentityRow({required this.name, required this.org});

  final String name;
  final String org;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name.isEmpty ? '—' : name,
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(org, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, this.dev = false, this.muted = false});

  final String label;
  final bool dev;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: dev
            ? const Color(0xFF2D2010)
            : muted
            ? const Color(0xFF1A1A1E)
            : const Color(0xFF18181C),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: dev
              ? const Color(0xFFFFA726).withValues(alpha: 0.4)
              : muted
              ? Colors.white10
              : Colors.white12,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: dev
              ? const Color(0xFFFFA726)
              : muted
              ? Colors.white30
              : Colors.white70,
          fontSize: 11,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}

// ── Action panel ──────────────────────────────────────────────────────────────

class _ActionPanel extends StatelessWidget {
  const _ActionPanel({
    required this.isGenerating,
    required this.hasFinished,
    required this.hasError,
    required this.canGenerate,
    required this.onGenerate,
    required this.onAddFeature,
    required this.onBackToHome,
  });

  final bool isGenerating;
  final bool hasFinished;
  final bool hasError;
  final bool canGenerate;
  final VoidCallback onGenerate;
  final VoidCallback onAddFeature;
  final VoidCallback onBackToHome;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (hasFinished) ...[
            const Icon(Icons.check_circle_outline, color: Color(0xFF4CAF50), size: 52),
            const SizedBox(height: 16),
            const Text(
              'Project Generated!',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Add a feature now in the Workshop, or open it in your IDE.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onAddFeature,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add a feature'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  backgroundColor: AppTheme.colorPrimaryCyan,
                  foregroundColor: Colors.black,
                  iconColor: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onBackToHome,
                icon: const Icon(Icons.home_outlined, size: 16),
                label: const Text('Back to Home'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 44),
                  foregroundColor: Colors.white70,
                  side: const BorderSide(color: Colors.white24),
                ),
              ),
            ),
          ] else if (hasError) ...[
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 52),
            const SizedBox(height: 16),
            const Text(
              'Generation failed',
              style: TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Check the System Output for details.',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const SizedBox(height: 20),
            _GenerateButton(
              isGenerating: false,
              canGenerate: canGenerate,
              onGenerate: onGenerate,
              retry: true,
            ),
          ] else ...[
            const Text(
              'Initialize Matrix',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Compile configuration and scaffold base architecture.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const SizedBox(height: 28),
            _GenerateButton(
              isGenerating: isGenerating,
              canGenerate: canGenerate,
              onGenerate: onGenerate,
              retry: false,
            ),
          ],
        ],
      ),
    );
  }
}

class _GenerateButton extends StatelessWidget {
  const _GenerateButton({
    required this.isGenerating,
    required this.canGenerate,
    required this.onGenerate,
    required this.retry,
  });

  final bool isGenerating;
  final bool canGenerate;
  final VoidCallback onGenerate;
  final bool retry;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: (isGenerating || !canGenerate) ? null : onGenerate,
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: canGenerate ? AppTheme.colorPrimaryCyan : Colors.white12,
            width: 1.5,
          ),
          foregroundColor: AppTheme.colorPrimaryCyan,
          disabledForegroundColor: Colors.white24,
        ),
        child: isGenerating
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.colorPrimaryCyan),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.power_settings_new, size: 16),
                  const SizedBox(width: 10),
                  Text(
                    retry ? 'RETRY' : 'GENERATE PROJECT',
                    style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
                  ),
                ],
              ),
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
