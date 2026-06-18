import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:neat/core/theme/app_theme.dart';
import 'package:neat/features/architecture/domain/models/architecture_state.dart';
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
    final hasGoRouter = ref.watch(
      selectedPackagesProvider.select((list) => list.any((p) => p.name.contains('go_router'))),
    );
    // Auth requires the typed router (a provider GoRouter) + the Supabase backend.
    final hasGoRouterBuilder = ref.watch(
      selectedPackagesProvider.select((list) => list.any((p) => p.name == 'go_router_builder')),
    );
    final hasSupabase = ref.watch(
      selectedPackagesProvider.select((list) => list.any((p) => p.name == 'supabase_flutter')),
    );
    final hasFirebase = ref.watch(
      selectedPackagesProvider.select((list) => list.any((p) => p.name == 'cloud_firestore')),
    );
    // A single backend drives the opt-ins; Firebase takes precedence if both.
    final hasBackend = hasSupabase || hasFirebase;
    final backendLabel = hasFirebase ? 'Firebase' : 'Supabase';
    final canAuth = hasBackend && hasGoRouterBuilder;
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
                                // Not yet validated by the generation harness.
                                disabled: true,
                                onTap: () {},
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
                              'Génère `@riverpod class MyNotifier extends _\$MyNotifier`. Le mode manuel NotifierProvider arrive bientôt — verrouillé sur generator.',
                          value: true,
                          // Locked ON: the manual NotifierProvider path isn't validated yet.
                          disabled: true,
                          onChanged: (_) {},
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
                        icon: Icons.cloud_off_outlined,
                        label: 'Storage Strategy',
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<StorageStrategy>(
                          segments: const [
                            ButtonSegment(
                              value: StorageStrategy.remoteOnly,
                              label: Text('Remote Only'),
                              icon: Icon(Icons.cloud_outlined),
                            ),
                            ButtonSegment(
                              value: StorageStrategy.offlineFirstRead,
                              label: Text('Offline-First'),
                              icon: Icon(Icons.sd_storage_outlined),
                            ),
                            ButtonSegment(
                              value: StorageStrategy.offlineFirstSync,
                              label: Text('Offline + Sync'),
                              icon: Icon(Icons.sync_outlined),
                            ),
                          ],
                          selected: {state.storageStrategy},
                          onSelectionChanged: (s) => notifier.setStorageStrategy(s.first),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        switch (state.storageStrategy) {
                          StorageStrategy.remoteOnly =>
                            'Source distante uniquement (Dio/Retrofit standard).',
                          StorageStrategy.offlineFirstRead =>
                            'Workspace + package Drift `_local_storage` : lecture local-first avec fallback cache.',
                          StorageStrategy.offlineFirstSync =>
                            'Tout le mode lecture + Outbox : les écritures hors ligne sont mises en file et rejouées par un SyncService au retour du réseau.',
                        },
                        style: Theme.of(context).textTheme.bodySmall,
                      ),

                      if (hasGoRouter) ...[
                        const SizedBox(height: 28),
                        _SectionHeader(
                          icon: Icons.space_dashboard_outlined,
                          label: 'Navigation',
                        ),
                        const SizedBox(height: 12),
                        _ToggleTile(
                          title: 'Bottom navigation shell',
                          description:
                              'L\'app démarre dans un StatefulShellRoute : la 1ʳᵉ feature devient le 1er onglet d\'une NavigationBar. Les Shell Branch ajoutées ensuite deviennent des onglets.',
                          value: state.useNavigationShell,
                          onChanged: notifier.toggleNavigationShell,
                        ),
                        if (state.useNavigationShell) ...[
                          const SizedBox(height: 12),
                          _ShellTabConfig(
                            icon: state.shellIcon,
                            labelHint: state.effectiveShellLabel,
                            onIcon: notifier.setShellIcon,
                            onLabel: notifier.setShellLabel,
                          ),
                        ],
                        if (canAuth) ...[
                          const SizedBox(height: 12),
                          _ToggleTile(
                            title: 'Generate Auth ($backendLabel)',
                            description:
                                'Feature auth complète : écrans login/signup/forgot, AuthController, '
                                'et un guard go_router (redirect → /login si non connecté).',
                            value: state.generateAuth,
                            onChanged: notifier.toggleGenerateAuth,
                          ),
                          if (state.generateAuth && hasFirebase) ...[
                            const SizedBox(height: 12),
                            _ToggleTile(
                              title: 'OAuth (Google + Apple)',
                              description:
                                  'Boutons Google/Apple sur l\'écran login via '
                                  '`signInWithProvider` (aucune dépendance en plus). Active les '
                                  'providers dans la console Firebase.',
                              value: state.generateOAuth,
                              onChanged: notifier.toggleGenerateOAuth,
                            ),
                          ],
                        ],
                      ],

                      if (hasBackend && hasRiverpod) ...[
                        const SizedBox(height: 28),
                        _SectionHeader(
                          icon: Icons.cloud_outlined,
                          label: 'Backend ($backendLabel)',
                        ),
                        const SizedBox(height: 12),
                        if (hasFirebase) ...[
                          _FirebaseConfigCard(
                            configPath: state.firebaseConfigPath,
                            onPick: () async {
                              final result = await FilePicker.pickFiles(
                                type: FileType.custom,
                                allowedExtensions: const ['json'],
                              );
                              final path = result?.files.single.path;
                              if (path != null) notifier.setFirebaseConfigPath(path);
                            },
                            onRemove: () => notifier.setFirebaseConfigPath(''),
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (state.useRiverpodAnnotations)
                          _ToggleTile(
                            title: 'Realtime list',
                            description: hasFirebase
                                ? 'La liste de la 1ʳᵉ feature devient live : un StreamNotifier '
                                    's\'abonne aux `.snapshots()` Firestore.'
                                : 'La liste de la 1ʳᵉ feature devient live : un StreamNotifier '
                                    's\'abonne à Supabase `.stream()` et l\'écran se met à jour à '
                                    'chaque INSERT/UPDATE/DELETE.',
                            value: state.generateRealtime,
                            onChanged: notifier.toggleGenerateRealtime,
                          ),
                        if (state.useRiverpodAnnotations) const SizedBox(height: 12),
                        _ToggleTile(
                          title: 'Storage',
                          description:
                              'StorageService (upload/download/remove) + provider + un widget '
                              'exemple d\'upload d\'avatar (image_picker).',
                          value: state.generateStorage,
                          onChanged: notifier.toggleGenerateStorage,
                        ),
                      ],

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
    this.disabled = false,
  });

  final String title;
  final String description;
  final bool isSelected;
  final bool isRecommended;
  final VoidCallback onTap;

  /// Visible but not selectable (feature not yet validated).
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final card = GestureDetector(
      onTap: disabled ? null : onTap,
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
            if (isRecommended || disabled) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: disabled
                        ? Colors.white24
                        : AppTheme.colorPrimaryCyan.withValues(alpha: 0.5),
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  disabled ? 'COMING SOON' : 'RECOMMENDED',
                  style: TextStyle(
                    color: disabled ? Colors.white38 : AppTheme.colorPrimaryCyan,
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

    return disabled ? Opacity(opacity: 0.45, child: card) : card;
  }
}

