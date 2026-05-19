import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:neat/core/error/failure.dart';

/// Gère la conversion des exceptions techniques en [Failure] applicatif.
/// Utilisé par les différents modules de l'application (Admin, Doctor, etc.).
class NetworkErrorHandler {
  static Failure handle(Object error) {
    if (error is DioException) {
      return _handleDioError(error);
    }
    if (kDebugMode) {
      debugPrint('⛔ NetworkErrorHandler — exception non-Dio : ${error.runtimeType} → $error');
    }
    return Failure(message: 'Une erreur inattendue est survenue.');
  }

  static Failure _handleDioError(DioException error) {
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => Failure(
        message: 'Le serveur met trop de temps à répondre. Vérifiez votre connexion.',
        originalError: error,
      ),
      DioExceptionType.connectionError => Failure(
        message: 'Impossible de contacter le serveur. Vérifiez votre connexion internet.',
        originalError: error,
      ),
      DioExceptionType.badResponse => _handleBadResponse(error),
      DioExceptionType.cancel => Failure(message: 'La requête a été annulée.'),
      _ => Failure(
        message: 'Une erreur réseau est survenue (${error.message}).',
        originalError: error,
      ),
    };
  }

  static Failure _handleBadResponse(DioException error) {
    final response = error.response;
    final statusCode = response?.statusCode;
    final data = response?.data;

    String? serverMessage;
    String? serverCode;

    if (data is Map<String, dynamic>) {
      // Structure standard de l'API : { "message": "...", "code": "..." }
      serverMessage = data['message']?.toString();
      serverCode = data['code']?.toString();

      // Parfois imbriqué dans un objet "error"
      final errorData = data['error'];
      if (errorData is Map) {
        serverMessage = errorData['message']?.toString() ?? serverMessage;
        serverCode = errorData['code']?.toString() ?? serverCode;
      }
    }

    final message = switch (statusCode) {
      400 => serverMessage ?? 'Requête invalide.',
      401 =>
        serverMessage == 'Unauthorized'
            ? 'Votre session a expiré. Veuillez vous reconnecter.'
            : (serverMessage ?? 'Identifiants incorrects ou session expirée.'),
      403 => serverMessage ?? 'Accès non autorisé.',
      404 => serverMessage ?? 'Ressource introuvable.',
      409 => serverMessage ?? 'Cette ressource existe déjà.',
      422 => serverMessage ?? 'Données invalides.',
      500 => 'Erreur interne du serveur. Réessayez plus tard.',
      _ => serverMessage ?? 'Une erreur serveur est survenue ($statusCode).',
    };

    return Failure(
      message: message,
      statusCode: statusCode,
      code: serverCode,
      originalError: error,
    );
  }
}
