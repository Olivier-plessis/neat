import 'package:neat/core/network/network_error_handler.dart';
import 'package:neat/core/result/result.dart';

/// UseCase de base pour l'application principale.
/// Il utilise [NetworkErrorHandler] pour transformer les erreurs Dio en [Failure].
abstract class UseCase<Params, T> {
  const UseCase();

  /// Logique métier du UseCase. Doit être implémentée par les sous-classes.
  Future<T> execute(Params params);

  /// Point d'entrée sécurisé qui capture les erreurs et renvoie un [Result].
  Future<Result<T>> call(Params params) async {
    try {
      final result = await execute(params);
      return Result.success(result);
    } catch (e) {
      return Result.failure(NetworkErrorHandler.handle(e));
    }
  }
}

/// Version sans paramètres du UseCase.
abstract class NoParamsUseCase<T> extends UseCase<Unit, T> {
  const NoParamsUseCase();

  @override
  Future<T> execute(Unit params);

  @override
  Future<Result<T>> call([Unit params = Unit.instance]) => super.call(params);
}
