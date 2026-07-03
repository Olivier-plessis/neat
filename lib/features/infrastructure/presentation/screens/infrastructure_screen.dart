import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:neat/core/theme/app_theme.dart';
import 'package:neat/core/theme/gap.dart';
import 'package:neat/core/theme/padding.dart';
import 'package:neat/features/architecture/domain/models/env_config.dart';
import 'package:neat/features/architecture/presentation/providers/architecture_provider.dart';
import 'package:neat/features/dependencies/domain/constants/backend_presets.dart';
import 'package:neat/features/dependencies/domain/models/pub_package.dart';
import 'package:neat/features/dependencies/presentation/providers/dependencies_provider.dart';
import 'package:neat/features/identity/presentation/providers/identity_provider.dart';

class InfrastructureScreen extends ConsumerWidget {
  const InfrastructureScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Project Infrastructure',
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 8),
        Text(
          'Pick a backend to seed your stack — its preset packages appear on the right.',
          style: TextStyle(color: Colors.grey[400], fontSize: 14),
        ),
        const SizedBox(height: 24),

        const _BackendSelector(),

        const SizedBox(height: 24),

        const Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 6, child: _BackendConfig()),
              SizedBox(width: 20),
              Expanded(flex: 4, child: _ManagedPackagesPanel()),
            ],
          ),
        ),
        const SizedBox(height: 20),
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
            iconColor: AppTheme.colorPrimaryCyan,
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
    this.fontSize = 16,
    this.disabled = false,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool active;
  final VoidCallback onTap;
  final double fontSize;

  /// Visible but not selectable (e.g. a client the generation harness hasn't
  /// validated yet) — mirrors architecture_screen.dart's _PatternCard.
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
            color: active ? AppTheme.colorPrimaryCyan : Colors.white10,
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
            Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
            const SizedBox(height: 12),
            if (active)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.check_circle, color: AppTheme.colorPrimaryCyan, size: 14),
                  SizedBox(width: 6),
                  Text(
                    'SELECTED',
                    style: TextStyle(
                      color: AppTheme.colorPrimaryCyan,
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

// ── Backend configuration (environments + per-backend credentials) ──────────────

class _BackendConfig extends ConsumerWidget {
  const _BackendConfig();

  Future<void> _pickFirebaseConfig(WidgetRef ref) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );
    final path = result?.files.single.path;
    if (path != null) ref.read(architectureProvider.notifier).setFirebaseConfigPath(path);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backend = ref.watch(selectedPackagesProvider.select(backendOf));
    final httpClient = ref.watch(selectedPackagesProvider.select(httpClientOf));
    final routingStyle = ref.watch(selectedPackagesProvider.select(routingStyleOf));
    final packagesNotifier = ref.read(selectedPackagesProvider.notifier);
    final arch = ref.watch(architectureProvider);
    final notifier = ref.read(architectureProvider.notifier);
    final platforms = ref.watch(identityProvider.select((s) => s.targetPlatforms));
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
              Text(
                'Select your favorite Http client: ',
                style: TextStyle(color: Colors.grey[400], fontSize: 15),
              ).paddedV(16),
              Row(
                spacing: 16,
                children: [
                  Flexible(
                    flex: 6,
                    child: _BackendCard(
                      icon: Icons.local_fire_department,
                      iconColor: const Color(0xFFFFA000),
                      title: 'Chopper',
                      subtitle: '',
                      active: httpClient == HttpClientKind.chopper,
                      onTap: () => packagesNotifier.applyHttpClientPreset(
                        presetForHttpClient(HttpClientKind.chopper),
                      ),
                    ),
                  ),
                  Flexible(
                    flex: 6,
                    child: _BackendCard(
                      icon: Icons.api_outlined,
                      iconColor: AppTheme.colorPrimaryCyan,
                      title: 'Dio',
                      subtitle: '',
                      active: httpClient == HttpClientKind.dio,
                      onTap: () => packagesNotifier.applyHttpClientPreset(
                        presetForHttpClient(HttpClientKind.dio),
                      ),
                    ),
                  ),
                  Flexible(
                    flex: 6,
                    child: Tooltip(
                      message:
                          'Not selectable yet — its API-source path has no generation-harness coverage.',
                      child: _BackendCard(
                        icon: Icons.bolt,
                        iconColor: const Color(0xFF3ECF8E),
                        title: 'Retrofit',
                        subtitle: '',
                        active: false,
                        disabled: true,
                        onTap: () {},
                      ),
                    ),
                  ),
                ],
              ),
              24.gapH,
            ],
            Text(
              'Routing style: ',
              style: TextStyle(color: Colors.grey[400], fontSize: 15),
            ).paddedV(16),
            Row(
              spacing: 16,
              children: [
                Flexible(
                  flex: 6,
                  child: _BackendCard(
                    icon: Icons.edit_road_outlined,
                    iconColor: AppTheme.colorPrimaryCyan,
                    title: 'Manual',
                    subtitle: 'Hand-written GoRoute list',
                    active: routingStyle == RoutingStyle.manual,
                    onTap: () => packagesNotifier.setRoutingStyle(RoutingStyle.manual),
                  ),
                ),
                Flexible(
                  flex: 6,
                  child: _BackendCard(
                    icon: Icons.route_outlined,
                    iconColor: const Color(0xFF3ECF8E),
                    title: 'Typed',
                    subtitle: 'go_router_builder codegen',
                    active: routingStyle == RoutingStyle.typed,
                    onTap: () => packagesNotifier.setRoutingStyle(RoutingStyle.typed),
                  ),
                ),
              ],
            ),
            24.gapH,
            Row(
              children: [
                Text('Configuration: ', style: TextStyle(color: Colors.grey[400], fontSize: 15)),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppTheme.colorPrimaryCyan,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (backend == BackendKind.firebase) ...[
              _FirebaseConfigUpload(
                path: arch.firebaseConfigPath,
                onPick: () => _pickFirebaseConfig(ref),
                onClear: () => notifier.setFirebaseConfigPath(''),
              ),
            ] else ...[
              for (var i = 0; i < arch.environments.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  // Key by backend so switching REST↔Supabase re-seeds each
                  // field's initialValue (the row's State is otherwise reused,
                  // leaking the previous backend's text into the new fields).
                  child: _EnvFieldRow(
                    key: ValueKey('cfg_${backend.name}_$i'),
                    env: arch.environments[i],
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
                  style: TextButton.styleFrom(foregroundColor: AppTheme.colorPrimaryCyan),
                ),
            ],
            const SizedBox(height: 4),
            _FlavorsToggle(
              value: arch.generateFlavors && flavorsAvailable,
              enabled: flavorsAvailable,
              note: flavorsSupported
                  ? (envCount < 2 ? 'Add a 2nd environment to enable native flavors.' : null)
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
      borderSide: BorderSide(color: AppTheme.colorPrimaryCyan.withValues(alpha: 0.5)),
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
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: isBase ? AppTheme.colorPrimaryCyan.withValues(alpha: 0.12) : null,
                    border: Border.all(
                      color: isBase
                          ? AppTheme.colorPrimaryCyan.withValues(alpha: 0.5)
                          : Colors.white12,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'BASE',
                    style: TextStyle(
                      color: isBase ? AppTheme.colorPrimaryCyan : Colors.white24,
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
            Expanded(child: _field(env.supabaseUrl, 'Supabase URL', onSupabaseUrl)),
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
            Expanded(child: _field(env.apiBaseUrl, 'API base URL (optional)', onApiUrl)),
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

class _FlavorsToggle extends StatelessWidget {
  const _FlavorsToggle({
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.note,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  /// Optional hint shown under the title (e.g. why the toggle is disabled).
  final String? note;

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
                  'Native build flavors (Android/iOS)',
                  style: TextStyle(color: titleColor, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  note ??
                      'productFlavors + per-flavor app id. OFF → envs run as Dart '
                          'entry points and a plain `flutter run` works.',
                  style: TextStyle(color: Colors.grey[500], fontSize: 11),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: enabled ? onChanged : null,
            activeTrackColor: AppTheme.colorPrimaryCyan,
          ),
        ],
      ),
    );
  }
}

class _FirebaseConfigUpload extends StatelessWidget {
  const _FirebaseConfigUpload({required this.path, required this.onPick, required this.onClear});

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
              color: hasFile ? AppTheme.colorPrimaryCyan : Colors.grey[500],
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                hasFile ? path.split('/').last : 'Firebase config (JSON) — optional',
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
                foregroundColor: AppTheme.colorPrimaryCyan,
                side: BorderSide(color: AppTheme.colorPrimaryCyan.withValues(alpha: 0.5)),
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
                const Icon(Icons.inventory_2_outlined, color: AppTheme.colorPrimaryCyan, size: 16),
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
                child: Text('No packages added yet.', style: TextStyle(color: Colors.grey)),
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
    ref.read(selectedPackagesProvider.notifier).setVersion(widget.package.name, _ctrl.text);
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
                              style: const TextStyle(color: Colors.white, fontSize: 12),
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
                                  borderSide: const BorderSide(color: AppTheme.colorPrimaryCyan),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(4),
                                  borderSide: const BorderSide(color: AppTheme.colorPrimaryCyan),
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
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2A2A2E),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.white12),
                              ),
                              child: Text(
                                widget.package.version,
                                style: const TextStyle(
                                  color: AppTheme.colorPrimaryCyan,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                    const SizedBox(width: 8),
                    Container(
                      width: 3,
                      height: 3,
                      decoration: BoxDecoration(color: Colors.grey[600], shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.package.isDev ? 'dev' : 'dep',
                      style: TextStyle(
                        color: widget.package.isDev
                            ? const Color(0xFFFFA726)
                            : AppTheme.colorPrimaryCyan,
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
