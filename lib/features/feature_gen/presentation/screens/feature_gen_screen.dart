import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:neat/core/contract/neat_contract.dart';
import 'package:neat/core/theme/app_theme.dart';
import 'package:neat/features/architecture/presentation/widgets/entity_fields_editor.dart';
import 'package:neat/features/feature_gen/domain/models/feature_gen_options.dart';
import 'package:neat/features/feature_gen/presentation/providers/workshop_controller.dart';
import 'package:neat/features/generation/domain/models/field_spec.dart';
import 'package:neat/features/generation/domain/services/json_entity_inferencer.dart';
import 'package:neat/features/identity/presentation/providers/stepper_provider.dart';

/// Workshop mode: open an existing NEAT project (via its `.neat.json`) and
/// generate a new feature. The project stack is fixed by the contract; the
/// Workshop only exposes the choices that genuinely vary per feature (routing
/// shape + which Clean Architecture layers to scaffold).
class FeatureGenScreen extends HookConsumerWidget {
  const FeatureGenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(workshopControllerProvider);
    final notifier = ref.read(workshopControllerProvider.notifier);
    final project = state.project;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Feature Workshop',
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 8),
        Text(
          'Generate production-ready features for your existing project. '
          'Select layers and routing strategy.',
          style: TextStyle(color: Colors.grey[400], fontSize: 14),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: project == null
              ? _OpenProjectPanel(error: state.error, onOpen: () => _pickAndOpen(notifier))
              : _Workshop(
                  state: state,
                  onGenerate: notifier.generateFeature,
                  onClose: () {
                    notifier.close();
                    ref.read(currentStepProvider.notifier).setStep(NeatStep.hub);
                  },
                  onImportTranslations: notifier.importTranslations,
                ),
        ),
      ],
    );
  }

  Future<void> _pickAndOpen(WorkshopController notifier) async {
    await FilePicker.skipEntitlementsChecks();
    final path = await FilePicker.getDirectoryPath(dialogTitle: 'Open a NEAT project');
    if (path != null) await notifier.openProject(path);
  }
}

// ── Empty state: open a project ────────────────────────────────────────────────

class _OpenProjectPanel extends StatelessWidget {
  const _OpenProjectPanel({required this.error, required this.onOpen});

  final String? error;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.folder_open_outlined, size: 48, color: Colors.grey[600]),
          const SizedBox(height: 16),
          const Text(
            'No project open',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            'Select a folder created by NEAT (it contains a .neat.json).',
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onOpen,
            icon: const Icon(Icons.folder_open, size: 18),
            label: const Text('Open Existing Project'),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.colorPrimaryCyan,
              foregroundColor: const Color(0xFF0E0E0E),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 16),
            Text(error!, style: TextStyle(color: Colors.redAccent[100], fontSize: 12)),
          ],
        ],
      ),
    );
  }
}

// ── Loaded project: the form + live blueprint ──────────────────────────────────

class _Workshop extends HookWidget {
  const _Workshop({
    required this.state,
    required this.onGenerate,
    required this.onClose,
    required this.onImportTranslations,
  });

  final WorkshopState state;
  final Future<void> Function(FeatureGenOptions) onGenerate;
  final VoidCallback onClose;
  final Future<void> Function(String csvPath) onImportTranslations;

