import 'package:neat/core/utils/app_logger.dart';
import 'package:neat/features/dependencies/data/datasources/pub_dev_datasource.dart';
import 'package:neat/features/dependencies/data/entities/pub_package_detail_entity.dart';
import 'package:neat/features/dependencies/data/entities/pub_package_score_entity.dart';
import 'package:neat/features/dependencies/data/entities/pub_search_entity.dart';
import 'package:neat/features/dependencies/domain/constants/dev_packages_whitelist.dart';
import 'package:neat/features/dependencies/domain/models/pub_package.dart';
import 'package:neat/features/dependencies/domain/repositories/pub_dev_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'pub_dev_repository_impl.g.dart';

class PubDevRepositoryImpl implements PubDevRepository {
  PubDevRepositoryImpl(this._datasource);

  final PubDevDatasource _datasource;

  @override
  Future<List<PubPackage>> searchPackages(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      final searchResponse = await _datasource.searchPackages(query);
      if (!searchResponse.isSuccessful || searchResponse.body == null) return [];

      final searchEntity = PubSearchResponseEntity.fromJson(
        searchResponse.body as Map<String, dynamic>,
      );

      // Récupère détails + scores en parallèle pour chaque résultat
      final packages = await Future.wait(
        searchEntity.packages.map((item) => _fetchPackage(item.package)),
      );

      return packages.whereType<PubPackage>().toList();
    } catch (e, s) {
      AppLogger.w('PubDevRepository.searchPackages failed', error: e, stackTrace: s);
      return [];
    }
  }

  Future<PubPackage?> _fetchPackage(String name) async {
    try {
      final results = await Future.wait([
        _datasource.getPackageDetail(name),
        _datasource.getPackageScore(name),
      ]);

      final detailResponse = results[0];
      final scoreResponse = results[1];

      if (!detailResponse.isSuccessful || detailResponse.body == null) return null;

      final detail = PubPackageDetailEntity.fromJson(
        detailResponse.body as Map<String, dynamic>,
      );

      PubPackageScoreEntity? score;
      if (scoreResponse.isSuccessful && scoreResponse.body != null) {
        score = PubPackageScoreEntity.fromJson(
          scoreResponse.body as Map<String, dynamic>,
        );
      }

      return PubPackage(
        name: detail.name,
        version: detail.latest.version,
        description: detail.latest.pubspec.description ?? '',
        likes: score?.likeCount ?? 0,
        pubPoints: score?.grantedPoints ?? 0,
        popularity: score != null ? (score.popularityScore * 100).round() : 0,
        isDev: devPackagesWhitelist.contains(detail.name),
      );
    } catch (e) {
      AppLogger.w('PubDevRepository._fetchPackage($name) failed', error: e);
      return null;
    }
  }
}

@Riverpod(keepAlive: true)
PubDevRepository pubDevRepository(Ref ref) =>
    PubDevRepositoryImpl(PubDevDatasource.create());
