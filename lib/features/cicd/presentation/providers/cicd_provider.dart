import 'package:neat/features/cicd/domain/models/cicd_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'cicd_provider.g.dart';

@Riverpod(keepAlive: true)
class CicdNotifier extends _$CicdNotifier {
  @override
  CicdState build() => const CicdState();

  void toggleTool(CiTool tool) {
    final next = Set<CiTool>.from(state.selectedTools);
    if (next.contains(tool)) {
      next.remove(tool);
    } else {
      next.add(tool);
    }
    state = state.copyWith(selectedTools: next);
  }

  void toggleAnalyze(bool val) => state = state.copyWith(runAnalyze: val);
  void toggleTests(bool val) => state = state.copyWith(runTests: val);
  void toggleAutoDeploy(bool val) => state = state.copyWith(autoDeploy: val);
  void setSentryDsn(String dsn) => state = state.copyWith(sentryDsn: dsn.trim());
}
