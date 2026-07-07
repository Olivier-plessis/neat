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
  }) {
    final p = pascal(featureName);
    // Nested objects (and list-element objects) each become their own sub-entity.
    final objects = collectObjectSpecs(fields);

    if (hasFreezed) {
      final classes = [
        _entityFreezed(p, fields),
        for (final o in objects) _entityFreezed(o.objectName, o.children),
      ].join('\n\n');
      return '''import 'package:freezed_annotation/freezed_annotation.dart';

part '${featureName}_entity.freezed.dart';

$classes
''';
    }

    final classes = [
      _entityPlain(p, fields),
      for (final o in objects) _entityPlain(o.objectName, o.children),
    ].join('\n\n');
    return '$classes\n';
  }

  /// One freezed entity class ([base] → `<base>Entity`). [entityType] already
  /// carries the nullability suffix.
  static String _entityFreezed(String base, List<FieldSpec> fields) {
    final params = fields
        .map((f) => f.nullable
            ? '    ${f.entityType} ${f.dartName},'
            : '    required ${f.entityType} ${f.dartName},')
        .join('\n');
    return '''@freezed
abstract class ${base}Entity with _\$${base}Entity {
  const factory ${base}Entity({
$params
  }) = _${base}Entity;
}''';
  }

  /// One plain entity class ([base] → `<base>Entity`).
  static String _entityPlain(String base, List<FieldSpec> fields) {
    final ctorParams = fields
        .map((f) => f.nullable ? '    this.${f.dartName},' : '    required this.${f.dartName},')
        .join('\n');
    final decls = fields.map((f) => '  final ${f.entityType} ${f.dartName};').join('\n');
    return '''class ${base}Entity {
  const ${base}Entity({
$ctorParams
  });

$decls
}''';
  }

  // ── domain/repositories (interface) ──────────────────────────────────────

  static String featureIRepository({
    required String featureName,
    required String packageName,
    bool hasHttpClient = false,
    bool offlineFirst = false,
    bool realtime = false,
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
    final readContract = resultReads
        ? '''
  Future<Result<List<${p}Entity>>> getAll();
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
    final watchContract = realtime ? '\n  Stream<List<${p}Entity>> watchAll();' : '';
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
