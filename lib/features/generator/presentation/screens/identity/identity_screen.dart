import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../providers/flutter_sdk_versions_provider.dart';
import '../../providers/identity_provider.dart';
import '../../providers/stepper_provider.dart';

class IdentityScreen extends HookConsumerWidget {
  const IdentityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(identityProvider.notifier);

    final initialState = useMemoized(() => ref.read(identityProvider));

    final nameController = useTextEditingController(text: initialState.name);
    final orgController = useTextEditingController(text: initialState.organization);
    final pathController = useTextEditingController(text: initialState.projectPath);

    final targetPlatforms = ref.watch(identityProvider.select((s) => s.targetPlatforms));
    final flutterVersion = ref.watch(identityProvider.select((s) => s.flutterVersion));
    final projectPath = ref.watch(identityProvider.select((s) => s.projectPath));
    final isNextEnabled = ref.watch(
      identityProvider.select((s) => s.name.isNotEmpty && s.projectPath.isNotEmpty),
    );

    useEffect(() {
      pathController.text = projectPath;
      return null;
    }, [projectPath]);

    return Column(
      crossAxisAlignment: .start,
      children: [
        const Text(
          'Project Identity',
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 8),
        Text(
          'Configure core parameters of your application. These parameters dictate the base scaffolding.',
          style: TextStyle(color: Colors.grey[400], fontSize: 14),
        ),
        const SizedBox(height: 40),

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
                      _buildSectionTitle("General Details & Name"),
                      const SizedBox(height: 16),

                      const Text(
                        'PROJECT NAME',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: nameController,
                        onChanged: notifier.updateName, // Pousse directement dans le provider
                        decoration: const InputDecoration(hintText: 'e.g., nexus_core_app'),
                      ),

                      const SizedBox(height: 24),

                      const Text(
                        'ORGANIZATION',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: orgController,
                        onChanged:
                            notifier.updateOrganization, // Pousse directement dans le provider
                        decoration: const InputDecoration(hintText: 'com.quantum.nexus'),
                      ),

                      const SizedBox(height: 24),

                      const Text(
                        'PROJECT LOCATION',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: pathController,
                              readOnly: true,
                              decoration: const InputDecoration(
                                hintText: 'Select destination folder...',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
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

              const SizedBox(width: 60),

              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle("Target Platforms"),
                    const SizedBox(height: 16),

                    _buildPlatformCheckbox("Android", "android", targetPlatforms, notifier),
                    _buildPlatformCheckbox("iOS", "ios", targetPlatforms, notifier),
                    _buildPlatformCheckbox("Web", "web", targetPlatforms, notifier),
                    _buildPlatformCheckbox(
                      "macOS / Windows / Linux (Desktop)",
                      "desktop",
                      targetPlatforms,
                      notifier,
                    ),

                    const SizedBox(height: 40),

                    _buildSectionTitle("Environment Setup"),
                    const SizedBox(height: 16),
                    const Text(
                      "FLUTTER SDK VERSION",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),

                    _FlutterVersionDropdown(
                      selectedVersion: flutterVersion,
                      onChanged: notifier.updateFlutterVersion,
                    ),

                    const Spacer(),

                    Align(
                      alignment: Alignment.bottomRight,
                      child: SizedBox(
                        height: 48,
                        width: 160,
                        child: ElevatedButton(
                          onPressed: isNextEnabled
                              ? () => ref
                                    .read(currentStepProvider.notifier)
                                    .setStep(NeatStep.dependencies)
                              : null,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("Next Step"),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward, size: 16),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
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
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildPlatformCheckbox(
    String label,
    String key,
    List<String> targetPlatforms,
    IdentityNotifier notifier,
  ) {
    final isChecked = targetPlatforms.contains(key);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        onTap: () => notifier.togglePlatform(key),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF141416),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isChecked ? AppTheme.colorPrimaryCyan : Colors.white10),
          ),
          child: Row(
            children: [
              Icon(
                isChecked ? Icons.check_box : Icons.check_box_outline_blank,
                color: isChecked ? AppTheme.colorPrimaryCyan : Colors.grey,
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isChecked ? Colors.white : Colors.grey[400],
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
      AsyncData(:final value) => _buildDropdown(value),
      AsyncError() => const SizedBox(
          height: 48,
          child: Center(
            child: Text(
              'Impossible de charger les versions',
              style: TextStyle(color: Colors.redAccent, fontSize: 13),
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

  Widget _buildDropdown(List<String> versions) {
    final effectiveValue = versions.contains(selectedVersion) ? selectedVersion : versions.first;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: effectiveValue,
          dropdownColor: AppTheme.colorSurfaceCard,
          isExpanded: true,
          items: versions
              .map((v) => DropdownMenuItem(
                    value: v,
                    child: Text(v, style: const TextStyle(color: Colors.white)),
                  ))
              .toList(),
          onChanged: (val) {
            if (val != null) onChanged(val);
          },
        ),
      ),
    );
  }
}
