import 'package:dio/dio.dart';
import 'package:neat/core/utils/app_logger.dart';

/// Intercepteur Dio qui trace toutes les requêtes/réponses dans la console.
/// Ajouté uniquement en debug/staging (voir [dioProvider]).
class LoggerInterceptor extends Interceptor {
  // Longueur max du body affiché (évite de noyer la console)
  static const int _maxBodyLength = 500;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    AppLogger.t(
      '→ ${options.method} ${options.uri}\n'
      '   headers: ${_formatHeaders(options.headers)}\n'
      '${options.data != null ? '   body: ${_truncate(options.data.toString())}' : ''}',
    );
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    final status = response.statusCode ?? 0;
    final icon = status >= 200 && status < 300 ? '✅' : '⚠️';
    AppLogger.t(
      '$icon ${response.requestOptions.method} $status '
      '${response.requestOptions.uri}\n'
      '   body: ${_truncate(response.data.toString())}',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final is401 = err.response?.statusCode == 401;
    final logFn = is401 ? AppLogger.w : AppLogger.e;

    logFn(
      '❌ ${err.requestOptions.method} ${err.requestOptions.uri}\n'
      '   status: ${err.response?.statusCode}\n'
      '   message: ${err.message}\n'
      '   response: ${_truncate(err.response?.data.toString() ?? '')}',
      error: is401 ? null : err,
      stackTrace: is401 ? null : err.stackTrace,
    );
    handler.next(err);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _truncate(String value) => value.length > _maxBodyLength
      ? '${value.substring(0, _maxBodyLength)}…'
      : value;

  String _formatHeaders(Map<String, dynamic> headers) {
    // Masque le token Bearer pour ne pas l'exposer en clair dans les logs
    final sanitized = Map<String, dynamic>.from(headers);
    if (sanitized.containsKey('Authorization')) {
      sanitized['Authorization'] = 'Bearer [REDACTED]';
    }
    return sanitized.toString();
  }
}
