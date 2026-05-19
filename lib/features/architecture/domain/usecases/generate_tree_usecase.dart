import 'package:neat/features/architecture/presentation/providers/architecture_provider.dart';

class GenerateTreeUsecase {
  const GenerateTreeUsecase();

  String execute(
    ArchitectureState state, {
    bool hasRiverpod = false,
    bool hasBloc = false,
  }) {
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
    lines.add('└── features/');
    lines.add('    └── auth/');
    lines.add('        ├── data/');
    lines.add('        │   ├── datasources/');
    lines.add('        │   ├── entities/');
    if (state.includeMappers) lines.add('        │   ├── mappers/');
    lines.add('        │   └── repositories/');
    lines.add('        ├── domain/');
    lines.add('        │   ├── models/');
    lines.add('        │   ├── repositories/');
    lines.add('        │   └── usecases/');
    lines.add('        └── presentation/');

    final stateManagementFolders = _stateManagementFolders(
      hasRiverpod: hasRiverpod,
      hasBloc: hasBloc,
      useCubit: state.useCubit,
    );

    for (var i = 0; i < stateManagementFolders.length; i++) {
      final isLast = i == stateManagementFolders.length - 1;
      lines.add('            ${isLast ? '└' : '├'}── ${stateManagementFolders[i]}/');
    }
    lines.add('            └── screens/');

    if (state.mirrorTestStructure) {
      lines.add('');
      lines.add('test/');
      lines.add('└── features/');
      lines.add('    └── auth/');
      lines.add('        ├── data/');
      lines.add('        ├── domain/');
      lines.add('        └── presentation/');
    }

    return lines.join('\n');
  }

  String _layerFirst(
    ArchitectureState state, {
    required bool hasRiverpod,
    required bool hasBloc,
  }) {
    final lines = <String>[];
    lines.add('lib/');
    lines.add('├── data/');
    lines.add('│   └── auth/');
    lines.add('│       ├── datasources/');
    lines.add('│       ├── entities/');
    if (state.includeMappers) lines.add('│       ├── mappers/');
    lines.add('│       └── repositories/');
    lines.add('├── domain/');
    lines.add('│   └── auth/');
    lines.add('│       ├── models/');
    lines.add('│       ├── repositories/');
    lines.add('│       └── usecases/');
    lines.add('└── presentation/');
    lines.add('    └── auth/');

    final stateManagementFolders = _stateManagementFolders(
      hasRiverpod: hasRiverpod,
      hasBloc: hasBloc,
      useCubit: state.useCubit,
    );

    for (var i = 0; i < stateManagementFolders.length; i++) {
      final isLast = i == stateManagementFolders.length - 1;
      lines.add('        ${isLast ? '└' : '├'}── ${stateManagementFolders[i]}/');
    }
    lines.add('        └── screens/');

    if (state.mirrorTestStructure) {
      lines.add('');
      lines.add('test/');
      lines.add('├── data/');
      lines.add('│   └── auth/');
      lines.add('├── domain/');
      lines.add('│   └── auth/');
      lines.add('└── presentation/');
      lines.add('    └── auth/');
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
