import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:neat/core/theme/app_theme.dart';
import 'package:neat/features/dependencies/domain/constants/dev_preset.dart';
import 'package:neat/features/dependencies/domain/models/pub_package.dart';
import 'package:neat/features/dependencies/presentation/providers/dependencies_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class DependenciesScreen extends HookConsumerWidget {
  const DependenciesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchController = useTextEditingController();

    final query = ref.watch(searchQueryProvider);
    final searchAsync = ref.watch(packageSearchResultsProvider);
    final selectedForDetail = ref.watch(packageForDetailProvider);

    final selectedCount = ref.watch(selectedPackagesProvider.select((l) => l.length));

    return Column(
      crossAxisAlignment: .start,
      children: [
        Row(
          children: [
            const Text(
              'Project Dependencies',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const Spacer(),
            _DevPresetButton(
              onTap: () => ref.read(selectedPackagesProvider.notifier).addAll(devPresetPackages),
            ),
            if (selectedCount > 0) ...[
              const SizedBox(width: 12),
              _PackagesBadgeButton(
                count: selectedCount,
                onTap: () => _showManagedPackagesSheet(context, ref),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Search and add packages from pub.dev to pre-configure your pubspec.yaml.',
          style: TextStyle(color: Colors.grey[400], fontSize: 14),
        ),
        const SizedBox(height: 24),

        TextField(
          controller: searchController,
          onChanged: ref.read(searchQueryProvider.notifier).update,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Search packages on pub.dev...',
            prefixIcon: const Icon(Icons.search, color: AppTheme.colorPrimaryCyan, size: 20),
            suffixIcon: query.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey, size: 18),
                    onPressed: () {
                      searchController.clear();
                      ref.read(searchQueryProvider.notifier).clear();
                    },
                  )
                : null,
          ),
        ),
        const SizedBox(height: 24),

        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: _SearchResults(
                  searchAsync: searchAsync,
                  query: query,
                  selectedForDetail: selectedForDetail,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 4,
                child: selectedForDetail != null
                    ? _PackageDetailCard(package: selectedForDetail)
                    : _EmptyDetailCard(hasQuery: query.isNotEmpty),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),
      ],
    );
  }

  void _showManagedPackagesSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) =>
          UncontrolledProviderScope(container: ref.container, child: const _ManagedPackagesSheet()),
    );
  }
}

// ── Dev preset button ─────────────────────────────────────────────────────────

class _DevPresetButton extends StatelessWidget {
  const _DevPresetButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1E),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white24),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bolt, color: Colors.white54, size: 16),
            SizedBox(width: 6),
            Text(
              'Dev Preset',
              style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Badge button ──────────────────────────────────────────────────────────────

class _PackagesBadgeButton extends StatelessWidget {
  const _PackagesBadgeButton({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1E),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.colorPrimaryCyan),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.archive_outlined, color: AppTheme.colorPrimaryCyan, size: 18),
                const SizedBox(width: 8),
                Text(
                  '$count Package${count > 1 ? 's' : ''}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: AppTheme.colorPrimaryCyan,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bottom sheet ──────────────────────────────────────────────────────────────

class _ManagedPackagesSheet extends ConsumerWidget {
  const _ManagedPackagesSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packages = ref.watch(selectedPackagesProvider);

    return Container(
      margin: const EdgeInsets.fromLTRB(40, 0, 40, 40),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              children: [
                const Icon(Icons.archive_outlined, color: AppTheme.colorPrimaryCyan, size: 20),
                const SizedBox(width: 10),
                const Text(
                  'Manage Dependencies',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white10, height: 1),
          if (packages.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Text('No packages added yet.', style: TextStyle(color: Colors.grey)),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 360),
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.all(16),
                itemCount: packages.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (_, i) => _SheetPackageTile(package: packages[i]),
              ),
            ),
          const Divider(color: Colors.white10, height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back to Search'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
                      widget.package.isDev ? 'dev_dependency' : 'dependency',
                      style: TextStyle(
                        color: widget.package.isDev
                            ? const Color(0xFFFFA726)
                            : AppTheme.colorPrimaryCyan,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 20),
            onPressed: () => ref.read(selectedPackagesProvider.notifier).toggle(widget.package),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

// ── Résultats de recherche ────────────────────────────────────────────────────

class _SearchResults extends ConsumerWidget {
  const _SearchResults({
    required this.searchAsync,
    required this.query,
    required this.selectedForDetail,
  });

  final AsyncValue<List<PubPackage>> searchAsync;
  final String query;
  final PubPackage? selectedForDetail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (searchAsync) {
      AsyncData(:final value) => _buildList(value, ref),
      AsyncError() => Center(
        child: Text('Error connecting to pub.dev', style: TextStyle(color: Colors.redAccent[100])),
      ),
      _ => const Center(child: CircularProgressIndicator(color: AppTheme.colorPrimaryCyan)),
    };
  }

  Widget _buildList(List<PubPackage> packages, WidgetRef ref) {
    if (query.isEmpty) {
      return const _Placeholder(icon: Icons.search, message: 'Start typing to search packages.');
    }
    if (packages.isEmpty) {
      return _Placeholder(icon: Icons.inbox_outlined, message: "No packages found for '$query'.");
    }

    return ListView.separated(
      itemCount: packages.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final pkg = packages[i];
        final isSelected = selectedForDetail?.name == pkg.name;
        final selectedPkg = ref.watch(
          selectedPackagesProvider.select(
            (list) =>
                list.cast<PubPackage?>().firstWhere((p) => p!.name == pkg.name, orElse: () => null),
          ),
        );
        return _PackageListTile(
          package: pkg,
          isSelected: isSelected,
          isAdded: selectedPkg != null,
          isDev: selectedPkg?.isDev ?? false,
          onTap: () => ref.read(packageForDetailProvider.notifier).select(pkg),
        );
      },
    );
  }
}

class _PackageListTile extends StatelessWidget {
  const _PackageListTile({
    required this.package,
    required this.isSelected,
    required this.isAdded,
    required this.isDev,
    required this.onTap,
  });

  final PubPackage package;
  final bool isSelected;
  final bool isAdded;
  final bool isDev;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF141416),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.colorPrimaryCyan : Colors.white10,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        package.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _VersionBadge(version: package.version),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    package.description,
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isAdded) ...[
              if (isDev)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D2010),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFFFFA726), width: 0.5),
                  ),
                  child: const Text(
                    'dev',
                    style: TextStyle(color: Color(0xFFFFA726), fontSize: 10),
                  ),
                ),
              const Icon(Icons.check_circle, color: AppTheme.colorPrimaryCyan, size: 20),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Detail card ───────────────────────────────────────────────────────────────

