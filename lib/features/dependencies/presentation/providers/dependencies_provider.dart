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
  List<PubPackage> build() => restPreset;

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
  ///
  /// [preset] (restPreset/supabasePreset/etc.) still carries Riverpod by
  /// default for backward compatibility, but if the user already switched to
  /// Bloc via [applyStateManagementPreset], that choice must survive a backend
  /// switch — so any state-management package in [preset] is skipped whenever
  /// the current manifest already has *some* state management selected
  /// (regardless of which family), mirroring how backend switching never
  /// touches [RoutingStyle] either.
  void applyBackendPreset(List<PubPackage> preset) {
    final stripped =
        state.where((p) => !backendMarkerPackages.contains(p.name)).toList();
    final hasStateManagement =
        stripped.any((p) => stateManagementMarkerPackages.contains(p.name));
    final existing = {for (final p in stripped) p.name};
    final toAdd = preset.where((p) =>
        !existing.contains(p.name) &&
        !isUnsupportedPackage(p.name) &&
        !(hasStateManagement && stateManagementMarkerPackages.contains(p.name)));
    state = [...stripped, ...toAdd];
  }

  /// Switches the REST HTTP client (chopper/dio) — same strip-then-add
  /// mechanism as [applyBackendPreset], just named for its own call sites
  /// (infrastructure_screen.dart's client picker, only shown for
  /// `BackendKind.rest`).
  void applyHttpClientPreset(List<PubPackage> preset) => applyBackendPreset(preset);

  /// Switches state management (Riverpod/Bloc) — independent of the backend/
  /// HTTP client choice, the same strip-then-add mechanism scoped to
  /// [stateManagementMarkerPackages] only (mirrors [applyBackendPreset]).
  void applyStateManagementPreset(List<PubPackage> preset) {
    final stripped =
        state.where((p) => !stateManagementMarkerPackages.contains(p.name)).toList();
    final existing = {for (final p in stripped) p.name};
    final toAdd =
        preset.where((p) => !existing.contains(p.name) && !isUnsupportedPackage(p.name));
    state = [...stripped, ...toAdd];
  }

  /// Switches routing style: adds/removes go_router_builder — a plain add/
  /// remove rather than a strip-then-add preset swap, since it just layers on
  /// top of the always-present go_router rather than replacing anything.
  void setRoutingStyle(RoutingStyle style) {
    final hasBuilder = isSelected('go_router_builder');
    if (style == RoutingStyle.typed && !hasBuilder) {
      state = [...state, goRouterBuilderPackage];
    } else if (style == RoutingStyle.manual && hasBuilder) {
      state = state.where((p) => p.name != 'go_router_builder').toList();
    }
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
