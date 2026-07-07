/// Packages NEAT has no generation support for, but that are real pub.dev
/// results a user might search for. They stay visible in the UI but can't be
/// selected, so a search never looks like a dead end — it's clear the
/// package exists, just not wired into any generated code path.
///
/// - retrofit / retrofit_generator: dropped (see ROADMAP.md) — it never had
///   generation-harness coverage and overlapped entirely with chopper, which
///   does.
/// - the bloc family: the BLoC/Cubit state generation isn't covered yet
///   (riverpod is the validated path).
bool isUnsupportedPackage(String name) {
  const exact = {'retrofit', 'retrofit_generator'};
  return exact.contains(name) || name.contains('bloc');
}
