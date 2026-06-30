import 'package:freezed_annotation/freezed_annotation.dart';

part 'env_config.freezed.dart';

/// One build environment (flavor): a [name] (default dev/staging/prod) and an
/// optional [apiBaseUrl] written into the matching `.env.<flavor>` file.
@freezed
abstract class EnvConfig with _$EnvConfig {
  const factory EnvConfig({
    required String name,
    @Default('') String apiBaseUrl,
    @Default('') String supabaseUrl,
    @Default('') String supabaseAnonKey,
  }) = _EnvConfig;

  const EnvConfig._();

  /// The sanitized flavor token used for files/classes/gradle:
  /// `.env.<flavor>`, `<Flavor>Env`, `main_<flavor>.dart`, `create("<flavor>")`.
  /// Lowercases, collapses non-alphanumerics to `_`, and guarantees a leading
  /// letter (falls back to `env`).
  String get flavor {
    final cleaned = name
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    if (cleaned.isEmpty || !RegExp(r'^[a-z]').hasMatch(cleaned)) return 'env_$cleaned';
    return cleaned;
  }
}
