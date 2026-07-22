import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:neat/features/architecture/domain/models/env_config.dart';
import 'package:neat/features/architecture/presentation/providers/architecture_provider.dart';
import 'package:neat/features/dependencies/domain/constants/backend_presets.dart';
import 'package:neat/features/dependencies/domain/models/pub_package.dart';
import 'package:neat/features/dependencies/presentation/providers/dependencies_provider.dart';
import 'package:neat/features/identity/presentation/providers/identity_provider.dart';
import 'package:neat/features/infrastructure/presentation/providers/infrastructure_tab_provider.dart';
import 'package:neat_ui/neat_ui.dart';

class InfrastructureScreen extends ConsumerWidget {
  const InfrastructureScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(currentInfrastructureTabProvider);
    final title = switch (tab) {
      InfrastructureTab.management => 'State management',
      InfrastructureTab.backend => 'Project Infrastructure',
      InfrastructureTab.navigation => 'Navigation',
      InfrastructureTab.localization => 'Localization',
    };
    final subtitle = switch (tab) {
      InfrastructureTab.management => 'Choose a state management system.',
      InfrastructureTab.backend =>
        'Pick a backend to seed your stack — its preset packages appear on the right.',
      InfrastructureTab.navigation =>
        'Pick a navigation engine and how routes are declared.',
      InfrastructureTab.localization =>
        'Pick which languages your app ships with.',
    };
    return ScreenForScaffold(
      title: title,
      subtitle: subtitle,
      child: Row(
        crossAxisAlignment: .start,
        spacing: 26,
        children: [
          Expanded(
            flex: 6,
            child: switch (tab) {
              InfrastructureTab.management => const _ManagementTab(),
              InfrastructureTab.backend => const _BackendTab(),
              InfrastructureTab.navigation => const _NavigationTab(),
              InfrastructureTab.localization => const _LocalizationTab(),
            },
          ),
          const Expanded(flex: 4, child: _ManagedPackagesPanel()),
        ],
      ),
    );
  }
}

class _ManagementTab extends ConsumerWidget {
  const _ManagementTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBloc =
        ref.watch(selectedPackagesProvider.select(stateManagementOf)) ==
        StateManagementKind.bloc;
    final isRiverpod =
        ref.watch(selectedPackagesProvider.select(stateManagementOf)) ==
        StateManagementKind.riverpod;

    final architecture = ref.watch(architectureProvider);
    final architectureNotifier = ref.read(architectureProvider.notifier);

    return Column(
      crossAxisAlignment: .start,
      children: [
        const _SectionLabel('State management', icon: Icons.hub_outlined),
        12.gapH,
        const _StateManagementSelector(),
        if (isRiverpod) ...[
          16.gapH,
          ToggleTile(
            title: 'Use @riverpod annotation syntax',
            description: architecture.useRiverpodAnnotations
                ? 'Génère `@riverpod class MyNotifier extends _\$MyNotifier` (code-gen via build_runner).'
                : 'Génère `class MyNotifier extends Notifier<T>` + `NotifierProvider` à la main — pas de build_runner pour l\'état, mais pas de liste/CRUD witness (voir ROADMAP.md).',
            value: architecture.useRiverpodAnnotations,
            onChanged: architectureNotifier.toggleRiverpodAnnotations,
          ),
        ],

        if (isBloc) ...[
          16.gapH,
          ToggleTile(
            title: 'Use Cubit instead of full BLoC',
            description:
                'Génère des `Cubit<State>` (sans Events) plutôt que des `Bloc<Event, State>` complets.',
            value: architecture.useCubit,
            onChanged: architectureNotifier.toggleCubit,
          ),
        ],
      ],
    );
  }
}

// ── Backend tab ───────────────────────────────────────────────────────────────

class _BackendTab extends StatelessWidget {
  const _BackendTab();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('Backend provider', icon: Icons.dns_outlined),
        12.gapH,
        const _BackendSelector(),
        24.gapH,
        const Expanded(child: _BackendConfig()),
      ],
    );
  }
}

// ── State management selector ──────────────────────────────────────────────

class _StateManagementSelector extends ConsumerWidget {
  const _StateManagementSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(
      selectedPackagesProvider.select(stateManagementOf),
    );
    final notifier = ref.read(selectedPackagesProvider.notifier);

