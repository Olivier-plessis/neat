import 'package:neat/core/contract/neat_contract.dart';

/// An existing NEAT project opened in Workshop mode: its on-disk location, the
/// stack read from `.neat.json`, and the features discovered by scanning
/// `lib/features/` (the filesystem is the source of truth for features).
class LoadedProject {
  const LoadedProject({
    required this.path,
    required this.contract,
    required this.features,
  });

  final String path;
  final NeatContract contract;
  final List<String> features;
}
