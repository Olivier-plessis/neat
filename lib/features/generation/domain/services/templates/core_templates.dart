class CoreTemplates {
  CoreTemplates._();

  // ── core/constants/app_route_path.dart ────────────────────────────────────

  static String appRoutePath({required String featureName, bool hasAuth = false}) {
    final c = _camel(featureName);
    final auth = hasAuth
        ? "\n  static const String login = '/login';\n"
            "  static const String signup = '/signup';\n"
            "  static const String forgotPassword = '/forgot-password';\n"
        : '';
    return '''class AppRoutePath {
  AppRoutePath._();

  /// First feature — app entry point.
  static const String $c = '/';
$auth  // neat:routes — feature route constants are inserted above this line.
}
''';
  }

  // ── core/env/app_env.dart (envied — flavor contract + singleton) ─────────

  static String appEnv({bool hasApiBaseUrl = true, bool hasSupabase = false}) {
    final api = hasApiBaseUrl ? '  abstract final String apiBaseUrl;\n' : '';
    final supa = hasSupabase
        ? '  abstract final String supabaseUrl;\n  abstract final String supabasePublishableKey;\n'
        : '';
    return '''/// The environment contract shared by every flavor.
abstract interface class AppEnvFields {
  abstract final String appName;
$api$supa}

/// Global access to the active environment.
/// Call [AppEnv.setEnv] in main() before runApp().
abstract interface class AppEnv implements AppEnvFields {
  static AppEnv? _instance;

  static AppEnv get current =>
      _instance ?? (throw StateError('AppEnv not set — call AppEnv.setEnv() in main().'));

  static void setEnv(AppEnv env) => _instance = env;
}
''';
  }

  // ── core/env/envs/<flavor>_env.dart (envied generated vars + AppEnv impl) ──

  /// [flavor] is one of: dev, staging, prod.
  static String flavorEnv({
    required String packageName,
    required String flavor,
    bool hasApiBaseUrl = true,
    bool hasSupabase = false,
  }) {
    final p = _pascal(flavor); // Dev / Staging / Prod
    final apiField = hasApiBaseUrl
        ? "\n\n  @EnviedField(varName: 'API_BASE_URL')\n"
            '  static final String apiBaseUrl = _${p}EnvVars.apiBaseUrl;'
        : '';
    final apiImpl = hasApiBaseUrl
        ? '\n\n  @override\n  final String apiBaseUrl = ${p}EnvVars.apiBaseUrl;'
        : '';
    final supaFields = hasSupabase
        ? '''

  @EnviedField(varName: 'SUPABASE_URL')
  static final String supabaseUrl = _${p}EnvVars.supabaseUrl;

  @EnviedField(varName: 'SUPABASE_PUBLISHABLE_KEY')
  static final String supabasePublishableKey = _${p}EnvVars.supabasePublishableKey;'''
        : '';
    final supaImpl = hasSupabase
        ? '''

  @override
  final String supabaseUrl = ${p}EnvVars.supabaseUrl;

  @override
  final String supabasePublishableKey = ${p}EnvVars.supabasePublishableKey;'''
        : '';
    return '''import 'package:envied/envied.dart';
import 'package:$packageName/core/env/app_env.dart';

part '${flavor}_env.g.dart';

@Envied(path: '.env.$flavor', obfuscate: true)
abstract class ${p}EnvVars {
  @EnviedField(varName: 'APP_NAME')
  static final String appName = _${p}EnvVars.appName;$apiField$supaFields
}

class ${p}Env implements AppEnv {
  @override
  final String appName = ${p}EnvVars.appName;$apiImpl$supaImpl
}
''';
  }

  /// Contents of a `.env.<flavor>` (or `.env.example`) file.
  static String envFile({
    required String appName,
    bool hasApiBaseUrl = true,
    bool hasSupabase = false,
  }) {
    final api = hasApiBaseUrl ? 'API_BASE_URL=\n' : '';
    final supa = hasSupabase ? 'SUPABASE_URL=\nSUPABASE_PUBLISHABLE_KEY=\n' : '';
    return '''APP_NAME=$appName
$api$supa''';
  }

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

  // ── core/network/supabase_provider.dart (Supabase backend) ────────────────

  /// Exposes the initialized [SupabaseClient] as a provider. The client is set
  /// up once in bootstrap via `Supabase.initialize(...)`.
  static String supabaseProvider({
    required String packageName,
    required bool useAnnotations,
  }) {
    if (useAnnotations) {
      return '''import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'supabase_provider.g.dart';

/// The app-wide Supabase client (initialized in bootstrap).
@Riverpod(keepAlive: true)
SupabaseClient supabaseClient(Ref ref) => Supabase.instance.client;

/// Convenience: the current auth state stream.
@Riverpod(keepAlive: true)
Stream<AuthState> authState(Ref ref) =>
    ref.watch(supabaseClientProvider).auth.onAuthStateChange;
''';
    }
    return '''import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The app-wide Supabase client (initialized in bootstrap).
final supabaseClientProvider =
    Provider<SupabaseClient>((ref) => Supabase.instance.client);
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

  /// A write that keeps failing is parked after this many attempts (kept in the
  /// table for inspection, but no longer retried) so it can't loop forever.
  static const int maxRetries = 5;

  StreamSubscription<bool>? _sub;

  /// Start listening for connectivity; flush automatically when back online.
  void start() {
    _sub = _network.onConnectivityChanged.listen((online) {
      if (online) flush();
    });
  }

  /// Replay every pending write, oldest first. Successful ones are removed;
  /// failures bump their retry counter; entries past [maxRetries] are skipped.
  Future<void> flush() async {
    if (!await _network.isConnected) return;
    for (final entry in await _db.pendingOutbox()) {
      if (entry.retryCount >= maxRetries) continue; // parked — give up
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

  /// Writes that exhausted their retries — surface these to the user / a report.
  Future<List<OutboxEntry>> failedWrites() async =>
      (await _db.pendingOutbox()).where((e) => e.retryCount >= maxRetries).toList();

  Future<void> dispose() async => _sub?.cancel();
}
''';

  // ── docs/OFFLINE.md (offline-first usage guide) ──────────────────────────

  static String offlineDoc({
    required String packageName,
    required String featureName,
    required String localStoragePackage,
    required bool hasSync,
  }) {
    final p = _pascal(featureName);
    final c = _camel(featureName);

    final syncIntro = hasSync
        ? 'reads are local-first with a cache fallback, and **writes work offline**: they are applied to the local DB immediately and queued in an Outbox that a `SyncService` replays when connectivity returns.'
        : 'reads are local-first with a cache fallback. Writes require connectivity (they are not queued — pick the **Offline + Sync** strategy for offline writes).';

    final writeSection = hasSync
        ? '''

## Writing (offline-capable)

`create` / `update` / `delete` are **optimistic**: the local Drift table is updated
immediately, then the operation is appended to the Outbox.

```dart
final create = ref.read(create${p}UsecaseProvider);
await create.execute(const ${p}Entity(id: '1', name: 'Ada'));
// → row upserted locally now; POST replayed automatically once online.
```

### The Outbox + SyncService

Every offline write becomes a row in the `OutboxEntries` table
(`operation`, `endpoint`, `payload`, `retryCount`). The `${c}SyncProvider`
starts a `SyncService` that listens to connectivity and, when back online,
**replays each queued write through the API source**, deleting it on success.

```dart
// Activate the sync engine once, high in the widget tree:
ref.watch(${c}SyncProvider);
```

- Successful replays are removed from the queue.
- Failing ones bump `retryCount`; after `SyncService.maxRetries` attempts they
  are **parked** (kept for inspection via `SyncService.failedWrites()`, never
  retried in a loop).
- ⚠️ No conflict resolution / exponential backoff out of the box — add your own
  policy in the replay callback (`core/sync/sync_service.dart`) if needed.'''
        : '';

    return '''# Offline-first

This project was generated with an **offline-first data layer**: $syncIntro

## Layout (Dart workspace)

```
$packageName/
├── pubspec.yaml                      # workspace root (the app)
├── packages/
│   └── $localStoragePackage/         # Drift database (typed tables + Outbox)
└── lib/
    ├── core/
    │   ├── network/network_info.dart # connectivity (connectivity_plus)
    │   ${hasSync ? '└── sync/sync_service.dart    # Outbox replay engine' : ''}
    └── features/$featureName/
        ├── data/sources/             # ${p}ApiSource (remote) + ${p}LocalSource (Drift)
        ├── data/repositories/        # offline-first orchestration
        └── presentation/providers/   # ${featureName}_providers.dart (the DI graph)
```

## Data flow

```
read  → repository.getAll()
          online?  → API  → write-through cache (Drift)  → entities
          offline? → Drift cache                          → entities
${hasSync ? '''write → repository.create/update/delete()
          → upsert/delete local (optimistic)
          → enqueue Outbox  → replayed by SyncService when online''' : 'write → requires connectivity (no queue in read-only mode)'}
```

## Wiring (already done)

Everything is wired as `keepAlive` Riverpod providers in
`lib/features/$featureName/presentation/providers/${featureName}_providers.dart`:

| Provider | What it gives |
|---|---|
| `${c}ApiSourceProvider` | remote source (uses the core dio/chopper client) |
| `appDatabaseProvider` | the Drift `AppDatabase` |
| `${c}LocalSourceProvider` | Drift-backed local source |
| `networkInfoProvider` | connectivity wrapper |
| `${c}RepositoryProvider` | offline-first repository |
| `get/create/update/delete${p}UsecaseProvider` | the usecases |
${hasSync ? '| `${c}SyncProvider` | the Outbox sync engine (auto-starts) |' : ''}

## Reading

```dart
final usecase = ref.watch(get${p}UsecaseProvider);
final result = await usecase.execute(); // local-first, refreshed from the API when online
```
$writeSection

## API base URL

The base URL flows from your env (`AppEnv.current.apiBaseUrl`, set in `bootstrap`)
into the core dio/chopper client provider. The API source's per-resource path
(e.g. `/${featureName}s`) is appended to it.

## Extending

- **More columns**: edit the `${p}Rows` table in
  `packages/$localStoragePackage/lib/src/database.dart`, then re-run
  `dart run build_runner build` **inside that package**, and update the
  row↔model mapping in `${p}LocalSource`.
- **New feature**: mirror the `$featureName` data layer + add its providers.
'''
        '${hasSync ? '\n- **Replay policy**: customise retries/backoff/conflicts in `SyncService`.\n' : '\n'}';
  }

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
      '''import 'package:go_router/go_router.dart';
import 'package:$packageName/core/constants/app_route_path.dart';
import 'routes.dart';

final appRouter = GoRouter(
  initialLocation: AppRoutePath.${_camel(featureName)},
  debugLogDiagnostics: true,
  routes: appRoutes,
);
''';

  // ── core/router/app_router.dart (go_router_builder + riverpod) ───────────

  static String appRouterBuilder({
    required String packageName,
    required String featureName,
    required bool useAnnotations,
    bool hasAuth = false,
  }) {
    final c = _camel(featureName);
    if (useAnnotations) {
      // Auth wires a RouterNotifier guard (refreshListenable + redirect).
      final authImport = hasAuth
          ? "import 'package:$packageName/core/router/router_notifier.dart';\n"
          : '';
      final body = hasAuth
          ? '''RouterConfig<Object> appRouter(Ref ref) {
  // riverpod strips the "Notifier" suffix: RouterNotifier → routerProvider.
  final guard = ref.watch(routerProvider.notifier);
  return GoRouter(
    initialLocation: AppRoutePath.$c,
    debugLogDiagnostics: true,
    refreshListenable: guard,
    redirect: guard.redirect,
    routes: appRoutes,
  );
}'''
          : '''RouterConfig<Object> appRouter(Ref ref) => GoRouter(
  initialLocation: AppRoutePath.$c,
  debugLogDiagnostics: true,
  routes: appRoutes,
);''';
      return '''import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:$packageName/core/constants/app_route_path.dart';
${authImport}import 'routes.dart';

part 'app_router.g.dart';

@Riverpod(keepAlive: true)
$body
''';
    }
    return '''import 'package:go_router/go_router.dart';
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
// neat:route-imports

/// Aggregated app routes. NEAT inserts new features at the anchors below.
final List<RouteBase> appRoutes = [
  ...$featureName.\$appRoutes,
  // neat:route-entries
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
import 'package:$packageName/core/constants/app_route_path.dart';
import 'package:$packageName/features/$featureName/presentation/pages/${featureName}_page.dart';
// neat:route-imports

/// App routes. NEAT inserts new features at the anchors below.
final List<RouteBase> appRoutes = [
  GoRoute(
    path: AppRoutePath.${_camel(featureName)},
    builder: (context, state) => const ${_pascal(featureName)}Page(),
  ),
  // neat:route-entries
];
''';

  // ── routes.dart rooted in a navigation shell (bottom nav from launch) ─────

  /// `routes.dart` for a shell-rooted app (go_router_builder): the only top-level
  /// route is the typed shell, so the bottom NavigationBar is the app's spine.
  static String routesAggregatorShell({required String packageName}) =>
      '''import 'package:go_router/go_router.dart';
import 'package:$packageName/core/router/app_shell_route.dart' as app_shell;
// neat:route-imports

/// Aggregated app routes. The app boots into the navigation shell; NEAT inserts
/// new features at the anchors below.
final List<RouteBase> appRoutes = [
  ...app_shell.\$appRoutes,
  // neat:route-entries
];
''';

  /// `routes.dart` for a shell-rooted app (plain go_router): the first feature is
  /// the shell's first branch, wrapped in a [StatefulShellRoute].
  static String routesManualShell({required String packageName, required String featureName}) =>
      '''import 'package:go_router/go_router.dart';
import 'package:$packageName/core/constants/app_route_path.dart';
import 'package:$packageName/core/router/scaffold_with_nav_bar.dart';
import 'package:$packageName/features/$featureName/presentation/pages/${featureName}_page.dart';
// neat:route-imports

/// Aggregated app routes. The app boots into the navigation shell; NEAT inserts
/// new features at the anchors below.
final List<RouteBase> appRoutes = [
${shellRouteEntryPlain(featureName: featureName)}
  // neat:route-entries
];
''';

  // ── core/providers/infrastructure_providers.dart (shared singletons) ──────

  /// App-wide infrastructure singletons (Drift database + connectivity),
  /// declared ONCE here rather than in each feature's DI graph. This guarantees
  /// every feature shares a single SQLite connection and a single connectivity
  /// stream — avoiding duplicate `AppDatabase` instances and lock contention.
  static String infrastructureProviders({
    required String packageName,
    required String localStoragePackage,
  }) =>
      '''import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:$localStoragePackage/$localStoragePackage.dart';
import 'package:$packageName/core/network/network_info.dart';

part 'infrastructure_providers.g.dart';

/// The single Drift database for the whole app. Every feature's local source
/// watches this provider, so they all share one connection.
@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) => AppDatabase();

/// App-wide connectivity. Shared by every offline-first repository + the
/// SyncService so connectivity is observed once.
@Riverpod(keepAlive: true)
NetworkInfo networkInfo(Ref ref) => NetworkInfo(Connectivity());
''';

  // ── Branding: app icons + splash from a logo ──────────────────────────────

  /// `flutter_launcher_icons.yaml` — generates platform app icons from the logo.
  static String launcherIconsConfig({
    String imagePath = 'assets/branding/logo.png',
    String adaptiveBackground = '#FFFFFF',
  }) =>
      '''flutter_launcher_icons:
  image_path: "$imagePath"
  android: true
  ios: true
  min_sdk_android: 21
  remove_alpha_ios: true
  adaptive_icon_background: "$adaptiveBackground"
  adaptive_icon_foreground: "$imagePath"
  web:
    generate: true
    image_path: "$imagePath"
  macos:
    generate: true
    image_path: "$imagePath"
  windows:
    generate: true
    image_path: "$imagePath"
''';

  /// `flutter_native_splash.yaml` — generates the native splash screen.
  static String nativeSplashConfig({
    String imagePath = 'assets/branding/logo.png',
    String colorLight = '#FFFFFF',
    String colorDark = '#0E0E0E',
  }) =>
      '''flutter_native_splash:
  color: "$colorLight"
  color_dark: "$colorDark"
  image: $imagePath
  image_dark: $imagePath
  android_12:
    image: $imagePath
    icon_background_color: "$colorLight"
    image_dark: $imagePath
    icon_background_color_dark: "$colorDark"
  android: true
  ios: true
  web: true
''';

  // ── Shell scaffold (bottom NavigationBar driven by a StatefulShellRoute) ──

  /// `lib/core/router/scaffold_with_nav_bar.dart` — created with the first shell
  /// branch. Subsequent branches insert a [NavigationDestination] at the anchor.
  static String scaffoldWithNavBar({required String firstIcon, required String firstLabel}) =>
      '''import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Shell scaffold: a bottom [NavigationBar] driven by the [StatefulShellRoute].
/// Each branch keeps its own navigation stack; tapping a destination switches
/// branches (re-tapping the current one pops to its root).
class ScaffoldWithNavBar extends StatelessWidget {
  const ScaffoldWithNavBar({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final destinations = <NavigationDestination>[
      const NavigationDestination(icon: Icon(Icons.$firstIcon), label: '$firstLabel'),
      // neat:shell-destinations
    ];
    return Scaffold(
      body: navigationShell,
      // A NavigationBar requires >= 2 destinations. With a single shell branch
      // we show none until more branches are added (e.g. via the NEAT Workshop).
      bottomNavigationBar: destinations.length >= 2
          ? NavigationBar(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: (index) => navigationShell.goBranch(
                index,
                initialLocation: index == navigationShell.currentIndex,
              ),
              destinations: destinations,
            )
          : null,
    );
  }
}
''';

  /// A single `NavigationDestination` line, inserted at the destinations anchor.
  static String shellDestination({required String icon, required String label}) =>
      "      const NavigationDestination(icon: Icon(Icons.$icon), label: '$label'),";

  // ── Shell route — plain go_router ─────────────────────────────────────────

  /// The whole `StatefulShellRoute.indexedStack(...)` block (first branch +
  /// anchors), inserted into `appRoutes` when the first shell branch is added.
  static String shellRouteEntryPlain({required String featureName}) {
    final p = _pascal(featureName);
    final c = _camel(featureName);
    return '''  StatefulShellRoute.indexedStack(
    builder: (context, state, navigationShell) =>
        ScaffoldWithNavBar(navigationShell: navigationShell),
    branches: [
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: AppRoutePath.$c,
            builder: (context, state) => const ${p}Page(),
          ),
        ],
      ),
      // neat:shell-branches
    ],
  ),''';
  }

  /// A single `StatefulShellBranch` block, inserted at the branches anchor.
  static String shellBranchPlain({required String featureName}) {
    final p = _pascal(featureName);
    final c = _camel(featureName);
    return '''      StatefulShellBranch(
        routes: [
          GoRoute(
            path: AppRoutePath.$c,
            builder: (context, state) => const ${p}Page(),
          ),
        ],
      ),''';
  }

  // ── Shell route — go_router_builder (typed) ───────────────────────────────

  /// The full `lib/core/router/app_shell_route.dart` (typed shell with the first
  /// branch + anchors), created when the first shell branch is added.
  static String appShellRouteBuilder({
    required String packageName,
    required String featureName,
  }) {
    final p = _pascal(featureName);
    final c = _camel(featureName);
    return '''import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:$packageName/core/constants/app_route_path.dart';
import 'package:$packageName/core/router/scaffold_with_nav_bar.dart';
import 'package:$packageName/features/$featureName/presentation/pages/${featureName}_page.dart';
// neat:shell-imports

part 'app_shell_route.g.dart';

@TypedStatefulShellRoute<AppShellRouteData>(
  branches: [
    TypedStatefulShellBranch<${p}BranchData>(
      routes: [
        TypedGoRoute<${p}Route>(path: AppRoutePath.$c),
      ],
    ),
    // neat:shell-branches
  ],
)
class AppShellRouteData extends StatefulShellRouteData {
  const AppShellRouteData();

  @override
  Widget builder(
    BuildContext context,
    GoRouterState state,
    StatefulNavigationShell navigationShell,
  ) =>
      ScaffoldWithNavBar(navigationShell: navigationShell);
}

class ${p}BranchData extends StatefulShellBranchData {
  const ${p}BranchData();
}

class ${p}Route extends GoRouteData with \$${p}Route {
  const ${p}Route();

  @override
  Widget build(BuildContext context, GoRouterState state) => const ${p}Page();
}
// neat:shell-classes
''';
  }

  /// A single `TypedStatefulShellBranch` block, inserted at the branches anchor.
  static String shellBranchBuilder({required String featureName}) {
    final p = _pascal(featureName);
    final c = _camel(featureName);
    return '''    TypedStatefulShellBranch<${p}BranchData>(
      routes: [
        TypedGoRoute<${p}Route>(path: AppRoutePath.$c),
      ],
    ),''';
  }

  /// The branch's `BranchData` + `GoRouteData` classes, inserted at the classes
  /// anchor (the builder generates the `\$<Feature>Route` mixin from the tree).
  static String shellBranchClassesBuilder({required String featureName}) {
    final p = _pascal(featureName);
    return '''class ${p}BranchData extends StatefulShellBranchData {
  const ${p}BranchData();
}

class ${p}Route extends GoRouteData with \$${p}Route {
  const ${p}Route();

  @override
  Widget build(BuildContext context, GoRouterState state) => const ${p}Page();
}
''';
  }

  static String _pascal(String s) => s.isEmpty
      ? s
      : s.split('_').map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1)).join();

  static String _camel(String s) {
    final p = _pascal(s);
    return p.isEmpty ? p : p[0].toLowerCase() + p.substring(1);
  }
}
