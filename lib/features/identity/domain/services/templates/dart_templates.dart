import 'package:neat/features/dependencies/domain/models/pub_package.dart';

class DartTemplates {
  DartTemplates._();

  static String mainDart(List<PubPackage> packages) {
    final hasRiverpod = packages.any((p) => p.name.contains('riverpod'));

    final imports = StringBuffer();
    final wrapper = StringBuffer();

    imports.writeln("import 'package:flutter/material.dart';");

    if (hasRiverpod) {
      imports.writeln("import 'package:hooks_riverpod/hooks_riverpod.dart';");
    }

    imports.writeln("import 'app.dart';");

    if (hasRiverpod) {
      wrapper.write('ProviderScope(child: const App())');
    } else {
      wrapper.write('const App()');
    }

    return '''${imports.toString()}
void main() {
  runApp(${wrapper.toString()});
}
''';
  }

  static String appDart({required String name}) =>
      '''import 'package:flutter/material.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '$name',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(
          child: Text('$name'),
        ),
      ),
    );
  }
}
''';

  static String featureExampleUsecase({required String featureName}) =>
      '''import 'dart:async';

abstract class ${_pascal(featureName)}Repository {
  // Define your repository interface here
}

class Example${_pascal(featureName)}Usecase {
  const Example${_pascal(featureName)}Usecase(this._repository);

  final ${_pascal(featureName)}Repository _repository;

  Future<void> execute() async {
    // Implement your use case logic here
  }
}
''';

  static String featureExampleModel({required String featureName}) =>
      '''// Domain model for $featureName
class ${_pascal(featureName)}Model {
  const ${_pascal(featureName)}Model({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;
}
''';

  static String featureProvider({
    required String featureName,
    required bool useAnnotations,
    required bool useCubit,
  }) {
    if (useCubit) return _cubitTemplate(featureName);
    if (useAnnotations) return _riverpodAnnotationTemplate(featureName);
    return _riverpodManualTemplate(featureName);
  }

  static String _riverpodAnnotationTemplate(String feature) =>
      '''import 'package:riverpod_annotation/riverpod_annotation.dart';

part '${feature}_provider.g.dart';

@riverpod
class ${_pascal(feature)}Notifier extends _\$${_pascal(feature)}Notifier {
  @override
  AsyncValue<void> build() => const AsyncData(null);
}
''';

  static String _riverpodManualTemplate(String feature) =>
      '''import 'package:flutter_riverpod/flutter_riverpod.dart';

final ${feature}Provider = StateNotifierProvider<${_pascal(feature)}Notifier, AsyncValue<void>>(
  (ref) => ${_pascal(feature)}Notifier(),
);

class ${_pascal(feature)}Notifier extends StateNotifier<AsyncValue<void>> {
  ${_pascal(feature)}Notifier() : super(const AsyncData(null));
}
''';

  static String _cubitTemplate(String feature) =>
      '''import 'package:flutter_bloc/flutter_bloc.dart';

class ${_pascal(feature)}Cubit extends Cubit<${_pascal(feature)}State> {
  ${_pascal(feature)}Cubit() : super(${_pascal(feature)}Initial());
}

abstract class ${_pascal(feature)}State {}
class ${_pascal(feature)}Initial extends ${_pascal(feature)}State {}
class ${_pascal(feature)}Loading extends ${_pascal(feature)}State {}
class ${_pascal(feature)}Loaded extends ${_pascal(feature)}State {}
class ${_pascal(feature)}Error extends ${_pascal(feature)}State {
  ${_pascal(feature)}Error(this.message);
  final String message;
}
''';

  static String gitkeep() => '';

  static String _pascal(String s) {
    if (s.isEmpty) return s;
    return s.split('_').map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1)).join();
  }

  static String coreResultDart() => r'''sealed class Result<T> {
  const Result();

  factory Result.success(T value) = _Success<T>;
  factory Result.failure(String message) = _Failure<T>;

  B fold<B>({
    required B Function(T value) onSuccess,
    required B Function(String message) onFailure,
  });

  T getOrThrow() => fold(onSuccess: (v) => v, onFailure: (e) => throw Exception(e));
  T? getOrNull() => fold(onSuccess: (v) => v, onFailure: (_) => null);
  T getOrDefault(T defaultValue) => fold(onSuccess: (v) => v, onFailure: (_) => defaultValue);
}

final class _Success<T> extends Result<T> {
  const _Success(this.value);
  final T value;

  @override
  B fold<B>({required B Function(T) onSuccess, required B Function(String) onFailure}) =>
      onSuccess(value);
}

final class _Failure<T> extends Result<T> {
  const _Failure(this.message);
  final String message;

  @override
  B fold<B>({required B Function(T) onSuccess, required B Function(String) onFailure}) =>
      onFailure(message);
}
''';

  static String coreUsecaseDart() => r'''abstract class UseCase<Params, T> {
  const UseCase();

  Future<T> execute(Params params);

  Future<T> call(Params params) => execute(params);
}

abstract class NoParamsUseCase<T> {
  const NoParamsUseCase();

  Future<T> execute();

  Future<T> call() => execute();
}
''';
}
