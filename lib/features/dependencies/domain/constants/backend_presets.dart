import 'package:neat/features/dependencies/domain/models/pub_package.dart';

/// The backend provider chosen on the Dependencies screen. Selecting one injects
/// its base preset into the manifest — the manifest stays the single source of
/// truth the generator reads (backend is inferred from the resulting packages).
enum BackendKind { rest, supabase, firebase }

/// Shared core every backend ships with (state mgmt, codegen, routing, env).
const _corePackages = <PubPackage>[
  PubPackage(
    name: 'hooks_riverpod',
    version: '3.3.1',
    description: 'Flutter hooks + Riverpod state management.',
  ),
  PubPackage(
    name: 'flutter_hooks',
    version: '0.21.3+1',
    description: 'React-style hooks for Flutter widgets.',
  ),
  PubPackage(
    name: 'riverpod_annotation',
    version: '4.0.2',
    description: 'Annotations for code-generated Riverpod providers.',
  ),
  PubPackage(
    name: 'json_annotation',
    version: '4.11.0',
    description: 'Annotations for json_serializable code generation.',
  ),
  PubPackage(
    name: 'freezed_annotation',
    version: '3.1.0',
    description: 'Annotations for freezed immutable classes.',
  ),
  PubPackage(name: 'go_router', version: '17.2.3', description: 'Declarative routing for Flutter.'),
  PubPackage(name: 'envied', version: '1.3.5', description: 'Declarative env for Flutter.'),
  PubPackage(
    name: 'riverpod_generator',
    version: '4.0.3',
    description: 'Code generator for Riverpod providers.',
    isDev: true,
  ),
  PubPackage(
    name: 'envied_generator',
    version: '1.3.5',
    description: 'Code generator for envied.',
    isDev: true,
  ),
  PubPackage(name: 'riverpod_lint', version: '3.1.3', description: 'Lint rules for Riverpod.', isDev: true),
  PubPackage(
    name: 'json_serializable',
    version: '6.13.0',
    description: 'Generates toJson/fromJson from annotations.',
    isDev: true,
  ),
  PubPackage(
    name: 'build_runner',
    version: '2.15.0',
    description: 'Build system for Dart code generation.',
    isDev: true,
  ),
  PubPackage(
    name: 'freezed',
    version: '3.2.5',
    description: 'Code generator for immutable classes and sealed unions.',
    isDev: true,
  ),
  PubPackage(
    name: 'go_router_builder',
    version: '4.3.0',
    description: 'Type-safe route generation for go_router.',
    isDev: true,
  ),
];

/// REST: core + a Chopper HTTP client.
const restPreset = <PubPackage>[
  ..._corePackages,
  PubPackage(name: 'chopper', version: '8.6.0', description: 'HTTP client generator using annotations.'),
  PubPackage(
    name: 'chopper_generator',
    version: '8.6.2',
    description: 'Code generator for Chopper HTTP clients.',
    isDev: true,
  ),
];

/// Supabase: core + the Supabase SDK (Postgres + Auth + Realtime + Storage).
const supabasePreset = <PubPackage>[
  ..._corePackages,
  PubPackage(
    name: 'supabase_flutter',
    version: '2.14.1',
    description: 'Supabase client: Postgres, Auth, Realtime, Storage.',
  ),
];

/// Firebase: core + Firebase Core & Firestore (auth/storage are opt-in toggles).
const firebasePreset = <PubPackage>[
  ..._corePackages,
  PubPackage(name: 'firebase_core', version: '3.8.1', description: 'Firebase core initialization.'),
  PubPackage(name: 'cloud_firestore', version: '5.6.0', description: 'Cloud Firestore database.'),
];

/// Backend-specific package names — stripped before applying a new preset so
/// switching backends is clean (non-backend packages are kept).
const backendMarkerPackages = <String>{
  'supabase_flutter',
  'cloud_firestore',
  'firebase_core',
  'firebase_auth',
  'firebase_storage',
  'chopper',
  'chopper_generator',
  'dio',
  'retrofit',
  'retrofit_generator',
};

List<PubPackage> presetFor(BackendKind kind) => switch (kind) {
      BackendKind.rest => restPreset,
      BackendKind.supabase => supabasePreset,
      BackendKind.firebase => firebasePreset,
    };

/// Infers the active backend from the manifest (the source of truth).
BackendKind backendOf(List<PubPackage> packages) {
  final names = packages.map((p) => p.name).toSet();
  if (names.contains('cloud_firestore')) return BackendKind.firebase;
  if (names.contains('supabase_flutter')) return BackendKind.supabase;
  return BackendKind.rest;
}
