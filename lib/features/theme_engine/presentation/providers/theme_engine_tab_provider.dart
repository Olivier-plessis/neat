import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'theme_engine_tab_provider.g.dart';

/// The active sub-tab within the Custom M3 editor (Theme Engine wizard step).
/// Purely a local UI grouping — mirrors `InfrastructureTab` (see
/// infrastructure_tab_provider.dart). Only meaningful when
/// `ThemeEngineState.approach == ThemeApproach.customM3`: FlexColorScheme has
/// no sub-tabs of its own (one single editor), and the entry point (no
/// approach picked yet) has none either.
enum ThemeEngineTab { colors, typography, buttonsShapes, icons }

@Riverpod(keepAlive: true)
class CurrentThemeEngineTab extends _$CurrentThemeEngineTab {
  @override
  ThemeEngineTab build() => ThemeEngineTab.colors;

  void setTab(ThemeEngineTab tab) => state = tab;
}
