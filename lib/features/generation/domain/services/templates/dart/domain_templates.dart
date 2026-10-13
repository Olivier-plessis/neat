import 'package:neat/features/generation/domain/models/field_spec.dart';
import 'package:neat/features/generation/domain/services/templates/dart/_template_utils.dart';
import 'package:neat/features/generation/domain/services/templates/dart/field_codegen.dart';

class DomainTemplates {
  DomainTemplates._();

  // ── domain/entities ───────────────────────────────────────────────────────

  static String featureEntity({
    required String featureName,
    bool hasFreezed = false,
    List<FieldSpec> fields = FieldSpec.idName,
    // Offline-first creation can't wait for a server-assigned id: add a
    // `create` factory that generates it on the client (uuid v4). The generated
    // project depends on `uuid` then (see PubspecWriter / the feature package's
    // pubspec).
    bool clientId = false,
  }) {
    final p = pascal(featureName);
    // Nested objects (and list-element objects) each become their own sub-entity.
    final objects = collectObjectSpecs(fields);
    // Enum fields: the entity types them as the domain enum, and re-exports it
    // so whatever imports the entity (model, page, tests) gets the enum too.
    final enumFiles = [
      for (final e in collectEnumSpecs(fields)) '${e.enumFileName}.dart',
    ];
    final enumImports = enumFiles.map((f) => "import '$f';").join('\n');
    final enumExports = enumFiles.map((f) => "export '$f';").join('\n');
    final enumLines = enumFiles.isEmpty ? '' : '$enumImports\n$enumExports\n';
    final uuidImport = clientId ? "import 'package:uuid/uuid.dart';\n" : '';

    if (hasFreezed) {
      final classes = [
        _entityFreezed(p, fields, clientId: clientId),
        for (final o in objects) _entityFreezed(o.objectName, o.children),
      ].join('\n\n');
      return '''import 'package:freezed_annotation/freezed_annotation.dart';
$uuidImport$enumLines
part '${featureName}_entity.freezed.dart';

$classes
''';
    }

    final classes = [
      _entityPlain(p, fields, clientId: clientId),
      for (final o in objects) _entityPlain(o.objectName, o.children),
    ].join('\n\n');
    final header = '$uuidImport$enumLines';
    return header.isEmpty ? '$classes\n' : '$header\n$classes\n';
  }

  /// The `create` factory: every field but the id, which is generated here
  /// (uuid v4) because the entity is created locally and queued before the
  /// server ever sees it.
  static String _createFactory(String base, List<FieldSpec> fields) {
    final id = idField(fields);
    final params = [
      for (final f in fields)
        if (!f.isId)
          f.nullable
              ? '${f.entityType} ${f.dartName}'
              : 'required ${f.entityType} ${f.dartName}',
    ].join(', ');
    final args = [
      for (final f in fields)
        f.isId
            ? '${f.dartName}: const Uuid().v4()'
            : '${f.dartName}: ${f.dartName}',
    ].join(', ');
    return '''
  /// A $base that does not exist yet. [${id.dartName}] is generated here, on the
  /// client: it is created locally and queued before the server ever sees it
  /// (offline-first), so it cannot wait for a server-assigned id.
  factory ${base}Entity.create({$params}) => ${base}Entity($args);''';
  }

  /// One freezed entity class ([base] → `<base>Entity`). [entityType] already
  /// carries the nullability suffix.
  static String _entityFreezed(
    String base,
    List<FieldSpec> fields, {
    bool clientId = false,
  }) {
    final params = fields
        .map(
          (f) => f.nullable
              ? '    ${f.entityType} ${f.dartName},'
              : '    required ${f.entityType} ${f.dartName},',
        )
        .join('\n');
    final create = clientId ? '\n${_createFactory(base, fields)}\n' : '';
    return '''@freezed
abstract class ${base}Entity with _\$${base}Entity {
${clientId ? '  const ${base}Entity._();\n\n' : ''}  const factory ${base}Entity({
$params
  }) = _${base}Entity;
$create}''';
  }

