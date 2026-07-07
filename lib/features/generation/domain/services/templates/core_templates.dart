import 'package:neat/features/generation/domain/models/field_spec.dart';
import 'package:neat/features/generation/domain/services/templates/dart/field_codegen.dart';

class CoreTemplates {
  CoreTemplates._();

  // ── core/constants/app_route_path.dart ────────────────────────────────────

  static String appRoutePath({
    required String featureName,
    bool hasFirstFeature = true,
    bool hasAuth = false,
  }) {
    final auth = hasAuth
        ? "\n  static const String login = '/login';\n"
            "  static const String signup = '/signup';\n"
            "  static const String forgotPassword = '/forgot-password';\n"
        : '';
    final entry = hasFirstFeature
        ? '  /// First feature — app entry point.\n'
            "  static const String ${_camel(featureName)} = '/';\n"
        : '  /// No first feature — the welcome placeholder owns the app\'s root\n'
            '  /// route until you add one via the Workshop.\n'
            "  static const String welcome = '/';\n";
    return '''class AppRoutePath {
  AppRoutePath._();

$entry$auth  // neat:routes — feature route constants are inserted above this line.
}
''';
  }

  // ── core/pages/welcome_page.dart (zero-feature fallback) ─────────────────

  /// Shown at `/` when [ArchitectureState.generateFirstFeature] is off — the
  /// app ships with no features yet, so something has to own the root route.
  static String welcomePage({required String packageName, required String appName}) =>
      '''import 'package:flutter/material.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.rocket_launch_outlined, size: 48),
              const SizedBox(height: 16),
              Text('Welcome to $appName', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                'No feature yet — open this project in the NEAT Workshop to add your first one.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
''';

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

