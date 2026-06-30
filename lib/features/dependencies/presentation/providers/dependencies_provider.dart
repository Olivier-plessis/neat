import 'dart:async';

import 'package:neat/features/dependencies/domain/constants/backend_presets.dart';
import 'package:neat/features/dependencies/domain/constants/unsupported_packages.dart';
import 'package:neat/features/dependencies/domain/models/pub_package.dart';
import 'package:neat/features/dependencies/domain/usecases/search_packages_usecase.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dependencies_provider.g.dart';

// ── Query avec debounce intégré ───────────────────────────────────────────────

@riverpod
class SearchQuery extends _$SearchQuery {
  Timer? _timer;

  @override
  String build() {
    ref.onDispose(() => _timer?.cancel());
    return '';
  }

  void update(String query) {
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 400), () {
      state = query;
      if (query.trim().isEmpty) {
        ref.read(packageForDetailProvider.notifier).state = null;
      }
    });
  }

  void clear() {
    _timer?.cancel();
    _timer = null;
    state = '';
    ref.read(packageForDetailProvider.notifier).state = null;
  }
}

// ── Résultats de recherche ────────────────────────────────────────────────────

@riverpod
Future<List<PubPackage>> packageSearchResults(Ref ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.trim().isEmpty) return [];

  final useCase = ref.read(searchPackagesUseCaseProvider);
  final result = await useCase(query);
  return result.getOrDefault([]);
}

// ── Package affiché dans la detail card ──────────────────────────────────────

@riverpod
class PackageForDetail extends _$PackageForDetail {
  @override
  PubPackage? build() => null;

  void select(PubPackage package) => state = package;
}

// ── Packages sélectionnés pour le projet (persist entre steps) ───────────────

@Riverpod(keepAlive: true)
class SelectedPackages extends _$SelectedPackages {
  @override
  List<PubPackage> build() => [];

  void toggle(PubPackage package) {
    final isSelected = state.any((p) => p.name == package.name);
    // Removing is always allowed; adding an unsupported package is a no-op.
    if (!isSelected && isUnsupportedPackage(package.name)) return;
    state = isSelected
        ? state.where((p) => p.name != package.name).toList()
        : [...state, package];
  }

  void addAll(List<PubPackage> packages) {
    final existing = {for (final p in state) p.name};
    final toAdd = packages
        .where((p) => !existing.contains(p.name) && !isUnsupportedPackage(p.name));
    state = [...state, ...toAdd];
  }

  /// Switches the backend: strips all backend-specific packages, then adds the
  /// chosen backend's base preset (keeping any non-backend packages the user
  /// already picked). The manifest remains the source of truth for generation.
  void applyBackendPreset(List<PubPackage> preset) {
    final stripped =
        state.where((p) => !backendMarkerPackages.contains(p.name)).toList();
    final existing = {for (final p in stripped) p.name};
    final toAdd =
        preset.where((p) => !existing.contains(p.name) && !isUnsupportedPackage(p.name));
    state = [...stripped, ...toAdd];
  }

  void setDev(String name, {required bool isDev}) {
    state = state
        .map((p) => p.name == name ? p.copyWith(isDev: isDev) : p)
        .toList();
  }

  void remove(String name) =>
      state = state.where((p) => p.name != name).toList();

  void setVersion(String name, String version) {
    final v = version.trim();
    if (v.isEmpty) return;
    state = state
        .map((p) => p.name == name ? p.copyWith(version: v) : p)
        .toList();
  }

  bool isSelected(String name) => state.any((p) => p.name == name);
}
