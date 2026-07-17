part of '../widgets.dart';

class BluePrintTree extends StatelessWidget {
  const BluePrintTree({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Self-contained max height: a plain (non-Expanded) child of a Column
    // gets unbounded height from its parent, which breaks the Flexible
    // scroll region below (RenderFlex needs a finite height to size a
    // flex child against) — capping it here means this widget works
    // wherever it's dropped, without every call site needing to remember
    // to wrap it.
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.neatColors.colorSurfaceCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.neatColors.surface10),
        ),
        child: Column(
          mainAxisSize: .min,
          crossAxisAlignment: .start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: context.neatColors.surface10,
                borderRadius: .vertical(top: Radius.circular(10)),
              ),
              child: Row(
                spacing: 6,
                children: [
                  Dot(color: context.neatColors.errorColor),
                  Dot(color: context.neatColors.colorYellow),
                  Dot(color: context.neatColors.colorGreen),
                  4.gapW,
                  Text('preview.tree'),
                ],
              ),
            ),
            Divider(height: 1, color: context.neatColors.surface10),
            Flexible(
              child: SizedBox(
                width: MediaQuery.sizeOf(context).width,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: child,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