    void pick(StateManagementKind kind) =>
        notifier.applyStateManagementPreset(presetForStateManagement(kind));

    return Row(
      children: [
        Expanded(
          child: _BackendCard(
            icon: Icons.water_drop_outlined,
            iconColor: Palette.colorPrimaryCyan,
            title: 'Riverpod',
            subtitle: 'Annotations or manual Notifier',
            active: active == StateManagementKind.riverpod,
            onTap: () => pick(StateManagementKind.riverpod),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _BackendCard(
            icon: Icons.call_split,
            iconColor: const Color(0xFFFFA000),
            title: 'Bloc / Cubit',
            subtitle: 'Events + States, or Cubit',
            active: active == StateManagementKind.bloc,
            onTap: () => pick(StateManagementKind.bloc),
          ),
        ),
      ],
    );
  }
}

// ── Backend selector ────────────────────────────────────────────────────────

class _BackendSelector extends ConsumerWidget {
  const _BackendSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(selectedPackagesProvider.select(backendOf));
    final notifier = ref.read(selectedPackagesProvider.notifier);

    void pick(BackendKind kind) => notifier.applyBackendPreset(presetFor(kind));

    return Row(
      children: [
        Expanded(
          child: _BackendCard(
            icon: Icons.api_outlined,
            iconColor: Palette.colorPrimaryCyan,
            title: 'REST API',
            subtitle: 'HTTP client',
            active: active == BackendKind.rest,
            onTap: () => pick(BackendKind.rest),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _BackendCard(
            icon: Icons.bolt,
            iconColor: const Color(0xFF3ECF8E),
            title: 'Supabase',
            subtitle: 'Postgres & Auth',
            active: active == BackendKind.supabase,
            onTap: () => pick(BackendKind.supabase),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _BackendCard(
            icon: Icons.local_fire_department,
            iconColor: const Color(0xFFFFA000),
            title: 'Firebase',
            subtitle: 'Google Cloud Eco',
            active: active == BackendKind.firebase,
            onTap: () => pick(BackendKind.firebase),
          ),
        ),
      ],
    );
  }
}

class _BackendCard extends StatelessWidget {
  const _BackendCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.active,
    required this.onTap,
    this.disabled = false,
  }) : fontSize = 16;

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool active;
  final VoidCallback onTap;
  final double fontSize;

  /// Visible but not selectable (e.g. a navigation engine NEAT doesn't
  /// generate yet) — mirrors architecture_screen.dart's _PatternCard.
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final card = InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        decoration: BoxDecoration(
          color: const Color(0xFF131316),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active ? Palette.colorPrimaryCyan : Colors.white10,
            width: active ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 26),
            ),
            14.gapH,
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
              ),
            ),
            4.gapH,
            Text(
              subtitle,
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
            const SizedBox(height: 12),
            if (active)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(
                    Icons.check_circle,
                    color: Palette.colorPrimaryCyan,
                    size: 14,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'SELECTED',
                    style: TextStyle(
                      color: Palette.colorPrimaryCyan,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              )
            else
              Text(
                disabled ? 'COMING SOON' : 'SELECT',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
          ],
        ),
      ),
    );

    return disabled ? Opacity(opacity: 0.5, child: card) : card;
  }
}

// ── Section label ────────────────────────────────────────────────────────────

/// A small icon+label header for a sub-group within a screen — lighter than a
/// full page/section title, used to visually separate the compact option rows
/// below (HTTP client, routing style, environments) without adding wizard steps.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label, {required this.icon});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[500], size: 14),
        const SizedBox(width: 8),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}

// ── Compact option card (secondary choices: HTTP client, routing style) ──────

/// A lighter, horizontal alternative to [_BackendCard] for secondary choices
/// nested under an already-made primary decision (e.g. the HTTP client within
/// "REST API"). Keeps those rows scannable in one glance instead of repeating
/// full-size cards for every sub-choice on the screen.
class _CompactOptionCard extends StatelessWidget {
  const _CompactOptionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.active,
    required this.onTap,
    this.tooltip,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final bool active;
  final VoidCallback onTap;

