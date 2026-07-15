/// Represents the result of an operation: success or failure.
///
/// Returned by all [UseCase]s to prevent exception propagation
/// to the presentation layer.
///
/// Usage:
/// ```dart
/// final result = await myUseCase(params);
/// result.fold(
///   (data)  => // success,
///   (error) => // failure,
/// );
/// ```
sealed class Result<T> {
  const Result();

  factory Result.success(T data) = _Success<T>;
  factory Result.failure(Object error) = _Failure<T>;

  bool get isSuccess => this is _Success<T>;
  bool get isFailure => this is _Failure<T>;

  /// Returns the value or throws the error.
  T getOrThrow() => switch (this) {
    _Success<T>(:final data) => data,
    _Failure<T>(:final error) => throw error,
  };

  /// Returns the value or `null` on failure.
  T? getOrNull() => switch (this) {
    _Success<T>(:final data) => data,
    _Failure<T>() => null,
  };

  /// Returns the value or [defaultValue] on failure.
  T getOrDefault(T defaultValue) => switch (this) {
    _Success<T>(:final data) => data,
    _Failure<T>() => defaultValue,
  };

  /// Executes [action] only on success.
  void onSuccess(void Function(T data) action) {
    if (this case _Success<T>(:final data)) action(data);
  }

  /// Executes [action] only on failure.
  void onFailure(void Function(Object error) action) {
    if (this case _Failure<T>(:final error)) action(error);
  }

  /// Transforms the value on success, propagates the error otherwise.
  Result<R> mapSuccess<R>(R Function(T data) mapper) => switch (this) {
    _Success<T>(:final data) => Result.success(mapper(data)),
    _Failure<T>(:final error) => Result.failure(error),
  };

  /// Transforms the error on failure, propagates the value otherwise.
  Result<T> mapFailure(Object Function(Object error) mapper) => switch (this) {
    _Success<T>() => this,
    _Failure<T>(:final error) => Result.failure(mapper(error)),
  };

  /// Folds both cases into a single value of type [R].
  R fold<R>(R Function(T data) onSuccess, R Function(Object error) onFailure) =>
      switch (this) {
        _Success<T>(:final data) => onSuccess(data),
        _Failure<T>(:final error) => onFailure(error),
      };
}

final class _Success<T> extends Result<T> {
  const _Success(this.data);
  final T data;
}

final class _Failure<T> extends Result<T> {
  const _Failure(this.error);
  final Object error;
}

/// Equivalent of [void] for [UseCase]s that do not return a value.
/// Keeps [Result] fully typed.
///
/// ```dart
/// class DeleteSomethingUseCase extends UseCase<String, Unit> { ... }
/// // On success: Result.success(Unit.instance)
/// ```
final class Unit {
  const Unit._();
  static const Unit instance = Unit._();
}
