import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:neat/core/contract/neat_contract.dart';
import 'package:neat/features/architecture/presentation/widgets/entity_fields_editor.dart';
import 'package:neat/features/feature_gen/domain/models/feature_gen_options.dart';
import 'package:neat/features/feature_gen/presentation/providers/workshop_controller.dart';
import 'package:neat/features/generation/domain/models/endpoint_spec.dart';
import 'package:neat/features/generation/domain/models/field_spec.dart';
import 'package:neat/features/generation/domain/services/json_entity_inferencer.dart';
import 'package:neat/features/shell/presentation/providers/stepper_provider.dart';
import 'package:neat_ui/neat_ui.dart';

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
        DecoratedBox(
          decoration: BoxDecoration(color: Colors.transparent),
          child: Padding(
            padding: const .fromLTRB(0, 28, 20, 24),
            child: Row(
              spacing: 12,
              children: [
                InkWell(
                  onTap: () => ref.read(currentStepProvider.notifier).setStep(NeatStep.hub),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF111416),
                      borderRadius: .circular(10),
                      border: .all(color: Palette.colorPrimaryCyan.withValues(alpha: 0.4)),
                    ),
                    child: const Icon(Icons.bolt, color: Palette.colorPrimaryCyan, size: 22),
                  ),
                ),

                const Text(
                  'Feature Workshop',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
          ),
        ),

        8.gapH,
        Text(
          'Generate production-ready features for your existing project. '
          'Select layers and routing strategy.',
          style: TextStyle(color: Colors.grey[400], fontSize: 14),
        ),
        12.gapH,
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
        24.gapH,
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
        mainAxisSize: .min,
        children: [
          Icon(Icons.folder_open_outlined, size: 48, color: Colors.grey[600]),
          16.gapH,
          const Text(
            'No project open',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
          ),
          6.gapH,
          Text(
            'Select a folder created by NEAT (it contains a .neat.json).',
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
          ),
          20.gapH,
          FilledButton.icon(
            onPressed: onOpen,
            icon: const Icon(Icons.folder_open, size: 18),
            label: const Text('Open Existing Project'),
            style: FilledButton.styleFrom(
              backgroundColor: Palette.colorPrimaryCyan,
              foregroundColor: const Color(0xFF0E0E0E),
              padding: const .symmetric(horizontal: 20, vertical: 14),
            ),
          ),
          if (error != null) ...[
            16.gapH,
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
    final apiPathCtrl = useTextEditingController();
    final options = useState(_defaultsFor(c));

    // Re-read on every keystroke so validation + blueprint stay live.
    useListenable(nameCtrl);
    useListenable(labelCtrl);
    useListenable(apiPathCtrl);
    final opts = options.value.copyWith(
      name: nameCtrl.text.trim(),
      shellLabel: labelCtrl.text.trim(),
      apiPath: apiPathCtrl.text.trim(),
    );

    final projectHasHttp = c.httpClient != 'none';
    final hasNav = c.navigation != 'none';
    // Child nesting + shell branches work for both go_router and go_router_builder.
    final routingEnabled = c.navigation == 'go_router' || c.navigation == 'go_router_builder';
    final needsParent = opts.routing == FeatureRouting.child;
    final parentMissing = needsParent && opts.parentFeature.isEmpty;
    final isShell = opts.routing == FeatureRouting.shell;

    // "Custom Endpoints" (ROADMAP.md §7 Phase 2): chopper-only, and — for
    // this pass — not combined with packageSplit (see
    // GenerateFeatureUsecase's own validation, which this mirrors so the
    // Workshop never even offers a combination it would reject).
    final canCustomEndpoints = c.httpClient == 'chopper' && !c.packageSplit;
    final endpointsValid = opts.endpoints.isNotEmpty &&
        opts.endpoints.every((e) => e.name.isNotEmpty && e.path.isNotEmpty) &&
        opts.endpoints.map((e) => e.name).toSet().length == opts.endpoints.length;

    final nameError = nameCtrl.text.isEmpty
        ? null
        : (opts.validateName() ??
              (project.features.contains(opts.name)
                  ? 'feature "${opts.name}" already exists'
                  : null));
    final canGenerate =
        nameCtrl.text.isNotEmpty &&
        nameError == null &&
        !parentMissing &&
        (!opts.useCustomEndpoints || endpointsValid) &&
        !state.isGenerating;

    void set(FeatureGenOptions v) => options.value = v;

    return Column(
      crossAxisAlignment: .start,
      children: [
        // Project header.
        Row(
          children: [
            const Icon(Icons.folder_special_outlined, size: 16, color: Palette.colorPrimaryCyan),
            8.gapW,
            Expanded(
              child: Text(
                c.projectName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '${project.features.length} features',
              style: TextStyle(color: Colors.grey[600], fontSize: 11),
            ),
            // Import translations (CSV) — only for projects generated with i18n.
            if (c.generateI18n) ...[
              12.gapW,
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
                style: TextButton.styleFrom(foregroundColor: Palette.colorPrimaryCyan),
              ),
            ],
            12.gapW,
            TextButton.icon(
              onPressed: state.isGenerating ? null : onClose,
              icon: const Icon(Icons.close, size: 14),
              label: const Text('Close', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(foregroundColor: Colors.white54),
            ),
          ],
        ),
        10.gapH,
        Wrap(spacing: 8, runSpacing: 8, children: _stackBadges(c).map((b) => _Badge(b)).toList()),
        20.gapH,
        Expanded(
          child: Row(
            crossAxisAlignment: .start,
            children: [
              // Left: the form.
              Expanded(
                flex: 6,
                child: ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: .start,
                      children: [
                        const _SectionTitle(Icons.edit_note, 'Feature Identity'),
                        10.gapH,
                        TextField(
                          controller: nameCtrl,
                          enabled: !state.isGenerating,
                          style: const TextStyle(color: Colors.white),
                          decoration: _fieldDecoration('e.g. user_profile, auth_login', nameError),
                        ),

                        // "Custom Endpoints" (ROADMAP.md §7 Phase 2) — an
                        // opt-in alternative to Entity + CRUD, only offered
                        // when the project's stack can actually support it
                        // (chopper, non-packageSplit).
                        if (canCustomEndpoints) ...[
                          24.gapH,
                          const _SectionTitle(Icons.api_outlined, 'Feature Shape'),
                          10.gapH,
                          _FeatureShapeRow(
                            useCustomEndpoints: opts.useCustomEndpoints,
                            enabled: !state.isGenerating,
                            onSelect: (v) => set(opts.copyWith(useCustomEndpoints: v)),
                          ),
                        ],

                        24.gapH,
                        if (hasNav) ...[
                          const _SectionTitle(Icons.alt_route, 'Navigation & Routing'),
                          10.gapH,
                          _RoutingRow(
                            selected: opts.routing,
                            enabled: !state.isGenerating,
                            routingEnabled: routingEnabled,
                            onSelect: (r) => set(opts.copyWith(routing: r)),
                          ),
                          if (needsParent) ...[
                            12.gapH,
                            _ParentSelector(
                              features: project.features,
                              selected: opts.parentFeature.isEmpty ? null : opts.parentFeature,
                              enabled: !state.isGenerating,
                              error: parentMissing ? 'Choose the parent feature.' : null,
                              onSelect: (f) => set(opts.copyWith(parentFeature: f ?? '')),
                            ),
                          ],
                          if (isShell) ...[
                            12.gapH,
                            _ShellBranchFields(
                              icon: opts.shellIcon,
                              labelCtrl: labelCtrl,
                              labelHint: opts.effectiveShellLabel,
                              enabled: !state.isGenerating,
                              onIcon: (i) => set(opts.copyWith(shellIcon: i)),
                            ),
                          ],
                          24.gapH,
                        ],
                        if (opts.useCustomEndpoints) ...[
                          const _SectionTitle(Icons.api_outlined, 'Endpoints'),
                          10.gapH,
                          _EndpointsEditor(
                            endpoints: opts.endpoints,
                            enabled: !state.isGenerating,
                            onChange: (eps) => set(opts.copyWith(endpoints: eps)),
                          ),
                        ] else ...[
                        const _SectionTitle(Icons.layers, 'Architecture Layers'),
                        10.gapH,
                        _LayerToggle(
                          title: 'Remote Data Source',
                          subtitle: projectHasHttp
                              ? 'Generates the ${c.httpClient} API source & CRUD.'
                              : 'Project has no HTTP client — unavailable.',
                          value: projectHasHttp && opts.includeRemoteDataSource,
                          enabled: projectHasHttp && !state.isGenerating,
                          onChanged: (v) => set(opts.copyWith(includeRemoteDataSource: v)),
                        ),
                        if (projectHasHttp && opts.includeRemoteDataSource) ...[
                          10.gapH,
                          TextField(
                            controller: apiPathCtrl,
                            enabled: !state.isGenerating,
                            style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
                            decoration: _fieldDecoration(
                              'API Path (optional) — e.g. /products',
                              null,
                            ),
                          ),
                          4.gapH,
                          Text(
                            opts.apiPath.isEmpty
                                ? 'Default REST path: /${opts.name.isEmpty ? '...' : opts.name}s'
                                : 'A relative path is prepended to the API Base URL; an absolute '
                                      'URL overrides it entirely.',
                            style: TextStyle(color: Colors.grey[600], fontSize: 11),
                          ),
                        ],
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
                          8.gapH,
                          Text(
                            'No data source selected — a pure entity + '
                            'presentation feature (no data/ layer at all).',
                            style: TextStyle(color: Colors.grey[500], fontSize: 12),
                          ),
                        ],
                        24.gapH,
                        const _SectionTitle(Icons.data_object, 'Entity Fields'),
                        10.gapH,
                        EntityFieldsEditor(
                          json: opts.json,
                          fields: opts.fields,
                          warnings: opts.fieldWarnings,
                          onInfer: (j) {
                            if (j.trim().isEmpty) {
                              set(
                                opts.copyWith(
                                  json: '',
                                  fields: FieldSpec.idName,
                                  fieldWarnings: const [],
                                ),
                              );
                              return;
                            }
                            final r = const JsonEntityInferencer().infer(j);
                            set(
                              opts.copyWith(json: j, fields: r.fields, fieldWarnings: r.warnings),
                            );
                          },
                          onReset: () => set(
                            opts.copyWith(
                              json: '',
                              fields: FieldSpec.idName,
                              fieldWarnings: const [],
                            ),
                          ),
                          onAddField: () {
                            final used = opts.fields.map((f) => f.dartName).toSet();
                            var n = 'field';
                            for (var i = 1; used.contains(n); i++) {
                              n = 'field$i';
                            }
                            set(
                              opts.copyWith(
                                fields: [
                                  ...opts.fields,
                                  FieldSpec(jsonKey: n, dartName: n),
                                ],
                              ),
                            );
                          },
                          onName: (i, v) => set(
                            opts.copyWith(
                              fields: _editField(
                                opts.fields,
                                i,
                                (f) => f.copyWith(dartName: v.trim()),
                              ),
                            ),
                          ),
                          onType: (i, v) => set(
                            opts.copyWith(
                              fields: _editField(
                                opts.fields,
                                i,
                                (f) => f.isId ? f : f.copyWith(dartType: v),
                              ),
                            ),
                          ),
                          onNullable: (i, v) => set(
                            opts.copyWith(
                              fields: _editField(
                                opts.fields,
                                i,
                                (f) => f.isId ? f : f.copyWith(nullable: v),
                              ),
                            ),
                          ),
                          onRemove: (i) {
                            if (opts.fields[i].isId) return;
                            set(opts.copyWith(fields: [...opts.fields]..removeAt(i)));
                          },
                        ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              24.gapW,
              // Right: blueprint + generate + logs.
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: .start,
                  children: [
                    const _SectionTitle(Icons.visibility_outlined, 'Blueprint Overview'),
                    10.gapH,
                    Expanded(
                      child: _BlueprintTree(options: opts, contract: c, hasHttp: projectHasHttp),
                    ),
                    12.gapH,
                    if (state.error != null) ...[
                      Text(
                        state.error!,
                        style: TextStyle(color: Colors.redAccent[100], fontSize: 12),
                      ),
                      8.gapH,
                    ],
                    if (state.logs.isNotEmpty) ...[_LogsConsole(logs: state.logs), 12.gapH],
                    SizedBox(
                      width: .infinity,
                      child: FilledButton.icon(
                        onPressed: canGenerate ? () => onGenerate(opts) : null,
                        icon: state.isGenerating
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF0E0E0E),
                                ),
                              )
                            : const Icon(Icons.auto_awesome, size: 16),
                        label: Text(state.isGenerating ? 'Generating…' : 'Generate Feature'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Palette.colorPrimaryCyan,
                          foregroundColor: const Color(0xFF0E0E0E),
                          padding: const .symmetric(vertical: 16),
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
      borderSide: const BorderSide(color: Palette.colorPrimaryCyan),
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

// ── Feature Shape cards (Entity + CRUD vs Custom Endpoints) ────────────────────

/// ROADMAP.md §7 Phase 2: picks between the entity-centric flow (one entity +
/// fixed CRUD) and the endpoint-centric one (N arbitrary REST calls). Reuses
/// [_RoutingCard]'s exact visual language — same kind of mutually-exclusive
/// mode choice, just two options instead of three.
class _FeatureShapeRow extends StatelessWidget {
  const _FeatureShapeRow({
    required this.useCustomEndpoints,
    required this.enabled,
    required this.onSelect,
  });

  final bool useCustomEndpoints;
  final bool enabled;
  final ValueChanged<bool> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _RoutingCard(
            title: 'Entity + CRUD',
            subtitle: 'One entity, full CRUD (get/create/update/delete)',
            isSelected: !useCustomEndpoints,
            onTap: enabled ? () => onSelect(false) : null,
          ),
        ),
        12.gapW,
        Expanded(
          child: _RoutingCard(
            title: 'Custom Endpoints',
            subtitle: 'N arbitrary REST calls, each typed independently',
            isSelected: useCustomEndpoints,
            onTap: enabled ? () => onSelect(true) : null,
          ),
        ),
      ],
    );
  }
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
        12.gapH,
        Expanded(
          child: _RoutingCard(
            title: 'Child Route',
            subtitle: 'Sub-route of another feature',
            isSelected: selected == FeatureRouting.child,
            comingSoon: !routingEnabled,
            onTap: enabled && routingEnabled ? () => onSelect(FeatureRouting.child) : null,
          ),
        ),
        12.gapH,
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
  'home',
  'dashboard',
  'person',
  'settings',
  'search',
  'favorite',
  'notifications',
  'list',
  'shopping_cart',
  'explore',
  'calendar_today',
  'chat',
  'map',
  'star',
  'folder',
  'account_circle',
];

const _iconData = <String, IconData>{
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
                    .map(
                      (i) => DropdownMenuItem(
                        value: i,
                        child: Row(
                          children: [
                            Icon(_iconData[i], size: 16, color: Palette.colorPrimaryCyan),
                            8.gapW,
                            Expanded(child: Text(i, overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ),
        12.gapW,
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
    contentPadding: const .symmetric(horizontal: 12, vertical: 8),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Colors.white10),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Palette.colorPrimaryCyan),
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
        contentPadding: const .symmetric(horizontal: 12, vertical: 4),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.white10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Palette.colorPrimaryCyan),
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
          items: features.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
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
    final cyan = Palette.colorPrimaryCyan;
    return Opacity(
      opacity: comingSoon ? 0.45 : 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const .all(16),
          decoration: BoxDecoration(
            color: isSelected ? cyan.withValues(alpha: 0.08) : const Color(0xFF161619),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? cyan : Colors.white12,
              width: isSelected ? 1.5 : 1,
            ),
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
                    6.gapW,
                    Container(
                      padding: const .symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'soon',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              4.gapH,
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
      padding: const .symmetric(vertical: 10),
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
                      6.gapW,
                      const Icon(Icons.lock_outline, size: 12, color: Colors.white38),
                    ],
                  ],
                ),
                2.gapH,
                Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: enabled ? onChanged : null,
            activeThumbColor: Palette.colorPrimaryCyan,
          ),
        ],
      ),
    );
  }
}

// ── Endpoints editor (Custom Endpoints mode — ROADMAP.md §7 Phase 2) ───────────

/// The list of [EndpointSpec]s for a "Custom Endpoints" feature — add/remove,
/// and per-endpoint name/method/path + request/response bodies (each reusing
/// [EntityFieldsEditor] as-is: it already works from any named field list,
/// nothing about it is entity-specific). Fully "controlled": all state lives
/// in [endpoints], bubbled up via [onChange] — matches every other field on
/// this screen. Only the expand/collapse of each endpoint's card is local,
/// ephemeral UI state (via [ExpansionTile]), never persisted.
class _EndpointsEditor extends StatelessWidget {
  const _EndpointsEditor({
    required this.endpoints,
    required this.enabled,
    required this.onChange,
  });

  final List<EndpointSpec> endpoints;
  final bool enabled;
  final ValueChanged<List<EndpointSpec>> onChange;

  void _update(int index, EndpointSpec Function(EndpointSpec) f) {
    final next = [...endpoints];
    next[index] = f(next[index]);
    onChange(next);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < endpoints.length; i++) ...[
          _EndpointRow(
            key: ValueKey(i),
            endpoint: endpoints[i],
            enabled: enabled,
            onName: (v) => _update(i, (e) => e.copyWith(name: v.trim())),
            onMethod: (m) => _update(i, (e) => e.copyWith(method: m)),
            onPath: (v) => _update(i, (e) => e.copyWith(path: v.trim())),
            onRequestInfer: (j) {
              if (j.trim().isEmpty) {
                _update(
                  i,
                  (e) => e.copyWith(requestJson: '', requestFields: const [], requestWarnings: const []),
                );
                return;
              }
              final r = const JsonEntityInferencer().infer(j, requireId: false);
              _update(
                i,
                (e) => e.copyWith(requestJson: j, requestFields: r.fields, requestWarnings: r.warnings),
              );
            },
            onRequestReset: () => _update(
              i,
              (e) => e.copyWith(requestJson: '', requestFields: const [], requestWarnings: const []),
            ),
            onRequestAddField: () => _update(i, (e) {
              final used = e.requestFields.map((f) => f.dartName).toSet();
              var n = 'field';
              for (var k = 1; used.contains(n); k++) {
                n = 'field$k';
              }
              return e.copyWith(requestFields: [...e.requestFields, FieldSpec(jsonKey: n, dartName: n)]);
            }),
            onRequestName: (fi, v) => _update(
              i,
              (e) => e.copyWith(
                requestFields: _editField(e.requestFields, fi, (f) => f.copyWith(dartName: v.trim())),
              ),
            ),
            onRequestType: (fi, v) => _update(
              i,
              (e) => e.copyWith(
                requestFields: _editField(e.requestFields, fi, (f) => f.copyWith(dartType: v)),
              ),
            ),
            onRequestNullable: (fi, v) => _update(
              i,
              (e) => e.copyWith(
                requestFields: _editField(e.requestFields, fi, (f) => f.copyWith(nullable: v)),
              ),
            ),
            onRequestRemove: (fi) => _update(
              i,
              (e) => e.copyWith(requestFields: [...e.requestFields]..removeAt(fi)),
            ),
            onResponseInfer: (j) {
              if (j.trim().isEmpty) {
                _update(
                  i,
                  (e) =>
                      e.copyWith(responseJson: '', responseFields: const [], responseWarnings: const []),
                );
                return;
              }
              final r = const JsonEntityInferencer().infer(j, requireId: false);
              _update(
                i,
                (e) =>
                    e.copyWith(responseJson: j, responseFields: r.fields, responseWarnings: r.warnings),
              );
            },
            onResponseReset: () => _update(
              i,
              (e) => e.copyWith(responseJson: '', responseFields: const [], responseWarnings: const []),
            ),
            onResponseAddField: () => _update(i, (e) {
              final used = e.responseFields.map((f) => f.dartName).toSet();
              var n = 'field';
              for (var k = 1; used.contains(n); k++) {
                n = 'field$k';
              }
              return e.copyWith(
                  responseFields: [...e.responseFields, FieldSpec(jsonKey: n, dartName: n)]);
            }),
            onResponseName: (fi, v) => _update(
              i,
              (e) => e.copyWith(
                responseFields: _editField(e.responseFields, fi, (f) => f.copyWith(dartName: v.trim())),
              ),
            ),
            onResponseType: (fi, v) => _update(
              i,
              (e) => e.copyWith(
                responseFields: _editField(e.responseFields, fi, (f) => f.copyWith(dartType: v)),
              ),
            ),
            onResponseNullable: (fi, v) => _update(
              i,
              (e) => e.copyWith(
                responseFields: _editField(e.responseFields, fi, (f) => f.copyWith(nullable: v)),
              ),
            ),
            onResponseRemove: (fi) => _update(
              i,
              (e) => e.copyWith(responseFields: [...e.responseFields]..removeAt(fi)),
            ),
            onRemove: () => onChange([...endpoints]..removeAt(i)),
          ),
          10.gapH,
        ],
        OutlinedButton.icon(
          onPressed: enabled
              ? () {
                  var n = 'endpoint';
                  final used = endpoints.map((e) => e.name).toSet();
                  for (var k = 1; used.contains(n); k++) {
                    n = 'endpoint$k';
                  }
                  onChange([...endpoints, EndpointSpec(name: n)]);
                }
              : null,
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Add endpoint'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Palette.colorPrimaryCyan,
            side: const BorderSide(color: Palette.colorPrimaryCyan),
          ),
        ),
      ],
    );
  }
}

