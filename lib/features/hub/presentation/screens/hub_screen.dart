import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:neat/features/feature_gen/presentation/providers/workshop_controller.dart';
import 'package:neat/features/hub/domain/models/recent_project.dart';
import 'package:neat/features/hub/presentation/providers/recent_projects_provider.dart';
import 'package:neat/features/shell/presentation/providers/stepper_provider.dart';
import 'package:neat_ui/neat_ui.dart';

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
        padding: const .fromLTRB(24, 20, 24, 24),
        child: Column(
          crossAxisAlignment: .start,
          children: [
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: .start,
                      children: [
                        24.gapH,
                        const Center(child: _Header()),
                        40.gapH,
                        // IntrinsicHeight bounds the Row's height inside the
                        // scroll view, so the two cards can stretch to equal height.
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: .stretch,
                            spacing: 24,
                            children: [
                              Expanded(
                                child: ApproachCard(
                                  icon: Icons.rocket_launch_outlined,
                                  accent: true,
                                  title: 'Create New Project',
                                  subtitle:
                                      'Generate a production-ready Flutter architecture from scratch.',
                                  button: 'Start Journey',
                                  onTap: () =>
                                      ref.read(currentStepProvider.notifier).startNewProject(),
                                ),
                              ),

                              Expanded(
                                child: ApproachCard(
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
                        48.gapH,
                        Row(
                          spacing: 8,
                          children: [
                            const Icon(Icons.history, size: 18, color: Palette.colorPrimaryCyan),
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
                        16.gapH,
                        switch (recents) {
                          AsyncData(:final value) when value.isEmpty => const _EmptyRecents(),
                          AsyncData(:final value) => Column(
                            children: [
                              for (final p in value)
                                Padding(
                                  padding: const .only(bottom: 10),
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
                          _ => Center(child: CircularProgressIndicator()).paddedAll(24),
                        },
                        24.gapH,
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
      spacing: 12,
      children: [
        RichText(
          text: TextSpan(
            style: context.textTheme.displayMedium!.copyWith(color: context.neatColors.surface),
            children: [
              TextSpan(text: 'Welcome to '),
              TextSpan(
                text: 'NEAT',
                style: TextStyle(color: context.neatColors.colorPrimaryCyan),
              ),
            ],
          ),
        ),
        Text(
          'The high-performance architect for Flutter applications.\nStart fresh or resume your current build.',
          textAlign: TextAlign.center,
          style: context.textTheme.bodyLarge,
        ),
      ],
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
      borderRadius: .circular(10),
      child: Container(
        padding: const .symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: context.neatColors.colorSurfaceCard,
          borderRadius: .circular(10),
          border: .all(color: context.neatColors.surface10),
        ),
        child: Row(
          spacing: 12,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: context.neatColors.surface.withValues(alpha: 0.04),
                borderRadius: .circular(8),
              ),
              child: const Icon(Icons.terminal, size: 18, color: Colors.white60),
            ),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.name,
                    style: context.textTheme.titleMedium!.copyWith(
                      color: context.neatColors.surface,
                    ),
                  ),
                  2.gapH,
                  Text(
                    project.path,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.titleSmall,
                  ),
                ],
              ),
            ),

            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('LAST OPENED', style: context.textTheme.bodySmall!),
                2.gapH,
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
      width: .infinity,
      padding: const .symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: context.neatColors.colorSurfaceCard,
        borderRadius: .circular(10),
        border: .all(color: Colors.white10),
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
