import 'package:flutter/material.dart';
import 'package:neat/features/feature_gen/domain/models/feature_gen_options.dart';
import 'package:neat/features/feature_gen/presentation/utils/field_decoration.dart';
import 'package:neat/features/feature_gen/presentation/widgets/crud_endpoint_row.dart';
import 'package:neat/features/feature_gen/presentation/widgets/layer_toggle.dart';
import 'package:neat/features/generation/domain/models/crud_endpoint_overrides.dart';
import 'package:neat_ui/neat_ui.dart';

/// Step 2 (Entity + CRUD mode): which Clean Architecture layers to scaffold
/// (Remote/Local Data Source, Domain UseCase, Data Mapper — always on), the
/// API path, and the opt-in "Customize endpoints" per-operation method+path
/// (chopper only — see CrudEndpointOverrides' own doc for why).
///
/// Purely presentational — the "keep the 5 operations' paths synced to the
/// shared API Path field" logic used to live here as a reactive useEffect
/// (which could fire mid-build and crash); it's now a direct event handler
/// on the API Path TextField's own controller listener, in
/// FeatureFormController.setApiPath, so this widget has nothing left to
/// synchronize itself.
class ArchitectureLayersStep extends StatelessWidget {
  const ArchitectureLayersStep({
    required this.opts,
    required this.onChanged,
    required this.apiPathCtrl,
    required this.enabled,
    required this.projectHasHttp,
    required this.httpClient,
    required this.storageStrategy,
    super.key,
  });

  final FeatureGenOptions opts;
  final ValueChanged<FeatureGenOptions> onChanged;
  final TextEditingController apiPathCtrl;
  final bool enabled;
  final bool projectHasHttp;
  final String httpClient;
  final String storageStrategy;

