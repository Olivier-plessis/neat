import 'package:neat/features/generation/domain/models/endpoint_spec.dart';

/// Per-operation endpoint override for the 5 fixed Entity+CRUD operations —
/// opt-in via `FeatureGenOptions.customizeEndpoints`. Unlike Custom Endpoints'
/// [EndpointSpec], there's no request/response body to define per operation
/// (every operation shares the feature's one entity) — just the method name
/// (like Custom Endpoints' own `name` field — renames the `ApiSource`'s
/// generated method + its call site in `RepositoryImpl`, not the stable
/// Clean-Architecture-facing names like `I<Feature>Repository.getAll()` or
/// `Get<Feature>Usecase`, which never change), HTTP verb, and path each of
/// the 5 fixed operations actually calls — for APIs that don't follow the
/// plain REST convention `apiPath`'s single base already covers (e.g.
/// dummyjson's recipes: `POST /recipes/add` to create, not `POST /recipes`).
/// `getById`/`update`/`delete` keep a literal `{id}` in their path —
/// chopper's own `@Path()` binding matches it natively, no runtime
/// substitution needed.
///
/// Hand-written, mirroring [EndpointSpec]'s own style rather than freezed —
/// a simple flat value object with no need for union types or deep
/// `copyWith`.
class CrudEndpointOverrides {
  const CrudEndpointOverrides({
    this.getAllName = 'getAll',
    this.getAllMethod = HttpMethod.get,
    this.getAllPath = '',
    this.getByIdName = 'getById',
    this.getByIdMethod = HttpMethod.get,
    this.getByIdPath = '',
    this.createName = 'add',
    this.createMethod = HttpMethod.post,
    this.createPath = '',
    this.updateName = 'update',
    this.updateMethod = HttpMethod.put,
    this.updatePath = '',
    this.deleteName = 'delete',
    this.deleteMethod = HttpMethod.delete,
    this.deletePath = '',
  });

  /// Sensible starting point when the "Customize endpoints" toggle is first
  /// switched on — the exact paths today's fixed derivation already uses, so
  /// the user only has to retype the operation(s) that genuinely differ
  /// (e.g. just `createPath`) instead of every one of the 5 from scratch.
  factory CrudEndpointOverrides.defaultsFor(String base) => CrudEndpointOverrides(
    getAllPath: base,
    getByIdPath: '$base/{id}',
    createPath: base,
    updatePath: '$base/{id}',
    deletePath: '$base/{id}',
  );

  final String getAllName;
  final HttpMethod getAllMethod;
  final String getAllPath;
  final String getByIdName;
  final HttpMethod getByIdMethod;
  final String getByIdPath;
  final String createName;
  final HttpMethod createMethod;
  final String createPath;
  final String updateName;
  final HttpMethod updateMethod;
  final String updatePath;
  final String deleteName;
  final HttpMethod deleteMethod;
  final String deletePath;

  CrudEndpointOverrides copyWith({
    String? getAllName,
    HttpMethod? getAllMethod,
    String? getAllPath,
    String? getByIdName,
    HttpMethod? getByIdMethod,
    String? getByIdPath,
    String? createName,
    HttpMethod? createMethod,
    String? createPath,
    String? updateName,
    HttpMethod? updateMethod,
    String? updatePath,
    String? deleteName,
    HttpMethod? deleteMethod,
    String? deletePath,
  }) => CrudEndpointOverrides(
    getAllName: getAllName ?? this.getAllName,
    getAllMethod: getAllMethod ?? this.getAllMethod,
    getAllPath: getAllPath ?? this.getAllPath,
    getByIdName: getByIdName ?? this.getByIdName,
    getByIdMethod: getByIdMethod ?? this.getByIdMethod,
    getByIdPath: getByIdPath ?? this.getByIdPath,
    createName: createName ?? this.createName,
    createMethod: createMethod ?? this.createMethod,
    createPath: createPath ?? this.createPath,
    updateName: updateName ?? this.updateName,
    updateMethod: updateMethod ?? this.updateMethod,
    updatePath: updatePath ?? this.updatePath,
    deleteName: deleteName ?? this.deleteName,
    deleteMethod: deleteMethod ?? this.deleteMethod,
    deletePath: deletePath ?? this.deletePath,
  );
}