  @override
  Widget build(BuildContext context) {
    final project = state.project!;
    final c = project.contract;
    final nameCtrl = useTextEditingController();
    final labelCtrl = useTextEditingController();
    final options = useState(_defaultsFor(c));

    // Re-read on every keystroke so validation + blueprint stay live.
    useListenable(nameCtrl);
    useListenable(labelCtrl);
    final opts = options.value
        .copyWith(name: nameCtrl.text.trim(), shellLabel: labelCtrl.text.trim());

    final projectHasHttp = c.httpClient != 'none';
    final hasNav = c.navigation != 'none';
    // Child nesting + shell branches work for both go_router and go_router_builder.
    final routingEnabled = c.navigation == 'go_router' || c.navigation == 'go_router_builder';
    final needsParent = opts.routing == FeatureRouting.child;
    final parentMissing = needsParent && opts.parentFeature.isEmpty;
    final isShell = opts.routing == FeatureRouting.shell;

    final nameError = nameCtrl.text.isEmpty
        ? null
        : (opts.validateName() ?? (project.features.contains(opts.name) ? 'feature "${opts.name}" already exists' : null));
    final canGenerate = nameCtrl.text.isNotEmpty &&
        nameError == null &&
        opts.hasAnyDataSource &&
        !parentMissing &&
        !state.isGenerating;

    void set(FeatureGenOptions v) => options.value = v;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Project header.
        Row(
          children: [
            const Icon(Icons.folder_special_outlined, size: 16, color: AppTheme.colorPrimaryCyan),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                c.projectName,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text('${project.features.length} features',
                style: TextStyle(color: Colors.grey[600], fontSize: 11)),
            // Import translations (CSV) — only for projects generated with i18n.
            if (c.generateI18n) ...[
              const SizedBox(width: 12),
              TextButton.icon(
                onPressed: state.isGenerating
                    ? null
                    : () async {
                        final result = await FilePicker.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: const ['csv'],
                        );
                        final path = result?.files.single.path;
                        if (path != null) await onImportTranslations(path);
                      },
                icon: const Icon(Icons.translate, size: 14),
                label: const Text('Import i18n', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(foregroundColor: AppTheme.colorPrimaryCyan),
              ),
            ],
            const SizedBox(width: 12),
            TextButton.icon(
              onPressed: state.isGenerating ? null : onClose,
              icon: const Icon(Icons.close, size: 14),
              label: const Text('Close', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(foregroundColor: Colors.white54),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: _stackBadges(c).map((b) => _Badge(b)).toList()),
        const SizedBox(height: 20),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: the form.
              Expanded(
                flex: 6,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SectionTitle(Icons.edit_note, 'Feature Identity'),
                      const SizedBox(height: 10),
                      TextField(
                        controller: nameCtrl,
                        enabled: !state.isGenerating,
                        style: const TextStyle(color: Colors.white),
                        decoration: _fieldDecoration('e.g. user_profile, auth_login', nameError),
                      ),
                      const SizedBox(height: 24),
                      if (hasNav) ...[
                        const _SectionTitle(Icons.alt_route, 'Navigation & Routing'),
                        const SizedBox(height: 10),
                        _RoutingRow(
                          selected: opts.routing,
                          enabled: !state.isGenerating,
                          routingEnabled: routingEnabled,
                          onSelect: (r) => set(opts.copyWith(routing: r)),
                        ),
                        if (needsParent) ...[
                          const SizedBox(height: 12),
                          _ParentSelector(
                            features: project.features,
                            selected: opts.parentFeature.isEmpty ? null : opts.parentFeature,
                            enabled: !state.isGenerating,
                            error: parentMissing ? 'Choose the parent feature.' : null,
                            onSelect: (f) => set(opts.copyWith(parentFeature: f ?? '')),
                          ),
                        ],
                        if (isShell) ...[
                          const SizedBox(height: 12),
                          _ShellBranchFields(
                            icon: opts.shellIcon,
                            labelCtrl: labelCtrl,
                            labelHint: opts.effectiveShellLabel,
                            enabled: !state.isGenerating,
                            onIcon: (i) => set(opts.copyWith(shellIcon: i)),
                          ),
                        ],
                        const SizedBox(height: 24),
                      ],
                      const _SectionTitle(Icons.layers, 'Architecture Layers'),
                      const SizedBox(height: 10),
                      _LayerToggle(
                        title: 'Remote Data Source',
                        subtitle: projectHasHttp
                            ? 'Generates the ${c.httpClient} API source & CRUD.'
                            : 'Project has no HTTP client — unavailable.',
                        value: projectHasHttp && opts.includeRemoteDataSource,
                        enabled: projectHasHttp && !state.isGenerating,
                        onChanged: (v) => set(opts.copyWith(includeRemoteDataSource: v)),
                      ),
                      _LayerToggle(
                        title: 'Local Data Source',
                        subtitle: c.storageStrategy == 'remoteOnly'
                            ? 'In-memory cache stub.'
                            : 'Drift-backed local cache (typed table injected).',
                        value: opts.includeLocalDataSource,
                        enabled: !state.isGenerating,
                        onChanged: (v) => set(opts.copyWith(includeLocalDataSource: v)),
                      ),
                      _LayerToggle(
                        title: 'Domain UseCase',
                        subtitle: 'Business logic classes with Result<T> return type.',
                        value: opts.includeUseCase,
                        enabled: !state.isGenerating,
                        onChanged: (v) => set(opts.copyWith(includeUseCase: v)),
                      ),
                      const _LayerToggle(
                        title: 'Data Mapper',
                        subtitle: 'DTO → Entity conversion (intrinsic to Clean Architecture).',
                        value: true,
                        enabled: false,
                        locked: true,
                      ),
                      if (!opts.hasAnyDataSource) ...[
                        const SizedBox(height: 8),
                        Text('Pick at least one data source.',
                            style: TextStyle(color: Colors.orangeAccent[100], fontSize: 12)),
                      ],
                      const SizedBox(height: 24),
                      const _SectionTitle(Icons.data_object, 'Entity Fields'),
                      const SizedBox(height: 10),
                      EntityFieldsEditor(
                        json: opts.json,
                        fields: opts.fields,
                        warnings: opts.fieldWarnings,
                        onInfer: (j) {
                          if (j.trim().isEmpty) {
                            set(opts.copyWith(
                                json: '', fields: FieldSpec.idName, fieldWarnings: const []));
                            return;
                          }
                          final r = const JsonEntityInferencer().infer(j);
                          set(opts.copyWith(json: j, fields: r.fields, fieldWarnings: r.warnings));
                        },
                        onReset: () => set(opts.copyWith(
                            json: '', fields: FieldSpec.idName, fieldWarnings: const [])),
                        onAddField: () {
                          final used = opts.fields.map((f) => f.dartName).toSet();
                          var n = 'field';
                          for (var i = 1; used.contains(n); i++) {
                            n = 'field$i';
                          }
                          set(opts.copyWith(fields: [
                            ...opts.fields,
                            FieldSpec(jsonKey: n, dartName: n),
                          ]));
                        },
                        onName: (i, v) => set(opts.copyWith(
                            fields: _editField(opts.fields, i, (f) => f.copyWith(dartName: v.trim())))),
                        onType: (i, v) => set(opts.copyWith(
                            fields: _editField(
                                opts.fields, i, (f) => f.isId ? f : f.copyWith(dartType: v)))),
                        onNullable: (i, v) => set(opts.copyWith(
                            fields: _editField(
                                opts.fields, i, (f) => f.isId ? f : f.copyWith(nullable: v)))),
                        onRemove: (i) {
                          if (opts.fields[i].isId) return;
                          set(opts.copyWith(fields: [...opts.fields]..removeAt(i)));
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 24),
              // Right: blueprint + generate + logs.
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionTitle(Icons.visibility_outlined, 'Blueprint Overview'),
                    const SizedBox(height: 10),
                    Expanded(child: _BlueprintTree(options: opts, contract: c, hasHttp: projectHasHttp)),
                    const SizedBox(height: 12),
                    if (state.error != null) ...[
                      Text(state.error!, style: TextStyle(color: Colors.redAccent[100], fontSize: 12)),
                      const SizedBox(height: 8),
                    ],
                    if (state.logs.isNotEmpty) ...[
                      _LogsConsole(logs: state.logs),
                      const SizedBox(height: 12),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: canGenerate ? () => onGenerate(opts) : null,
                        icon: state.isGenerating
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0E0E0E)),
                              )
                            : const Icon(Icons.auto_awesome, size: 16),
                        label: Text(state.isGenerating ? 'Generating…' : 'Generate Feature'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.colorPrimaryCyan,
                          foregroundColor: const Color(0xFF0E0E0E),
                          padding: const EdgeInsets.symmetric(vertical: 16),
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

  /// Sensible per-feature defaults derived from the project stack.
  static FeatureGenOptions _defaultsFor(NeatContract c) => FeatureGenOptions(
        includeRemoteDataSource: c.httpClient != 'none',
        includeLocalDataSource: c.storageStrategy != 'remoteOnly',
      );

  static InputDecoration _fieldDecoration(String hint, String? error) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[600]),
        errorText: error,
        filled: true,
        fillColor: const Color(0xFF18181C),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.white10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppTheme.colorPrimaryCyan),
        ),
      );

  static List<String> _stackBadges(NeatContract c) => [
        c.architecture == 'feature_first' ? 'Feature-First' : 'Layer-First',
        c.stateManagement,
        if (c.navigation != 'none') c.navigation,
        if (c.httpClient != 'none') c.httpClient,
        if (c.themeApproach != 'none') c.themeApproach,
        if (c.storageStrategy != 'remoteOnly') c.storageStrategy,
        if (c.extractUiPackage) 'ui-package',
      ];
}

// ── Navigation & Routing cards ─────────────────────────────────────────────────

class _RoutingRow extends StatelessWidget {
  const _RoutingRow({
    required this.selected,
    required this.enabled,
    required this.routingEnabled,
    required this.onSelect,
  });

