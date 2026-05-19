/// Représente une erreur applicative structurée.
class Failure {
  Failure({
    required this.message,
    this.statusCode,
    this.code,
    this.originalError,
  });

  /// Message lisible par l'utilisateur.
  final String message;

  /// Code de statut HTTP (ex: 401, 500).
  final int? statusCode;

  /// Code d'erreur métier renvoyé par l'API (ex: 'USER_NOT_FOUND').
  final String? code;

  /// L'erreur d'origine (souvent une DioException).
  final Object? originalError;

  @override
  String toString() => 'Failure(message: $message, code: $code, statusCode: $statusCode)';
}
