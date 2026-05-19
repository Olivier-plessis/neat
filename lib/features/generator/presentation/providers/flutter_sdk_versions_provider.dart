import 'package:neat/features/generator/domain/usecases/fetch_stable_flutter_versions_usecase.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'flutter_sdk_versions_provider.g.dart';

@Riverpod(keepAlive: true)
class FlutterSdkVersions extends _$FlutterSdkVersions {
  @override
  Future<List<String>> build() async {
    final useCase = ref.read(fetchStableFlutterVersionsUseCaseProvider);
    final result = await useCase();
    // Le repository garantit un fallback : result est toujours un succès.
    // getOrThrow() est donc sans risque, et met le provider en erreur uniquement
    // si un bug inattendu survient (pratique pour le debug).
    return result.getOrThrow();
  }
}
