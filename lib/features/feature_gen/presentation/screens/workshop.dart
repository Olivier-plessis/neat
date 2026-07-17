import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:neat/core/contract/neat_contract.dart';
import 'package:neat/features/architecture/presentation/lines/crud_lines.dart';
import 'package:neat/features/feature_gen/domain/models/feature_gen_options.dart';
import 'package:neat/features/feature_gen/presentation/providers/feature_form_controller.dart';
import 'package:neat/features/feature_gen/presentation/providers/workshop_controller.dart';
import 'package:neat/features/feature_gen/presentation/screens/stepper/architecture_layers_step.dart';
import 'package:neat/features/feature_gen/presentation/screens/stepper/endpoints_step.dart';
import 'package:neat/features/feature_gen/presentation/screens/stepper/entity_fields_step.dart';
import 'package:neat/features/feature_gen/presentation/screens/stepper/identity_routing_step.dart';
import 'package:neat_ui/neat_ui.dart';

class Workshop extends ConsumerStatefulWidget {
  const Workshop({
    required this.state,
    required this.onGenerate,
    required this.onClose,
    required this.onImportTranslations,
    super.key,
  });

  final WorkshopState state;
  final Future<void> Function(FeatureGenOptions) onGenerate;
  final VoidCallback onClose;
  final Future<void> Function(String csvPath) onImportTranslations;

  @override
  ConsumerState<Workshop> createState() => _WorkshopState();
}

class _WorkshopState extends ConsumerState<Workshop> {
  late final NeatContract _contract;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _labelCtrl;
  late final TextEditingController _apiPathCtrl;
  late final ScrollController _logsScrollController;

