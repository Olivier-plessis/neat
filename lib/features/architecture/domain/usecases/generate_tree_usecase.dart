import 'package:neat/features/architecture/domain/models/architecture_state.dart';

class GenerateTreeUsecase {
  const GenerateTreeUsecase();

  String execute(ArchitectureState state, {bool hasRiverpod = false, bool hasBloc = false}) {
    return state.pattern == StructuralPattern.featureFirst
        ? _featureFirst(state, hasRiverpod: hasRiverpod, hasBloc: hasBloc)
        : _layerFirst(state, hasRiverpod: hasRiverpod, hasBloc: hasBloc);
  }

  String _featureFirst(
    ArchitectureState state, {
    required bool hasRiverpod,
    required bool hasBloc,
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
