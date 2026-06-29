import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:neat/core/theme/app_theme.dart';
import 'package:neat/features/feature_gen/presentation/providers/workshop_controller.dart';
import 'package:neat/features/hub/domain/models/recent_project.dart';
import 'package:neat/features/hub/presentation/providers/recent_projects_provider.dart';
import 'package:neat/features/identity/presentation/providers/stepper_provider.dart';

/// The landing screen: create a fresh project (→ wizard) or open an existing
/// NEAT project (→ Workshop), plus a list of recent projects.
class HubScreen extends ConsumerWidget {
  const HubScreen({super.key});

  Future<void> _open(BuildContext context, WidgetRef ref, String path) async {
    final workshop = ref.read(workshopControllerProvider.notifier);
    await workshop.openProject(path);
    final state = ref.read(workshopControllerProvider);
    if (state.project != null) {
      ref.read(currentStepProvider.notifier).setStep(NeatStep.featureGen);
    } else if (state.error != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.error!)));
    }
  }

  Future<void> _browse(BuildContext context, WidgetRef ref) async {
    await FilePicker.skipEntitlementsChecks();
    final path = await FilePicker.getDirectoryPath(dialogTitle: 'Open a NEAT project');
    if (path != null && context.mounted) await _open(context, ref, path);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recents = ref.watch(recentProjectsProvider);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Neat-home', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),
                        const Center(child: _Header()),
                        const SizedBox(height: 40),
                        // IntrinsicHeight bounds the Row's height inside the
                        // scroll view, so the two cards can stretch to equal height.
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: _ActionCard(
                                  icon: Icons.rocket_launch_outlined,
                                  accent: true,
                                  title: 'Create New Project',
                                  subtitle:
                                      'Generate a production-ready Flutter architecture from scratch.',
                                  button: 'Start Journey',
                                  onTap: () => ref
                                      .read(currentStepProvider.notifier)
                                      .setStep(NeatStep.identity),
                                ),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                child: _ActionCard(
                                  icon: Icons.folder_open_outlined,
                                  accent: false,
                                  title: 'Open Existing Project',
                                  subtitle: 'Browse and load a NEAT project into the Workshop.',
                                  button: 'Browse Files',
                                  onTap: () => _browse(context, ref),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 48),
                        Row(
                          children: [
                            const Icon(Icons.history, size: 18, color: AppTheme.colorPrimaryCyan),
                            const SizedBox(width: 8),
                            const Text(
                              'Recent Projects',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        switch (recents) {
                          AsyncData(:final value) when value.isEmpty => const _EmptyRecents(),
                          AsyncData(:final value) => Column(
                              children: [
                                for (final p in value)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: _RecentTile(
                                      project: p,
                                      onTap: () => _open(context, ref, p.path),
                                      onRemove: () =>
                                          ref.read(recentProjectsProvider.notifier).remove(p.path),
                                    ),
                                  ),
                              ],
                            ),
                          AsyncError() => const _EmptyRecents(),
                          _ => const Padding(
                              padding: EdgeInsets.all(24),
                              child: Center(child: CircularProgressIndicator()),
                            ),
                        },
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RichText(
          text: const TextSpan(
            style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
            children: [
              TextSpan(text: 'Welcome to '),
              TextSpan(text: 'NEAT', style: TextStyle(color: AppTheme.colorPrimaryCyan)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'The high-performance architect for Flutter applications.\nStart fresh or resume your current build.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[400], fontSize: 14, height: 1.5),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.accent,
    required this.title,
    required this.subtitle,
    required this.button,
    required this.onTap,
  });

  final IconData icon;
  final bool accent;
  final String title;
  final String subtitle;
  final String button;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
        decoration: BoxDecoration(
          color: const Color(0xFF131316),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: accent
                    ? AppTheme.colorPrimaryCyan.withValues(alpha: 0.12)
                    : Colors.white.withValues(alpha: 0.04),
                shape: BoxShape.circle,
                border: Border.all(
                  color: accent ? AppTheme.colorPrimaryCyan.withValues(alpha: 0.4) : Colors.white12,
                ),
              ),
              child: Icon(icon, color: accent ? AppTheme.colorPrimaryCyan : Colors.white70, size: 26),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500], fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(160, 44),
                foregroundColor: accent ? AppTheme.colorPrimaryCyan : Colors.white,
                side: BorderSide(
                  color: accent ? AppTheme.colorPrimaryCyan : Colors.white24,
                ),
              ),
              child: Text(button.toUpperCase(), style: const TextStyle(letterSpacing: 0.8)),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentTile extends StatelessWidget {
  const _RecentTile({required this.project, required this.onTap, required this.onRemove});

  final RecentProject project;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF131316),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.terminal, size: 18, color: Colors.white60),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.name,
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    project.path,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12, fontFamily: 'monospace'),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'LAST OPENED',
                  style: TextStyle(color: Colors.grey[700], fontSize: 9, letterSpacing: 1),
                ),
                const SizedBox(height: 2),
                Text(
                  _relativeTime(project.lastOpened),
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 16, color: Colors.white24),
              onPressed: onRemove,
              tooltip: 'Retirer de la liste',
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyRecents extends StatelessWidget {
  const _EmptyRecents();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: const Color(0xFF131316),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: Center(
        child: Text(
          'No projects yet — create one to get started.',
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
      ),
    );
  }
}

String _relativeTime(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays == 1) return 'yesterday';
  if (diff.inDays < 7) return '${diff.inDays} days ago';
  return '${time.day}/${time.month}/${time.year}';
}
