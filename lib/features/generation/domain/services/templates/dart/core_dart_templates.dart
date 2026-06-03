class CoreDartTemplates {
  CoreDartTemplates._();

  static String gitkeep() => '';

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