class _PackageDetailCard extends ConsumerWidget {
  const _PackageDetailCard({required this.package});

  final PubPackage package;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPkg = ref.watch(
      selectedPackagesProvider.select(
        (list) =>
            list.cast<PubPackage?>().firstWhere((p) => p!.name == package.name, orElse: () => null),
      ),
    );
    final isAdded = selectedPkg != null;
    final isDev = selectedPkg?.isDev ?? package.isDev;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF18181C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  package.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _VersionBadge(version: package.version),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            package.description,
            style: TextStyle(color: Colors.grey[400], fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _MetricBadge(label: 'LIKES', value: _formatCount(package.likes)),
              const SizedBox(width: 12),
              _MetricBadge(label: 'PUB POINTS', value: '${package.pubPoints}'),
              const SizedBox(width: 12),
              _MetricBadge(label: 'POPULARITY', value: '${package.popularity}%'),
            ],
          ),
          const SizedBox(height: 20),
          _DevToggle(
            packageName: package.name,
            isDev: isDev,
            isAdded: isAdded,
            onChanged: (value) {
              if (isAdded) {
                ref.read(selectedPackagesProvider.notifier).setDev(package.name, isDev: value);
              }
            },
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.colorPrimaryCyan,
                      side: const BorderSide(color: AppTheme.colorPrimaryCyan),
                    ),
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text('View on pub.dev'),
                    onPressed: () => _launchPubDev(package.name),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isAdded
                          ? const Color(0xFF2A1A1A)
                          : AppTheme.colorPrimaryCyan,
                      foregroundColor: isAdded ? Colors.redAccent : AppTheme.colorNeutralBg,
                      side: isAdded ? const BorderSide(color: Colors.redAccent) : BorderSide.none,
                    ),
                    icon: Icon(isAdded ? Icons.remove_circle_outline : Icons.add, size: 18),
                    label: Text(isAdded ? 'Remove' : 'Add'),
                    onPressed: () => ref
                        .read(selectedPackagesProvider.notifier)
                        .toggle(package.copyWith(isDev: isDev)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatCount(int count) =>
      count >= 1000 ? '${(count / 1000).toStringAsFixed(1)}k' : '$count';

  Future<void> _launchPubDev(String packageName) async {
    final url = Uri.parse('https://pub.dev/packages/$packageName');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}

// ── Widgets utilitaires ───────────────────────────────────────────────────────

class _VersionBadge extends StatelessWidget {
  const _VersionBadge({required this.version});

  final String version;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.colorSecondaryBlue,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'v$version',
        style: const TextStyle(color: AppTheme.colorPrimaryCyan, fontSize: 11),
      ),
    );
  }
}

class _MetricBadge extends StatelessWidget {
  const _MetricBadge({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF141416),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(color: Colors.grey[500], fontSize: 10, letterSpacing: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _DevToggle extends StatelessWidget {
  const _DevToggle({
    required this.packageName,
    required this.isDev,
    required this.isAdded,
    required this.onChanged,
  });

  final String packageName;
  final bool isDev;
  final bool isAdded;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                  isDev ? 'dev_dependencies' : 'dependencies',
                  style: TextStyle(
                    color: isDev ? const Color(0xFFFFA726) : AppTheme.colorPrimaryCyan,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isDev ? 'Build-time only (generators, linters…)' : 'Shipped with the app',
                  style: TextStyle(color: Colors.grey[600], fontSize: 11),
                ),
              ],
            ),
          ),
          Switch(
            value: isDev,
            onChanged: isAdded ? onChanged : null,
            activeThumbColor: const Color(0xFFFFA726),
            activeTrackColor: const Color(0xFF3D2A10),
            inactiveThumbColor: AppTheme.colorPrimaryCyan,
            inactiveTrackColor: AppTheme.colorSecondaryBlue,
          ),
        ],
      ),
    );
  }
}

class _EmptyDetailCard extends StatelessWidget {
  const _EmptyDetailCard({required this.hasQuery});

  final bool hasQuery;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF18181C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: _Placeholder(
        icon: Icons.open_in_new_outlined,
        message: hasQuery ? 'Click a package to see details.' : 'Search a package first.',
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white12, size: 40),
          const SizedBox(height: 12),
          Text(message, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        ],
      ),
    );
  }
}
