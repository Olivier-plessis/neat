import 'package:flutter/foundation.dart';
import 'package:neat/core/utils/app_logger.dart';

void registerErrorHandler() {
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    AppLogger.f(
      details.exceptionAsString(),
      error: details.exception,
      stackTrace: details.stack,
    );
  };
}