  final FeatureRouting selected;
  final bool enabled;
  final bool routingEnabled;
  final ValueChanged<FeatureRouting> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _RoutingCard(
            title: 'Root Route',
            subtitle: '/feature',
            isSelected: selected == FeatureRouting.root,
            onTap: enabled ? () => onSelect(FeatureRouting.root) : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _RoutingCard(
            title: 'Child Route',
            subtitle: 'Sub-route of another feature',
            isSelected: selected == FeatureRouting.child,
            comingSoon: !routingEnabled,
            onTap: enabled && routingEnabled ? () => onSelect(FeatureRouting.child) : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _RoutingCard(
            title: 'Shell Branch',
            subtitle: 'Bottom-nav branch',
            isSelected: selected == FeatureRouting.shell,
            comingSoon: !routingEnabled,
            onTap: enabled && routingEnabled ? () => onSelect(FeatureRouting.shell) : null,
          ),
        ),
      ],
    );
  }
}

/// Common Material icons offered for a shell branch (kept curated so the
/// generated `Icon(Icons.<name>)` always compiles).
const _shellIcons = <String>[
  'home', 'dashboard', 'person', 'settings', 'search', 'favorite',
  'notifications', 'list', 'shopping_cart', 'explore', 'calendar_today',
  'chat', 'map', 'star', 'folder', 'account_circle',
];

