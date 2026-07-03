import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'infrastructure_tab_provider.g.dart';

/// The active sub-tab within the Infrastructure wizard step. Purely a local
/// UI grouping — it does NOT affect [NeatStep]'s wizard progress/index, since
/// Infrastructure still counts as a single step (see main_layout.dart's
/// PROGRESS bar); this only decides which panel is shown and which sidenav
/// sub-item is highlighted.
enum InfrastructureTab { backend, navigation, localization }

@Riverpod(keepAlive: true)
class CurrentInfrastructureTab extends _$CurrentInfrastructureTab {
  @override
  InfrastructureTab build() => InfrastructureTab.backend;

  void setTab(InfrastructureTab tab) => state = tab;
}
