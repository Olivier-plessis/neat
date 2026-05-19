import 'package:chopper/chopper.dart';

part 'flutter_sdk_datasource.chopper.dart';

@ChopperApi()
abstract class FlutterSdkDatasource extends ChopperService {
  @GET(path: '/flutter_infra_release/releases/releases_macos.json')
  Future<Response<Map<String, dynamic>>> fetchReleases();

  static FlutterSdkDatasource create() => _$FlutterSdkDatasource(
    ChopperClient(
      baseUrl: Uri.parse('https://storage.googleapis.com'),
      services: [_$FlutterSdkDatasource()],
      converter: const JsonConverter(),
    ),
  );
}
