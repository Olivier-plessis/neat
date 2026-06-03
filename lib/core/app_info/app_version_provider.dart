import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_version_provider.g.dart';

/// The app version label, read once from the platform bundle.
///
/// Returns "vX.Y.Z+B" (e.g. "v1.0.0+1"). Kept alive so the lookup runs once.
@Riverpod(keepAlive: true)
Future<String> appVersion(Ref ref) async {
  final info = await PackageInfo.fromPlatform();
  return 'v${info.version}';
}