const _iconData = <String, IconData>{
  'home': Icons.home, 'dashboard': Icons.dashboard, 'person': Icons.person,
  'settings': Icons.settings, 'search': Icons.search, 'favorite': Icons.favorite,
  'notifications': Icons.notifications, 'list': Icons.list,
  'shopping_cart': Icons.shopping_cart, 'explore': Icons.explore,
  'calendar_today': Icons.calendar_today, 'chat': Icons.chat, 'map': Icons.map,
  'star': Icons.star, 'folder': Icons.folder, 'account_circle': Icons.account_circle,
};

/// Icon + label for a shell branch's NavigationBar destination.
class _ShellBranchFields extends StatelessWidget {
  const _ShellBranchFields({
    required this.icon,
    required this.labelCtrl,
    required this.labelHint,
    required this.enabled,
    required this.onIcon,
  });

  final String icon;
  final TextEditingController labelCtrl;
  final String labelHint;
  final bool enabled;
  final ValueChanged<String> onIcon;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: InputDecorator(
            decoration: _decoration('Nav icon'),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _iconData.containsKey(icon) ? icon : 'home',
                isExpanded: true,
                dropdownColor: const Color(0xFF18181C),
                style: const TextStyle(color: Colors.white, fontSize: 13),
                onChanged: enabled ? (v) => onIcon(v ?? 'home') : null,
                items: _shellIcons
                    .map((i) => DropdownMenuItem(
                          value: i,
                          child: Row(
                            children: [
                              Icon(_iconData[i], size: 16, color: AppTheme.colorPrimaryCyan),
                              const SizedBox(width: 8),
                              Expanded(child: Text(i, overflow: TextOverflow.ellipsis)),
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
            controller: labelCtrl,
            enabled: enabled,
            style: const TextStyle(color: Colors.white),
            decoration: _decoration('Nav label').copyWith(
              hintText: labelHint.isEmpty ? 'e.g. Home' : labelHint,
              hintStyle: TextStyle(color: Colors.grey[600]),
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _decoration(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54, fontSize: 13),
        filled: true,
        fillColor: const Color(0xFF18181C),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.white10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppTheme.colorPrimaryCyan),
        ),
      );
}

/// Dropdown of existing features to nest a child route under.
class _ParentSelector extends StatelessWidget {
  const _ParentSelector({
    required this.features,
    required this.selected,
    required this.enabled,
    required this.error,
    required this.onSelect,
  });

  final List<String> features;
  final String? selected;
  final bool enabled;
  final String? error;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: 'Parent feature',
        labelStyle: const TextStyle(color: Colors.white54, fontSize: 13),
        errorText: error,
        filled: true,
        fillColor: const Color(0xFF18181C),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.white10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppTheme.colorPrimaryCyan),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selected,
          isExpanded: true,
          dropdownColor: const Color(0xFF18181C),
          hint: Text('Select a feature', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          style: const TextStyle(color: Colors.white, fontSize: 13),
          onChanged: enabled ? onSelect : null,
          items: features
              .map((f) => DropdownMenuItem(value: f, child: Text(f)))
              .toList(),
        ),
      ),
    );
  }
}

