import 'package:flutter/material.dart';
import 'package:neat_ui/neat_ui.dart';

/// Common Material icons offered for a shell branch (kept curated so the
/// generated `Icon(Icons.<name>)` always compiles).
const _shellIcons = <String>[
  'home',
  'dashboard',
  'person',
  'settings',
  'search',
  'favorite',
  'notifications',
  'list',
  'shopping_cart',
  'explore',
  'calendar_today',
  'chat',
  'map',
  'star',
  'folder',
  'account_circle',
];

const _iconData = <String, IconData>{
  'home': Icons.home,
  'dashboard': Icons.dashboard,
  'person': Icons.person,
  'settings': Icons.settings,
  'search': Icons.search,
  'favorite': Icons.favorite,
  'notifications': Icons.notifications,
  'list': Icons.list,
  'shopping_cart': Icons.shopping_cart,
  'explore': Icons.explore,
  'calendar_today': Icons.calendar_today,
  'chat': Icons.chat,
  'map': Icons.map,
  'star': Icons.star,
  'folder': Icons.folder,
  'account_circle': Icons.account_circle,
};

/// Icon + label for a shell branch's NavigationBar destination.
class ShellBranchFields extends StatelessWidget {
  const ShellBranchFields({
    required this.icon,
    required this.labelCtrl,
    required this.labelHint,
    required this.enabled,
    required this.onIcon,
    super.key,
  });

  final String icon;
  final TextEditingController labelCtrl;
  final String labelHint;
  final bool enabled;
  final ValueChanged<String> onIcon;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12,
      children: [
        SizedBox(
          width: 140,
          child: InputDecorator(
            decoration: _decoration('Nav icon', context),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _iconData.containsKey(icon) ? icon : 'home',
                isExpanded: true,
                dropdownColor: context.neatColors.colorSurfaceCard,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                onChanged: enabled ? (v) => onIcon(v ?? 'home') : null,
                items: _shellIcons
                    .map(
                      (i) => DropdownMenuItem(
                        value: i,
                        child: Row(
                          spacing: 8,
                          children: [
                            Icon(_iconData[i], size: 16, color: Palette.colorPrimaryCyan),
                            Expanded(child: Text(i, overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ),
        Expanded(
          child: TextField(
            controller: labelCtrl,
            enabled: enabled,
            style: const TextStyle(color: Colors.white),
            decoration: _decoration('Nav label', context).copyWith(
              hintText: labelHint.isEmpty ? 'e.g. Home' : labelHint,
              hintStyle: TextStyle(color: Colors.grey[600]),
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _decoration(String label, BuildContext context) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: Colors.white54, fontSize: 13),
    filled: true,
    fillColor: context.neatColors.colorNeutralBg,
    contentPadding: const .symmetric(horizontal: 12, vertical: 2),
    enabledBorder: OutlineInputBorder(
      borderRadius: .circular(8),
      borderSide: BorderSide(color: context.neatColors.surface10),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: .circular(8),
      borderSide: BorderSide(color: context.neatColors.colorPrimaryCyan),
    ),
  );
}