  /// One plain entity class ([base] → `<base>Entity`).
  static String _entityPlain(
    String base,
    List<FieldSpec> fields, {
    bool clientId = false,
  }) {
    final ctorParams = fields
        .map(
          (f) => f.nullable
              ? '    this.${f.dartName},'
              : '    required this.${f.dartName},',
        )
        .join('\n');
    final decls = fields
        .map((f) => '  final ${f.entityType} ${f.dartName};')
        .join('\n');
    final create = clientId ? '\n${_createFactory(base, fields)}\n' : '';
    return '''class ${base}Entity {
  const ${base}Entity({
$ctorParams
  });

$decls
$create}''';
  }

  /// One domain enum for an enum field: each member carries the text stored in
  /// the database ([value]) and [fromValue] turns text back into a member,
  /// falling back to the **first** one for anything this version doesn't know
  /// (an older or newer backend) rather than breaking a whole list. The DTO and
  /// the Drift row keep the plain `String`; the model's mappers convert.
  ///
  /// [checkedBy]: the Supabase table whose migration constrains the column with
  /// a SQL `CHECK` over these same values (mentioned in the doc comment).
  static String featureEnum({
    required FieldSpec field,
    required String featureName,
    String? checkedBy,
  }) {
    final name = field.resolvedEnumName;
    final values = field.enumValues.isEmpty
        ? FieldSpec.defaultEnumValues
        : field.enumValues;
    final used = <String>{};
    final members = [
      for (final v in values)
        () {
          var member = enumMemberName(v);
          for (var n = 2; !used.add(member); n++) {
            member = '${enumMemberName(v)}$n';
          }
          return (member, v);
        }(),
    ];
    final fallback = members.first.$1;
    final constants = members
        .map((m) => "  ${m.$1}('${m.$2.replaceAll("'", r"\'")}')")
        .join(',\n');
    final check = checkedBy == null
        ? ''
        : ', constrained by a CHECK in the Supabase migration';
    return '''/// The allowed values of `$featureName.${field.jsonKey}`. [value] is the text
/// stored in the database (`${checkedBy ?? featureName}.${field.jsonKey}`$check).
enum $name {
$constants;

  const $name(this.value);

  /// The text stored in the database and sent over the wire.
  final String value;

  /// Unknown values (an older or newer backend) fall back to [$fallback]
  /// instead of breaking the whole list.
  static $name fromValue(String value) => values.firstWhere(
    (e) => e.value == value,
    orElse: () => $fallback,
  );
}
''';
  }

  // ── domain/repositories (interface) ──────────────────────────────────────

  static String featureIRepository({
    required String featureName,
    required String packageName,
    bool hasHttpClient = false,
    bool offlineFirst = false,
    bool realtime = false,
    // Offline-first + sync: `watchAll()` is the live list read from the local
    // Drift table (the source of truth the UI watches), not the remote
    // realtime stream — see DataTemplates.featureRepositoryImpl's localWatch.
    bool localWatch = false,
    // Set when the feature lives in its own workspace package (`packageSplit`
    // — see ROADMAP.md §6a): Result/Failure/UseCase live in this shared
    // package instead of the app, since a pub workspace forbids the feature
    // package depending back on the app.
    String? corePackageName,
  }) {
    final p = pascal(featureName);
    // Offline-first reads return Result<T> directly — they encapsulate a
    // network→cache fallback strategy, not a boilerplate try/catch, so they
    // bypass UseCase.call()'s generic Result-wrapping (see featureGetUsecase).
    // Every other method throws on failure; UseCase.call() wraps it.
    final resultReads = offlineFirst && hasHttpClient;
    final getAllDoc = localWatch
        ? '  /// Pulls the remote rows into the local database (falls back to it offline).\n'
        : '';
    final readContract = resultReads
        ? '''
$getAllDoc  Future<Result<List<${p}Entity>>> getAll();
  Future<Result<${p}Entity>> getById(String id);'''
        : '''
  Future<List<${p}Entity>> getAll();
  Future<${p}Entity> getById(String id);''';
    // A remote source unlocks the full CRUD write contract.
    final writeContract = hasHttpClient
        ? '''
  Future<${p}Entity> create(${p}Entity entity);
  Future<${p}Entity> update(${p}Entity entity);
  Future<bool> delete(String id);'''
        : '';
    // Realtime: a live stream of the full list (Supabase `.stream()`).
    // Offline-first + sync: the same method name, but read from the local
    // database instead (documented on the interface so a screen author reads
    // the right contract).
    final watchContract = localWatch
        ? '''

  /// Live list read from the local database — what screens should show.
  Stream<List<${p}Entity>> watchAll();'''
        : realtime
        ? '\n  Stream<List<${p}Entity>> watchAll();'
        : '';
    final resultImport = resultReads
        ? "import 'package:${corePackageName ?? packageName}/core/result/result.dart';\n"
        : '';
    return '''$resultImport'''
        '''import '../entities/${featureName}_entity.dart';

abstract class I${p}Repository {
$readContract
$writeContract$watchContract
}
''';
  }

