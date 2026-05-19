import 'package:neat/core/usecase/use_case.dart';
import 'package:neat/features/dependencies/data/repositories/pub_dev_repository_impl.dart';
import 'package:neat/features/dependencies/domain/models/pub_package.dart';
import 'package:neat/features/dependencies/domain/repositories/pub_dev_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'search_packages_usecase.g.dart';

class SearchPackagesUseCase extends UseCase<String, List<PubPackage>> {
  const SearchPackagesUseCase(this._repository);

  final PubDevRepository _repository;

  @override
  Future<List<PubPackage>> execute(String query) =>
      _repository.searchPackages(query);
}

@Riverpod(keepAlive: true)
SearchPackagesUseCase searchPackagesUseCase(Ref ref) =>
    SearchPackagesUseCase(ref.read(pubDevRepositoryProvider));
