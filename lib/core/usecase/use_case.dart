import 'package:neat/core/network/network_error_handler.dart';
import 'package:neat/core/result/result.dart';

/// Base UseCase for the application.
/// Uses [NetworkErrorHandler] to map exceptions into [Failure] results.
abstract class UseCase<Params, T> {
  const UseCase();

  /// The core logic of the UseCase. Must be implemented by subclasses.
  Future<T> execute(Params params);

  /// Secure entry point that catches errors and returns a [Result].
  Future<Result<T>> call(Params params) async {
    try {
      final result = await execute(params);
      return Result.success(result);
    } catch (e) {
      return Result.failure(NetworkErrorHandler.handle(e));
    }
  }
}

/// Parameterless version of the UseCase.
abstract class NoParamsUseCase<T> extends UseCase<Unit, T> {
  const NoParamsUseCase();

  @override
  Future<T> execute(Unit params);

  @override
  Future<Result<T>> call([Unit params = Unit.instance]) => super.call(params);
}
