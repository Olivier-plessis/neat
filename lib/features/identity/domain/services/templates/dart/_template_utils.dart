/// Shared utility used by all dart sub-templates.
String pascal(String s) {
  if (s.isEmpty) return s;
  return s.split('_').map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1)).join();
}

/// snake_case → lowerCamelCase, for Dart identifiers (provider/route vars).
/// e.g. "neat_core" → "neatCore"
String camel(String s) {
  final p = pascal(s);
  return p.isEmpty ? p : p[0].toLowerCase() + p.substring(1);
}
