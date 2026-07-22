import 'package:neat/core/contract/neat_contract.dart';
import 'package:neat/features/feature_gen/domain/models/feature_gen_options.dart';

/// The existing entity + CRUD preview.
List<String> crudLines(
  String name,
  bool hasHttp,
  FeatureGenOptions options,
  NeatContract contract,
) {
  final remote = hasHttp && options.includeRemoteDataSource;
  // Mirrors FeatureScaffolder's writeLocal exactly: a local source is only
  // written for the offline-first 3-source repo (remote + a project that
  // actually ships Drift), or a genuinely local-only feature (no remote,
  // Local Data Source explicitly on) — never forced on just because remote
  // is off (that made the toggle meaningless — see ROADMAP.md).
  final localIsDrift = contract.storageStrategy != 'remoteOnly';
  final local = options.includeLocalDataSource && (!remote || localIsDrift);
  final hasAnyDataSource = remote || local;

  // Merge into parent (opt-in, child routes only — see FeatureGenOptions
  // .mergeIntoParent / FeatureScaffolder's mergeBase): own entity/repository
  // /datasource, but nested in a "$name/" subfolder per layer inside the
  // parent's own package/folder instead of a separate feature.
  if (options.routing == FeatureRouting.child &&
      options.mergeIntoParent &&
      options.parentFeature.isNotEmpty) {
    return [
      '${options.parentFeature}/ (merged)',
      if (hasAnyDataSource) ...[
        '├── data/',
        '│   └── $name/',
        '│       ├── sources/',
        if (remote) '│       │   ├── ${name}_api_source.dart',
        if (local) '│       │   └── ${name}_local_source.dart',
        '│       ├── models/',
        '│       └── repositories/',
      ],
      '├── domain/',
      '│   └── $name/',
      '│       ├── entities/',
      if (hasAnyDataSource) '│       ├── repositories/',
      if (options.includeUseCase && hasAnyDataSource) '│       └── usecases/',
      '└── presentation/',
      '    └── $name/',
      '        ├── pages/',
      '        ├── providers/',
      '        └── widgets/',
    ];
  }

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
    if (contract.navigation != 'none' && options.routing == FeatureRouting.root) '    ├── routes/',
    '    └── widgets/',
  ];
}

/// Custom Endpoints (ROADMAP.md §7 Phase 2): no entity, no repository, no
/// local source — mirrors FeatureScaffolder's useCustomEndpoints branch
/// exactly. Models only for endpoints that actually have a body.
List<String> customEndpointsLines(String name, FeatureGenOptions options, NeatContract contract) {
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
    for (final e in endpoints) '│       ├── ${e.name.isEmpty ? '<endpoint>' : e.name}_usecase.dart',
    '└── presentation/',
    '    ├── pages/',
    '    ├── providers/',
    if (contract.navigation != 'none' && options.routing == FeatureRouting.root) '    ├── routes/',
    '    └── widgets/',
  ];
}
