import 'package:neat/features/dependencies/domain/models/pub_package.dart';

const devPresetPackages = [
  // ── Runtime dependencies ──────────────────────────────────────────────────
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
  PubPackage(
    name: 'chopper',
    version: '8.6.0',
    description: 'HTTP client generator using annotations.',
  ),
  PubPackage(name: 'go_router', version: '17.2.3', description: 'Declarative routing for Flutter.'),
  PubPackage(name: 'envied', version: '1.3.5', description: 'Declarative env for Flutter.'),

  // ── Dev dependencies ──────────────────────────────────────────────────────
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
  PubPackage(
    name: 'riverpod_lint',
    version: '3.1.3',
    description: 'Lint rules for Riverpod.',
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
  PubPackage(
    name: 'go_router_builder',
    version: '4.3.0',
    description: 'Type-safe route generation for go_router.',
    isDev: true,
  ),
  PubPackage(
    name: 'chopper_generator',
    version: '8.6.2',
    description: 'Code generator for Chopper HTTP clients.',
    isDev: true,
  ),
];