// ── Toggle tile ───────────────────────────────────────────────────────────────

class _ToggleTile extends StatelessWidget {
  const _ToggleTile({
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
    this.disabled = false,
  });

  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  /// Locked: shown but not toggleable (feature pinned / not yet validated).
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: disabled ? 0.55 : 1,
      child: Container(
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
            onTap: disabled ? null : () => onChanged(!value),
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
      ),
    );
  }
}

// ── Firebase config upload ─────────────────────────────────────────────────────

/// Upload the Firebase config JSON → NEAT generates `firebase_options.dart`.
class _FirebaseConfigCard extends StatelessWidget {
  const _FirebaseConfigCard({
    required this.configPath,
    required this.onPick,
    required this.onRemove,
  });

  final String configPath;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final hasFile = configPath.isNotEmpty;
    final fileName = hasFile ? configPath.split(Platform.pathSeparator).last : null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF18181C),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Icon(
            hasFile ? Icons.check_circle_outline : Icons.upload_file_outlined,
            color: hasFile ? AppTheme.colorPrimaryCyan : Colors.grey[500],
            size: 20,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Firebase config (JSON)',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  fileName ??
                      'Optionnel : la web app config (apiKey, projectId…). Sans fichier, des '
                          'placeholders compilables sont générés.',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (hasFile)
            IconButton(
              icon: const Icon(Icons.close, size: 18, color: Colors.white54),
              onPressed: onRemove,
              tooltip: 'Retirer',
            ),
          OutlinedButton(
            onPressed: onPick,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.colorPrimaryCyan,
              side: BorderSide(color: AppTheme.colorPrimaryCyan.withValues(alpha: 0.5)),
            ),
            child: Text(hasFile ? 'Changer' : 'Upload'),
          ),
        ],
      ),
    );
  }
}

// ── Shell first-tab config (icon + label) ──────────────────────────────────────

/// Curated Material icons (kept so the generated `Icon(Icons.<name>)` compiles).
const _shellIcons = <String, IconData>{
  'home': Icons.home, 'dashboard': Icons.dashboard, 'person': Icons.person,
  'settings': Icons.settings, 'search': Icons.search, 'favorite': Icons.favorite,
  'notifications': Icons.notifications, 'list': Icons.list,
  'shopping_cart': Icons.shopping_cart, 'explore': Icons.explore,
  'calendar_today': Icons.calendar_today, 'chat': Icons.chat, 'map': Icons.map,
  'star': Icons.star, 'folder': Icons.folder, 'account_circle': Icons.account_circle,
};

class _ShellTabConfig extends StatefulWidget {
  const _ShellTabConfig({
    required this.icon,
    required this.labelHint,
    required this.onIcon,
    required this.onLabel,
  });

  final String icon;
  final String labelHint;
  final ValueChanged<String> onIcon;
  final ValueChanged<String> onLabel;

  @override
  State<_ShellTabConfig> createState() => _ShellTabConfigState();
}

class _ShellTabConfigState extends State<_ShellTabConfig> {
  final _labelCtrl = TextEditingController();

  @override
  void dispose() {
    _labelCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final icon = _shellIcons.containsKey(widget.icon) ? widget.icon : 'home';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 160,
          child: InputDecorator(
            decoration: const InputDecoration(labelText: 'First tab icon'),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: icon,
                isExpanded: true,
                dropdownColor: const Color(0xFF18181C),
                style: const TextStyle(color: Colors.white, fontSize: 13),
                onChanged: (v) => widget.onIcon(v ?? 'home'),
                items: _shellIcons.entries
                    .map((e) => DropdownMenuItem(
                          value: e.key,
                          child: Row(
                            children: [
                              Icon(e.value, size: 16, color: AppTheme.colorPrimaryCyan),
                              const SizedBox(width: 8),
                              Expanded(child: Text(e.key, overflow: TextOverflow.ellipsis)),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: _labelCtrl,
            onChanged: widget.onLabel,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              labelText: 'First tab label',
              hintText: widget.labelHint.isEmpty ? 'e.g. Home' : widget.labelHint,
            ),
          ),
        ),
      ],
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
