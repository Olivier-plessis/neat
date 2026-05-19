import 'package:neat/core/result/result.dart';
import 'package:neat/core/usecase/use_case.dart';
import 'package:neat/features/generator/data/repositories/flutter_sdk_repository_impl.dart';
import 'package:neat/features/generator/domain/repositories/flutter_sdk_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'fetch_stable_flutter_versions_usecase.g.dart';

class FetchStableFlutterVersionsUseCase extends NoParamsUseCase<List<String>> {
  const FetchStableFlutterVersionsUseCase(this._repository);

  final FlutterSdkRepository _repository;

  @override
  Future<List<String>> execute(Unit params) =>
      _repository.fetchStableVersions();
}

@Riverpod(keepAlive: true)
FetchStableFlutterVersionsUseCase fetchStableFlutterVersionsUseCase(Ref ref) =>
    FetchStableFlutterVersionsUseCase(ref.read(flutterSdkRepositoryProvider));