  /// Extra context (e.g. what the option does) shown on hover instead of
  /// taking up permanent vertical space.
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final card = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF131316),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? Palette.colorPrimaryCyan : Colors.white10,
            width: active ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (active)
              const Icon(
                Icons.check_circle,
                color: Palette.colorPrimaryCyan,
                size: 16,
              ),
          ],
        ),
      ),
    );

    return tooltip == null ? card : Tooltip(message: tooltip!, child: card);
  }
}

// ── Backend configuration (environments + per-backend credentials) ──────────────

class _BackendConfig extends ConsumerWidget {
  const _BackendConfig();

  Future<void> _pickFirebaseConfig(WidgetRef ref) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );
    final path = result?.files.single.path;
    if (path != null) {
      ref.read(architectureProvider.notifier).setFirebaseConfigPath(path);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backend = ref.watch(selectedPackagesProvider.select(backendOf));
    final httpClient = ref.watch(selectedPackagesProvider.select(httpClientOf));
    final packagesNotifier = ref.read(selectedPackagesProvider.notifier);
    final arch = ref.watch(architectureProvider);
    final notifier = ref.read(architectureProvider.notifier);
    final platforms = ref.watch(
      identityProvider.select((s) => s.targetPlatforms),
    );
    final label = switch (backend) {
      BackendKind.rest => 'REST API',
      BackendKind.supabase => 'Supabase',
      BackendKind.firebase => 'Firebase',
    };

    final envCount = arch.environments.length;
    final canRemove = envCount > 1;
    final canAdd = envCount < ArchitectureNotifier.maxEnvironments;
    // Native flavors are a mobile-only concept (productFlavors / iOS schemes) and
    // only make sense with ≥2 environments. Web/desktop still get per-env entry
    // points — just without the native `--flavor` layer.
    final flavorsSupported = platforms.any((p) => p == 'android' || p == 'ios');
    final flavorsAvailable = flavorsSupported && envCount >= 2;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF131316),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (backend == BackendKind.rest) ...[
              const _SectionLabel('HTTP client', icon: Icons.dns_outlined),
              10.gapH,
              Row(
                spacing: 10,
                children: [
                  Expanded(
                    child: _CompactOptionCard(
                      icon: Icons.local_fire_department,
                      iconColor: const Color(0xFFFFA000),
                      title: 'Chopper',
                      active: httpClient == HttpClientKind.chopper,
                      onTap: () => packagesNotifier.applyHttpClientPreset(
                        presetForHttpClient(HttpClientKind.chopper),
                      ),
                    ),
                  ),
                  Expanded(
                    child: _CompactOptionCard(
                      icon: Icons.api_outlined,
                      iconColor: Palette.colorPrimaryCyan,
                      title: 'Dio',
                      active: httpClient == HttpClientKind.dio,
                      onTap: () => packagesNotifier.applyHttpClientPreset(
                        presetForHttpClient(HttpClientKind.dio),
                      ),
                    ),
                  ),
                ],
              ),
              20.gapH,
            ],
            _SectionLabel('Environments · $label', icon: Icons.dns_outlined),
            12.gapH,
            if (backend == BackendKind.firebase) ...[
              _FirebaseConfigUpload(
                path: arch.firebaseConfigPath,
                onPick: () => _pickFirebaseConfig(ref),
                onClear: () => notifier.setFirebaseConfigPath(''),
              ),
            ] else ...[
              for (final (i, env) in arch.environments.indexed)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  // Key by backend so switching REST↔Supabase re-seeds each
                  // field's initialValue (the row's State is otherwise reused,
                  // leaking the previous backend's text into the new fields).
                  child: _EnvFieldRow(
                    key: ValueKey('cfg_${backend.name}_$i'),
                    env: env,
                    backend: backend,
                    isBase: i == arch.baseEnvIndex,
                    onMakeBase: () => notifier.setBaseEnv(i),
                    onName: (v) => notifier.setEnvName(i, v),
                    onApiUrl: (v) => notifier.setEnvApiUrl(i, v),
                    onSupabaseUrl: (v) => notifier.setEnvSupabaseUrl(i, v),
                    onSupabaseKey: (v) => notifier.setEnvSupabaseKey(i, v),
                    onRemove: canRemove ? () => notifier.removeEnv(i) : null,
                  ),
                ),
              if (canAdd)
                TextButton.icon(
                  onPressed: notifier.addEnv,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add environment'),
                  style: TextButton.styleFrom(
                    foregroundColor: Palette.colorPrimaryCyan,
                  ),
                ),
            ],
            16.gapH,
            const Divider(color: Colors.white10, height: 1),
            16.gapH,
            _ToggleRow(
              title: 'Native build flavors (Android/iOS)',
              value: arch.generateFlavors && flavorsAvailable,
              enabled: flavorsAvailable,
              description: flavorsSupported
                  ? (envCount < 2
                        ? 'Add a 2nd environment to enable native flavors.'
                        : 'productFlavors + per-flavor app id. OFF → envs run as Dart entry '
                              'points and a plain `flutter run` works.')
                  : 'Native flavors need an Android/iOS target. Environments still '
                        'work as Dart entry points on web/desktop.',
              onChanged: notifier.toggleGenerateFlavors,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Navigation tab ────────────────────────────────────────────────────────────

class _NavigationTab extends ConsumerWidget {
  const _NavigationTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routingStyle = ref.watch(
      selectedPackagesProvider.select(routingStyleOf),
    );
    final packagesNotifier = ref.read(selectedPackagesProvider.notifier);
    final arch = ref.watch(architectureProvider);
    final notifier = ref.read(architectureProvider.notifier);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel(
            'Navigation provider',
            icon: Icons.alt_route_outlined,
          ),
          12.gapH,
          const Row(
            spacing: 16,
            children: [
              Expanded(
                child: _BackendCard(
                  icon: Icons.api_outlined,
                  iconColor: Palette.colorPrimaryCyan,
                  title: 'Go Router',
                  subtitle: '',
                  active: true,
                  onTap: _noop,
                ),
              ),
              Expanded(
                child: _BackendCard(
                  icon: Icons.bolt,
                  iconColor: Color(0xFF3ECF8E),
                  title: 'Auto Route',
                  subtitle: '',
                  active: false,
                  disabled: true,
                  onTap: _noop,
                ),
              ),
              Expanded(
                child: _BackendCard(
                  icon: Icons.local_fire_department,
                  iconColor: Color(0xFFFFA000),
                  title: 'Navigator',
                  subtitle: '',
                  active: false,
                  disabled: true,
                  onTap: _noop,
                ),
              ),
            ],
          ),
          24.gapH,
          const Divider(color: Colors.white10, height: 1),
          24.gapH,
          const _SectionLabel('Routing style', icon: Icons.route_outlined),
          10.gapH,
          Row(
            spacing: 10,
            children: [
              Expanded(
                child: _CompactOptionCard(
                  icon: Icons.edit_road_outlined,
                  iconColor: Palette.colorPrimaryCyan,
                  title: 'Manual',
                  active: routingStyle == RoutingStyle.manual,
                  tooltip: 'Hand-written GoRoute list.',
                  onTap: () =>
                      packagesNotifier.setRoutingStyle(RoutingStyle.manual),
                ),
              ),
              Expanded(
                child: _CompactOptionCard(
                  icon: Icons.route_outlined,
                  iconColor: const Color(0xFF3ECF8E),
                  title: 'Typed',
                  active: routingStyle == RoutingStyle.typed,
                  tooltip: 'go_router_builder codegen.',
                  onTap: () =>
                      packagesNotifier.setRoutingStyle(RoutingStyle.typed),
                ),
              ),
            ],
          ),
          24.gapH,
          const Divider(color: Colors.white10, height: 1),
          24.gapH,
          const _SectionLabel(
            'Navigation shell',
            icon: Icons.space_dashboard_outlined,
          ),
          12.gapH,
          _ToggleRow(
            title: 'Bottom navigation shell',
            description: arch.generateFirstFeature
                ? 'The app boots into a StatefulShellRoute: the 1st feature becomes the '
                      '1st tab of a NavigationBar. Shell Branches added later become tabs.'
                : 'Requires a first feature — enable "Generate example feature" on the '
                      'Architecture step.',
            value: arch.generateFirstFeature && arch.useNavigationShell,
            enabled: arch.generateFirstFeature,
            onChanged: notifier.toggleNavigationShell,
          ),
          if (arch.useNavigationShell) ...[
            24.gapH,
            _ShellTabConfig(
              icon: arch.shellIcon,
              labelHint: arch.effectiveShellLabel,
              onIcon: notifier.setShellIcon,
              onLabel: notifier.setShellLabel,
            ),
          ],
        ],
      ),
    );
  }
}

