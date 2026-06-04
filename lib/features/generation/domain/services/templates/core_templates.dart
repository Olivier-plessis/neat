class CoreTemplates {
  CoreTemplates._();

  // ── core/constants/app_route_path.dart ────────────────────────────────────

  static String appRoutePath({required String featureName}) {
    final c = _camel(featureName);
    return '''class AppRoutePath {
  AppRoutePath._();

  /// First feature — app entry point.
  static const String $c = '/';
}
''';
  }

  // ── core/env/app_env.dart (envied — flavor contract + singleton) ─────────

  static String appEnv() => r'''/// The environment contract shared by every flavor.
abstract interface class AppEnvFields {
  abstract final String appName;
  abstract final String apiBaseUrl;
}

/// Global access to the active environment.
/// Call [AppEnv.setEnv] in main() before runApp().
abstract interface class AppEnv implements AppEnvFields {
  static AppEnv? _instance;

  static AppEnv get current =>
      _instance ?? (throw StateError('AppEnv not set — call AppEnv.setEnv() in main().'));

  static void setEnv(AppEnv env) => _instance = env;
}
''';

  // ── core/env/envs/<flavor>_env.dart (envied generated vars + AppEnv impl) ──

  /// [flavor] is one of: dev, staging, prod.
  static String flavorEnv({required String packageName, required String flavor}) {
    final p = _pascal(flavor); // Dev / Staging / Prod
    return '''import 'package:envied/envied.dart';
import 'package:$packageName/core/env/app_env.dart';

part '${flavor}_env.g.dart';

@Envied(path: '.env.$flavor', obfuscate: true)
abstract class ${p}EnvVars {
  @EnviedField(varName: 'APP_NAME')
  static final String appName = _${p}EnvVars.appName;

  @EnviedField(varName: 'API_BASE_URL')
  static final String apiBaseUrl = _${p}EnvVars.apiBaseUrl;
}

class ${p}Env implements AppEnv {
  @override
  final String appName = ${p}EnvVars.appName;

  @override
  final String apiBaseUrl = ${p}EnvVars.apiBaseUrl;
}
''';
  }

  /// Contents of a `.env.<flavor>` (or `.env.example`) file.
  static String envFile({required String appName}) => '''APP_NAME=$appName
API_BASE_URL=
''';

  // ── core/network/network_info.dart (offline-first) ───────────────────────

  static String networkInfo() => r'''import 'package:connectivity_plus/connectivity_plus.dart';

/// Thin wrapper over connectivity_plus used by offline-first repositories to
/// decide whether to hit the network or serve from the local cache.
class NetworkInfo {
  const NetworkInfo(this._connectivity);

  final Connectivity _connectivity;

  /// True when at least one connectivity transport is available.
  Future<bool> get isConnected async {
    final results = await _connectivity.checkConnectivity();
    return !results.contains(ConnectivityResult.none);
  }

  /// Reactive connectivity stream (true = online).
  Stream<bool> get onConnectivityChanged => _connectivity.onConnectivityChanged
      .map((results) => !results.contains(ConnectivityResult.none));
}
''';

  // ── core/error/error_handler.dart (global error routing) ──────────────────

  static String errorHandler({required String packageName}) => '''import 'package:flutter/foundation.dart';
import 'package:$packageName/core/utils/app_logger.dart';

/// Routes framework (sync) and platform (async) errors to [AppLogger].
/// Call once from bootstrap(), inside the guarded zone.
void registerErrorHandler() {
  FlutterError.onError = (FlutterErrorDetails details) {
    AppLogger.e('FlutterError', error: details.exception, stackTrace: details.stack);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    AppLogger.f('Uncaught platform error', error: error, stackTrace: stack);
    return true;
  };
}
''';

  // ── core/utils/app_logger.dart (observability) ───────────────────────────

  static String appLogger({required bool useEnvied, required String packageName}) {
    if (useEnvied) {
      return '''import 'package:logger/logger.dart';
import 'package:$packageName/core/env/app_env.dart';
import 'package:$packageName/core/env/envs/prod_env.dart';

/// Centralised logger. Level is quietened to warnings in the prod flavor.
abstract final class AppLogger {
  static final Logger _logger = Logger(printer: PrettyPrinter(), level: _level());

  static Level _level() {
    try {
      return AppEnv.current is ProdEnv ? Level.warning : Level.trace;
    } catch (_) {
      return Level.trace; // env not set yet — log everything
    }
  }

  static void t(dynamic message) => _logger.t(message);
  static void d(dynamic message) => _logger.d(message);
  static void i(dynamic message) => _logger.i(message);
  static void w(dynamic message, {Object? error, StackTrace? stackTrace}) =>
      _logger.w(message, error: error, stackTrace: stackTrace);
  static void e(dynamic message, {Object? error, StackTrace? stackTrace}) =>
      _logger.e(message, error: error, stackTrace: stackTrace);
  static void f(dynamic message, {Object? error, StackTrace? stackTrace}) =>
      _logger.f(message, error: error, stackTrace: stackTrace);
}
''';
    }
    return r'''import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Centralised logger. Level is quietened to warnings in release builds.
abstract final class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(),
    level: kReleaseMode ? Level.warning : Level.trace,
  );

  static void t(dynamic message) => _logger.t(message);
  static void d(dynamic message) => _logger.d(message);
  static void i(dynamic message) => _logger.i(message);
  static void w(dynamic message, {Object? error, StackTrace? stackTrace}) =>
      _logger.w(message, error: error, stackTrace: stackTrace);
  static void e(dynamic message, {Object? error, StackTrace? stackTrace}) =>
      _logger.e(message, error: error, stackTrace: stackTrace);
  static void f(dynamic message, {Object? error, StackTrace? stackTrace}) =>
      _logger.f(message, error: error, stackTrace: stackTrace);
}
''';
  }

  // ── core/observers/provider_observer.dart (Riverpod lifecycle) ────────────

  static String riverpodObserver({
    required String packageName,
    required bool useAnnotations,
  }) {
    final riverpodImport = useAnnotations
        ? "import 'package:hooks_riverpod/hooks_riverpod.dart';"
        : "import 'package:flutter_riverpod/flutter_riverpod.dart';";
    return '''$riverpodImport
import 'package:$packageName/core/utils/app_logger.dart';

/// Logs the lifecycle of every provider (add / update / dispose / fail).
final class RiverpodObserver extends ProviderObserver {
  @override
  void didAddProvider(ProviderObserverContext context, Object? value) {
    AppLogger.d(
      'add   \${context.provider.name ?? context.provider.runtimeType} = \$value',
    );
  }

  @override
  void didUpdateProvider(
    ProviderObserverContext context,
    Object? previousValue,
    Object? newValue,
  ) {
    AppLogger.d(
      'update \${context.provider.name ?? context.provider.runtimeType}: '
      '\$previousValue → \$newValue',
    );
  }

  @override
  void didDisposeProvider(ProviderObserverContext context) {
    AppLogger.d(
      'dispose \${context.provider.name ?? context.provider.runtimeType}',
    );
  }

  @override
  void providerDidFail(
    ProviderObserverContext context,
    Object error,
    StackTrace stackTrace,
  ) {
    AppLogger.e(
      'fail   \${context.provider.name ?? context.provider.runtimeType}',
      error: error,
      stackTrace: stackTrace,
    );
  }
}
''';
  }

  // ── core/observers/logger_interceptor.dart (HTTP logging) ─────────────────

  static String loggerInterceptor({
    required String packageName,
    required String httpClient,
  }) {
    if (httpClient == 'chopper') {
      return '''import 'dart:async';

import 'package:chopper/chopper.dart';
import 'package:$packageName/core/utils/app_logger.dart';

/// Chopper interceptor that traces requests/responses via [AppLogger].
class LoggerInterceptor implements Interceptor {
  @override
  FutureOr<Response<BodyType>> intercept<BodyType>(Chain<BodyType> chain) async {
    final request = chain.request;
    AppLogger.t('→ \${request.method} \${request.url}');
    final response = await chain.proceed(request);
    final status = response.statusCode;
    final icon = status >= 200 && status < 300 ? '✅' : '⚠️';
    AppLogger.t('\$icon \${request.method} \$status \${request.url}');
    return response;
  }
}
''';
    }

    // Dio (dio / retrofit)
    return '''import 'package:dio/dio.dart';
import 'package:$packageName/core/utils/app_logger.dart';

/// Dio interceptor that traces requests/responses via [AppLogger].
/// The Authorization header is redacted so tokens never hit the logs.
class LoggerInterceptor extends Interceptor {
  static const int _maxBodyLength = 500;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    AppLogger.t(
      '→ \${options.method} \${options.uri}\\n'
      '   headers: \${_formatHeaders(options.headers)}'
      '\${options.data != null ? '\\n   body: \${_truncate(options.data.toString())}' : ''}',
    );
    handler.next(options);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    final status = response.statusCode ?? 0;
    final icon = status >= 200 && status < 300 ? '✅' : '⚠️';
    AppLogger.t(
      '\$icon \${response.requestOptions.method} \$status \${response.requestOptions.uri}\\n'
      '   body: \${_truncate(response.data.toString())}',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    AppLogger.e(
      '❌ \${err.requestOptions.method} \${err.requestOptions.uri}\\n'
      '   status: \${err.response?.statusCode}\\n'
      '   message: \${err.message}',
      error: err,
      stackTrace: err.stackTrace,
    );
    handler.next(err);
  }

  String _truncate(String value) =>
      value.length > _maxBodyLength ? '\${value.substring(0, _maxBodyLength)}…' : value;

  String _formatHeaders(Map<String, dynamic> headers) {
    final sanitized = Map<String, dynamic>.from(headers);
    if (sanitized.containsKey('Authorization')) {
      sanitized['Authorization'] = 'Bearer [REDACTED]';
    }
    return sanitized.toString();
  }
}
''';
  }

  // ── core/network/dio_provider.dart (dio / retrofit) ───────────────────────

  static String dioProvider({
    required String packageName,
    required bool useAnnotations,
    required bool useEnvied,
  }) {
    final baseUrl = useEnvied ? 'AppEnv.current.apiBaseUrl' : "''";
    final envImport =
        useEnvied ? "import 'package:$packageName/core/env/app_env.dart';\n" : '';
    if (useAnnotations) {
      return '''import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
${envImport}import 'package:$packageName/core/observers/logger_interceptor.dart';

part 'dio_provider.g.dart';

/// Configured Dio instance. Inject it into your retrofit/dio API sources.
@Riverpod(keepAlive: true)
Dio dio(Ref ref) {
  final dio = Dio(BaseOptions(baseUrl: $baseUrl));
  if (kDebugMode) {
    dio.interceptors.add(LoggerInterceptor());
  }
  return dio;
}
''';
    }
    return '''import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
${envImport}import 'package:$packageName/core/observers/logger_interceptor.dart';

/// Configured Dio instance. Inject it into your retrofit/dio API sources.
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(baseUrl: $baseUrl));
  if (kDebugMode) {
    dio.interceptors.add(LoggerInterceptor());
  }
  return dio;
});
''';
  }

  // ── core/network/chopper_client_provider.dart (chopper) ───────────────────

  static String chopperClientProvider({
    required String packageName,
    required bool useAnnotations,
    required bool useEnvied,
  }) {
    final baseUrl = useEnvied ? 'AppEnv.current.apiBaseUrl' : "''";
    final envImport =
        useEnvied ? "import 'package:$packageName/core/env/app_env.dart';\n" : '';
    if (useAnnotations) {
      return '''import 'package:chopper/chopper.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
${envImport}import 'package:$packageName/core/observers/logger_interceptor.dart';

part 'chopper_client_provider.g.dart';

/// Configured ChopperClient. Register your generated services in [services],
/// e.g. `services: [MyApiSource.create()]`, then read them with getService.
@Riverpod(keepAlive: true)
ChopperClient chopperClient(Ref ref) => ChopperClient(
      baseUrl: Uri.parse($baseUrl),
      interceptors: [if (kDebugMode) LoggerInterceptor()],
      converter: const JsonConverter(),
      services: const [],
    );
''';
    }
    return '''import 'package:chopper/chopper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
${envImport}import 'package:$packageName/core/observers/logger_interceptor.dart';

/// Configured ChopperClient. Register your generated services in [services].
final chopperClientProvider = Provider<ChopperClient>((ref) {
  return ChopperClient(
    baseUrl: Uri.parse($baseUrl),
    interceptors: [if (kDebugMode) LoggerInterceptor()],
    converter: const JsonConverter(),
    services: const [],
  );
});
''';
  }

  // ── core/sync/sync_service.dart (offline-first + sync / Outbox) ───────────

  static String syncService({
    required String packageName,
    required String localStoragePackage,
  }) => '''import 'dart:async';

import 'package:$localStoragePackage/$localStoragePackage.dart';
import 'package:$packageName/core/network/network_info.dart';

/// How a single queued write is pushed to the backend. Return true on success
/// (the entry is then removed), false to keep it for a later retry.
///
/// Wire this to your HTTP client, e.g.:
/// ```dart
/// SyncService(db, network, (e) async {
///   final res = await dio.request(e.endpoint,
///       data: e.payload, options: Options(method: 'POST'));
///   return res.statusCode == 200 || res.statusCode == 201;
/// });
/// ```
typedef OutboxReplay = Future<bool> Function(OutboxEntry entry);

/// Drains the Outbox queue when connectivity returns.
class SyncService {
  SyncService(this._db, this._network, this._replay);

  final AppDatabase _db;
  final NetworkInfo _network;
  final OutboxReplay _replay;

  StreamSubscription<bool>? _sub;

  /// Start listening for connectivity; flush automatically when back online.
  void start() {
    _sub = _network.onConnectivityChanged.listen((online) {
      if (online) flush();
    });
  }

  /// Replay every pending write. Successful ones are removed; failures bump
  /// their retry counter and stay queued.
  Future<void> flush() async {
    if (!await _network.isConnected) return;
    for (final entry in await _db.pendingOutbox()) {
      try {
        if (await _replay(entry)) {
          await _db.deleteOutbox(entry.id);
        } else {
          await _db.incrementRetry(entry.id);
        }
      } catch (_) {
        await _db.incrementRetry(entry.id);
      }
    }
  }

  Future<void> dispose() async => _sub?.cancel();
}
''';

  // ── core/error/failure.dart ───────────────────────────────────────────────

  static String failure() => r'''sealed class Failure {
  const Failure(this.message);
  final String message;
}

final class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Network error. Please check your connection.']);
}

final class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Server error. Please try again later.']);
  final int? statusCode = null;
}

final class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Cache error. Please try again.']);
}

final class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'An unexpected error occurred.']);
}
''';

  // ── core/utils/extensions.dart ────────────────────────────────────────────

  static String extensions() => r'''extension StringX on String {
  bool get isNullOrEmpty => isEmpty;

  String get capitalize =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';

  String? get nullIfEmpty => isEmpty ? null : this;
}

extension IterableX<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;

  T? firstWhereOrNull(bool Function(T) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
''';

  // ── core/router/app_router.dart (basic GoRouter, no builder) ─────────────

  static String appRouter({required String packageName, required String featureName}) =>
      '''import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:$packageName/core/constants/app_route_path.dart';
import 'package:$packageName/features/$featureName/presentation/pages/${featureName}_page.dart';

final appRouter = GoRouter(
  initialLocation: AppRoutePath.${_camel(featureName)},
  debugLogDiagnostics: true,
  routes: [
    GoRoute(
      path: AppRoutePath.${_camel(featureName)},
      builder: (context, state) => const ${_pascal(featureName)}Page(),
    ),
  ],
);
''';

  // ── core/router/app_router.dart (go_router_builder + riverpod) ───────────

  static String appRouterBuilder({
    required String packageName,
    required String featureName,
    required bool useAnnotations,
  }) {
    final c = _camel(featureName);
    if (useAnnotations) {
      return '''import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:$packageName/core/constants/app_route_path.dart';
import 'routes.dart';

part 'app_router.g.dart';

@Riverpod(keepAlive: true)
RouterConfig<Object> appRouter(Ref ref) => GoRouter(
  initialLocation: AppRoutePath.$c,
  debugLogDiagnostics: true,
  routes: appRoutes,
);
''';
    }
    return '''import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:$packageName/core/constants/app_route_path.dart';
import 'routes.dart';

final appRouter = GoRouter(
  initialLocation: AppRoutePath.$c,
  debugLogDiagnostics: true,
  routes: appRoutes,
);
''';
  }

  // ── core/router/routes.dart (aggregator of per-feature routes) ───────────

  /// Aggregates each feature's generated `\$appRoutes`. New features add an
  /// aliased import + spread here.
  static String routesAggregator({required String packageName, required String featureName}) =>
      '''import 'package:go_router/go_router.dart';
import 'package:$packageName/features/$featureName/presentation/routes/${featureName}_routes.dart'
    as $featureName;

/// Aggregated app routes.
///
/// To add a feature: create its `<feature>_routes.dart` under the feature's
/// presentation/routes/ folder, then import it here with an alias and spread
/// its generated `\$appRoutes`.
final List<RouteBase> appRoutes = [
  ...$featureName.\$appRoutes,
];
''';

  // ── features/<f>/presentation/routes/<f>_routes.dart (typed routes) ──────

  static String featureRoutes({required String packageName, required String featureName}) =>
      '''import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:$packageName/core/constants/app_route_path.dart';
import 'package:$packageName/features/$featureName/presentation/pages/${featureName}_page.dart';

part '${featureName}_routes.g.dart';

@TypedGoRoute<${_pascal(featureName)}Route>(path: AppRoutePath.${_camel(featureName)})
class ${_pascal(featureName)}Route extends GoRouteData with \$${_pascal(featureName)}Route {
  const ${_pascal(featureName)}Route();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const ${_pascal(featureName)}Page();
}
''';

  // ── core/router/routes.dart (manual) ─────────────────────────────────────

  static String routesManual({required String packageName, required String featureName}) =>
      '''import 'package:go_router/go_router.dart';
import 'package:$packageName/features/$featureName/presentation/pages/${featureName}_page.dart';

final appRoutes = [
  GoRoute(
    path: '/',
    builder: (context, state) => const ${_pascal(featureName)}Page(),
  ),
];
''';

  static String _pascal(String s) => s.isEmpty
      ? s
      : s.split('_').map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1)).join();

  static String _camel(String s) {
    final p = _pascal(s);
    return p.isEmpty ? p : p[0].toLowerCase() + p.substring(1);
  }
}
