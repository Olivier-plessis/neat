// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'pub_dev_datasource.dart';

// **************************************************************************
// ChopperGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
final class _$PubDevDatasource extends PubDevDatasource {
  _$PubDevDatasource([ChopperClient? client]) {
    if (client == null) return;
    this.client = client;
  }

  @override
  final Type definitionType = PubDevDatasource;

  @override
  Future<Response<dynamic>> searchPackages(String query) {
    final Uri $url = Uri.parse('/api/search');
    final Map<String, dynamic> $params = <String, dynamic>{'q': query};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> getPackageDetail(String name) {
    final Uri $url = Uri.parse('/api/packages/${name}');
    final Request $request = Request('GET', $url, client.baseUrl);
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> getPackageScore(String name) {
    final Uri $url = Uri.parse('/api/packages/${name}/score');
    final Request $request = Request('GET', $url, client.baseUrl);
    return client.send<dynamic, dynamic>($request);
  }
}