  // ── domain/usecases ───────────────────────────────────────────────────────

  static String featureGetUsecase({
    required String featureName,
    required String packageName,
    bool offlineFirst = false,
    // See featureIRepository's doc — same packageSplit rationale.
    String? corePackageName,
  }) {
    final p = pascal(featureName);
    final corePkg = corePackageName ?? packageName;
    // Offline-first: the repository already returns a Result<T> encapsulating
    // its network→cache fallback (see featureRepositoryImpl / featureIRepository)
    // — unwrap it via getOrThrow() so UseCase.call() can still uniformly
    // rewrap it into a Result/Failure. getOrThrow() throws the Failure object
    // itself on total failure, which NetworkErrorHandler passes through as-is.
    final body = offlineFirst
        ? '''async {
    final result = await _repository.getAll();
    return result.getOrThrow();
  }'''
        : '=> _repository.getAll();';
    // No Result import needed: getOrThrow() is a plain instance method on the
    // sealed Result<T> class (not an extension), and the repository's return
    // type is already resolvable via i_<feature>_repository.dart below, which
    // imports result.dart itself — importing it again here is unused.
    return '''import 'package:$corePkg/core/usecases/use_case.dart';
import '../entities/${featureName}_entity.dart';
import '../repositories/i_${featureName}_repository.dart';

class Get${p}Usecase extends NoParamsUseCase<List<${p}Entity>> {
  const Get${p}Usecase(this._repository);

  final I${p}Repository _repository;

  @override
  Future<List<${p}Entity>> execute(Unit _) $body
}
''';
  }

  /// CRUD write usecases (generated when a remote source is present). The
  /// repository throws on failure — UseCase.call() converts it to a Failure.
  static String featureCrudUsecases({
    required String featureName,
    required String packageName,
    // See featureIRepository's doc — same packageSplit rationale.
    String? corePackageName,
  }) {
    final p = pascal(featureName);
    return '''import 'package:${corePackageName ?? packageName}/core/usecases/use_case.dart';
import '../entities/${featureName}_entity.dart';
import '../repositories/i_${featureName}_repository.dart';

class Create${p}Usecase extends UseCase<${p}Entity, ${p}Entity> {
  const Create${p}Usecase(this._repository);

  final I${p}Repository _repository;

  @override
  Future<${p}Entity> execute(${p}Entity entity) => _repository.create(entity);
}

class Update${p}Usecase extends UseCase<${p}Entity, ${p}Entity> {
  const Update${p}Usecase(this._repository);

  final I${p}Repository _repository;

  @override
  Future<${p}Entity> execute(${p}Entity entity) => _repository.update(entity);
}

class Delete${p}Usecase extends UseCase<String, bool> {
  const Delete${p}Usecase(this._repository);

  final I${p}Repository _repository;

  @override
  Future<bool> execute(String id) => _repository.delete(id);
}
''';
  }

  // ── Example / placeholder ─────────────────────────────────────────────────

  static String featureExampleUsecase({required String featureName}) {
    final p = pascal(featureName);
    return '''import 'dart:async';

abstract class ${p}Repository {
  // Define your repository interface here
}

class Example${p}Usecase {
  const Example${p}Usecase(this._repository);

  final ${p}Repository _repository;

  Future<void> execute() async {
    // Implement your use case logic here
  }
}
''';
  }
}
