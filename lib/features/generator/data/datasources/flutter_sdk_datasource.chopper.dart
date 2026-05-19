// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'flutter_sdk_datasource.dart';

// **************************************************************************
// ChopperGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
final class _$FlutterSdkDatasource extends FlutterSdkDatasource {
  _$FlutterSdkDatasource([ChopperClient? client]) {
    if (client == null) return;
    this.client = client;
  }

  @override
  final Type definitionType = FlutterSdkDatasource;

  @override
  Future<Response<Map<String, dynamic>>> fetchReleases() {
    final Uri $url = Uri.parse(
      '/flutter_infra_release/releases/releases_macos.json',
    );
    final Request $request = Request('GET', $url, client.baseUrl);
    return client.send<Map<String, dynamic>, Map<String, dynamic>>($request);
  }
}
