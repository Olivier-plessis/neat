/// Represents a structured application error.
class Failure {
  Failure({
    required this.message,
    this.statusCode,
    this.code,
    this.originalError,
  });

  /// User-friendly error message.
  final String message;

  /// HTTP status code (e.g. 401, 500).
  final int? statusCode;

  /// Business error code returned by the API (e.g. 'USER_NOT_FOUND').
  final String? code;

  /// Original error (underlying technical exception).
  final Object? originalError;

  @override
  String toString() =>
      'Failure(message: $message, code: $code, statusCode: $statusCode)';
}
