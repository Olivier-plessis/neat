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

  static String appDart({
    required String name,
    required bool hasGoRouter,
    required bool hasRiverpod,
    required bool useAnnotations,
    required bool hasBloc,
    required bool useCubit,
  }) {
    final imports = StringBuffer();
    imports.writeln("import 'package:flutter/material.dart';");

    if (hasGoRouter) {
      imports.writeln("import 'core/router/app_router.dart';");
    }
    if (!hasGoRouter) {
      imports.writeln("import 'core/theme/app_theme.dart';");
    } else {
      imports.writeln("import 'core/theme/app_theme.dart';");
    }

    if (hasRiverpod && !useAnnotations) {
      imports.writeln("import 'package:flutter_riverpod/flutter_riverpod.dart';");
      imports.writeln("import 'core/theme/theme_mode_controller.dart';");
    } else if (hasRiverpod && useAnnotations) {
      imports.writeln("import 'package:hooks_riverpod/hooks_riverpod.dart';");
      imports.writeln("import 'core/theme/theme_mode_controller.dart';");
    }

    if (hasBloc || useCubit) {
      imports.writeln("import 'package:flutter_bloc/flutter_bloc.dart';");
      if (useCubit) {
        imports.writeln("import 'core/theme/brightness_theme/brightness_cubit.dart';");
      } else {
        imports.writeln("import 'core/theme/brightness_theme/brightness_bloc.dart';");
      }
    }

    final body = StringBuffer();

    if (hasGoRouter) {
      if (useAnnotations) {
        body.write('''class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeControllerProvider);
    return MaterialApp.router(
      title: '$name',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}''');
      } else if (hasRiverpod) {
        body.write('''class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeControllerProvider);
    return MaterialApp.router(
      title: '$name',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}''');
      } else if (useCubit) {
        body.write('''class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BrightnessCubit(),
      child: BlocBuilder<BrightnessCubit, BrightnessState>(
        builder: (context, state) => MaterialApp.router(
          title: '$name',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: context.read<BrightnessCubit>().themeMode,
          routerConfig: appRouter,
        ),
      ),
    );
  }
}''');
      } else if (hasBloc) {
        body.write('''class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BrightnessBloc(),
      child: BlocBuilder<BrightnessBloc, BrightnessState>(
        builder: (context, state) => MaterialApp.router(
          title: '$name',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: context.read<BrightnessBloc>().themeMode,
          routerConfig: appRouter,
        ),
      ),
    );
  }
}''');
      } else {
        body.write('''class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '$name',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: appRouter,
    );
  }
}''');
      }
    } else {
      body.write('''class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '$name',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('$name'),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: () {}, child: const Text('$name')),
                const SizedBox(height: 8),
                TextButton(onPressed: () {}, child: const Text('$name')),
                const SizedBox(height: 8),
                FilledButton(onPressed: () {}, child: const Text('$name')),
                const SizedBox(height: 8),
                OutlinedButton(onPressed: () {}, child: const Text('$name')),
                const SizedBox(height: 8),
                const TextField(decoration: InputDecoration(hintText: '$name')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}''');
    }

    return '${imports.toString()}\n${body.toString()}\n';
  }

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

  // ── Feature: domain/entities ──────────────────────────────────────────────

  static String featureEntity({required String featureName}) =>
      '''abstract class ${_pascal(featureName)}Entity {
  const ${_pascal(featureName)}Entity({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;
}
''';

  // ── Feature: domain/repositories (interface) ─────────────────────────────

  static String featureIRepository({required String featureName, required String packageName}) =>
      '''import 'package:$packageName/core/result/result.dart';
import '../entities/${featureName}_entity.dart';

abstract class I${_pascal(featureName)}Repository {
  Future<Result<List<${_pascal(featureName)}Entity>>> getAll();
  Future<Result<${_pascal(featureName)}Entity>> getById(String id);
}
''';

  // ── Feature: domain/usecases ──────────────────────────────────────────────

  static String featureGetUsecase({required String featureName, required String packageName}) =>
      '''import 'package:$packageName/core/result/result.dart';
import '../entities/${featureName}_entity.dart';
import '../repositories/i_${featureName}_repository.dart';

class Get${_pascal(featureName)}Usecase {
  const Get${_pascal(featureName)}Usecase(this._repository);

  final I${_pascal(featureName)}Repository _repository;

  Future<Result<List<${_pascal(featureName)}Entity>>> execute() => _repository.getAll();
}
''';

  // ── Feature: data/models ──────────────────────────────────────────────────

  static String featureModel({
    required String featureName,
    required String packageName,
    required bool hasFreezed,
    required bool hasJsonSerializable,
  }) {
    final pascal = _pascal(featureName);
    if (hasFreezed) {
      final jsonAnnotation = hasJsonSerializable
          ? "\nimport 'package:json_annotation/json_annotation.dart';"
          : '';
      final jsonFactoryAnnotation = hasJsonSerializable ? '\n  @JsonSerializable()' : '';
      final partJson = hasJsonSerializable ? "\npart '${featureName}_model.g.dart';" : '';
      return '''import 'package:freezed_annotation/freezed_annotation.dart';$jsonAnnotation

part '${featureName}_model.freezed.dart';$partJson

@freezed
abstract class ${pascal}Model with _\$${pascal}Model {$jsonFactoryAnnotation
  const factory ${pascal}Model({
    required String id,
    required String name,
  }) = _${pascal}Model;
${hasJsonSerializable ? "\n  factory ${pascal}Model.fromJson(Map<String, dynamic> json) =>\n      _\$${pascal}ModelFromJson(json);" : ''}
}
''';
    }

    return '''import 'package:$packageName/features/$featureName/domain/entities/${featureName}_entity.dart';

class ${pascal}Model extends ${pascal}Entity {
  const ${pascal}Model({
    required super.id,
    required super.name,
  });

  factory ${pascal}Model.fromJson(Map<String, dynamic> json) =>
      ${pascal}Model(
        id: json['id'] as String,
        name: json['name'] as String,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
  };
}
''';
  }

  // ── Feature: data/repositories (impl) ────────────────────────────────────

  static String featureRepositoryImpl({
    required String featureName,
    required String packageName,
    required bool hasHttpClient,
  }) {
    final sourceImport = hasHttpClient
        ? "import '../sources/${featureName}_api_source.dart';"
        : "import '../sources/${featureName}_local_source.dart';";
    final sourceName = hasHttpClient
        ? '${_pascal(featureName)}ApiSource'
        : '${_pascal(featureName)}LocalSource';

    return '''import 'package:$packageName/core/result/result.dart';
import 'package:$packageName/features/$featureName/domain/entities/${featureName}_entity.dart';
import 'package:$packageName/features/$featureName/domain/repositories/i_${featureName}_repository.dart';
$sourceImport

class ${_pascal(featureName)}RepositoryImpl implements I${_pascal(featureName)}Repository {
  const ${_pascal(featureName)}RepositoryImpl(this._source);

  final $sourceName _source;

  @override
  Future<Result<List<${_pascal(featureName)}Entity>>> getAll() async {
    try {
      final data = await _source.getAll();
      return Result.success(data);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  @override
  Future<Result<${_pascal(featureName)}Entity>> getById(String id) async {
    try {
      final data = await _source.getById(id);
      return Result.success(data);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }
}
''';
  }

  // ── Feature: data/sources (api) ───────────────────────────────────────────

  static String featureApiSource({
    required String featureName,
    required String packageName,
    required String httpClient,
  }) {
    if (httpClient == 'retrofit') {
      return '''import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:$packageName/features/$featureName/data/models/${featureName}_model.dart';

part '${featureName}_api_source.g.dart';

@RestApi()
abstract class ${_pascal(featureName)}ApiSource {
  factory ${_pascal(featureName)}ApiSource(Dio dio, {String baseUrl}) =
      _${_pascal(featureName)}ApiSource;

  @GET('/${featureName}s')
  Future<List<${_pascal(featureName)}Model>> getAll();

  @GET('/${featureName}s/{id}')
  Future<${_pascal(featureName)}Model> getById(@Path('id') String id);
}
''';
    }

    if (httpClient == 'chopper') {
      return '''import 'package:chopper/chopper.dart';
import 'package:$packageName/features/$featureName/data/models/${featureName}_model.dart';

part '${featureName}_api_source.chopper.dart';

@ChopperApi(baseUrl: '/${featureName}s')
abstract class ${_pascal(featureName)}ApiSource extends ChopperService {
  static ${_pascal(featureName)}ApiSource create([ChopperClient? client]) =>
      _\$${_pascal(featureName)}ApiSource(client);

  @GET()
  Future<Response<List<${_pascal(featureName)}Model>>> getAll();

  @GET(path: '/{id}')
  Future<Response<${_pascal(featureName)}Model>> getById(@Path() String id);
}
''';
    }

    // dio plain
    return '''import 'package:dio/dio.dart';
import 'package:$packageName/features/$featureName/data/models/${featureName}_model.dart';

class ${_pascal(featureName)}ApiSource {
  const ${_pascal(featureName)}ApiSource(this._dio);

  final Dio _dio;

  Future<List<${_pascal(featureName)}Model>> getAll() async {
    final response = await _dio.get<List<dynamic>>('/${featureName}s');
    return (response.data ?? [])
        .cast<Map<String, dynamic>>()
        .map(${_pascal(featureName)}Model.fromJson)
        .toList();
  }

  Future<${_pascal(featureName)}Model> getById(String id) async {
    final response = await _dio.get<Map<String, dynamic>>('/${featureName}s/\$id');
    return ${_pascal(featureName)}Model.fromJson(response.data!);
  }
}
''';
  }

  // ── Feature: data/sources (local) ────────────────────────────────────────

  static String featureLocalSource({required String featureName, required String packageName}) =>
      '''import 'package:$packageName/features/$featureName/data/models/${featureName}_model.dart';

class ${_pascal(featureName)}LocalSource {
  const ${_pascal(featureName)}LocalSource();

  Future<List<${_pascal(featureName)}Model>> getAll() async {
    return [];
  }

  Future<${_pascal(featureName)}Model> getById(String id) async {
    throw UnimplementedError('getById not implemented');
  }
}
''';

  // ── Feature: presentation/pages ──────────────────────────────────────────

  static String featurePage({
    required String featureName,
    required String packageName,
    required bool hasRiverpod,
    required bool useAnnotations,
    required bool hasBloc,
    required bool useCubit,
  }) {
    if (hasRiverpod) {
      final body = useAnnotations
          ? '''switch (state) {
        AsyncData() => const Center(child: Text('${_pascal(featureName)}')),
        AsyncError(:final error) => Center(child: Text(error.toString())),
        _ => const Center(child: CircularProgressIndicator()),
      }'''
          : '''state.when(
        data: (_) => const Center(child: Text('${_pascal(featureName)}')),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
      )''';

      final themeControllerImport = useAnnotations
          ? "import 'package:$packageName/core/theme/theme_mode_controller.dart';"
          : "import 'package:$packageName/core/theme/theme_mode_controller.dart';";

      return '''import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:$packageName/features/$featureName/presentation/providers/${featureName}_provider.dart';
$themeControllerImport

class ${_pascal(featureName)}Page extends ConsumerWidget {
  const ${_pascal(featureName)}Page({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(${featureName}Provider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('${_pascal(featureName)}'),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
            onPressed: () => ref.read(themeModeControllerProvider.notifier).toggle(),
          ),
        ],
      ),
      body: $body,
    );
  }
}
''';
    }

    if (useCubit) {
      return '''import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:$packageName/core/theme/brightness_theme/brightness_cubit.dart';
import 'package:$packageName/features/$featureName/presentation/cubit/${featureName}_cubit.dart';

class ${_pascal(featureName)}Page extends StatelessWidget {
  const ${_pascal(featureName)}Page({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BlocProvider(
      create: (_) => ${_pascal(featureName)}Cubit(),
      child: BlocBuilder<${_pascal(featureName)}Cubit, ${_pascal(featureName)}State>(
        builder: (context, state) => Scaffold(
          appBar: AppBar(
            title: const Text('${_pascal(featureName)}'),
            actions: [
              IconButton(
                icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
                onPressed: () => context.read<BrightnessCubit>().toggle(),
              ),
            ],
          ),
          body: const Center(child: Text('${_pascal(featureName)}')),
        ),
      ),
    );
  }
}
''';
    }

    if (hasBloc) {
      return '''import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:$packageName/core/theme/brightness_theme/brightness_bloc.dart';
import 'package:$packageName/features/$featureName/presentation/bloc/${featureName}_bloc.dart';

class ${_pascal(featureName)}Page extends StatelessWidget {
  const ${_pascal(featureName)}Page({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BlocProvider(
      create: (_) => ${_pascal(featureName)}Bloc(),
      child: BlocBuilder<${_pascal(featureName)}Bloc, ${_pascal(featureName)}State>(
        builder: (context, state) => Scaffold(
          appBar: AppBar(
            title: const Text('${_pascal(featureName)}'),
            actions: [
              IconButton(
                icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
                onPressed: () => context.read<BrightnessBloc>().add(const BrightnessToggled()),
              ),
            ],
          ),
          body: const Center(child: Text('${_pascal(featureName)}')),
        ),
      ),
    );
  }
}
''';
    }

    return '''import 'package:flutter/material.dart';

class ${_pascal(featureName)}Page extends StatelessWidget {
  const ${_pascal(featureName)}Page({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('${_pascal(featureName)}')),
      body: const Center(child: Text('${_pascal(featureName)}')),
    );
  }
}
''';
  }

  // ── Feature: presentation/routes (GoRouteData) ───────────────────────────

  static String featureRoute({
    required String featureName,
    required String packageName,
    required bool useBuilder,
  }) {
    if (useBuilder) {
      return '''import 'package:go_router/go_router.dart';
import 'package:$packageName/features/$featureName/presentation/pages/${featureName}_page.dart';

class ${_pascal(featureName)}Route extends GoRouteData {
  const ${_pascal(featureName)}Route();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const ${_pascal(featureName)}Page();
}
''';
    }
    return '''import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:$packageName/features/$featureName/presentation/pages/${featureName}_page.dart';

final ${featureName}Route = GoRoute(
  path: '/',
  builder: (context, state) => const ${_pascal(featureName)}Page(),
);
''';
  }

  // ── Feature: cubit ───────────────────────────────────────────────────────

  static String featureCubit({required String featureName}) =>
      '''import 'package:flutter_bloc/flutter_bloc.dart';

part '${featureName}_state.dart';

class ${_pascal(featureName)}Cubit extends Cubit<${_pascal(featureName)}State> {
  ${_pascal(featureName)}Cubit() : super(const ${_pascal(featureName)}Initial());

  Future<void> load() async {
    emit(const ${_pascal(featureName)}Loading());
    // TODO: load data
    emit(const ${_pascal(featureName)}Loaded());
  }
}
''';

  static String featureCubitState({required String featureName}) =>
      '''part of '${featureName}_cubit.dart';

sealed class ${_pascal(featureName)}State {
  const ${_pascal(featureName)}State();
}

final class ${_pascal(featureName)}Initial extends ${_pascal(featureName)}State {
  const ${_pascal(featureName)}Initial();
}

final class ${_pascal(featureName)}Loading extends ${_pascal(featureName)}State {
  const ${_pascal(featureName)}Loading();
}

final class ${_pascal(featureName)}Loaded extends ${_pascal(featureName)}State {
  const ${_pascal(featureName)}Loaded();
}

final class ${_pascal(featureName)}Error extends ${_pascal(featureName)}State {
  const ${_pascal(featureName)}Error(this.message);
  final String message;
}
''';

  // ── Feature: bloc ─────────────────────────────────────────────────────────

  static String featureBloc({required String featureName}) =>
      '''import 'package:flutter_bloc/flutter_bloc.dart';

part '${featureName}_event.dart';
part '${featureName}_state.dart';

class ${_pascal(featureName)}Bloc extends Bloc<${_pascal(featureName)}Event, ${_pascal(featureName)}State> {
  ${_pascal(featureName)}Bloc() : super(const ${_pascal(featureName)}Initial()) {
    on<${_pascal(featureName)}LoadRequested>(_onLoadRequested);
  }

  Future<void> _onLoadRequested(
    ${_pascal(featureName)}LoadRequested event,
    Emitter<${_pascal(featureName)}State> emit,
  ) async {
    emit(const ${_pascal(featureName)}Loading());
    // TODO: load data
    emit(const ${_pascal(featureName)}Loaded());
  }
}
''';

  static String featureBlocEvent({required String featureName}) =>
      '''part of '${featureName}_bloc.dart';

sealed class ${_pascal(featureName)}Event {
  const ${_pascal(featureName)}Event();
}

final class ${_pascal(featureName)}LoadRequested extends ${_pascal(featureName)}Event {
  const ${_pascal(featureName)}LoadRequested();
}
''';

  static String featureBlocState({required String featureName}) =>
      '''part of '${featureName}_bloc.dart';

sealed class ${_pascal(featureName)}State {
  const ${_pascal(featureName)}State();
}

final class ${_pascal(featureName)}Initial extends ${_pascal(featureName)}State {
  const ${_pascal(featureName)}Initial();
}

final class ${_pascal(featureName)}Loading extends ${_pascal(featureName)}State {
  const ${_pascal(featureName)}Loading();
}

final class ${_pascal(featureName)}Loaded extends ${_pascal(featureName)}State {
  const ${_pascal(featureName)}Loaded();
}

final class ${_pascal(featureName)}Error extends ${_pascal(featureName)}State {
  const ${_pascal(featureName)}Error(this.message);
  final String message;
}
''';
}
