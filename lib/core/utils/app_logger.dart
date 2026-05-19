import 'package:logger/logger.dart';

abstract final class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(),
    level: _getLogLevel(),
  );

  static Level _getLogLevel() {
    return Level.trace;
  }

  /// Trace — cycle de vie, informations très granulaires
  static void t(dynamic message) => _logger.t(message);

  /// Debug — informations utiles au débogage
  static void d(dynamic message) => _logger.d(message);

  /// Info — événements métier notables
  static void i(dynamic message) => _logger.i(message);

  /// Warning — situation inattendue, non bloquante
  static void w(dynamic message, {Object? error, StackTrace? stackTrace}) =>
      _logger.w(message, error: error, stackTrace: stackTrace);

  /// Error — erreur récupérable
  static void e(dynamic message, {Object? error, StackTrace? stackTrace}) {
    _logger.e(message, error: error, stackTrace: stackTrace);
    // TODO: envoyer vers un service crash (Sentry, Firebase Crashlytics…)
  }

  /// Fatal — erreur critique non récupérable
  static void f(dynamic message, {Object? error, StackTrace? stackTrace}) {
    _logger.f(message, error: error, stackTrace: stackTrace);
    // TODO: envoyer vers un service crash (Sentry, Firebase Crashlytics…)
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
