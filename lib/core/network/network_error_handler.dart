import 'package:flutter/foundation.dart';
import 'package:neat/core/error/failure.dart';

/// Converts technical exceptions thrown by use cases into an application
/// [Failure]. NEAT's networking is chopper-based, so this stays transport
/// agnostic — any error maps to a user-readable failure.
class NetworkErrorHandler {
  static Failure handle(Object error) {
    if (kDebugMode) {
      debugPrint('⛔ NetworkErrorHandler — ${error.runtimeType} → $error');
    }
    return Failure(
      message: 'Une erreur inattendue est survenue.',
      originalError: error,
    );
  }
}
