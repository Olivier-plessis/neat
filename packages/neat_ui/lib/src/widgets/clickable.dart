part of 'widgets.dart';

/// A tap target that shows the pointer cursor on hover (desktop affordance).
/// Drop-in replacement for a simple `GestureDetector(onTap:, child:)`.
class Clickable extends StatelessWidget {
  const Clickable({required this.onTap, required this.child, super.key});

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(onTap: onTap, behavior: HitTestBehavior.opaque, child: child),
    );
  }
}