  /// [flavor] is one of: dev, staging, prod. When [single] is true (a single
  /// environment), the class prefix is dropped → `EnvVars`/`Env` reading a plain
  /// `.env` (part `env.g.dart`), instead of `<Flavor>EnvVars`/`<Flavor>Env`.
  static String flavorEnv({
    required String packageName,
    required String flavor,
    bool single = false,
    bool hasApiBaseUrl = true,
    bool hasSupabase = false,
  }) {
    final p = single ? '' : _pascal(flavor); // '' / Dev / Staging / Prod
    // Source file is env.dart (single) or <flavor>_env.dart → matching part.
    final partFile = single ? 'env.g.dart' : '${flavor}_env.g.dart';
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
    final envPath = single ? '.env' : '.env.$flavor';
    return '''import 'package:envied/envied.dart';
import 'package:$packageName/core/env/app_env.dart';

part '$partFile';

@Envied(path: '$envPath', obfuscate: true)
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

  /// Contents of a `.env.<flavor>` (or `.env.example`) file. [apiBaseUrl]
  /// pre-fills `API_BASE_URL` (blank when not provided).
  static String envFile({
    required String appName,
    bool hasApiBaseUrl = true,
    bool hasSupabase = false,
    String apiBaseUrl = '',
    String supabaseUrl = '',
    String supabaseKey = '',
  }) {
    final api = hasApiBaseUrl ? 'API_BASE_URL=$apiBaseUrl\n' : '';
    final supa =
        hasSupabase ? 'SUPABASE_URL=$supabaseUrl\nSUPABASE_PUBLISHABLE_KEY=$supabaseKey\n' : '';
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

  static String errorHandler({required String packageName, String? corePackageName}) =>
      '''import 'package:flutter/foundation.dart';
import 'package:${corePackageName ?? packageName}/core/utils/app_logger.dart';

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

  static String appLogger({
    required bool useEnvied,
    required String packageName,
    String prodFlavor = 'prod',
  }) {
    if (useEnvied) {
      final prodEnv = '${_pascal(prodFlavor)}Env';
      return '''import 'package:logger/logger.dart';
import 'package:$packageName/core/env/app_env.dart';
import 'package:$packageName/core/env/envs/${prodFlavor}_env.dart';

/// Centralised logger. Level is quietened to warnings in the production flavor.
abstract final class AppLogger {
  static final Logger _logger = Logger(printer: PrettyPrinter(), level: _level());

  static Level _level() {
    try {
      return AppEnv.current is $prodEnv ? Level.warning : Level.trace;
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
    String? corePackageName,
  }) {
    final riverpodImport = useAnnotations
        ? "import 'package:hooks_riverpod/hooks_riverpod.dart';"
        : "import 'package:flutter_riverpod/flutter_riverpod.dart';";
    return '''$riverpodImport
import 'package:${corePackageName ?? packageName}/core/utils/app_logger.dart';

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

    // Dio
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

  // ── core/network/dio_provider.dart ────────────────────────────────────────

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

/// Configured Dio instance. Inject it into your dio API sources.
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

/// Configured Dio instance. Inject it into your dio API sources.
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
${envImport}import 'package:$packageName/core/network/chopper_model_converter.dart';
import 'package:$packageName/core/observers/logger_interceptor.dart';

part 'chopper_client_provider.g.dart';

/// Configured ChopperClient. Register your generated services in [services],
/// e.g. `services: [MyApiSource.create()]`, then read them with getService.
@Riverpod(keepAlive: true)
ChopperClient chopperClient(Ref ref) => ChopperClient(
      baseUrl: Uri.parse($baseUrl),
      interceptors: [if (kDebugMode) LoggerInterceptor()],
      converter: const ModelJsonConverter(),
      services: const [],
    );
''';
    }
    return '''import 'package:chopper/chopper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
${envImport}import 'package:$packageName/core/network/chopper_model_converter.dart';
import 'package:$packageName/core/observers/logger_interceptor.dart';

/// Configured ChopperClient. Register your generated services in [services].
final chopperClientProvider = Provider<ChopperClient>((ref) {
  return ChopperClient(
    baseUrl: Uri.parse($baseUrl),
    interceptors: [if (kDebugMode) LoggerInterceptor()],
    converter: const ModelJsonConverter(),
    services: const [],
  );
});
''';
  }

  // ── core/network/chopper_model_converter.dart (chopper JSON → Model) ──────

  /// Chopper's built-in `JsonConverter` only decodes to primitives/Map/List —
  /// it never calls a custom Model's `fromJson`, so `Response<List<XModel>>`
  /// throws `FormatException: expected ... to be XModel, but got Map` at
  /// runtime (dart:convert's decoded JSON stays `Map`/`List`, never becomes
  /// the target class). [ModelJsonConverter] fixes this with a small
  /// Type→decoder registry (Dart's generics erase the type, so the generic
  /// [convertResponse] can't call `InnerType.fromJson()` directly — the
  /// registry is the workaround). NEAT appends one entry per chopper-backed
  /// feature, at `// neat:chopper-decoders`, both at generation time and via
  /// the Workshop.
  /// [featureName] seeds the registry with a "witness" decoder entry so it's
  /// never pointlessly empty — null when there's no first feature yet (the
  /// registry starts genuinely empty; the Workshop's anchors still work when
  /// a real feature is added later).
  static String chopperModelConverter({
    required String packageName,
    String? featureName,
  }) {
    final witnessImport = featureName != null
        ? "import 'package:$packageName/features/$featureName/data/models/${featureName}_model.dart';\n"
        : '';
    final witnessDecoder =
        featureName != null ? '  ${_pascal(featureName)}Model: (json) => ${_pascal(featureName)}Model.fromJson(json),\n' : '';
    return '''import 'dart:async';

import 'package:chopper/chopper.dart';
$witnessImport// neat:chopper-imports — feature model imports are inserted above this line.

typedef JsonDecoder = Object Function(Map<String, dynamic> json);

/// Maps each chopper-backed feature's Model to its `fromJson` factory.
final Map<Type, JsonDecoder> chopperModelDecoders = {
$witnessDecoder  // neat:chopper-decoders — feature decoders are inserted above this line.
};

/// Decodes chopper responses into the registered Model classes (single object
/// or list), falling back to the default behaviour for anything not
/// registered (e.g. `Response<dynamic>` from `delete()`).
class ModelJsonConverter extends JsonConverter {
  const ModelJsonConverter();

  @override
  FutureOr<Response<BodyType>> convertResponse<BodyType, InnerType>(
    Response response,
  ) async {
    final decoder = chopperModelDecoders[InnerType];
    if (decoder == null) {
      return super.convertResponse<BodyType, InnerType>(response);
    }

    // dynamic/dynamic sidesteps decodeJson's own Iterable<InnerType>/Map<String,
    // InnerType> type-check branches — it leaves body as the raw decoded
    // Map/List, which chopperModelDecoders below then knows how to convert.
    final raw = await decodeJson<dynamic, dynamic>(response);
    final body = raw.body;
    if (body is List) {
      // Must build a genuinely-typed List<InnerType> — a List<Object> (what
      // .map(...).toList() gives without the per-item cast) fails the BodyType
      // cast below at runtime even though every element is an InnerType.
      final list = body.map((e) => decoder(e as Map<String, dynamic>) as InnerType).toList();
      return raw.copyWith<BodyType>(body: list as BodyType);
    }
    return raw.copyWith<BodyType>(body: decoder(body as Map<String, dynamic>) as BodyType);
  }
}

/// Thrown by [unwrapChopperResponse] on a non-2xx response — carries the
/// status code + error body so `NetworkErrorHandler` can build a proper
/// [Failure] instead of a bare "Null check operator used on a null value"
/// (chopper doesn't throw on HTTP errors by default — it just returns a
/// `Response` with a null body and `isSuccessful == false`).
class ChopperApiException implements Exception {
  const ChopperApiException({required this.statusCode, this.body});

  final int statusCode;
  final Object? body;

  @override
  String toString() => 'ChopperApiException(statusCode: \$statusCode, body: \$body)';
}

/// Unwraps a chopper [Response], throwing [ChopperApiException] on failure
/// instead of the default force-unwrap (`.body!`).
T unwrapChopperResponse<T>(Response<T> response) {
  if (!response.isSuccessful) {
    throw ChopperApiException(statusCode: response.statusCode, body: response.error ?? response.body);
  }
  return response.body as T;
}
''';
  }

  // ── core/network/network_error_handler.dart (Failure mapping) ─────────────

  /// Converts a thrown error into a structured [Failure] — the **only** place
  /// exceptions are caught and mapped (`UseCase.call` invokes it). Branches on
  /// [httpClient] so only the relevant client's exception type is imported;
  /// always generated (even with no http client) since `UseCase.call` always
  /// references it, and it needs a fallback branch regardless.
  static String networkErrorHandler({
    required String packageName,
    required String httpClient,
    bool hasRiverpod = true,
  }) {
    final isDioLike = httpClient == 'dio';
    // ChopperApiException lives in chopper_model_converter.dart, itself only
    // generated alongside the (Riverpod-wired) chopper client — see
    // launch_generation_usecase.dart's `httpClient == 'chopper' && hasRiverpod`.
    final isChopper = httpClient == 'chopper' && hasRiverpod;
    final isSupabase = httpClient == 'supabase';
    final isFirebase = httpClient == 'firebase';

    final imports = StringBuffer()
      ..writeln("import 'package:$packageName/core/error/failure.dart';");
    if (isDioLike) imports.writeln("import 'package:dio/dio.dart';");
    if (isChopper) {
      imports.writeln("import 'package:$packageName/core/network/chopper_model_converter.dart';");
    }
    if (isSupabase) imports.writeln("import 'package:supabase_flutter/supabase_flutter.dart';");
    if (isFirebase) imports.writeln("import 'package:firebase_core/firebase_core.dart';");

    final branches = StringBuffer();
    if (isDioLike) {
      branches.writeln('    if (error is DioException) return _handleDioError(error);');
    }
    if (isChopper) {
      branches.writeln('    if (error is ChopperApiException) return _handleChopperError(error);');
    }
    if (isSupabase) {
      branches.write('''    if (error is AuthException) {
      return Failure(message: error.message, code: error.code, originalError: error);
    }
    if (error is PostgrestException) {
      return Failure(message: error.message, code: error.code, originalError: error);
    }
''');
    }
    if (isFirebase) {
      branches.writeln('''    if (error is FirebaseException) {
      return Failure(message: _firebaseMessage(error), code: error.code, originalError: error);
    }''');
    }

    final helpers = StringBuffer();
    if (isDioLike) {
      helpers.write('''

  static Failure _handleDioError(DioException error) {
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => const Failure(
          message: 'The server took too long to respond. Check your connection.',
        ),
      DioExceptionType.connectionError => const Failure(
          message: 'Could not reach the server. Check your internet connection.',
        ),
      DioExceptionType.badResponse => _handleBadStatus(error.response?.statusCode, error),
      DioExceptionType.cancel => const Failure(message: 'The request was cancelled.'),
      _ => Failure(message: 'A network error occurred (\${error.message}).', originalError: error),
    };
  }

  static Failure _handleBadStatus(int? statusCode, Object originalError) {
    final message = switch (statusCode) {
      400 => 'Invalid request.',
      401 => 'Your session has expired. Please sign in again.',
      403 => 'You are not authorized to do this.',
      404 => 'The requested resource was not found.',
      409 => 'This resource already exists.',
      422 => 'Invalid data.',
      500 => 'Internal server error. Please try again later.',
      _ => 'A server error occurred\${statusCode == null ? '' : ' (\$statusCode)'}.',
    };
    return Failure(message: message, statusCode: statusCode, originalError: originalError);
  }''');
    }
    if (isChopper) {
      helpers.write('''

  static Failure _handleChopperError(ChopperApiException error) {
    final message = switch (error.statusCode) {
      400 => 'Invalid request.',
      401 => 'Your session has expired. Please sign in again.',
      403 => 'You are not authorized to do this.',
      404 => 'The requested resource was not found.',
      409 => 'This resource already exists.',
      422 => 'Invalid data.',
      500 => 'Internal server error. Please try again later.',
      _ => 'A server error occurred (\${error.statusCode}).',
    };
    return Failure(message: message, statusCode: error.statusCode, originalError: error);
  }''');
    }
    if (isFirebase) {
      helpers.write('''

  static String _firebaseMessage(FirebaseException error) => switch (error.code) {
        'permission-denied' => 'You are not authorized to do this.',
        'not-found' => 'The requested resource was not found.',
        'already-exists' => 'This resource already exists.',
        'unavailable' => 'The service is temporarily unavailable. Please try again.',
        'unauthenticated' => 'Your session has expired. Please sign in again.',
        _ => error.message ?? 'A server error occurred.',
      };''');
    }

    return '''${imports.toString()}
/// Converts a thrown error into a structured [Failure]. This is the **only**
/// place exceptions are caught and mapped — [UseCase.call] invokes it.
class NetworkErrorHandler {
  static Failure handle(Object error) {
    // Already structured (e.g. thrown by Result.getOrThrow() in the
    // offline-first read path) — pass it through unchanged.
    if (error is Failure) return error;
$branches
    return Failure(message: 'An unexpected error occurred.', originalError: error);
  }
$helpers
}
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

  // ── core/network/firebase_provider.dart (Firebase singletons) ─────────────

  /// Firestore (+ optional Auth / Storage) providers. Firebase itself is
  /// initialized in bootstrap from the generated `firebase_options.dart`.
  static String firebaseProvider({
    required String packageName,
    required bool useAnnotations,
    bool hasAuth = false,
    bool hasStorage = false,
  }) {
    final pkgImports = StringBuffer()
      ..writeln("import 'package:cloud_firestore/cloud_firestore.dart';");
    if (hasAuth) pkgImports.writeln("import 'package:firebase_auth/firebase_auth.dart';");
    if (hasStorage) {
      pkgImports.writeln("import 'package:firebase_storage/firebase_storage.dart';");
    }

    if (useAnnotations) {
      final providers = StringBuffer()
        ..writeln('@Riverpod(keepAlive: true)')
        ..write('FirebaseFirestore firestore(Ref ref) => FirebaseFirestore.instance;');
      if (hasAuth) {
        providers
          ..writeln()
          ..writeln()
          ..writeln('@Riverpod(keepAlive: true)')
          ..write('FirebaseAuth firebaseAuth(Ref ref) => FirebaseAuth.instance;');
      }
      if (hasStorage) {
        providers
          ..writeln()
          ..writeln()
          ..writeln('@Riverpod(keepAlive: true)')
          ..write('FirebaseStorage firebaseStorage(Ref ref) => FirebaseStorage.instance;');
      }
      return '''import 'package:riverpod_annotation/riverpod_annotation.dart';
${pkgImports.toString().trimRight()}

part 'firebase_provider.g.dart';

/// App-wide Firebase singletons (Firebase is initialized in bootstrap).
${providers.toString()}
''';
    }

    final providers = StringBuffer()
      ..writeln('final firestoreProvider =')
      ..write('    Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);');
    if (hasAuth) {
      providers
        ..writeln()
        ..writeln()
        ..writeln('final firebaseAuthProvider =')
        ..write('    Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);');
    }
    if (hasStorage) {
      providers
        ..writeln()
        ..writeln()
        ..writeln('final firebaseStorageProvider =')
        ..write('    Provider<FirebaseStorage>((ref) => FirebaseStorage.instance);');
    }
    return '''import 'package:flutter_riverpod/flutter_riverpod.dart';
${pkgImports.toString().trimRight()}

${providers.toString()}
''';
  }

  // ── lib/firebase_options.dart (generated from the uploaded config) ─────────

  /// Builds a `firebase_options.dart` from a parsed Firebase config map (the web
  /// app config or a FlutterFire JSON). One `FirebaseOptions` is reused across
  /// platforms — enough to compile & run; for full native per-platform values,
  /// run `flutterfire configure` to regenerate.
  static String firebaseOptions(Map<String, dynamic> config) {
    String esc(Object? v) => (v ?? '').toString().replaceAll("'", r"\'");
    final optional = StringBuffer();
    for (final key in const ['authDomain', 'storageBucket', 'measurementId', 'databaseURL']) {
      final value = config[key];
      if (value != null && value.toString().isNotEmpty) {
        optional.writeln("    $key: '${esc(value)}',");
      }
    }
    return '''// GENERATED by NEAT from your uploaded Firebase config.
// For full per-platform native support, run `flutterfire configure` to
// regenerate this file with platform-specific FirebaseOptions.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

/// Default [FirebaseOptions] for use with your Firebase apps.
class DefaultFirebaseOptions {
  const DefaultFirebaseOptions._();

  static FirebaseOptions get currentPlatform => _options;

  static const FirebaseOptions _options = FirebaseOptions(
    apiKey: '${esc(config['apiKey'])}',
    appId: '${esc(config['appId'])}',
    messagingSenderId: '${esc(config['messagingSenderId'])}',
    projectId: '${esc(config['projectId'])}',
${optional.toString().trimRight()}
  );
}
''';
  }

  // ── firestore.rules / firestore.indexes.json / firebase.json ──────────────

  /// Firestore Security Rules scaffold. Default-deny, with a per-collection rule
  /// for the first feature. With auth, only signed-in users get access; without
  /// auth, it's wide open (dev only) and loudly flagged.
  static String firestoreRules({required String featureName, required bool hasAuth}) {
    final collection = '${featureName}s';
    final rule = hasAuth
        ? 'allow read, write: if request.auth != null; // signed-in users only'
        : 'allow read, write: if true; // ⚠️ DEV ONLY — lock this down before production';
    return '''rules_version = '2';

// Firestore Security Rules — generated by NEAT.
// Everything is denied by default; add a `match` block per collection.
// Test locally with the emulator, deploy with: firebase deploy --only firestore:rules
service cloud.firestore {
  match /databases/{database}/documents {
    match /$collection/{id} {
      $rule
    }
  }
}
''';
  }

  /// Empty composite-index manifest (add indexes as your queries grow).
  static String firestoreIndexes() => '''{
  "indexes": [],
  "fieldOverrides": []
}
''';

  /// firebase.json wiring the rules + indexes for the Firebase CLI.
  static String firebaseJson() => '''{
  "firestore": {
    "rules": "firestore.rules",
    "indexes": "firestore.indexes.json"
  }
}
''';

  /// A short guide on the generated Firebase wiring + how to harden it.
  static String firebaseDoc(String packageName) => '''# Firebase

This project uses **Firebase** as its backend (Firestore as the data store).

## What NEAT generated
- `lib/firebase_options.dart` — built from your uploaded config. **One**
  `FirebaseOptions` is reused across platforms.
- `lib/core/network/firebase_provider.dart` — `firestoreProvider` (+ auth /
  storage providers when those opt-ins are on).
- `Firebase.initializeApp(...)` in `lib/core/bootstrap.dart`, with Firestore
  **offline persistence enabled** (no separate Drift layer is generated).
- Feature remote sources talk to `collection('<feature>s')`; the document id is
  merged into the model JSON, so the repository / usecases stay unchanged.
- **Security Rules**: `firestore.rules` + `firestore.indexes.json` + `firebase.json`
  (default-deny, with a rule for the first feature's collection). Deploy with
  `firebase deploy --only firestore:rules`.

## OAuth (if enabled)
Google + Apple sign-in use Firebase's built-in `signInWithProvider` (no extra
SDKs). Enable the providers in the Firebase console (Authentication → Sign-in
method). On Android/iOS this opens an OAuth web flow; for the native Google
account picker, add `google_sign_in` and swap to `signInWithCredential`. Apple
sign-in needs the "Sign in with Apple" capability + a Services ID.

## Make it production-ready
For real per-platform native apps, regenerate `firebase_options.dart` with the
FlutterFire CLI (it writes platform-specific values + native config files):

```sh
dart pub global activate flutterfire_cli
flutterfire configure --project=<your-firebase-project>
```

Then commit the updated `lib/firebase_options.dart` and the native files it adds,
and review `firestore.rules` before shipping.
''';

  // ── core/storage/storage_service.dart (Storage, opt-in) ───────────────────

  /// A thin wrapper over the project's object storage + a provider. Both
  /// backends expose the same contract: [upload] returns a ready-to-use URL,
  /// plus [download] / [remove]. So the sample widget stays backend-agnostic.
  // corePackageName: storage_service.dart itself always stays app-level
  // (nothing NEAT generates imports it cross-package), but the client-init
  // provider it reads (supabaseClientProvider/firebaseStorageProvider) moves
  // into core when packageSplit is on, so this one import still redirects.
  static String storageService({
    required String packageName,
    required bool useAnnotations,
    String backend = 'supabase',
    String? corePackageName,
  }) {
    final isFirebase = backend == 'firebase';
    final pkgImport = isFirebase
        ? "import 'package:firebase_storage/firebase_storage.dart';"
        : "import 'package:supabase_flutter/supabase_flutter.dart';";
    final providerImport =
        "import 'package:${corePackageName ?? packageName}/core/network/${isFirebase ? 'firebase' : 'supabase'}_provider.dart';";
    final construct = isFirebase
        ? 'StorageService(ref.watch(firebaseStorageProvider))'
        : 'StorageService(ref.watch(supabaseClientProvider))';

    final body = isFirebase
        ? r'''/// A thin wrapper over a Firebase Storage prefix.
class StorageService {
  const StorageService(this._storage, {this.prefix = 'avatars'});

  final FirebaseStorage _storage;
  final String prefix;

  Reference _ref(String path) => _storage.ref('$prefix/$path');

  /// Uploads raw [bytes] to [path] and returns the download URL.
  Future<String> upload(
    String path,
    Uint8List bytes, {
    String? contentType,
  }) async {
    final ref = _ref(path);
    await ref.putData(bytes, SettableMetadata(contentType: contentType));
    return ref.getDownloadURL();
  }

  /// Downloads [path] as bytes (null if too large / missing).
  Future<Uint8List?> download(String path) => _ref(path).getData();

  /// Removes [path] from storage.
  Future<void> remove(String path) => _ref(path).delete();
}'''
        : r'''/// A thin wrapper over a single Supabase Storage bucket.
class StorageService {
  const StorageService(this._client, {this.bucket = 'avatars'});

  final SupabaseClient _client;
  final String bucket;

  StorageFileApi get _bucket => _client.storage.from(bucket);

  /// Uploads raw [bytes] to [path] (upserts) and returns the public URL.
  Future<String> upload(
    String path,
    Uint8List bytes, {
    String? contentType,
  }) async {
    await _bucket.uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(upsert: true, contentType: contentType),
    );
    return _bucket.getPublicUrl(path);
  }

  /// Downloads [path] as bytes.
  Future<Uint8List> download(String path) => _bucket.download(path);

  /// Removes [path] from the bucket.
  Future<void> remove(String path) => _bucket.remove([path]);
}''';

    if (useAnnotations) {
      return '''import 'dart:typed_data';

import 'package:riverpod_annotation/riverpod_annotation.dart';
$pkgImport
$providerImport

part 'storage_service.g.dart';

$body

@Riverpod(keepAlive: true)
StorageService storageService(Ref ref) => $construct;
''';
    }
    return '''import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
$pkgImport
$providerImport

$body

final storageServiceProvider = Provider<StorageService>(
  (ref) => $construct,
);
''';
  }

  // ── core/storage/avatar_upload_field.dart (sample upload widget) ──────────

  /// A sample widget: pick an image, upload it to Storage, show the result.
  static String avatarUploadField({required String packageName}) {
    return r'''import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:PACKAGE/core/storage/storage_service.dart';

/// Sample: pick an image from the gallery, upload it to object storage, then
/// display it from the returned URL. Drop it into any screen (e.g. a profile)
/// and pass a stable [path] (typically `userId/avatar.png`).
class AvatarUploadField extends ConsumerStatefulWidget {
  const AvatarUploadField({super.key, this.path = 'avatar.png'});

  /// Object path inside the storage bucket/prefix.
  final String path;

  @override
  ConsumerState<AvatarUploadField> createState() => _AvatarUploadFieldState();
}

class _AvatarUploadFieldState extends ConsumerState<AvatarUploadField> {
  String? _url;
  bool _busy = false;

  Future<void> _pickAndUpload() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    setState(() => _busy = true);
    try {
      final storage = ref.read(storageServiceProvider);
      final bytes = await picked.readAsBytes();
      final url = await storage.upload(
        widget.path,
        bytes,
        contentType: picked.mimeType,
      );
      // Cache-bust so the freshly uploaded image shows immediately.
      if (mounted) {
        setState(() => _url = '$url?t=${DateTime.now().millisecondsSinceEpoch}');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 48,
          backgroundImage: _url == null ? null : NetworkImage(_url!),
          child: _url == null ? const Icon(Icons.person, size: 48) : null,
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _busy ? null : _pickAndUpload,
          icon: _busy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.upload),
          label: const Text('Upload avatar'),
        ),
      ],
    );
  }
}
'''
        .replaceAll('PACKAGE', packageName);
  }

  // ── core/sync/sync_service.dart (offline-first + sync / Outbox) ───────────

  static String syncService({
    required String packageName,
    required String localStoragePackage,
  }) => '''import 'dart:async';

import 'package:$localStoragePackage/$localStoragePackage.dart';
import 'package:$packageName/core/network/network_info.dart';

/// Outcome of attempting to push one queued write to the backend.
enum ReplaySyncResult {
  /// The write succeeded — the entry is removed from the queue.
  success,

  /// A transient failure (network, 5xx, timeout) — retried later with
  /// exponential backoff.
  retry,

  /// The backend rejected the write because the resource changed since it was
  /// queued (e.g. a 409, or a newer `updatedAt`). Parked separately from
  /// ordinary retries until the app resolves it via [AppDatabase.resolveConflict]
  /// — a generic sync engine can't safely guess a merge policy on your behalf.
  conflict,
}

/// How a single queued write is pushed to the backend.
///
/// Wire this to your HTTP client, e.g.:
/// ```dart
/// SyncService(db, network, (e) async {
///   final res = await dio.request(e.endpoint,
///       data: e.payload, options: Options(method: 'POST'));
///   if (res.statusCode == 409) return ReplaySyncResult.conflict;
///   return ReplaySyncResult.success;
/// });
/// ```
typedef OutboxReplay = Future<ReplaySyncResult> Function(OutboxEntry entry);

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
  Timer? _retryTimer;

  /// Start listening for connectivity; flush automatically when back online.
  void start() {
    _sub = _network.onConnectivityChanged.listen((online) {
      if (online) flush();
    });
  }

  /// Exponential backoff before a failed write is retried: 5s, 10s, 20s,
  /// 40s... capped at 5 minutes so a long outage doesn't wedge a write for hours.
  static Duration _backoffFor(int retryCount) =>
      Duration(seconds: (5 * (1 << retryCount)).clamp(5, 300));

  /// Replay every due write, oldest first (an entry whose backoff hasn't
  /// elapsed yet, or that's flagged as conflicting, is skipped this round).
  /// Successful ones are removed; transient failures bump their retry counter
  /// and schedule the next backoff; conflicts are parked separately. If
  /// anything is still owed a retry, a timer re-flushes once the earliest one
  /// is due, so recovery doesn't depend on another connectivity flap.
  Future<void> flush() async {
    if (!await _network.isConnected) return;
    _retryTimer?.cancel();
    final now = DateTime.now();
    Duration? nextWait;

    void scheduleRetry(Duration wait) {
      if (nextWait == null || wait < nextWait!) nextWait = wait;
    }

    for (final entry in await _db.pendingOutbox()) {
      if (entry.retryCount >= maxRetries) continue; // parked — give up
      final due = entry.nextRetryAt;
      if (due != null && due.isAfter(now)) {
        scheduleRetry(due.difference(now));
        continue;
      }
      try {
        switch (await _replay(entry)) {
          case ReplaySyncResult.success:
            await _db.deleteOutbox(entry.id);
          case ReplaySyncResult.retry:
            final backoff = _backoffFor(entry.retryCount + 1);
            await _db.incrementRetry(entry.id, nextRetryAt: now.add(backoff));
            scheduleRetry(backoff);
          case ReplaySyncResult.conflict:
            await _db.markConflict(entry.id);
        }
      } catch (_) {
        final backoff = _backoffFor(entry.retryCount + 1);
        await _db.incrementRetry(entry.id, nextRetryAt: now.add(backoff));
        scheduleRetry(backoff);
      }
    }

    if (nextWait != null) _retryTimer = Timer(nextWait!, flush);
  }

  /// Writes that exhausted their retries — surface these to the user / a report.
  Future<List<OutboxEntry>> failedWrites() async =>
      (await _db.pendingOutbox()).where((e) => e.retryCount >= maxRetries).toList();

  /// Writes flagged as conflicting — surface these for the app to resolve
  /// (see [AppDatabase.resolveConflict]); distinct from [failedWrites], which
  /// is exhausted retries rather than a detected conflict.
  Future<List<OutboxEntry>> conflictedWrites() => _db.conflictedOutbox();

  Future<void> dispose() async {
    _retryTimer?.cancel();
    await _sub?.cancel();
  }
}
''';

  // ── docs/OFFLINE.md (offline-first usage guide) ──────────────────────────

  static String offlineDoc({
    required String packageName,
    required String featureName,
    required String localStoragePackage,
    required bool hasSync,
    List<FieldSpec> fields = FieldSpec.idName,
  }) {
    final p = _pascal(featureName);
    final c = _camel(featureName);
    // A representative constructor call for the doc sample (non-compiled prose).
    final sampleArgs = fields.map((f) => '${f.dartName}: ${f.entityPlaceholder()}').join(', ');

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
await create(${p}Entity($sampleArgs)); // usecase(params) — never .execute() directly
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
- Failing ones back off exponentially (5s, 10s, 20s... capped at 5 minutes)
  and bump `retryCount`; after `SyncService.maxRetries` attempts they are
  **parked** (kept for inspection via `SyncService.failedWrites()`, never
  retried in a loop).
- A replay that returns `ReplaySyncResult.conflict` (e.g. the backend answered
  409) is set aside from ordinary retries — inspect it via
  `SyncService.conflictedWrites()` and resolve it with
  `AppDatabase.resolveConflict(id, retry: ...)`. Detecting *what* counts as a
  conflict for your backend is up to the replay callback
  (`core/sync/sync_service.dart`) — a generic engine can't guess your merge
  policy.'''
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
        ├── data/repositories/        # offline-first orchestration +
        │                             # ${featureName}_repository_providers.dart (repository-level DI)
        └── presentation/providers/   # ${featureName}_usecase_providers.dart (usecase-level DI)
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

Everything is wired as `keepAlive` Riverpod providers, split by layer so
presentation never touches a concrete Data type (only the abstract repository
provider, exposed from data/) — see `docs/ARCHITECTURE.md` if generated, or
AGENTS.md, for the full rule:

`lib/features/$featureName/data/repositories/${featureName}_repository_providers.dart`
(repository-level DI):

| Provider | What it gives |
|---|---|
| `${c}ApiSourceProvider` | remote source (uses the core dio/chopper client) |
| `appDatabaseProvider` | the Drift `AppDatabase` |
| `${c}LocalSourceProvider` | Drift-backed local source |
| `networkInfoProvider` | connectivity wrapper |
| `${c}RepositoryProvider` | offline-first repository (abstract-typed) |
${hasSync ? '| `${c}SyncProvider` | the Outbox sync engine (auto-starts) |' : ''}

`lib/features/$featureName/presentation/providers/${featureName}_usecase_providers.dart`
(usecase-level DI, built from `${c}RepositoryProvider` above):

| Provider | What it gives |
|---|---|
| `get/create/update/delete${p}UsecaseProvider` | the usecases |

## Reading

```dart
final usecase = ref.watch(get${p}UsecaseProvider);
final result = await usecase(); // local-first, refreshed from the API when online
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
        '${hasSync ? '\n- **Replay policy**: `SyncService` already backs off exponentially and parks conflicts — wire your backend\'s own conflict detection (e.g. a 409 check) into the replay callback.\n' : '\n'}';
  }

  // ── core/error/failure.dart ───────────────────────────────────────────────

  /// A structured application error — the payload carried by `Result.failure`.
  /// Built by `NetworkErrorHandler.handle` from whatever a [UseCase.call]
  /// caught (a client-specific exception, or a [Failure] already thrown by a
  /// repository — see the offline-first read path in the generated repository).
  static String failure() => r'''class Failure {
  const Failure({required this.message, this.statusCode, this.code, this.originalError});

  /// User-facing message.
  final String message;

  /// HTTP status code, when the failure came from a network response.
  final int? statusCode;

  /// A machine-readable error code from the backend (e.g. Firebase's
  /// 'permission-denied'), when available.
  final String? code;

  /// The original thrown error, kept for logging/debugging.
  final Object? originalError;

  @override
  String toString() => 'Failure(message: $message, code: $code, statusCode: $statusCode)';
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

  static String appRouter({
    required String packageName,
    required String featureName,
    bool hasFirstFeature = true,
  }) {
    final routeConst = hasFirstFeature ? _camel(featureName) : 'welcome';
    return '''import 'package:go_router/go_router.dart';
import 'package:$packageName/core/constants/app_route_path.dart';
import 'routes.dart';

final appRouter = GoRouter(
  initialLocation: AppRoutePath.$routeConst,
  debugLogDiagnostics: true,
  routes: appRoutes,
);
''';
  }

  // ── core/router/app_router.dart (go_router_builder + riverpod) ───────────

  static String appRouterBuilder({
    required String packageName,
    required String featureName,
    required bool useAnnotations,
    bool hasAuth = false,
    bool hasFirstFeature = true,
  }) {
    final c = hasFirstFeature ? _camel(featureName) : 'welcome';
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
  ///
  /// [featurePackageName] is set when the feature was split into its own
  /// workspace package (packageSplit — see ROADMAP.md §6a): the one
  /// legitimate app→feature-package import, same as [routesManual].
  static String routesAggregator({
    required String packageName,
    required String featureName,
    String? featurePackageName,
  }) {
    final routesImport = featurePackageName != null
        ? "import 'package:$featurePackageName/presentation/routes/${featureName}_routes.dart'\n    as $featureName;"
        : "import 'package:$packageName/features/$featureName/presentation/routes/${featureName}_routes.dart'\n    as $featureName;";
    return '''import 'package:go_router/go_router.dart';
$routesImport
// neat:route-imports

/// Aggregated app routes. NEAT inserts new features at the anchors below.
final List<RouteBase> appRoutes = [
  ...$featureName.\$appRoutes,
  // neat:route-entries
];
''';
  }

  // ── features/<f>/presentation/routes/<f>_routes.dart (typed routes) ──────

  static String featureRoutes({
    required String packageName,
    required String featureName,
    // Set when the feature was split into its own workspace package
    // (packageSplit — see ROADMAP.md §6a): AppRoutePath crosses into the
    // shared core package instead of the app (the app's own copy would be
    // the forbidden feature→app cycle) — the page self-reference is already
    // relative, since this file lives in the same package as the page.
    String? corePackageName,
  }) =>
      '''import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:${corePackageName ?? packageName}/core/constants/app_route_path.dart';
import '../pages/${featureName}_page.dart';

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

  static String routesManual({
    required String packageName,
    required String featureName,
    // Set when the first feature was split into its own workspace package
    // (packageSplit — see ROADMAP.md §6a): the app still owns its own
    // AppRoutePath, only the feature-page import crosses the package
    // boundary.
    String? featurePackageName,
  }) {
    final pageImport = featurePackageName != null
        ? "import 'package:$featurePackageName/presentation/pages/${featureName}_page.dart';"
        : "import 'package:$packageName/features/$featureName/presentation/pages/${featureName}_page.dart';";
    return '''import 'package:go_router/go_router.dart';
import 'package:$packageName/core/constants/app_route_path.dart';
$pageImport
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
  }

  /// `routes.dart` (manual go_router) when there's no first feature — the
  /// welcome placeholder owns `/` instead. Same anchors as [routesManual], so
  /// the Workshop's insertion logic is unaffected when a real feature is
  /// added later.
  static String routesManualWelcome({required String packageName}) =>
      '''import 'package:go_router/go_router.dart';
import 'package:$packageName/core/constants/app_route_path.dart';
import 'package:$packageName/core/pages/welcome_page.dart';
// neat:route-imports

/// App routes. NEAT inserts new features at the anchors below.
final List<RouteBase> appRoutes = [
  GoRoute(
    path: AppRoutePath.welcome,
    builder: (context, state) => const WelcomePage(),
  ),
  // neat:route-entries
];
''';

  // ── core/router/welcome_route.dart (typed route, no first feature) ───────

  /// Typed-route counterpart to [featureRoutes] for the welcome placeholder —
  /// same `@TypedGoRoute` shape, so [routesAggregatorWelcome] can spread its
  /// generated `\$appRoutes` exactly like a real feature's.
  static String welcomeRoute({required String packageName}) =>
      '''import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:$packageName/core/constants/app_route_path.dart';
import 'package:$packageName/core/pages/welcome_page.dart';

part 'welcome_route.g.dart';

@TypedGoRoute<WelcomeRoute>(path: AppRoutePath.welcome)
class WelcomeRoute extends GoRouteData with \$WelcomeRoute {
  const WelcomeRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const WelcomePage();
}
''';

  /// `routes.dart` (go_router_builder) when there's no first feature —
  /// aggregates [welcomeRoute] instead of a feature's routes file. Same
  /// anchors as [routesAggregator].
  static String routesAggregatorWelcome({required String packageName}) =>
      '''import 'package:go_router/go_router.dart';
import 'package:$packageName/core/router/welcome_route.dart' as welcome;
// neat:route-imports

/// Aggregated app routes. NEAT inserts new features at the anchors below.
final List<RouteBase> appRoutes = [
  ...welcome.\$appRoutes,
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
  /// the shell's first branch, wrapped in a [StatefulShellRoute]. [featurePackageName]
  /// crosses into the split feature package instead of `features/<name>/` when
  /// packageSplit is on (see ROADMAP.md §6a).
  static String routesManualShell({
    required String packageName,
    required String featureName,
    String? featurePackageName,
  }) {
    final pageImport = featurePackageName != null
        ? "import 'package:$featurePackageName/presentation/pages/${featureName}_page.dart';"
        : "import 'package:$packageName/features/$featureName/presentation/pages/${featureName}_page.dart';";
    return '''import 'package:go_router/go_router.dart';
import 'package:$packageName/core/constants/app_route_path.dart';
import 'package:$packageName/core/router/scaffold_with_nav_bar.dart';
$pageImport
// neat:route-imports

/// Aggregated app routes. The app boots into the navigation shell; NEAT inserts
/// new features at the anchors below.
final List<RouteBase> appRoutes = [
${shellRouteEntryPlain(featureName: featureName)}
  // neat:route-entries
];
''';
  }

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
    required List<String> platforms,
    String imagePath = 'assets/branding/logo.png',
    String adaptiveBackground = '#FFFFFF',
  }) {
    final hasAndroid = platforms.contains('android');
    final hasIos = platforms.contains('ios');
    final hasWeb = platforms.contains('web');
    final hasMacos = platforms.contains('macos');
    final hasWindows = platforms.contains('windows');
    final hasLinux = platforms.contains('linux');

    return '''flutter_launcher_icons:
  image_path: "$imagePath"
  android: $hasAndroid
  ios: $hasIos
  min_sdk_android: 21
  remove_alpha_ios: true
  adaptive_icon_background: "$adaptiveBackground"
  adaptive_icon_foreground: "$imagePath"
  web:
    generate: $hasWeb
    image_path: "$imagePath"
  macos:
    generate: $hasMacos
    image_path: "$imagePath"
  windows:
    generate: $hasWindows
    image_path: "$imagePath"
  linux:
    generate: $hasLinux
    image_path: "$imagePath"
''';
  }

  /// `flutter_native_splash.yaml` — generates the native splash screen.
  static String nativeSplashConfig({
    required List<String> platforms,
    String imagePath = 'assets/branding/logo.png',
    String colorLight = '#FFFFFF',
    String colorDark = '#0E0E0E',
  }) {
    final hasAndroid = platforms.contains('android');
    final hasIos = platforms.contains('ios');
    final hasWeb = platforms.contains('web');
    final hasMacos = platforms.contains('macos');
    final hasWindows = platforms.contains('windows');
    final hasLinux = platforms.contains('linux');

    return '''flutter_native_splash:
  color: "$colorLight"
  color_dark: "$colorDark"
  image: $imagePath
  image_dark: $imagePath
  android_12:
    image: $imagePath
    icon_background_color: "$colorLight"
    image_dark: $imagePath
    icon_background_color_dark: "$colorDark"
  android: $hasAndroid
  ios: $hasIos
  web: $hasWeb
  macos: $hasMacos
  windows: $hasWindows
  linux: $hasLinux
''';
  }

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
  /// [featurePackageName] crosses into the split feature package instead of
  /// `features/<name>/` when packageSplit is on (see ROADMAP.md §6a).
  static String appShellRouteBuilder({
    required String packageName,
    required String featureName,
    String? featurePackageName,
  }) {
    final p = _pascal(featureName);
    final c = _camel(featureName);
    final pageImport = featurePackageName != null
        ? "import 'package:$featurePackageName/presentation/pages/${featureName}_page.dart';"
        : "import 'package:$packageName/features/$featureName/presentation/pages/${featureName}_page.dart';";
    return '''import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:$packageName/core/constants/app_route_path.dart';
import 'package:$packageName/core/router/scaffold_with_nav_bar.dart';
$pageImport
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
