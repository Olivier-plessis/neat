import 'package:chopper/chopper.dart';

part 'pub_dev_datasource.chopper.dart';

@ChopperApi()
abstract class PubDevDatasource extends ChopperService {
  @GET(path: '/api/search')
  Future<Response<dynamic>> searchPackages(@Query('q') String query);

  @GET(path: '/api/packages/{name}')
  Future<Response<dynamic>> getPackageDetail(@Path('name') String name);

  @GET(path: '/api/packages/{name}/score')
  Future<Response<dynamic>> getPackageScore(@Path('name') String name);

  static PubDevDatasource create() => _$PubDevDatasource(
    ChopperClient(
      baseUrl: Uri.parse('https://pub.dev'),
      services: [_$PubDevDatasource()],
      converter: const JsonConverter(),
    ),
  );
}
