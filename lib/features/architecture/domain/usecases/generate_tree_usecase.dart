import 'package:neat/features/architecture/domain/models/architecture_state.dart';

class GenerateTreeUsecase {
  const GenerateTreeUsecase();

  String execute(
    ArchitectureState state, {
    bool hasRiverpod = false,
    bool hasBloc = false,
    // Only meaningful with pattern == featureFirst — packageSplit moves the
    // feature out to packages/<packageName>_<feature>/ instead of
    // lib/features/<feature>/ (see ROADMAP.md §6a). Callers only pass true
    // once the combo is actually supported (see architecture_screen.dart's
    // canPackageSplit) — this usecase doesn't re-validate it.
    bool packageSplit = false,
    String packageName = '',
  }) {
    return state.pattern == StructuralPattern.featureFirst
        ? _featureFirst(
            state,
            hasRiverpod: hasRiverpod,
            hasBloc: hasBloc,
            packageSplit: packageSplit,
            packageName: packageName,
          )
        : _layerFirst(state, hasRiverpod: hasRiverpod, hasBloc: hasBloc);
  }

  String _featureFirst(
    ArchitectureState state, {
    required bool hasRiverpod,
    required bool hasBloc,
    bool packageSplit = false,
    String packageName = '',
  }) {
    final lines = <String>[];
    lines.add('lib/');
    lines.add(state.generateFirstFeature ? '├── core/' : '└── core/');
    lines.add('│   ├── theme/');
    lines.add('│   ├── router/');
    lines.add('│   └── utils/');
    if (!state.generateFirstFeature) {
      // No first feature yet — nothing else to preview (add one via the
      // Workshop after generation).
      return lines.join('\n');
    }
    final f = state.firstFeatureName.isEmpty ? 'feature' : state.firstFeatureName;

    // packageSplit: the feature lives in its own workspace package (package
    // root == feature root), not nested under lib/ at all — shown as its own
    // top-level tree section instead of a features/<f>/ line, to reflect that
    // it's a genuinely separate package (see ROADMAP.md §6a).
    if (packageSplit) {
      final pkg = '${packageName.isEmpty ? 'app' : packageName}_$f';
      lines.add('');
      lines.add('packages/$pkg/lib/');
      lines.add('├── data/');
      lines.add('│   ├── models/');
      if (state.includeMappers) lines.add('│   ├── mappers/');
      lines.add('│   ├── repositories/');
      lines.add('│   └── sources/');
      lines.add('├── domain/');
      lines.add('│   ├── entities/');
      lines.add('│   ├── repositories/');
      lines.add('│   └── usecases/');
      lines.add('└── presentation/');
      lines.add('    ├── pages/');
      for (final folder
          in _stateManagementFolders(hasRiverpod: hasRiverpod, hasBloc: hasBloc, useCubit: state.useCubit)) {
        lines.add('    ├── $folder/');
      }
      lines.add('    ├── routes/');
      lines.add('    └── widgets/');
      if (state.mirrorTestStructure) {
        lines.add('');
        lines.add('packages/$pkg/test/');
        lines.add('├── data/');
        lines.add('├── domain/');
        lines.add('└── presentation/');
      }
      return lines.join('\n');
    }

    lines.add('└── features/');
    lines.add('    └── $f/');
    lines.add('        ├── data/');
    lines.add('        │   ├── models/');
    if (state.includeMappers) lines.add('        │   ├── mappers/');
    lines.add('        │   ├── repositories/');
    lines.add('        │   └── sources/');
    lines.add('        ├── domain/');
    lines.add('        │   ├── entities/');
    lines.add('        │   ├── repositories/');
    lines.add('        │   └── usecases/');
    lines.add('        └── presentation/');
    lines.add('        │   ├── pages/');

    final stateManagementFolders = _stateManagementFolders(
      hasRiverpod: hasRiverpod,
      hasBloc: hasBloc,
      useCubit: state.useCubit,
    );
    for (final folder in stateManagementFolders) {
      lines.add('        │   ├── $folder/');
    }
    lines.add('        │   ├── routes/');
    lines.add('        │   └── widgets/');

    if (state.mirrorTestStructure) {
      lines.add('');
      lines.add('test/');
      lines.add('└── features/');
      lines.add('    └── $f/');
      lines.add('        ├── data/');
      lines.add('        ├── domain/');
      lines.add('        └── presentation/');
    }

    return lines.join('\n');
  }

  String _layerFirst(ArchitectureState state, {required bool hasRiverpod, required bool hasBloc}) {
    final lines = <String>[];
    lines.add('lib/');
    lines.add(state.generateFirstFeature ? '├── core/' : '└── core/');
    lines.add('│   ├── theme/');
    lines.add('│   ├── router/');
    lines.add('│   └── utils/');
    if (!state.generateFirstFeature) {
      return lines.join('\n');
    }
    final f = state.firstFeatureName.isEmpty ? 'feature' : state.firstFeatureName;
    lines.add('├── data/');
    lines.add('│   └── $f/');
    lines.add('│       ├── models/');
    if (state.includeMappers) lines.add('│       ├── mappers/');
    lines.add('│       ├── repositories/');
    lines.add('│       └── sources/');
    lines.add('├── domain/');
    lines.add('│   └── $f/');
    lines.add('│       ├── entities/');
    lines.add('│       ├── repositories/');
    lines.add('│       └── usecases/');
    lines.add('└── presentation/');
    lines.add('    └── $f/');
    lines.add('        ├── pages/');

    final stateManagementFolders = _stateManagementFolders(
      hasRiverpod: hasRiverpod,
      hasBloc: hasBloc,
      useCubit: state.useCubit,
    );
    for (final folder in stateManagementFolders) {
      lines.add('        ├── $folder/');
    }
    lines.add('        ├── routes/');
    lines.add('        └── widgets/');

    if (state.mirrorTestStructure) {
      lines.add('');
      lines.add('test/');
      lines.add('├── data/');
      lines.add('│   └── $f/');
      lines.add('├── domain/');
      lines.add('│   └── $f/');
      lines.add('└── presentation/');
      lines.add('    └── $f/');
    }

    return lines.join('\n');
  }

  List<String> _stateManagementFolders({
    required bool hasRiverpod,
    required bool hasBloc,
    required bool useCubit,
  }) {
    final folders = <String>[];
    if (hasRiverpod) folders.add('providers');
    if (hasBloc) folders.add(useCubit ? 'cubits' : 'bloc');
    return folders;
  }
}
