import 'package:neat/features/generation/domain/services/templates/dart/_template_utils.dart';

class DomainTemplates {
  DomainTemplates._();

  // ── domain/entities ───────────────────────────────────────────────────────

  static String featureEntity({
    required String featureName,
    bool hasFreezed = false,
  }) {
    final p = pascal(featureName);

    if (hasFreezed) {
      return '''import 'package:freezed_annotation/freezed_annotation.dart';

part '${featureName}_entity.freezed.dart';

@freezed
abstract class ${p}Entity with _\$${p}Entity {
  const factory ${p}Entity({
    required String id,
    required String name,
  }) = _${p}Entity;
}
''';
    }

    return '''class ${p}Entity {
  const ${p}Entity({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;
}
''';
  }

  // ── domain/repositories (interface) ──────────────────────────────────────

  static String featureIRepository({
    required String featureName,
    required String packageName,
    bool hasHttpClient = false,
  }) {
    final p = pascal(featureName);
    // A remote source unlocks the full CRUD write contract.
    final writeContract = hasHttpClient
        ? '''
  Future<Result<${p}Entity>> create(${p}Entity entity);
  Future<Result<${p}Entity>> update(${p}Entity entity);
  Future<Result<bool>> delete(String id);'''
        : '';
    return '''import 'package:$packageName/core/result/result.dart';
import '../entities/${featureName}_entity.dart';

abstract class I${p}Repository {
  Future<Result<List<${p}Entity>>> getAll();
  Future<Result<${p}Entity>> getById(String id);
$writeContract
}
''';
  }

  // ── domain/usecases ───────────────────────────────────────────────────────

  static String featureGetUsecase({
    required String featureName,
    required String packageName,
  }) {
    final p = pascal(featureName);
    return '''import 'package:$packageName/core/result/result.dart';
import 'package:$packageName/core/usecases/use_case.dart';
import '../entities/${featureName}_entity.dart';
import '../repositories/i_${featureName}_repository.dart';

class Get${p}Usecase extends NoParamsUseCase<Result<List<${p}Entity>>> {
  const Get${p}Usecase(this._repository);

  final I${p}Repository _repository;

  @override
  Future<Result<List<${p}Entity>>> execute() => _repository.getAll();
}
''';
  }

  /// CRUD write usecases (generated when a remote source is present).
  static String featureCrudUsecases({
    required String featureName,
    required String packageName,
  }) {
    final p = pascal(featureName);
    return '''import 'package:$packageName/core/result/result.dart';
import 'package:$packageName/core/usecases/use_case.dart';
import '../entities/${featureName}_entity.dart';
import '../repositories/i_${featureName}_repository.dart';

class Create${p}Usecase extends UseCase<${p}Entity, Result<${p}Entity>> {
  const Create${p}Usecase(this._repository);

  final I${p}Repository _repository;

  @override
  Future<Result<${p}Entity>> execute(${p}Entity entity) => _repository.create(entity);
}

class Update${p}Usecase extends UseCase<${p}Entity, Result<${p}Entity>> {
  const Update${p}Usecase(this._repository);

  final I${p}Repository _repository;

  @override
  Future<Result<${p}Entity>> execute(${p}Entity entity) => _repository.update(entity);
}

class Delete${p}Usecase extends UseCase<String, Result<bool>> {
  const Delete${p}Usecase(this._repository);

  final I${p}Repository _repository;

  @override
  Future<Result<bool>> execute(String id) => _repository.delete(id);
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
