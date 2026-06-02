import 'package:neat/features/identity/domain/services/templates/dart/_template_utils.dart';

class StateTemplates {
  StateTemplates._();

  // ── Cubit ─────────────────────────────────────────────────────────────────

  static String featureCubit({required String featureName}) {
    final p = pascal(featureName);
    return '''import 'package:flutter_bloc/flutter_bloc.dart';

part '${featureName}_state.dart';

class ${p}Cubit extends Cubit<${p}State> {
  ${p}Cubit() : super(const ${p}Initial());

  Future<void> load() async {
    emit(const ${p}Loading());
    // TODO: load data
    emit(const ${p}Loaded());
  }
}
''';
  }

  static String featureCubitState({required String featureName}) {
    final p = pascal(featureName);
    return '''part of '${featureName}_cubit.dart';

sealed class ${p}State {
  const ${p}State();
}

final class ${p}Initial extends ${p}State {
  const ${p}Initial();
}

final class ${p}Loading extends ${p}State {
  const ${p}Loading();
}

final class ${p}Loaded extends ${p}State {
  const ${p}Loaded();
}

final class ${p}Error extends ${p}State {
  const ${p}Error(this.message);
  final String message;
}
''';
  }

  // ── Bloc ──────────────────────────────────────────────────────────────────

  static String featureBloc({required String featureName}) {
    final p = pascal(featureName);
    return '''import 'package:flutter_bloc/flutter_bloc.dart';

part '${featureName}_event.dart';
part '${featureName}_state.dart';

class ${p}Bloc extends Bloc<${p}Event, ${p}State> {
  ${p}Bloc() : super(const ${p}Initial()) {
    on<${p}LoadRequested>(_onLoadRequested);
  }

  Future<void> _onLoadRequested(
    ${p}LoadRequested event,
    Emitter<${p}State> emit,
  ) async {
    emit(const ${p}Loading());
    // TODO: load data
    emit(const ${p}Loaded());
  }
}
''';
  }

  static String featureBlocEvent({required String featureName}) {
    final p = pascal(featureName);
    return '''part of '${featureName}_bloc.dart';

sealed class ${p}Event {
  const ${p}Event();
}

final class ${p}LoadRequested extends ${p}Event {
  const ${p}LoadRequested();
}
''';
  }

  static String featureBlocState({required String featureName}) {
    final p = pascal(featureName);
    return '''part of '${featureName}_bloc.dart';

sealed class ${p}State {
  const ${p}State();
}

final class ${p}Initial extends ${p}State {
  const ${p}Initial();
}

final class ${p}Loading extends ${p}State {
  const ${p}Loading();
}

final class ${p}Loaded extends ${p}State {
  const ${p}Loaded();
}

final class ${p}Error extends ${p}State {
  const ${p}Error(this.message);
  final String message;
}
''';
  }
}
