class CoreDartTemplates {
  CoreDartTemplates._();

  static String gitkeep() => '';

  static String coreResultDart({required String packageName}) => '''import 'package:$packageName/core/error/failure.dart';

sealed class Result<T> {
  const Result();

  factory Result.success(T value) = _Success<T>;
  factory Result.failure(Failure failure) = _Failure<T>;

  B fold<B>({
    required B Function(T value) onSuccess,
    required B Function(Failure failure) onFailure,
  });

  /// Returns the value, or **throws the [Failure] itself** (not wrapped) —
  /// so a caller re-catching it (e.g. [UseCase.call]) gets a structured error
  /// it can pass straight through instead of re-mapping.
  T getOrThrow() => fold(onSuccess: (v) => v, onFailure: (f) => throw f);
  T? getOrNull() => fold(onSuccess: (v) => v, onFailure: (_) => null);
  T getOrDefault(T defaultValue) => fold(onSuccess: (v) => v, onFailure: (_) => defaultValue);
}

final class _Success<T> extends Result<T> {
  const _Success(this.value);
  final T value;

  @override
  B fold<B>({required B Function(T) onSuccess, required B Function(Failure) onFailure}) =>
      onSuccess(value);
}

final class _Failure<T> extends Result<T> {
  const _Failure(this.failure);
  final Failure failure;

  @override
  B fold<B>({required B Function(T) onSuccess, required B Function(Failure) onFailure}) =>
      onFailure(failure);
}
''';

  /// [UseCase.execute] is the business logic — it **may throw** (a repository
  /// method call, a parsing error, anything). [UseCase.call] is the *only*
  /// place that catches: it converts whatever was thrown into a [Failure] via
  /// [NetworkErrorHandler] and returns a [Result]. Always invoke usecases via
  /// the callable shorthand (`usecase(params)`, i.e. `call`) — never
  /// `execute()` directly, which has no error handling of its own.
  static String coreUsecaseDart({required String packageName}) =>
      '''import 'package:$packageName/core/network/network_error_handler.dart';
import 'package:$packageName/core/result/result.dart';

abstract class UseCase<Params, T> {
  const UseCase();

  Future<T> execute(Params params);

  Future<Result<T>> call(Params params) async {
    try {
      return Result.success(await execute(params));
    } catch (e) {
      return Result.failure(NetworkErrorHandler.handle(e));
    }
  }
}

abstract class NoParamsUseCase<T> extends UseCase<Unit, T> {
  const NoParamsUseCase();

  @override
  Future<T> execute(Unit params);

  @override
  Future<Result<T>> call([Unit params = Unit.instance]) => super.call(params);
}

/// Stand-in for `void` params/results, so [UseCase]/[NoParamsUseCase] stay
/// fully generic (a `NoParamsUseCase<T>` is just a `UseCase<Unit, T>`).
final class Unit {
  const Unit._();
  static const Unit instance = Unit._();
}
''';
}
