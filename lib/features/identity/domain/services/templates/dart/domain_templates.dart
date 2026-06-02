import 'package:neat/features/identity/domain/services/templates/dart/_template_utils.dart';

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
  }) {
    final p = pascal(featureName);
    return '''import 'package:$packageName/core/result/result.dart';
import '../entities/${featureName}_entity.dart';

abstract class I${p}Repository {
  Future<Result<List<${p}Entity>>> getAll();
  Future<Result<${p}Entity>> getById(String id);
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
import '../entities/${featureName}_entity.dart';
import '../repositories/i_${featureName}_repository.dart';

class Get${p}Usecase {
  const Get${p}Usecase(this._repository);

  final I${p}Repository _repository;

  Future<Result<List<${p}Entity>>> execute() => _repository.getAll();
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
