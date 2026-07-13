import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'architecture_tab_provider.g.dart';

/// The active sub-tab within the Architecture wizard step. Purely a local UI
/// grouping — it does NOT affect [NeatStep]'s wizard progress/index, since
/// Architecture still counts as a single step (see main_layout.dart's
/// PROGRESS bar); this only decides which panel is shown and which sidenav
/// sub-item is highlighted. Mirrors infrastructure_tab_provider.dart exactly.
enum ArchitectureTab { structure, storage, features }

@Riverpod(keepAlive: true)
class CurrentArchitectureTab extends _$CurrentArchitectureTab {
  @override
  ArchitectureTab build() => ArchitectureTab.structure;

  void setTab(ArchitectureTab tab) => state = tab;
}
