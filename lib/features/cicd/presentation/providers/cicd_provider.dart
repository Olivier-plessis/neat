import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'cicd_provider.g.dart';

enum CiTool {
  githubActions,
  gitlabCi,
  codemagic,
  fastlane,
  shorebird,
}

class CicdState {
  const CicdState({
    this.selectedTools = const {},
    this.runAnalyze = true,
    this.runTests = true,
    this.autoDeploy = false,
  });

  final Set<CiTool> selectedTools;
  final bool runAnalyze;
  final bool runTests;
  final bool autoDeploy;

  bool isSelected(CiTool tool) => selectedTools.contains(tool);

  bool get hasCiRunner => selectedTools.any(
        (t) => t == CiTool.githubActions || t == CiTool.gitlabCi || t == CiTool.codemagic,
      );

  CicdState copyWith({
    Set<CiTool>? selectedTools,
    bool? runAnalyze,
    bool? runTests,
    bool? autoDeploy,
  }) =>
      CicdState(
        selectedTools: selectedTools ?? this.selectedTools,
        runAnalyze: runAnalyze ?? this.runAnalyze,
        runTests: runTests ?? this.runTests,
        autoDeploy: autoDeploy ?? this.autoDeploy,
      );
}

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
}
