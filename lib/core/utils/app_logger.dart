import 'package:logger/logger.dart';

abstract final class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(),
    level: _getLogLevel(),
  );

  static Level _getLogLevel() {
    return Level.trace;
  }

  /// Trace — lifecycle, highly granular information
  static void t(dynamic message) => _logger.t(message);

  /// Debug — useful information for debugging
  static void d(dynamic message) => _logger.d(message);

  /// Info — notable business events
  static void i(dynamic message) => _logger.i(message);

  /// Warning — unexpected situation, non-blocking
  static void w(dynamic message, {Object? error, StackTrace? stackTrace}) =>
      _logger.w(message, error: error, stackTrace: stackTrace);

  /// Error — recoverable error
  static void e(dynamic message, {Object? error, StackTrace? stackTrace}) {
    _logger.e(message, error: error, stackTrace: stackTrace);
    // TODO: send to a crash reporting service (Sentry, Firebase Crashlytics, etc.)
  }

  /// Fatal — critical non-recoverable error
  static void f(dynamic message, {Object? error, StackTrace? stackTrace}) {
    _logger.f(message, error: error, stackTrace: stackTrace);
    // TODO: send to a crash reporting service (Sentry, Firebase Crashlytics, etc.)
  }
}

// Example Usage:
// final logger = AppLogger();
// logger.i("User successfully logged in.");
// logger.d("Fetching user data: $userId");
// try {
//   // some operation
// } catch (e, s) {
//   logger.e("Failed to perform operation", e, s);
// }
