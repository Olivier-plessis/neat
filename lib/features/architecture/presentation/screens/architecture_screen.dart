import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:neat/features/architecture/domain/models/architecture_state.dart';
import 'package:neat/features/architecture/domain/usecases/generate_tree_usecase.dart';
import 'package:neat/features/architecture/presentation/providers/architecture_provider.dart';
import 'package:neat/features/dependencies/presentation/providers/dependencies_provider.dart';
import 'package:neat_ui/neat_ui.dart';

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
    // v1 scope: the "seen it" flag is a Riverpod provider (see
    // OnboardingTemplates) — same annotations requirement as Realtime/Storage.
    final canOnboarding = hasRiverpod && state.useRiverpodAnnotations;
    final hasDio = ref.watch(
      selectedPackagesProvider.select((list) => list.any((p) => p.name == 'dio')),
    );
    final hasChopper = ref.watch(
      selectedPackagesProvider.select((list) => list.any((p) => p.name == 'chopper')),
    );
    // packageSplit combo (see ROADMAP.md §6a): dio/chopper/supabase/firebase,
    // any storage strategy (remote-only, offline-first read, or offline-first
    // + sync/Outbox), Riverpod annotations, manual or typed (go_router_builder)
    // routing. A first feature is *not* required — packageSplitSupported
    // (launch_generation_usecase.dart) never checked for one, and an
    // integration test now proves the shared core package generates cleanly
    // with zero feature packages, with the Workshop adding the real first
    // feature as its own split package afterwards (previously the only way
    // to get packageSplit at all, since it can't be turned on retroactively
    // on an existing project). Auth/realtime/storage all work too (Auth
    // stays app-level even when split — see AuthTemplates). Mirrors
    // launch_generation_usecase.dart's packageSplitSupported — the generator
    // re-derives this independently rather than trusting the raw flag, so
    // keeping the toggle disabled outside this combo is a UX courtesy, not
    // the only safety net.
    final canPackageSplit =
        hasRiverpod &&
        state.useRiverpodAnnotations &&
        hasGoRouter &&
        (hasDio || hasChopper || hasBackend);
    final tree = const GenerateTreeUsecase().execute(
      state,
      hasRiverpod: hasRiverpod,
      hasBloc: hasBloc,
      packageSplit: canPackageSplit && state.packageSplit,
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
                      SectionHeader(icon: Icons.bookmark_added_outlined, label: 'First Feature'),
                      const SizedBox(height: 12),
                      ToggleTile(
                        title: 'Generate example feature',
                        description: (hasRiverpod && !state.useRiverpodAnnotations) || hasBloc
                            ? 'FakeStore Products — with ${hasBloc ? (state.useCubit ? 'Cubit' : 'Bloc') : 'manual NotifierProvider'} '
                                  '(no @riverpod annotations) this is a placeholder page + '
                                  '${hasBloc ? (state.useCubit ? 'Cubit' : 'Bloc') : 'Notifier'} stub, not the '
                                  'full-CRUD example: the usecase-level DI graph is annotation-only. '
                                  'Off → the app ships with zero features either way.'
                            : 'FakeStore Products: a full-CRUD worked example against a public '
                                  'API, so a fresh project runs and shows real data. Off → the app '
                                  'ships with zero features (a placeholder welcome screen). Add your '
                                  'own entity later from the Workshop.',
                        value: state.generateFirstFeature,
                        onChanged: notifier.setGenerateFirstFeature,
                      ),
                      if (state.generateFirstFeature) ...[
                        const SizedBox(height: 12),
                        _FeatureNameField(
                          initialValue: state.firstFeatureName,
                          errorText: state.validateFirstFeatureName(),
                          onChanged: notifier.setFirstFeatureName,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          canPackageSplit && state.packageSplit
                              ? 'Generated at packages/${state.firstFeatureName.isEmpty ? '...' : state.firstFeatureName}/'
                              : 'Generated at lib/features/${state.firstFeatureName.isEmpty ? '...' : state.firstFeatureName}/',
                          style: TextStyle(
                            color: Palette.colorPrimaryCyan.withValues(alpha: 0.7),
                            fontSize: 11,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                      const SizedBox(height: 28),

                      SectionHeader(icon: Icons.view_quilt_outlined, label: 'Structural Pattern'),
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
                      SectionHeader(
                        icon: Icons.layers_outlined,
                        label: 'Clean Architecture Layers',
                      ),
                      const SizedBox(height: 12),
                      ToggleTile(
                        title: 'Include Data Mappers',
                        description: 'Generate dedicated DTO to Domain Entity mappers.',
                        value: state.includeMappers,
                        onChanged: notifier.toggleMappers,
                      ),

                      const SizedBox(height: 28),
                      SectionHeader(icon: Icons.cloud_off_outlined, label: 'Storage Strategy'),
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
                      Text(switch (state.storageStrategy) {
                        StorageStrategy.remoteOnly =>
                          'Source distante uniquement (Dio/Chopper standard).',
                        StorageStrategy.offlineFirstRead =>
                          'Workspace + package Drift `_local_storage` : lecture local-first avec fallback cache.',
                        StorageStrategy.offlineFirstSync =>
                          'Tout le mode lecture + Outbox : les écritures hors ligne sont mises en file et rejouées par un SyncService au retour du réseau.',
                      }, style: Theme.of(context).textTheme.bodySmall),

                      const SizedBox(height: 28),
                      SectionHeader(icon: Icons.dns_outlined, label: 'Modular Monorepo'),
                      const SizedBox(height: 12),
                      ToggleTile(
                        title: 'Split first feature into its own package',
                        description: canPackageSplit
                            ? (state.generateFirstFeature
                                  ? 'Team workflow: the first feature moves into its own workspace '
                                        'package (packages/'
                                        '${state.firstFeatureName.isEmpty ? '<feature>' : state.firstFeatureName}/), '
                                        'depending only on a shared core package (Result/Failure/'
                                        'UseCase/networking) — never on the app itself, so multiple devs '
                                        'can own separate features without touching a shared lib/.'
                                  : 'Team workflow: the shared core package (Result/Failure/'
                                        'UseCase/networking) is generated with zero feature packages — '
                                        'add your first one later from the Workshop, already split into '
                                        'its own packages/<feature>/, depending only on core.')
                            : 'Requires: dio/chopper/Supabase/Firebase, and Riverpod with '
                                  '@riverpod annotations — not yet available for manual Notifier or '
                                  'Bloc/Cubit projects. See ROADMAP.md §6a.',
                        value: canPackageSplit && state.packageSplit,
                        disabled: !canPackageSplit,
                        onChanged: notifier.togglePackageSplit,
                      ),

                      if (hasGoRouter) ...[
                        // The bottom-navigation-shell toggle (+ its
                        // _ShellTabConfig) moved to Infrastructure > Navigation
                        // — it's a navigation-engine concern, not an
                        // architecture-layer one. This section now only
                        // covers backend-driven auth, which still needs
                        // go_router (its guard) to make sense.
                        if (canAuth) ...[
                          const SizedBox(height: 28),
                          SectionHeader(icon: Icons.space_dashboard_outlined, label: 'Navigation'),
                          const SizedBox(height: 12),
                          ToggleTile(
                            title: 'Generate Auth ($backendLabel)',
                            description:
                                'Feature auth complète : écrans login/signup/forgot, AuthController, '
                                'et un guard go_router (redirect → /login si non connecté).',
                            value: state.generateAuth,
                            onChanged: notifier.toggleGenerateAuth,
                          ),
                          if (state.generateAuth && hasFirebase) ...[
                            const SizedBox(height: 12),
                            ToggleTile(
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
                        SectionHeader(icon: Icons.cloud_outlined, label: 'Backend ($backendLabel)'),
                        const SizedBox(height: 12),
                        // Backend credentials (URLs / keys / Firebase config) live
                        // on the Dependencies screen now.
                        if (state.useRiverpodAnnotations)
                          ToggleTile(
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
                        ToggleTile(
                          title: 'Storage',
                          description:
                              'StorageService (upload/download/remove) + provider + un widget '
                              'exemple d\'upload d\'avatar (image_picker).',
                          value: state.generateStorage,
                          onChanged: notifier.toggleGenerateStorage,
                        ),
                      ],

                      // Internationalization moved to Infrastructure >
                      // Localization — it's a "which providers/languages does
                      // this app ship with" decision, same family as
                      // Backend/Navigation provider, not an architecture-layer
                      // concern.
                      const SizedBox(height: 28),
                      SectionHeader(icon: Icons.bug_report_outlined, label: 'Testing Architecture'),
                      const SizedBox(height: 12),
                      ToggleTile(
                        title: 'Mirror Structure in /test',
                        description:
                            'Automatically create matching directory structures for unit and widget tests.',
                        value: state.mirrorTestStructure,
                        onChanged: notifier.toggleMirrorTest,
                      ),

                      const SizedBox(height: 28),
                      SectionHeader(icon: Icons.flag_outlined, label: 'Onboarding'),
                      const SizedBox(height: 12),
                      ToggleTile(
                        title: 'First-launch onboarding flow',
                        description: canOnboarding
                            ? 'A content-free PageView skeleton (a few slides + Skip/Next) shown '
                                  'once, then never again — write your own slide content. NEAT '
                                  'does not wire it into your router (it depends on your '
                                  'navigation shell/auth setup) — the generated OnboardingPage '
                                  'has a doc comment showing exactly how.'
                            : 'Requires Riverpod with @riverpod annotations — the persisted '
                                  '"seen it" flag is a Riverpod provider.',
                        value: canOnboarding && state.generateOnboarding,
                        disabled: !canOnboarding,
                        onChanged: notifier.toggleGenerateOnboarding,
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
                          color: Palette.colorPrimaryCyan,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'FOLDER STRUCTURE PREVIEW',
                          style: TextStyle(
                            color: Palette.colorPrimaryCyan,
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
  void didUpdateWidget(_FeatureNameField old) {
    super.didUpdateWidget(old);
    // Re-seed only on external changes (a preset switch), never while the
    // user types (then the value already matches).
    if (widget.initialValue != _ctrl.text) _ctrl.text = widget.initialValue;
  }

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
            color: isSelected ? Palette.colorPrimaryCyan : Colors.white10,
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
                  color: isSelected ? Palette.colorPrimaryCyan : Colors.grey[600],
                  size: 22,
                ),
                const Spacer(),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? Palette.colorPrimaryCyan : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? Palette.colorPrimaryCyan : Colors.white24,
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
                color: isSelected ? Palette.colorPrimaryCyan : Colors.white,
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
                        : Palette.colorPrimaryCyan.withValues(alpha: 0.5),
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  disabled ? 'COMING SOON' : 'RECOMMENDED',
                  style: TextStyle(
                    color: disabled ? Colors.white38 : Palette.colorPrimaryCyan,
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
