/// Packages whose generated code paths are **not yet validated** by the
/// generation harness. They stay visible in the UI but can't be selected, so
/// users never generate an untested combination.
///
/// - retrofit / retrofit_generator: the retrofit API-source path has no
///   integration coverage (chopper & dio do).
/// - the bloc family: the BLoC/Cubit state generation isn't covered yet
///   (riverpod is the validated path).
bool isUnsupportedPackage(String name) {
  const exact = {'retrofit', 'retrofit_generator'};
  return exact.contains(name) || name.contains('bloc');
}
