/// Shared utility used by all dart sub-templates.
String pascal(String s) {
  if (s.isEmpty) return s;
  return s
      .split('_')
      .map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1))
      .join();
}

/// snake_case → lowerCamelCase, for Dart identifiers (provider/route vars).
/// e.g. "neat_core" → "neatCore"
String camel(String s) {
  final p = pascal(s);
  return p.isEmpty ? p : p[0].toLowerCase() + p.substring(1);
}

/// The base path the Outbox queues a feature's writes under (`<base>` for a
/// create, `<base>/<id>` for an update/delete). Supabase/Firebase address a
/// table/collection, not a REST path, so `apiPath` is ignored there and the
/// table name is used — the same one the API source writes to. REST clients
/// keep the `apiPath` override (an absolute URL overrides the client's base).
String outboxEndpointBase({
  required String httpClient,
  required String featureName,
  String? apiPath,
  String? tableName,
}) => switch (httpClient) {
  'supabase' || 'firebase' => '/${tableName ?? '${featureName}s'}',
  _ => apiPath ?? '/${featureName}s',
};

/// The Outbox `resource` for [outboxEndpointBase]: its path without slashes
/// (`/products` → `products`, `https://host/api/v1/products` →
/// `api/v1/products`). Must match what the generated `SyncService` computes
/// from a queued entry's endpoint (which is the base + `/<id>`).
String outboxResourceFor({
  required String httpClient,
  required String featureName,
  String? apiPath,
  String? tableName,
}) {
  final base = outboxEndpointBase(
    httpClient: httpClient,
    featureName: featureName,
    apiPath: apiPath,
    tableName: tableName,
  );
  final path = Uri.tryParse(base)?.path ?? base;
  return path.split('/').where((s) => s.isNotEmpty).join('/');
}
