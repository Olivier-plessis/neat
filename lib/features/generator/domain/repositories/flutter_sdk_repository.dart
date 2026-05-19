abstract interface class FlutterSdkRepository {
  Future<List<String>> fetchStableVersions();
}