class _RoutingCard extends StatelessWidget {
  const _RoutingCard({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    this.onTap,
    this.comingSoon = false,
  });

  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback? onTap;
  final bool comingSoon;

  @override
  Widget build(BuildContext context) {
    final cyan = AppTheme.colorPrimaryCyan;
    return Opacity(
      opacity: comingSoon ? 0.45 : 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? cyan.withValues(alpha: 0.08) : const Color(0xFF161619),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSelected ? cyan : Colors.white12, width: isSelected ? 1.5 : 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? cyan : Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (comingSoon) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('soon',
                          style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Architecture Layer toggle ──────────────────────────────────────────────────

class _LayerToggle extends StatelessWidget {
  const _LayerToggle({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.enabled,
    this.onChanged,
    this.locked = false,
  });

  final String title;
  final String subtitle;
  final bool value;
  final bool enabled;
  final ValueChanged<bool>? onChanged;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)),
                    if (locked) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.lock_outline, size: 12, color: Colors.white38),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: enabled ? onChanged : null,
            activeThumbColor: AppTheme.colorPrimaryCyan,
          ),
        ],
      ),
    );
  }
}

// ── Blueprint Overview (live feature tree) ─────────────────────────────────────

class _BlueprintTree extends StatelessWidget {
  const _BlueprintTree({required this.options, required this.contract, required this.hasHttp});

  final FeatureGenOptions options;
  final NeatContract contract;
  final bool hasHttp;

  @override
  Widget build(BuildContext context) {
    final name = options.name.isEmpty ? 'feature_name' : options.name;
    final remote = hasHttp && options.includeRemoteDataSource;
    final local = options.includeLocalDataSource || !remote;
    final lines = <String>[
      'lib/features/$name/',
      '├── data/',
      '│   ├── sources/',
      if (remote) '│   │   ├── ${name}_api_source.dart',
      if (local) '│   │   └── ${name}_local_source.dart',
      '│   ├── models/',
      '│   └── repositories/',
      '├── domain/',
      '│   ├── entities/',
      '│   ├── repositories/',
      if (options.includeUseCase) '│   └── usecases/',
      '└── presentation/',
      '    ├── pages/',
      '    ├── providers/',
      // child/shell features don't get their own route file (it lives in the
      // parent's / shell's tree), so only a root route adds routes/.
      if (contract.navigation != 'none' && options.routing == FeatureRouting.root)
        '    ├── routes/',
      '    └── widgets/',
    ];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0B0B0D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Terminal chrome.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                _dot(const Color(0xFFFF5F56)),
                const SizedBox(width: 6),
                _dot(const Color(0xFFFFBD2E)),
                const SizedBox(width: 6),
                _dot(const Color(0xFF27C93F)),
                const SizedBox(width: 14),
                Text('feature.tree', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white10),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: lines
                    .map((l) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 1.5),
                          child: Text(
                            l,
                            style: TextStyle(
                              color: l.startsWith('lib/')
                                  ? Colors.white
                                  : AppTheme.colorPrimaryCyan.withValues(alpha: 0.85),
                              fontSize: 12.5,
                              fontFamily: 'monospace',
                              height: 1.2,
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(Color c) => Container(width: 12, height: 12, decoration: BoxDecoration(color: c, shape: BoxShape.circle));
}

// ── Logs console ───────────────────────────────────────────────────────────────

class _LogsConsole extends StatelessWidget {
  const _LogsConsole({required this.logs});
  final List<String> logs;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 140),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0F),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: SingleChildScrollView(
        reverse: true,
        child: Text(
          logs.join('\n'),
          style: TextStyle(color: Colors.grey[400], fontSize: 11, fontFamily: 'monospace', height: 1.5),
        ),
      ),
    );
  }
}

// ── Small shared bits ──────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.icon, this.label);
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.colorPrimaryCyan),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.colorPrimaryCyan.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.colorPrimaryCyan.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: const TextStyle(color: AppTheme.colorPrimaryCyan, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// Returns a copy of [fields] with the entry at [index] transformed by [update].
List<FieldSpec> _editField(
  List<FieldSpec> fields,
  int index,
  FieldSpec Function(FieldSpec) update,
) {
  if (index < 0 || index >= fields.length) return fields;
  final next = [...fields];
  next[index] = update(next[index]);
  return next;
}
