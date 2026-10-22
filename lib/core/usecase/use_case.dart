import 'package:neat/core/error/failure.dart';
import 'package:neat/core/network/network_error_handler.dart';
import 'package:neat/core/result/result.dart';
import 'package:neat/core/utils/app_logger.dart';

/// Base UseCase for the application.
/// Uses [NetworkErrorHandler] to map exceptions into [Failure] results, and
/// logs the cause of any it did not expect (see [call]).
abstract class UseCase<Params, T> {
  const UseCase();

  /// The core logic of the UseCase. Must be implemented by subclasses.
  Future<T> execute(Params params);

  /// Secure entry point that catches errors and returns a [Result].
  ///
  /// Whatever is thrown comes back as a [Failure], which a screen reduces to a
  /// generic message: the real cause lives only in [Failure.originalError], so
  /// it is also written to the log (with its stack trace). A [Failure] thrown
  /// on purpose (a refused action) is not an unexpected error and is not logged.
  Future<Result<T>> call(Params params) async {
    try {
      final result = await execute(params);
      return Result.success(result);
    } catch (e, stackTrace) {
      if (e is! Failure) {
        AppLogger.e('$runtimeType failed', error: e, stackTrace: stackTrace);
      }
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