  @override
  Widget build(BuildContext context) {
    // Deliberately doesn't fall back to the feature name here (unlike the
    // "Default REST path" hint below, which describes the *generated*
    // fallback for the non-customized case) — with nothing typed in API
    // Path, these 5 fields show a plain, generic "type something" hint
    // instead of a guessed value, so nothing here is derived from the
    // feature name.
    final hasApiPath = opts.apiPath.isNotEmpty;
    final pathHint = hasApiPath ? opts.apiPath : '/endpoint';
    final idPathHint = hasApiPath ? '${opts.apiPath}/{id}' : '/endpoint/{id}';

    // Only relative paths need the leading slash — an absolute URL (see the
    // hint text below) overrides the API Base URL entirely and has its own
    // scheme instead.
    final apiPathError =
        opts.apiPath.isNotEmpty &&
            !opts.apiPath.startsWith('/') &&
            !opts.apiPath.startsWith('http://') &&
            !opts.apiPath.startsWith('https://')
        ? 'Relative paths must start with a slash, e.g. /products'
        : null;

    return Column(
      crossAxisAlignment: .start,
      children: [
        const SectionHeader(icon: Icons.layers, label: 'Architecture Layers'),
        10.gapH,
        LayerToggle(
          title: 'Remote Data Source',
          subtitle: projectHasHttp
              ? 'Generates the $httpClient API source & CRUD.'
              : 'Project has no HTTP client — unavailable.',
          value: projectHasHttp && opts.includeRemoteDataSource,
          enabled: projectHasHttp && enabled,
          onChanged: (v) => onChanged(opts.copyWith(includeRemoteDataSource: v)),
        ),
        if (projectHasHttp && opts.includeRemoteDataSource) ...[
          10.gapH,
          TextField(
            controller: apiPathCtrl,
            enabled: enabled,
            style: const TextStyle(color: Colors.white),
            decoration: fieldDecoration(
              'API Path (optional) — e.g. /products',
              apiPathError,
              context,
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
        // Opt-in (chopper only): each of the 5 fixed CRUD operations gets its
        // own method + path instead of all 5 sharing the API Path above — for
        // APIs like dummyjson's recipes, which create via POST /recipes/add
        // rather than POST /recipes.
        if (projectHasHttp && httpClient == 'chopper' && opts.includeRemoteDataSource) ...[
          8.gapH,
          LayerToggle(
            title: 'Customize endpoints',
            subtitle:
                'Set each operation\'s own method + path '
                '(e.g. POST /products/add to create).',
            value: opts.customizeEndpoints,
            enabled: enabled,
            onChanged: (v) => onChanged(
              v
                  // Pre-fill real, editable values when there's an API Path
                  // to derive them from — otherwise every operation that
                  // doesn't actually differ still needs retyping by hand.
                  // With nothing typed yet, leave paths blank (just the
                  // hint shows) rather than guessing from the feature name.
                  ? opts.copyWith(
                      customizeEndpoints: true,
                      endpointOverrides: hasApiPath
                          ? CrudEndpointOverrides.defaultsFor(opts.apiPath)
                          : const CrudEndpointOverrides(),
                    )
                  : opts.copyWith(customizeEndpoints: false),
            ),
          ),
          if (opts.customizeEndpoints) ...[
            8.gapH,
            DecoratedBox(
              decoration: BoxDecoration(
                color: context.neatColors.colorSurfaceCard,
                borderRadius: .circular(10),
                border: .all(color: context.neatColors.surface10),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Column(
                  children: [
                    CrudEndpointRow(
                      key: const ValueKey('getAll'),
                      label: 'Get All',
                      name: opts.endpointOverrides.getAllName,
                      method: opts.endpointOverrides.getAllMethod,
                      path: opts.endpointOverrides.getAllPath,
                      pathHint: pathHint,
                      enabled: enabled,
                      onName: (v) => onChanged(
                        opts.copyWith(
                          endpointOverrides: opts.endpointOverrides.copyWith(getAllName: v),
                        ),
                      ),
                      onMethod: (m) => onChanged(
                        opts.copyWith(
                          endpointOverrides: opts.endpointOverrides.copyWith(getAllMethod: m),
                        ),
                      ),
                      onPath: (v) => onChanged(
                        opts.copyWith(
                          endpointOverrides: opts.endpointOverrides.copyWith(getAllPath: v),
                        ),
                      ),
                    ),
                    const Divider(height: 1, color: Colors.white10),
                    CrudEndpointRow(
                      key: const ValueKey('getById'),
                      label: 'Get By Id',
                      name: opts.endpointOverrides.getByIdName,
                      method: opts.endpointOverrides.getByIdMethod,
                      path: opts.endpointOverrides.getByIdPath,
                      pathHint: idPathHint,
                      enabled: enabled,
                      onName: (v) => onChanged(
                        opts.copyWith(
                          endpointOverrides: opts.endpointOverrides.copyWith(getByIdName: v),
                        ),
                      ),
                      onMethod: (m) => onChanged(
                        opts.copyWith(
                          endpointOverrides: opts.endpointOverrides.copyWith(getByIdMethod: m),
                        ),
                      ),
                      onPath: (v) => onChanged(
                        opts.copyWith(
                          endpointOverrides: opts.endpointOverrides.copyWith(getByIdPath: v),
                        ),
                      ),
                    ),
                    const Divider(height: 1, color: Colors.white10),
                    CrudEndpointRow(
                      key: const ValueKey('create'),
                      label: 'Create',
                      name: opts.endpointOverrides.createName,
                      method: opts.endpointOverrides.createMethod,
                      path: opts.endpointOverrides.createPath,
                      pathHint: pathHint,
                      enabled: enabled,
                      onName: (v) => onChanged(
                        opts.copyWith(
                          endpointOverrides: opts.endpointOverrides.copyWith(createName: v),
                        ),
                      ),
                      onMethod: (m) => onChanged(
                        opts.copyWith(
                          endpointOverrides: opts.endpointOverrides.copyWith(createMethod: m),
                        ),
                      ),
                      onPath: (v) => onChanged(
                        opts.copyWith(
                          endpointOverrides: opts.endpointOverrides.copyWith(createPath: v),
                        ),
                      ),
                    ),
                    const Divider(height: 1, color: Colors.white10),
                    CrudEndpointRow(
                      key: const ValueKey('update'),
                      label: 'Update',
                      name: opts.endpointOverrides.updateName,
                      method: opts.endpointOverrides.updateMethod,
                      path: opts.endpointOverrides.updatePath,
                      pathHint: idPathHint,
                      enabled: enabled,
                      onName: (v) => onChanged(
                        opts.copyWith(
                          endpointOverrides: opts.endpointOverrides.copyWith(updateName: v),
                        ),
                      ),
                      onMethod: (m) => onChanged(
                        opts.copyWith(
                          endpointOverrides: opts.endpointOverrides.copyWith(updateMethod: m),
                        ),
                      ),
                      onPath: (v) => onChanged(
                        opts.copyWith(
                          endpointOverrides: opts.endpointOverrides.copyWith(updatePath: v),
                        ),
                      ),
                    ),
                    const Divider(height: 1, color: Colors.white10),
                    CrudEndpointRow(
                      key: const ValueKey('delete'),
                      label: 'Delete',
                      name: opts.endpointOverrides.deleteName,
                      method: opts.endpointOverrides.deleteMethod,
                      path: opts.endpointOverrides.deletePath,
                      pathHint: idPathHint,
                      enabled: enabled,
                      onName: (v) => onChanged(
                        opts.copyWith(
                          endpointOverrides: opts.endpointOverrides.copyWith(deleteName: v),
                        ),
                      ),
                      onMethod: (m) => onChanged(
                        opts.copyWith(
                          endpointOverrides: opts.endpointOverrides.copyWith(deleteMethod: m),
                        ),
                      ),
                      onPath: (v) => onChanged(
                        opts.copyWith(
                          endpointOverrides: opts.endpointOverrides.copyWith(deletePath: v),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
        LayerToggle(
          title: 'Local Data Source',
          subtitle: storageStrategy == 'remoteOnly'
              ? 'In-memory cache stub.'
              : 'Drift-backed local cache (typed table injected).',
          value: opts.includeLocalDataSource,
          enabled: enabled,
          onChanged: (v) => onChanged(opts.copyWith(includeLocalDataSource: v)),
        ),
        LayerToggle(
          title: 'Domain UseCase',
          subtitle: 'Business logic classes with Result<T> return type.',
          value: opts.includeUseCase,
          enabled: enabled,
          onChanged: (v) => onChanged(opts.copyWith(includeUseCase: v)),
        ),
        const LayerToggle(
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
      ],
    );
  }
}