  @override
  void initState() {
    super.initState();
    _contract = widget.state.project!.contract;
    final notifier = ref.read(featureFormControllerProvider(_contract).notifier);
    final initialOpts = ref.read(featureFormControllerProvider(_contract)).opts;
    // Own controllers (this State's, not the provider's) so typing doesn't
    // jump the cursor on every rebuild — each just forwards its raw text to
    // the notifier, which owns all the "what else needs to change" logic
    // (see FeatureFormController.setApiPath).
    _nameCtrl = TextEditingController(text: initialOpts.name)
      ..addListener(() => notifier.setName(_nameCtrl.text.trim()));
    _labelCtrl = TextEditingController(text: initialOpts.shellLabel)
      ..addListener(() => notifier.setShellLabel(_labelCtrl.text.trim()));
    _apiPathCtrl = TextEditingController(text: initialOpts.apiPath)
      ..addListener(() => notifier.setApiPath(_apiPathCtrl.text.trim()));
    _logsScrollController = ScrollController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _labelCtrl.dispose();
    _apiPathCtrl.dispose();
    _logsScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final project = widget.state.project!;
    final c = project.contract;
    final formState = ref.watch(featureFormControllerProvider(c));
    final formNotifier = ref.read(featureFormControllerProvider(c).notifier);
    final opts = formState.opts;

    // Auto-scroll the System Output panel to the bottom whenever a new log
    // line arrives — Riverpod's own mechanism for reacting to a value
    // changing (no useEffect/hooks needed).
    ref.listen(workshopControllerProvider, (previous, next) {
      if (next.logs.length > (previous?.logs.length ?? 0)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_logsScrollController.hasClients) {
            _logsScrollController.animateTo(
              _logsScrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });

    final projectHasHttp = c.httpClient != 'none';
    final hasNav = c.navigation != 'none';
    // Child nesting + shell branches work for both go_router and go_router_builder.
    final routingEnabled = c.navigation == 'go_router' || c.navigation == 'go_router_builder';
    final needsParent = opts.routing == FeatureRouting.child;
    final parentMissing = needsParent && opts.parentFeature.isEmpty;

    // "Custom Endpoints" (ROADMAP.md §7 Phase 2): chopper-only, and — for
    // this pass — not combined with packageSplit (see
    // GenerateFeatureUsecase's own validation, which this mirrors so the
    // Workshop never even offers a combination it would reject).
    final canCustomEndpoints = c.httpClient == 'chopper' && !c.packageSplit;
    final endpointsValid =
        opts.endpoints.isNotEmpty &&
        opts.endpoints.every((e) => e.name.isNotEmpty && e.path.isNotEmpty) &&
        opts.endpoints.map((e) => e.name).toSet().length == opts.endpoints.length;

    final nameError = opts.name.isEmpty
        ? null
        : (opts.validateName() ??
              (project.features.contains(opts.name)
                  ? 'feature "${opts.name}" already exists'
                  : null));
    final canGenerate =
        opts.name.isNotEmpty &&
        nameError == null &&
        !parentMissing &&
        (!opts.useCustomEndpoints || endpointsValid) &&
        !widget.state.isGenerating;

    // Stepper: Custom Endpoints has no separate "Entity Fields" step (the
    // endpoints editor already carries its own request/response field
    // editors inline). Feature Shape can only be flipped from step 0, so a
    // step count shrinking never strands the current step out of range.
    final stepLabels = opts.useCustomEndpoints
        ? const ['Identity & Routing', 'Endpoints']
        : const ['Identity & Routing', 'Architecture Layers', 'Entity Fields'];
    final totalSteps = stepLabels.length;
    final step1Valid = opts.name.isNotEmpty && nameError == null && !parentMissing;

    final stepContent = <Widget>[
      IdentityRoutingStep(
        opts: opts,
        onChanged: formNotifier.update,
        nameCtrl: _nameCtrl,
        labelCtrl: _labelCtrl,
        nameError: nameError,
        enabled: !widget.state.isGenerating,
        canCustomEndpoints: canCustomEndpoints,
        hasNav: hasNav,
        routingEnabled: routingEnabled,
        needsParent: needsParent,
        parentMissing: parentMissing,
        features: project.features,
      ),
      opts.useCustomEndpoints
          ? EndpointsStep(
              opts: opts,
              onChanged: formNotifier.update,
              enabled: !widget.state.isGenerating,
            )
          : ArchitectureLayersStep(
              opts: opts,
              onChanged: formNotifier.update,
              apiPathCtrl: _apiPathCtrl,
              enabled: !widget.state.isGenerating,
              projectHasHttp: projectHasHttp,
              httpClient: c.httpClient,
              storageStrategy: c.storageStrategy,
            ),
      if (!opts.useCustomEndpoints) EntityFieldsStep(opts: opts, onChanged: formNotifier.update),
    ];

    return Column(
      crossAxisAlignment: .start,
      children: [
        // Project header.
        Row(
          children: [
            Icon(
              Icons.folder_special_outlined,
              size: 16,
              color: context.neatColors.colorPrimaryCyan,
            ),
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
                onPressed: widget.state.isGenerating
                    ? null
                    : () async {
                        final result = await FilePicker.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: const ['csv'],
                        );
                        final path = result?.files.single.path;
                        if (path != null) await widget.onImportTranslations(path);
                      },
                icon: const Icon(Icons.translate, size: 14),
                label: const Text('Import i18n', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(foregroundColor: context.neatColors.colorPrimaryCyan),
              ),
            ],
            12.gapW,
            TextButton.icon(
              onPressed: widget.state.isGenerating ? null : widget.onClose,
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
              // Left: the stepper form.
              Expanded(
                flex: 10,
                child: Column(
                  crossAxisAlignment: .start,
                  children: [
                    _StepIndicator(
                      current: formState.step,
                      labels: stepLabels,
                      onSelect: widget.state.isGenerating ? null : formNotifier.setStep,
                    ),
                    16.gapH,
                    Expanded(
                      child: ScrollConfiguration(
                        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                        child: SingleChildScrollView(child: stepContent[formState.step]),
                      ),
                    ),
                    16.gapH,
                    Row(
                      mainAxisAlignment: .spaceBetween,
                      children: [
                        if (formState.step > 0)
                          OutlinedButton.icon(
                            onPressed: widget.state.isGenerating
                                ? null
                                : () => formNotifier.setStep(formState.step - 1),
                            icon: const Icon(Icons.arrow_back, size: 16),
                            label: const Text('Back'),
                            style: TextButton.styleFrom(foregroundColor: Colors.white54),
                          )
                        else
                          const SizedBox.shrink(),
                        if (formState.step < totalSteps - 1)
                          OutlinedButton.icon(
                            onPressed:
                                (formState.step == 0 && !step1Valid) || widget.state.isGenerating
                                ? null
                                : () => formNotifier.setStep(formState.step + 1),
                            icon: const Icon(Icons.arrow_forward, size: 16),
                            label: const Text('Next'),
                            style: FilledButton.styleFrom(
                              backgroundColor: context.neatColors.colorPrimaryCyan,
                              foregroundColor: const Color(0xFF0E0E0E),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              24.gapW,
              // Right: blueprint + generate + logs (fixed across every step).
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: .start,
                  children: [
                    _BlueprintTree(options: opts, contract: c, hasHttp: projectHasHttp),
                    16.gapH,
                    SizedBox(
                      width: .infinity,
                      child: OutlinedButton.icon(
                        onPressed: canGenerate && formState.step == totalSteps - 1
                            ? () => widget.onGenerate(opts)
                            : null,
                        icon: widget.state.isGenerating
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF0E0E0E),
                                ),
                              )
                            : const Icon(Icons.auto_awesome, size: 18),
                        label: Text(widget.state.isGenerating ? 'Generating…' : 'Generate Feature'),
                        style: FilledButton.styleFrom(
                          backgroundColor: context.neatColors.colorPrimaryCyan,
                          foregroundColor: context.neatColors.colorSurfaceCard,
                          padding: const .symmetric(vertical: 18),
                          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    if (widget.state.error != null) ...[
                      12.gapH,
                      Text(
                        widget.state.error!,
                        style: TextStyle(color: Colors.redAccent[100], fontSize: 12),
                      ),
                    ],
                    if (widget.state.logs.isNotEmpty) ...[
                      16.gapH,
                      FeatureTree(
                        isGenerating: widget.state.isGenerating,
                        scrollController: _logsScrollController,
                        logs: widget.state.logs,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

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

// ── Step indicator (Identity+Routing / Layers / Entity Fields) ─────────────────

/// Clickable step breadcrumb for the Workshop form — jumping to any step
/// directly is always allowed (nothing here blocks navigation the way the
/// "Next" button's validation does; the Generate button on the right is the
/// single gate that actually matters).
class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.current, required this.labels, required this.onSelect});

  final int current;
  final List<String> labels;
  final ValueChanged<int>? onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final (i, label) in labels.indexed) ...[
          if (i > 0)
            Expanded(
              child: Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                color: Colors.white12,
              ),
            ),
          InkWell(
            onTap: onSelect == null ? null : () => onSelect!(i),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const .symmetric(vertical: 4, horizontal: 2),
              child: Row(
                mainAxisSize: .min,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == current
                          ? context.neatColors.colorPrimaryCyan
                          : i < current
                          ? context.neatColors.colorPrimaryCyan.withValues(alpha: 0.25)
                          : Colors.white10,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: i == current
                            ? context.neatColors.colorNeutralBg
                            : i < current
                            ? context.neatColors.colorPrimaryCyan
                            : Colors.grey[500],
                      ),
                    ),
                  ),
                  8.gapW,
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: i == current ? Colors.white : Colors.grey[500],
                      fontWeight: i == current ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
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
    final lines = options.useCustomEndpoints
        ? customEndpointsLines(name, options, contract)
        : crudLines(name, hasHttp, options, contract);
    return BluePrintTree(
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
                        : context.neatColors.colorLightGreen.withValues(alpha: 0.85),
                    fontSize: 11.5,
                    height: 1.2,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

// ── Small shared bits ──────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  const _Badge(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const .symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: context.neatColors.colorPrimaryCyan.withValues(alpha: 0.1),
        borderRadius: .circular(6),
        border: .all(color: context.neatColors.colorPrimaryCyan.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: context.neatColors.colorPrimaryCyan,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
