/// Représente le résultat d'une opération : succès ou échec.
///
/// Retourné par tous les [UseCase] pour éviter la propagation d'exceptions
/// jusqu'à la couche présentation.
///
/// Usage :
/// ```dart
/// final result = await myUseCase(params);
/// result.fold(
///   (data)  => // succès,
///   (error) => // échec,
/// );
/// ```
sealed class Result<T> {
  const Result();

  factory Result.success(T data) = _Success<T>;
  factory Result.failure(Object error) = _Failure<T>;

  bool get isSuccess => this is _Success<T>;
  bool get isFailure => this is _Failure<T>;

  /// Retourne la valeur ou lève l'erreur.
  T getOrThrow() => switch (this) {
    _Success<T>(:final data) => data,
    _Failure<T>(:final error) => throw error,
  };

  /// Retourne la valeur ou `null` en cas d'échec.
  T? getOrNull() => switch (this) {
    _Success<T>(:final data) => data,
    _Failure<T>() => null,
  };

  /// Retourne la valeur ou [defaultValue] en cas d'échec.
  T getOrDefault(T defaultValue) => switch (this) {
    _Success<T>(:final data) => data,
    _Failure<T>() => defaultValue,
  };

  /// Exécute [action] uniquement en cas de succès.
  void onSuccess(void Function(T data) action) {
    if (this case _Success<T>(:final data)) action(data);
  }

  /// Exécute [action] uniquement en cas d'échec.
  void onFailure(void Function(Object error) action) {
    if (this case _Failure<T>(:final error)) action(error);
  }

  /// Transforme la valeur en cas de succès, propage l'erreur sinon.
  Result<R> mapSuccess<R>(R Function(T data) mapper) => switch (this) {
    _Success<T>(:final data) => Result.success(mapper(data)),
    _Failure<T>(:final error) => Result.failure(error),
  };

  /// Transforme l'erreur en cas d'échec, propage la valeur sinon.
  Result<T> mapFailure(Object Function(Object error) mapper) => switch (this) {
    _Success<T>() => this,
    _Failure<T>(:final error) => Result.failure(mapper(error)),
  };

  /// Branche sur les deux cas et retourne une valeur [R].
  R fold<R>(
      R Function(T data) onSuccess,
      R Function(Object error) onFailure,
      ) =>
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

/// Équivalent de [void] pour les [UseCase] qui ne retournent pas de valeur.
/// Permet de garder [Result] pleinement typé.
///
/// ```dart
/// class DeleteSomethingUseCase extends UseCase<String, Unit> { ... }
/// // En cas de succès : Result.success(Unit.instance)
/// ```
final class Unit {
  const Unit._();
  static const Unit instance = Unit._();
}