class _EndpointRow extends HookWidget {
  const _EndpointRow({
    required this.endpoint,
    required this.enabled,
    required this.onName,
    required this.onMethod,
    required this.onPath,
    required this.onRequestInfer,
    required this.onRequestReset,
    required this.onRequestAddField,
    required this.onRequestName,
    required this.onRequestType,
    required this.onRequestNullable,
    required this.onRequestRemove,
    required this.onResponseInfer,
    required this.onResponseReset,
    required this.onResponseAddField,
    required this.onResponseName,
    required this.onResponseType,
    required this.onResponseNullable,
    required this.onResponseRemove,
    required this.onRemove,
    super.key,
  });

  final EndpointSpec endpoint;
  final bool enabled;
  final ValueChanged<String> onName;
  final ValueChanged<HttpMethod> onMethod;
  final ValueChanged<String> onPath;
  final ValueChanged<String> onRequestInfer;
  final VoidCallback onRequestReset;
  final VoidCallback onRequestAddField;
  final void Function(int, String) onRequestName;
  final void Function(int, String) onRequestType;
  final void Function(int, bool) onRequestNullable;
  final ValueChanged<int> onRequestRemove;
  final ValueChanged<String> onResponseInfer;
  final VoidCallback onResponseReset;
  final VoidCallback onResponseAddField;
  final void Function(int, String) onResponseName;
  final void Function(int, String) onResponseType;
  final void Function(int, bool) onResponseNullable;
  final ValueChanged<int> onResponseRemove;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    // Own controllers (created once per row, keyed by the parent's
    // ValueKey(i)) so typing doesn't recreate them / jump the cursor on
    // every rebuild — same pattern _Workshop itself uses for its own text
    // fields, just local to this row instead of lifted to the top.
    final nameCtrl = useTextEditingController(text: endpoint.name);
    final pathCtrl = useTextEditingController(text: endpoint.path);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF161619),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: endpoint.name.startsWith('endpoint') && endpoint.path.isEmpty,
          title: Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: nameCtrl,
                  enabled: enabled,
                  onChanged: onName,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: const InputDecoration.collapsed(hintText: 'name, e.g. login'),
                ),
              ),
              8.gapW,
              SizedBox(
                width: 90,
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<HttpMethod>(
                    value: endpoint.method,
                    isDense: true,
                    dropdownColor: const Color(0xFF18181C),
                    style: const TextStyle(color: Palette.colorPrimaryCyan, fontSize: 12),
                    onChanged: enabled ? (m) => onMethod(m ?? HttpMethod.get) : null,
                    items: HttpMethod.values
                        .map((m) => DropdownMenuItem(value: m, child: Text(m.name.toUpperCase())))
                        .toList(),
                  ),
                ),
              ),
              8.gapW,
              Expanded(
                flex: 3,
                child: TextField(
                  controller: pathCtrl,
                  enabled: enabled,
                  onChanged: onPath,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'monospace'),
                  decoration: const InputDecoration.collapsed(hintText: '/auth/login'),
                ),
              ),
              IconButton(
                onPressed: enabled ? onRemove : null,
                icon: const Icon(Icons.delete_outline, size: 18, color: Colors.white54),
                tooltip: 'Remove endpoint',
              ),
            ],
          ),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          children: [
            Text(
              'Request body (optional)',
              style: TextStyle(color: Colors.grey[500], fontSize: 11, fontWeight: FontWeight.bold),
            ),
            8.gapH,
            EntityFieldsEditor(
              json: endpoint.requestJson,
              fields: endpoint.requestFields,
              warnings: endpoint.requestWarnings,
              onInfer: onRequestInfer,
              onReset: onRequestReset,
              onAddField: onRequestAddField,
              onName: onRequestName,
              onType: onRequestType,
              onNullable: onRequestNullable,
              onRemove: onRequestRemove,
            ),
            16.gapH,
            Text(
              'Response body (optional)',
              style: TextStyle(color: Colors.grey[500], fontSize: 11, fontWeight: FontWeight.bold),
            ),
            8.gapH,
            EntityFieldsEditor(
              json: endpoint.responseJson,
              fields: endpoint.responseFields,
              warnings: endpoint.responseWarnings,
              onInfer: onResponseInfer,
              onReset: onResponseReset,
              onAddField: onResponseAddField,
              onName: onResponseName,
              onType: onResponseType,
              onNullable: onResponseNullable,
              onRemove: onResponseRemove,
            ),
          ],
        ),
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
    final lines = options.useCustomEndpoints ? _customEndpointsLines(name) : _crudLines(name);

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
            padding: const .symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                _dot(const Color(0xFFFF5F56)),
                6.gapW,
                _dot(const Color(0xFFFFBD2E)),
                6.gapW,
                _dot(const Color(0xFF27C93F)),
                14.gapW,
                Text('feature.tree', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white10),
          Expanded(
            child: SingleChildScrollView(
              padding: const .fromLTRB(18, 14, 14, 14),
              child: Column(
                crossAxisAlignment: .start,
                children: lines
                    .map(
                      (l) => Padding(
                        padding: const .symmetric(vertical: 1.5),
                        child: Text(
                          l,
                          style: TextStyle(
                            color: l.startsWith('lib/')
                                ? Colors.white
                                : Palette.colorPrimaryCyan.withValues(alpha: 0.85),
                            fontSize: 12.5,
                            fontFamily: 'monospace',
                            height: 1.2,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(Color c) => Container(
    width: 12,
    height: 12,
    decoration: BoxDecoration(color: c, shape: BoxShape.circle),
  );

  /// The existing entity + CRUD preview (unchanged).
  List<String> _crudLines(String name) {
    final remote = hasHttp && options.includeRemoteDataSource;
    // Mirrors FeatureScaffolder's writeLocal exactly: a local source is only
    // written for the offline-first 3-source repo (remote + a project that
    // actually ships Drift), or a genuinely local-only feature (no remote,
    // Local Data Source explicitly on) — never forced on just because remote
    // is off (that made the toggle meaningless — see ROADMAP.md).
    final localIsDrift = contract.storageStrategy != 'remoteOnly';
    final local = options.includeLocalDataSource && (!remote || localIsDrift);
    final hasAnyDataSource = remote || local;
    return [
      'lib/features/$name/',
      if (hasAnyDataSource) ...[
        '├── data/',
        '│   ├── sources/',
        if (remote) '│   │   ├── ${name}_api_source.dart',
        if (local) '│   │   └── ${name}_local_source.dart',
        '│   ├── models/',
        '│   └── repositories/',
      ],
      '├── domain/',
      '│   ├── entities/',
      if (hasAnyDataSource) '│   ├── repositories/',
      if (options.includeUseCase && hasAnyDataSource) '│   └── usecases/',
      '└── presentation/',
      '    ├── pages/',
      '    ├── providers/',
      // child/shell features don't get their own route file (it lives in the
      // parent's / shell's tree), so only a root route adds routes/.
      if (contract.navigation != 'none' && options.routing == FeatureRouting.root)
        '    ├── routes/',
      '    └── widgets/',
    ];
  }

  /// Custom Endpoints (ROADMAP.md §7 Phase 2): no entity, no repository, no
  /// local source — mirrors FeatureScaffolder's useCustomEndpoints branch
  /// exactly. Models only for endpoints that actually have a body.
  List<String> _customEndpointsLines(String name) {
    final endpoints = options.endpoints;
    final hasAnyModel = endpoints.any((e) => e.hasRequestBody || e.hasResponseBody);
    return [
      'lib/features/$name/',
      '├── data/',
      '│   ├── sources/',
      '│   │   └── ${name}_api_source.dart',
      if (hasAnyModel) ...[
        for (final e in endpoints.where((e) => e.hasRequestBody || e.hasResponseBody))
          '│   └── models/${e.name.isEmpty ? '<endpoint>' : e.name}_model.dart',
      ] else
        '│   └── models/ (none — no endpoint has a request/response body)',
      '├── domain/',
      '│   └── usecases/',
      for (final e in endpoints)
        '│       ├── ${e.name.isEmpty ? '<endpoint>' : e.name}_usecase.dart',
      '└── presentation/',
      '    ├── pages/',
      '    ├── providers/',
      if (contract.navigation != 'none' && options.routing == FeatureRouting.root)
        '    ├── routes/',
      '    └── widgets/',
    ];
  }
}

// ── Logs console ───────────────────────────────────────────────────────────────

class _LogsConsole extends StatelessWidget {
  const _LogsConsole({required this.logs});

  final List<String> logs;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: .infinity,
      constraints: const BoxConstraints(maxHeight: 140),
      padding: const .all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0F),
        borderRadius: .circular(8),
        border: .all(color: Colors.white10),
      ),
      child: SingleChildScrollView(
        reverse: true,
        child: Text(
          logs.join('\n'),
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 11,
            fontFamily: 'monospace',
            height: 1.5,
          ),
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
        Icon(icon, size: 16, color: Palette.colorPrimaryCyan),
        8.gapW,
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
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
      padding: const .symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Palette.colorPrimaryCyan.withValues(alpha: 0.1),
        borderRadius: .circular(6),
        border: .all(color: Palette.colorPrimaryCyan.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Palette.colorPrimaryCyan,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
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
