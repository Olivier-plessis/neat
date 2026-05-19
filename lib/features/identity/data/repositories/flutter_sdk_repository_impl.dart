import 'package:neat/core/utils/app_logger.dart';
import 'package:neat/features/identity/data/datasources/flutter_sdk_datasource.dart';
import 'package:neat/features/identity/data/entities/flutter_release_entity.dart';
import 'package:neat/features/identity/domain/repositories/flutter_sdk_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'flutter_sdk_repository_impl.g.dart';

const _stableVersionsLimit = 6;
const _fallbackVersions = ['3.29.3', '3.27.4', '3.24.5', '3.22.3'];

class FlutterSdkRepositoryImpl implements FlutterSdkRepository {
  FlutterSdkRepositoryImpl(this._datasource);

  final FlutterSdkDatasource _datasource;

  @override
  Future<List<String>> fetchStableVersions() async {
    try {
      final response = await _datasource.fetchReleases();
      if (!response.isSuccessful || response.body == null) {
        return _fallbackVersions;
      }

      final entity = FlutterReleasesResponseEntity.fromJson(response.body!);
      final versions = entity.releases
          .where((r) => r.channel == 'stable')
          .map((r) => r.version)
          .toSet()
          .take(_stableVersionsLimit)
          .toList();

      return versions.isEmpty ? _fallbackVersions : versions;
    } catch (e, s) {
      AppLogger.w(
        'FlutterSdkRepository: falling back to hardcoded versions',
        error: e,
        stackTrace: s,
      );
      return _fallbackVersions;
    }
  }
}

@Riverpod(keepAlive: true)
FlutterSdkRepository flutterSdkRepository(Ref ref) =>
    FlutterSdkRepositoryImpl(FlutterSdkDatasource.create());
