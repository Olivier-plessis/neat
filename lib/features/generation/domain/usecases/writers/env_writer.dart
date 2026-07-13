import 'dart:io';

import 'package:neat/features/architecture/domain/models/env_config.dart';
import 'package:neat/features/generation/domain/services/templates/core_templates.dart';
import 'package:neat/features/generation/domain/usecases/writers/generation_io.dart';

/// Writes the envied environment system: `app_env.dart`, per-flavor `Env`
/// classes, `.env`/`.env.<flavor>`/`.env.example`, and the gitignore entry
/// keeping secrets out of git — split out of `LaunchGenerationUsecase` (see
/// ROADMAP.md for the per-domain writer split).
abstract final class EnvWriter {
  static Future<void> write(
    Directory projectDir,
    String lib,
    String packageName, {
    required List<EnvConfig> environments,
    bool singleEnv = false,
    bool hasSupabase = false,
    bool hasApiBaseUrl = true,
    // Sentry (CI/CD screen, opt-in): a single DSN, same across every flavor —
    // see CoreTemplates.appEnv's doc.
    bool hasSentry = false,
    String sentryDsn = '',
  }) async {
    // Dart: contract shared by every env.
    await writeFile(
      '$lib/core/env/app_env.dart',
      CoreTemplates.appEnv(
        hasApiBaseUrl: hasApiBaseUrl,
        hasSupabase: hasSupabase,
        hasSentry: hasSentry,
      ),
    );

    if (singleEnv) {
      // One env → a single `Env`/`EnvVars` reading a plain `.env` (no flavor
      // suffix, no per-env classes, no entry points).
      final env = environments.first;
      await writeFile(
        '$lib/core/env/envs/env.dart',
        CoreTemplates.flavorEnv(
          packageName: packageName,
          flavor: env.flavor,
          single: true,
          hasApiBaseUrl: hasApiBaseUrl,
          hasSupabase: hasSupabase,
          hasSentry: hasSentry,
        ),
      );
      await writeFile(
        '${projectDir.path}/.env',
        CoreTemplates.envFile(
          appName: packageName,
          hasApiBaseUrl: hasApiBaseUrl,
          hasSupabase: hasSupabase,
          hasSentry: hasSentry,
          apiBaseUrl: env.apiBaseUrl,
          supabaseUrl: env.supabaseUrl,
          supabaseKey: env.supabaseAnonKey,
          sentryDsn: sentryDsn,
        ),
      );
    } else {
      // ≥2 envs: per-env envied classes + `.env.<flavor>` files (must exist
      // before build_runner so envied can read them). The user-provided API URL
      // (if any) is pre-filled per environment.
      for (final env in environments) {
        await writeFile(
          '$lib/core/env/envs/${env.flavor}_env.dart',
          CoreTemplates.flavorEnv(
            packageName: packageName,
            flavor: env.flavor,
            hasApiBaseUrl: hasApiBaseUrl,
            hasSupabase: hasSupabase,
            hasSentry: hasSentry,
          ),
        );
      }
      for (final env in environments) {
        await writeFile(
          '${projectDir.path}/.env.${env.flavor}',
          CoreTemplates.envFile(
            appName: packageName,
            hasApiBaseUrl: hasApiBaseUrl,
            hasSupabase: hasSupabase,
            hasSentry: hasSentry,
            apiBaseUrl: env.apiBaseUrl,
            supabaseUrl: env.supabaseUrl,
            supabaseKey: env.supabaseAnonKey,
            // Same DSN across every flavor (unlike apiBaseUrl) — see
            // CoreTemplates.appEnv's doc.
            sentryDsn: sentryDsn,
          ),
        );
      }
    }
    await writeFile(
      '${projectDir.path}/.env.example',
      CoreTemplates.envFile(
        appName: packageName,
        hasApiBaseUrl: hasApiBaseUrl,
        hasSupabase: hasSupabase,
        hasSentry: hasSentry,
      ),
    );

    // Keep secrets out of git (but commit .env.example).
    await appendGitignore(projectDir, '''

# Environment files (envied) — keep only .env.example
.env
.env.*
!.env.example
''');
  }
}
