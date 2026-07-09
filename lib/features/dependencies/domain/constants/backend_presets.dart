import 'package:neat/features/dependencies/domain/models/pub_package.dart';

/// The backend provider chosen on the Dependencies screen. Selecting one injects
/// its base preset into the manifest — the manifest stays the single source of
/// truth the generator reads (backend is inferred from the resulting packages).
enum BackendKind { rest, supabase, firebase }

/// Packages every backend ships with **regardless of state management**
/// (model codegen, routing, env) — state management itself is a separate,
/// independently-swappable axis (see [StateManagementKind]) so switching
/// backend never clobbers a Riverpod/Bloc choice, the same way it never
/// touches [RoutingStyle].
const _sharedCore = <PubPackage>[
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
    name: 'envied_generator',
    version: '1.3.5',
    description: 'Code generator for envied.',
    isDev: true,
  ),
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
];

/// Riverpod state management — NEAT's default (see [StateManagementKind]).
const _riverpodPreset = <PubPackage>[
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
    name: 'riverpod_generator',
    version: '4.0.3',
    description: 'Code generator for Riverpod providers.',
    isDev: true,
  ),
  PubPackage(
    name: 'riverpod_lint',
    version: '3.1.4',
    description: 'Lint rules for Riverpod.',
    isDev: true,
  ),
];

/// Bloc/Cubit state management (see [StateManagementKind]).
const _blocPreset = <PubPackage>[
  PubPackage(
    name: 'flutter_bloc',
    version: '9.1.1',
    description: 'Bloc/Cubit state management for Flutter.',
  ),
];

/// Backward-compat composition (shared + Riverpod) — seeds [restPreset] et al.
/// so a fresh project defaults to Riverpod, same packages as before this axis
/// was split out.
const _corePackages = <PubPackage>[..._sharedCore, ..._riverpodPreset];

/// Opt-in typed routing (see [RoutingStyle]) — not bundled in [_corePackages]
/// so "manual go_router" is a real, reachable default instead of something
/// only achieved by manually deleting a package from Managed Packages.
const goRouterBuilderPackage = PubPackage(
  name: 'go_router_builder',
  version: '4.3.0',
  description: 'Type-safe route generation for go_router.',
  isDev: true,
);

/// REST: core + a Chopper HTTP client.
const restPreset = <PubPackage>[
  ..._corePackages,
  PubPackage(
    name: 'chopper',
    version: '8.6.0',
    description: 'HTTP client generator using annotations.',
  ),
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

/// Dio: core + the Dio HTTP client, no code-generated client wrapper.
const dioPreset = <PubPackage>[
  ..._corePackages,
  PubPackage(name: 'dio', version: '5.9.2', description: 'Powerful HTTP client for Dart.'),
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

/// The REST HTTP client — only meaningful when [backendOf] is
/// [BackendKind.rest]; picking one swaps the client package the same way
/// [applyBackendPreset]-family calls swap the backend (strip the marker
/// packages, add the new preset — see dependencies_provider.dart).
enum HttpClientKind { chopper, dio }

List<PubPackage> presetForHttpClient(HttpClientKind kind) => switch (kind) {
  HttpClientKind.chopper => restPreset,
  HttpClientKind.dio => dioPreset,
};

/// Infers the active REST client from the manifest. Defaults to chopper
/// (restPreset's own default) when dio isn't present.
HttpClientKind httpClientOf(List<PubPackage> packages) {
  final names = packages.map((p) => p.name).toSet();
  if (names.contains('dio')) return HttpClientKind.dio;
  return HttpClientKind.chopper;
}

/// go_router (always present, see [_corePackages]) can run in two modes:
/// hand-written routes, or `go_router_builder`'s typed, code-generated ones.
/// This is a plain add/remove of a single package (unlike [HttpClientKind]'s
/// mutually-exclusive presets), since [goRouterBuilderPackage] just layers on
/// top of go_router rather than replacing anything.
enum RoutingStyle { manual, typed }

/// Infers the active routing style from the manifest.
RoutingStyle routingStyleOf(List<PubPackage> packages) =>
    packages.any((p) => p.name == 'go_router_builder') ? RoutingStyle.typed : RoutingStyle.manual;

/// State management — independent of [BackendKind]/[HttpClientKind]: picking
/// one swaps just this slice of the manifest (see
/// [SelectedPackages.applyStateManagementPreset]), leaving the backend/HTTP
/// client choice untouched, the same way [RoutingStyle] is independent too.
enum StateManagementKind { riverpod, bloc }

List<PubPackage> presetForStateManagement(StateManagementKind kind) => switch (kind) {
  StateManagementKind.riverpod => _riverpodPreset,
  StateManagementKind.bloc => _blocPreset,
};

/// State-management package names — stripped before applying a new state
/// management preset (mirrors [backendMarkerPackages]), and consulted by
/// [SelectedPackages.applyBackendPreset] so switching backend never re-adds
/// Riverpod on top of an existing Bloc choice (or vice versa).
const stateManagementMarkerPackages = <String>{
  'hooks_riverpod',
  'flutter_hooks',
  'riverpod_annotation',
  'riverpod_generator',
  'riverpod_lint',
  'flutter_bloc',
  'bloc',
};

/// Infers the active state management from the manifest. Defaults to
/// Riverpod (NEAT's default) when no bloc-family package is present.
StateManagementKind stateManagementOf(List<PubPackage> packages) =>
    packages.any((p) => p.name.contains('bloc'))
    ? StateManagementKind.bloc
    : StateManagementKind.riverpod;
