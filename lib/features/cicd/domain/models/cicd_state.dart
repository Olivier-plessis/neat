import 'package:freezed_annotation/freezed_annotation.dart';

part 'cicd_state.freezed.dart';

/// CI/CD configuration chosen in the wizard.
///
/// Pure domain value object — no Flutter/Riverpod imports — so it can be
/// consumed by domain usecases (e.g. generation) without depending on the
/// presentation layer.
enum CiTool {
  githubActions,
  gitlabCi,
  codemagic,
  fastlane,
  shorebird,
}

@freezed
abstract class CicdState with _$CicdState {
  const CicdState._();

  const factory CicdState({
    @Default(<CiTool>{}) Set<CiTool> selectedTools,
    @Default(true) bool runAnalyze,
    @Default(true) bool runTests,
    @Default(false) bool autoDeploy,
  }) = _CicdState;

  bool isSelected(CiTool tool) => selectedTools.contains(tool);

  bool get hasCiRunner => selectedTools.any(
        (t) => t == CiTool.githubActions || t == CiTool.gitlabCi || t == CiTool.codemagic,
      );
}
