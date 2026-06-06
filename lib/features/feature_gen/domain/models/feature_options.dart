/// Per-feature choices (distinct from the stack, which the contract fixes).
enum FeatureRouting {
  root,
  child, // sub-route of another feature — not generated yet
  shell, // bottom-nav / side-rail branch — not generated yet
}

/// Options the user picks for a single feature in the Workshop. Layers default
/// to the project stack; the user can opt a feature out of some of them.
class FeatureOptions {
  const FeatureOptions({
    this.routing = FeatureRouting.root,
    this.includeRemote = true,
    this.includeUseCase = true,
  });

  final FeatureRouting routing;
  final bool includeRemote;
  final bool includeUseCase;

  FeatureOptions copyWith({
    FeatureRouting? routing,
    bool? includeRemote,
    bool? includeUseCase,
  }) =>
      FeatureOptions(
        routing: routing ?? this.routing,
        includeRemote: includeRemote ?? this.includeRemote,
        includeUseCase: includeUseCase ?? this.includeUseCase,
      );
}
