import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:neat/features/identity/domain/models/identity_state.dart';
import 'package:neat/features/identity/presentation/providers/flutter_sdk_versions_provider.dart';
import 'package:neat/features/identity/presentation/providers/identity_provider.dart';
import 'package:neat_ui/neat_ui.dart';

class IdentityScreen extends HookConsumerWidget {
  const IdentityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(identityProvider.notifier);

    final initialState = useMemoized(() => ref.read(identityProvider));

    final nameController = useTextEditingController(text: initialState.name);
    final orgController = useTextEditingController(text: initialState.organization);
    final pathController = useTextEditingController(text: initialState.projectPath);
    final descriptionController = useTextEditingController(text: initialState.description);

    final targetPlatforms = ref.watch(identityProvider.select((s) => s.targetPlatforms));
    final flutterVersion = ref.watch(identityProvider.select((s) => s.flutterVersion));
    final projectPath = ref.watch(identityProvider.select((s) => s.projectPath));
    final state = ref.watch(identityProvider);
    useEffect(() {
      pathController.text = projectPath;
      return null;
    }, [projectPath]);

    return Column(
      crossAxisAlignment: .start,
      children: [
        Text('Project Identity', style: context.textTheme.headlineLarge),
        8.gapH,
        Text(
          'Configure core parameters of your application. These parameters dictate the base scaffolding.',
          style: context.textTheme.bodyLarge,
        ),
        40.gapH,

        Expanded(
          child: Row(
            crossAxisAlignment: .start,
            children: [
              Expanded(
                flex: 6,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: .start,
                    children: [
                      SectionHeader(label: 'General Name & Details'),
                      16.gapH,

                      const FieldLabel('PROJECT NAME'),
                      8.gapH,
                      NeatTextField(
                        controller: nameController,
                        onChanged: notifier.updateName,
                        decoration: InputDecoration(
                          hintText: 'e.g., neat_core_app',
                          errorText: state.validateProjectName(),
                        ),
                      ),

                      24.gapH,

                      const FieldLabel('PROJECT DESCRIPTION'),
                      8.gapH,
                      NeatTextField(
                        controller: descriptionController,
                        onChanged: notifier.updateDescription,
                        decoration: const InputDecoration(hintText: 'my flutter app description'),
                      ),

                      24.gapH,

                      const FieldLabel('ORGANIZATION'),
                      8.gapH,
                      NeatTextField(
                        controller: orgController,
                        onChanged: notifier.updateOrganization,
                        decoration: InputDecoration(
                          hintText: 'com.quantum.neat',
                          errorText: state.validateOrganization(),
                        ),
                      ),

                      24.gapH,

                      const FieldLabel('PROJECT LOCATION'),
                      8.gapH,
                      Row(
                        children: [
                          Expanded(
                            child: NeatTextField(
                              controller: pathController,
                              readOnly: true,
                              decoration: const InputDecoration(
                                hintText: 'Select destination folder...',
                              ),
                            ),
                          ),
                          12.gapW,
                          SizedBox(
                            height: 46,
                            child: OutlinedButton.icon(
                              onPressed: notifier.pickDirectory,
                              icon: const Icon(Icons.folder_open, size: 18),
                              label: const Text('Browse'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              60.gapW,

              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionHeader(label: 'Target Platforms'),
                    16.gapH,

                    _buildPlatformCheckbox(
                      context,
                      'Android',
                      'android',
                      targetPlatforms,
                      notifier,
                    ),
                    _buildPlatformCheckbox(context, 'iOS', 'ios', targetPlatforms, notifier),
                    _buildPlatformCheckbox(context, 'Web', 'web', targetPlatforms, notifier),
                    _buildPlatformCheckbox(
                      context,
                      'macOS / Windows / Linux (Desktop)',
                      'desktop',
                      targetPlatforms,
                      notifier,
                    ),

                    40.gapH,

                    Row(
                      children: [
                        SectionHeader(label: 'Environment Setup'),
                        12.gapW,
                        Tooltip(
                          message: 'Generates .fvmrc to sync Flutter SDK version across your team',
                          child: Icon(Icons.info_outline),
                        ),
                      ],
                    ),
                    16.gapH,
                    const FieldLabel('FLUTTER SDK VERSION'),
                    8.gapH,

                    _FlutterVersionDropdown(
                      selectedVersion: flutterVersion,
                      onChanged: notifier.updateFlutterVersion,
                    ),

                    const Spacer(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlatformCheckbox(
    BuildContext context,
    String label,
    String key,
    List<String> targetPlatforms,
    IdentityNotifier notifier,
  ) {
    final isChecked = targetPlatforms.contains(key);
    final accent = context.neatColors.colorPrimaryCyan;
    return Padding(
      padding: const .symmetric(vertical: 6),
      child: InkWell(
        onTap: () => notifier.togglePlatform(key),
        borderRadius: .circular(8),
        child: Container(
          padding: const .symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: context.neatColors.dark,
            borderRadius: .circular(8),
            border: .all(color: isChecked ? accent : context.neatColors.surface10),
          ),
          child: Row(
            spacing: 12,
            children: [
              Icon(
                isChecked ? Icons.check_box : Icons.check_box_outline_blank,
                color: isChecked ? accent : Colors.grey,
              ),
              Flexible(
                child: Text(
                  label,
                  style: context.textTheme.bodyLarge!.copyWith(
                    color: isChecked ? context.neatColors.surface : Colors.grey[400],
                    fontWeight: isChecked ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FlutterVersionDropdown extends ConsumerWidget {
  const _FlutterVersionDropdown({required this.selectedVersion, required this.onChanged});

  final String selectedVersion;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final versionsAsync = ref.watch(flutterSdkVersionsProvider);

    return switch (versionsAsync) {
      AsyncData(:final value) => _buildDropdown(context, value),
      AsyncError() => SizedBox(
        height: 48,
        child: Center(
          child: Text(
            'Impossible de charger les versions',
            style: context.textTheme.bodyMedium!.copyWith(color: context.neatColors.errorColor),
          ),
        ),
      ),
      _ => const SizedBox(
        height: 48,
        child: Center(
          child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      ),
    };
  }

  Widget _buildDropdown(BuildContext context, List<String> versions) {
    final effectiveValue = versions.contains(selectedVersion) ? selectedVersion : versions.first;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: context.neatColors.mainDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.neatColors.surface10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: effectiveValue,
          dropdownColor: context.neatColors.colorSurfaceCard,
          isExpanded: true,
          items: versions
              .map(
                (v) => DropdownMenuItem(
                  value: v,
                  child: Text(
                    v,
                    style: context.textTheme.bodyLarge!.copyWith(color: context.neatColors.surface),
                  ),
                ),
              )
              .toList(),
          onChanged: (val) {
            if (val != null) onChanged(val);
          },
        ),
      ),
    );
  }
}
