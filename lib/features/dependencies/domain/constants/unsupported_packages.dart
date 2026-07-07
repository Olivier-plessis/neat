/// Packages NEAT has no generation support for, but that are real pub.dev
/// results a user might search for. They stay visible in the UI but can't be
/// selected, so a search never looks like a dead end — it's clear the
/// package exists, just not wired into any generated code path.
///
/// - retrofit / retrofit_generator: dropped (see ROADMAP.md) — it never had
///   generation-harness coverage and overlapped entirely with chopper, which
///   does.
///
/// The bloc family (`flutter_bloc`/`bloc`) used to be blocked here too —
/// unblocked instead (see ROADMAP.md): Cubit/Bloc generation is real now,
/// same "selectable, generator-supported" bar as chopper/dio.
bool isUnsupportedPackage(String name) {
  const exact = {'retrofit', 'retrofit_generator'};
  return exact.contains(name);
}