void _noop() {}

// ── Shell first-tab config (icon + label) ──────────────────────────────────────

/// Curated Material icons (kept so the generated `Icon(Icons.<name>)` compiles).
const _shellIcons = <String, IconData>{
  'home': Icons.home,
  'dashboard': Icons.dashboard,
  'person': Icons.person,
  'settings': Icons.settings,
  'search': Icons.search,
  'favorite': Icons.favorite,
  'notifications': Icons.notifications,
  'list': Icons.list,
  'shopping_cart': Icons.shopping_cart,
  'explore': Icons.explore,
  'calendar_today': Icons.calendar_today,
  'chat': Icons.chat,
  'map': Icons.map,
  'star': Icons.star,
  'folder': Icons.folder,
  'account_circle': Icons.account_circle,
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
                dropdownColor: context.neatColors.colorSurfaceCard,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                onChanged: (v) => widget.onIcon(v ?? 'home'),
                items: _shellIcons.entries
                    .map(
                      (e) => DropdownMenuItem(
                        value: e.key,
                        child: Row(
                          children: [
                            Icon(
                              e.value,
                              size: 16,
                              color: Palette.colorPrimaryCyan,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                e.key,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
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
              hintText: widget.labelHint.isEmpty
                  ? 'e.g. Home'
                  : widget.labelHint,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Localization tab ──────────────────────────────────────────────────────────

class _LocalizationTab extends ConsumerWidget {
  const _LocalizationTab();

  Future<void> _pickCsv(WidgetRef ref) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['csv'],
    );
    final path = result?.files.single.path;
    if (path != null) {
      ref.read(architectureProvider.notifier).setI18nCsvPath(path);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final arch = ref.watch(architectureProvider);
    final notifier = ref.read(architectureProvider.notifier);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF131316),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ToggleRow(
              title: 'i18n (slang)',
              description:
                  'Type-safe translations with slang: TranslationProvider + '
                  '`context.t`, and a sample language switcher in the AppBar.',
              value: arch.generateI18n,
              onChanged: notifier.toggleGenerateI18n,
            ),
            if (arch.generateI18n) ...[
              24.gapH,
              const Divider(color: Colors.white10, height: 1),
              24.gapH,
              const _SectionLabel('Languages', icon: Icons.translate_outlined),
              12.gapH,
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  for (final (code, title, iconColor) in [
                    ('en', 'English', context.neatColors.colorPrimaryCyan),
                    ('fr', 'French', context.neatColors.colorTertiaryPurple),
                    ('es', 'Spanish', context.neatColors.errorColor),
                    ('de', 'German', context.neatColors.colorYellow),
                    ('it', 'Italian', context.neatColors.colorGreen),
                  ])
                    SizedBox(
                      width: 180,
                      child: _BackendCard(
                        icon: Icons.language,
                        iconColor: iconColor,
                        title: title,
                        subtitle: '',
                        active: arch.i18nLocales.contains(code),
                        onTap: () => notifier.toggleI18nLocale(code),
                      ),
                    ),
                ],
              ),
              8.gapH,
              Text(
                'At least one language stays selected.',
                style: TextStyle(color: Colors.grey[600], fontSize: 11),
              ),
              24.gapH,
              const Divider(color: Colors.white10, height: 1),
              24.gapH,
              _UploadFileCard(
                title: 'Translations (CSV)',
                icon: Icons.table_chart_outlined,
                filePath: arch.i18nCsvPath,
                emptyHint:
                    'Optional: a compact CSV (`key,en,fr,…`) to translate in a '
                    'spreadsheet. Replaces the default scaffold above.',
                onPick: () => _pickCsv(ref),
                onRemove: () => notifier.setI18nCsvPath(''),
                allowedExtensions: const ['csv'],
                onFilePicked: notifier.setI18nCsvPath,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── File upload card (Firebase config / i18n CSV) ────────────────────────────

/// A reusable "upload a file" row: title + hint (or the picked file name) + an
/// Upload/Change button and a clear button. Also a [DropZone] — dropping a
/// file matching [allowedExtensions] calls [onFilePicked] directly (it
/// already has the path, no picker dialog needed), same allow-list the
/// click-to-browse [onPick] handler passes to `FilePicker.pickFiles`.
class _UploadFileCard extends StatelessWidget {
  const _UploadFileCard({
    required this.title,
    required this.icon,
    required this.filePath,
    required this.emptyHint,
    required this.onPick,
    required this.onRemove,
    required this.allowedExtensions,
    required this.onFilePicked,
  });

  final String title;
  final IconData icon;
  final String filePath;
  final String emptyHint;
  final VoidCallback onPick;
  final VoidCallback onRemove;
  final List<String> allowedExtensions;
  final ValueChanged<String> onFilePicked;

  @override
  Widget build(BuildContext context) {
    final hasFile = filePath.isNotEmpty;
    final fileName = hasFile
        ? filePath.split(Platform.pathSeparator).last
        : null;
    return DropZone(
      allowedExtensions: allowedExtensions,
      onFilePicked: onFilePicked,
      onRejected: () => neatSnack(
        context,
        'Drop a .${allowedExtensions.join('/.')}  file',
        success: false,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF18181C),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Icon(
              hasFile ? Icons.check_circle_outline : icon,
              color: hasFile ? Palette.colorPrimaryCyan : Colors.grey[500],
              size: 20,
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
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    fileName ?? emptyHint,
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
                tooltip: 'Remove',
              ),
            OutlinedButton(
              onPressed: onPick,
              style: OutlinedButton.styleFrom(
                foregroundColor: Palette.colorPrimaryCyan,
                side: BorderSide(
                  color: Palette.colorPrimaryCyan.withValues(alpha: 0.5),
                ),
              ),
              child: Text(hasFile ? 'Change' : 'Upload'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EnvFieldRow extends StatelessWidget {
  const _EnvFieldRow({
    required this.env,
    required this.backend,
    required this.isBase,
    required this.onMakeBase,
    required this.onName,
    required this.onApiUrl,
    required this.onSupabaseUrl,
    required this.onSupabaseKey,
    this.onRemove,
    super.key,
  });

  final EnvConfig env;
  final BackendKind backend;
  final bool isBase;

  /// Promotes this env to the production base (the BASE chip).
  final VoidCallback onMakeBase;
  final ValueChanged<String> onName;
  final ValueChanged<String> onApiUrl;
  final ValueChanged<String> onSupabaseUrl;
  final ValueChanged<String> onSupabaseKey;

  /// When null, the remove control is hidden (a single env can't be removed).
  final VoidCallback? onRemove;

  static InputDecoration _dec(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: Colors.grey[700], fontSize: 12),
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Colors.white12),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(
        color: Palette.colorPrimaryCyan.withValues(alpha: 0.5),
      ),
    ),
  );

  Widget _field(
    String initial,
    String hint,
    ValueChanged<String> onChanged, {
    bool obscure = false,
  }) {
    return TextFormField(
      initialValue: initial,
      onChanged: onChanged,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white, fontSize: 12),
      decoration: _dec(hint),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0F),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          SizedBox(width: 130, child: _field(env.name, 'env', onName)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Tooltip(
              message: isBase ? 'Production base' : 'Set as production base',
              child: InkWell(
                onTap: isBase ? null : onMakeBase,
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: isBase
                        ? Palette.colorPrimaryCyan.withValues(alpha: 0.12)
                        : null,
                    border: Border.all(
                      color: isBase
                          ? Palette.colorPrimaryCyan.withValues(alpha: 0.5)
                          : Colors.white12,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'BASE',
                    style: TextStyle(
                      color: isBase ? Palette.colorPrimaryCyan : Colors.white24,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          if (backend == BackendKind.supabase) ...[
            Expanded(
              child: _field(env.supabaseUrl, 'Supabase URL', onSupabaseUrl),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _field(
                env.supabaseAnonKey,
                'anon / publishable key',
                onSupabaseKey,
                obscure: true,
              ),
            ),
          ] else
            Expanded(
              child: _field(
                env.apiBaseUrl,
                'API base URL (optional)',
                onApiUrl,
              ),
            ),
          if (onRemove != null)
            IconButton(
              icon: const Icon(Icons.close, size: 16, color: Colors.white38),
              onPressed: onRemove,
              tooltip: 'Remove environment',
              padding: const EdgeInsets.only(left: 6),
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}

/// A generic title+description+switch row (no card wrapper) — used for both
/// native flavors and the bottom-navigation-shell toggle.
class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final titleColor = enabled ? Colors.white : Colors.white38;
    return Opacity(
      opacity: enabled ? 1 : 0.6,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(color: Colors.grey[500], fontSize: 11),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: enabled ? onChanged : null,
            activeTrackColor: Palette.colorPrimaryCyan,
          ),
        ],
      ),
    );
  }
}

class _FirebaseConfigUpload extends StatelessWidget {
  const _FirebaseConfigUpload({
    required this.path,
    required this.onPick,
    required this.onClear,
  });

  final String path;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final hasFile = path.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              hasFile ? Icons.check_circle_outline : Icons.upload_file_outlined,
              color: hasFile ? Palette.colorPrimaryCyan : Colors.grey[500],
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                hasFile
                    ? path.split('/').last
                    : 'Firebase config (JSON) — optional',
                style: TextStyle(color: Colors.grey[300], fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (hasFile)
              IconButton(
                icon: const Icon(Icons.close, size: 16, color: Colors.white54),
                onPressed: onClear,
              ),
            OutlinedButton(
              onPressed: onPick,
              style: OutlinedButton.styleFrom(
                foregroundColor: Palette.colorPrimaryCyan,
                side: BorderSide(
                  color: Palette.colorPrimaryCyan.withValues(alpha: 0.5),
                ),
              ),
              child: Text(hasFile ? 'Change' : 'Upload'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Single config for now → generates lib/firebase_options.dart. For full '
          'per-platform native setup, run `flutterfire configure` after generation.',
          style: TextStyle(color: Colors.grey[600], fontSize: 11),
        ),
      ],
    );
  }
}

// ── Managed Packages Panel ────────────────────────────────────────────────────

class _ManagedPackagesPanel extends ConsumerWidget {
  const _ManagedPackagesPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packages = ref.watch(selectedPackagesProvider);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF18181C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(
                  Icons.inventory_2_outlined,
                  color: Palette.colorPrimaryCyan,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  '${packages.length} SELECTED PACKAGES',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white10, height: 1),
          if (packages.isEmpty)
            const Expanded(
              child: Center(
                child: Text(
                  'No packages added yet.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: packages.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _SheetPackageTile(package: packages[i]),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Managed Packages Tile ─────────────────────────────────────────────────────

class _SheetPackageTile extends ConsumerStatefulWidget {
  const _SheetPackageTile({required this.package});

  final PubPackage package;

  @override
  ConsumerState<_SheetPackageTile> createState() => _SheetPackageTileState();
}

class _SheetPackageTileState extends ConsumerState<_SheetPackageTile> {
  bool _editing = false;
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.package.version);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _commit() {
    ref
        .read(selectedPackagesProvider.notifier)
        .setVersion(widget.package.name, _ctrl.text);
    setState(() => _editing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF141416),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.package.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _editing
                        ? SizedBox(
                            width: 110,
                            height: 24,
                            child: TextField(
                              controller: _ctrl,
                              autofocus: true,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                              decoration: InputDecoration(
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 4,
                                ),
                                filled: true,
                                fillColor: const Color(0xFF2A2A2E),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(4),
                                  borderSide: const BorderSide(
                                    color: Palette.colorPrimaryCyan,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(4),
                                  borderSide: const BorderSide(
                                    color: Palette.colorPrimaryCyan,
                                  ),
                                ),
                              ),
                              onSubmitted: (_) => _commit(),
                              onTapOutside: (_) => _commit(),
                            ),
                          )
                        : GestureDetector(
                            onTap: () {
                              _ctrl.text = widget.package.version;
                              setState(() => _editing = true);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2A2A2E),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.white12),
                              ),
                              child: Text(
                                widget.package.version,
                                style: const TextStyle(
                                  color: Palette.colorPrimaryCyan,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                    const SizedBox(width: 8),
                    Container(
                      width: 3,
                      height: 3,
                      decoration: BoxDecoration(
                        color: Colors.grey[600],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.package.isDev ? 'dev' : 'dep',
                      style: TextStyle(
                        color: widget.package.isDev
                            ? const Color(0xFFFFA726)
                            : Palette.colorPrimaryCyan,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
