/// Shared utility used by all dart sub-templates.
String pascal(String s) {
  if (s.isEmpty) return s;
  return s.split('_').map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1)).join();
}
