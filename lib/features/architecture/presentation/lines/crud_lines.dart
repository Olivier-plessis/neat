import 'package:neat/core/contract/neat_contract.dart';
import 'package:neat/features/feature_gen/domain/models/feature_gen_options.dart';
import 'package:neat/features/generation/domain/services/templates/dart/field_codegen.dart';

/// The entity + CRUD preview: the feature's own tree (a folder under
/// `lib/features/`, or — packageSplit — a workspace package under `packages/`),
/// then the files it adds elsewhere: the Drift table + DAO in the database
/// package, and the Supabase SQL migration. Mirrors what [FeatureScaffolder] and
/// `GenerateFeatureUsecase` actually write.
List<String> crudLines(
  String name,
  bool hasHttp,
  FeatureGenOptions options,
  NeatContract contract,
) {
  final remote = hasHttp && options.includeRemoteDataSource;
  final split = contract.packageSplit;
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
      '${split ? 'packages/${options.parentFeature}/lib' : options.parentFeature}/ (merged)',
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

  // Enum fields each get a domain enum file next to the entity.
  final enumFiles = [
    for (final e in collectEnumSpecs(resolveEnumNames(name, options.fields)))
      '${e.enumFileName}.dart',
  ];
  final tree = <String>[
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
    for (final (i, f) in ['${name}_entity.dart', ...enumFiles].indexed)
      '│   │   ${i == enumFiles.length ? '└' : '├'}── $f',
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

  // packageSplit: the feature is its own workspace package, with a pubspec and
  // the layers under its lib/ — not a folder under the app's lib/features/.
  final feature = split
      ? [
          'packages/$name/',
          '├── pubspec.yaml',
          '└── lib/',
          for (final l in tree) '    $l',
        ]
      : ['lib/features/$name/', ...tree];

  // Outside the feature's own tree: the Drift table + DAO (any project with a
  // Drift package, when this feature keeps a local source) and the Supabase SQL
  // migration (a Supabase remote source).
  final table = options.tableName.isEmpty ? '${name}s' : options.tableName;
  final drift = local && localIsDrift;
  return [
    ...feature,
    if (drift) ...[
      '',
      'packages/${contract.projectName}_database/lib/src/',
      '├── table/${name}_table.dart',
      '└── dao/${name}_dao.dart',
    ],
    if (remote && contract.httpClient == 'supabase') ...[
      '',
      'supabase/migrations/',
      '└── <timestamp>_create_$table.sql',
    ],
  ];
}

/// Custom Endpoints (ROADMAP.md §7 Phase 2): no entity, no repository, no
/// local source — mirrors FeatureScaffolder's useCustomEndpoints branch
/// exactly. Models only for endpoints that actually have a body.
List<String> customEndpointsLines(
  String name,
  FeatureGenOptions options,
  NeatContract contract,
) {
  final endpoints = options.endpoints;
  final hasAnyModel = endpoints.any(
    (e) => e.hasRequestBody || e.hasResponseBody,
  );
  return [
    'lib/features/$name/',
    '├── data/',
    '│   ├── sources/',
    '│   │   └── ${name}_api_source.dart',
    if (hasAnyModel) ...[
      for (final e in endpoints.where(
        (e) => e.hasRequestBody || e.hasResponseBody,
      ))
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
