import 'dart:io';

import 'package:neat/features/architecture/domain/models/architecture_state.dart';
import 'package:neat/features/generation/domain/services/templates/core_templates.dart';
import 'package:neat/features/generation/domain/usecases/writers/generation_io.dart';

/// Writes backend + offline-first infrastructure: the Firebase client
/// provider + firebase_options.dart/Firestore config, the opt-in Storage
/// service, and (offline-first) NetworkInfo + the shared infrastructure
/// providers + SyncService + OFFLINE.md — split out of
/// `LaunchGenerationUsecase`'s `_buildScaffold` (see ROADMAP.md for the
/// per-domain writer split).
abstract final class BackendWriter {
  static Future<void> write({
    required Directory projectDir,
    required String lib,
    required ArchitectureState architecture,
    required String featureName,
    required String packageName,
    required String httpClient,
    required bool hasRiverpod,
    required bool useAnnotations,
    required bool hasAuth,
    required bool hasStorage,
    String? corePackageName,
    String? localStoragePackage,
    bool hasSync = false,
  }) async {
    // ── core/network + firebase_options (Firebase backend) ───────────────────
    // packageSplit: same reasoning as supabase for firebase_provider.dart —
    // firebase_options.dart/firestore config stay app-level regardless (not
    // Dart-importable, no boundary to cross).
    if (httpClient == 'firebase' && hasRiverpod && corePackageName == null) {
      await writeFile(
        '$lib/core/network/firebase_provider.dart',
        CoreTemplates.firebaseProvider(
          packageName: packageName,
          useAnnotations: useAnnotations,
          hasAuth: hasAuth,
          hasStorage: hasStorage,
        ),
      );
    }
    if (httpClient == 'firebase' && hasRiverpod) {
      // firebase_options.dart from the uploaded config JSON (stub values if
      // none was provided — the project still compiles).
      final config = readFirebaseConfig(architecture.firebaseConfigPath);
      await writeFile(
        '$lib/firebase_options.dart',
        CoreTemplates.firebaseOptions(config),
      );
      // A short guide to swap in real per-platform values.
      await writeFile(
        '${projectDir.path}/docs/FIREBASE.md',
        CoreTemplates.firebaseDoc(packageName),
      );
      // Firestore Security Rules scaffold + Firebase CLI wiring.
      await writeFile(
        '${projectDir.path}/firestore.rules',
        CoreTemplates.firestoreRules(
          featureName: featureName,
          hasAuth: hasAuth,
        ),
      );
      await writeFile(
        '${projectDir.path}/firestore.indexes.json',
        CoreTemplates.firestoreIndexes(),
      );
      await writeFile(
        '${projectDir.path}/firebase.json',
        CoreTemplates.firebaseJson(),
      );
    }

    // ── core/storage (Storage, opt-in) ───────────────────────────────────────
    if (hasStorage) {
      await writeFile(
        '$lib/core/storage/storage_service.dart',
        CoreTemplates.storageService(
          packageName: packageName,
          useAnnotations: useAnnotations,
          backend: httpClient,
          corePackageName: corePackageName,
        ),
      );
      await writeFile(
        '$lib/core/storage/avatar_upload_field.dart',
        CoreTemplates.avatarUploadField(packageName: packageName),
      );
    }

    // ── core/network (offline-first) ────────────────────────────────────────
    if (localStoragePackage != null && corePackageName == null) {
      await writeFile(
        '$lib/core/network/network_info.dart',
        CoreTemplates.networkInfo(),
      );
    }

    // ── core/providers (shared infrastructure singletons) ────────────────────
    // Drift db + connectivity, declared once for the whole app (not per feature).
    if (localStoragePackage != null &&
        useAnnotations &&
        corePackageName == null) {
      await writeFile(
        '$lib/core/providers/infrastructure_providers.dart',
        CoreTemplates.infrastructureProviders(
          packageName: packageName,
          localStoragePackage: localStoragePackage,
        ),
      );
    }

    // ── core/sync (offline-first + sync / Outbox) ────────────────────────────
    if (localStoragePackage != null && hasSync && corePackageName == null) {
      await writeFile(
        '$lib/core/sync/sync_service.dart',
        CoreTemplates.syncService(
          packageName: packageName,
          localStoragePackage: localStoragePackage,
        ),
      );
    }

    // ── docs/OFFLINE.md (usage guide) ────────────────────────────────────────
    // Uses the first feature as a worked example — skipped when there isn't
    // one yet (the guide is still useful once a real feature is added via
    // the Workshop, at which point OFFLINE.md can be revisited manually).
    if (localStoragePackage != null && architecture.generateFirstFeature) {
      await writeFile(
        '${projectDir.path}/docs/OFFLINE.md',
        CoreTemplates.offlineDoc(
          packageName: packageName,
          featureName: featureName,
          localStoragePackage: localStoragePackage,
          hasSync: hasSync,
          fields: architecture.firstFeatureFields,
        ),
      );
    }
  }
}
