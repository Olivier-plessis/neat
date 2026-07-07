part of '../widgets.dart';

class ApproachCard extends StatefulWidget {
  const ApproachCard({
    required this.icon,
    required this.accent,
    required this.title,
    required this.subtitle,
    required this.button,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final bool accent;
  final String title;
  final String subtitle;
  final String button;
  final VoidCallback onTap;

  @override
  State<ApproachCard> createState() => _ApproachCardState();
}

class _ApproachCardState extends State<ApproachCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const .all(28),
        decoration: BoxDecoration(
          color: _hovered
              ? context.neatColors.colorPrimaryCyan.withValues(alpha: 0.06)
              : widget.accent
              ? Palette.colorPrimaryCyan.withValues(alpha: 0.12)
              : const Color(0xFF111316),
          borderRadius: .circular(16),
          border: .all(
            color: _hovered
                ? context.neatColors.colorPrimaryCyan.withValues(alpha: 0.5)
                : widget.accent
                ? Palette.colorPrimaryCyan.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.08),
            width: _hovered ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            8.gapH,
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: _hovered || widget.accent
                    ? Palette.colorPrimaryCyan.withValues(alpha: 0.12)
                    : Colors.white.withValues(alpha: 0.04),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _hovered || widget.accent
                      ? Palette.colorPrimaryCyan.withValues(alpha: 0.4)
                      : Colors.white12,
                ),
              ),
              child: Icon(
                widget.icon,
                size: 40,
                color: _hovered || widget.accent ? Palette.colorPrimaryCyan : Colors.white38,
              ),
            ),

            20.gapH,
            Text(
              widget.title,
              style: TextStyle(
                color: _hovered ? Colors.white : Colors.white70,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            10.gapH,
            Text(
              widget.subtitle,
              style: const TextStyle(color: Colors.white38, fontSize: 13, height: 1.5),
              textAlign: TextAlign.center,
            ),
            24.gapH,
            OutlinedButton(
              onPressed: widget.onTap,
              style: OutlinedButton.styleFrom(
                foregroundColor: _hovered || widget.accent
                    ? Palette.colorPrimaryCyan
                    : Colors.white54,
                side: BorderSide(
                  color: _hovered || widget.accent ? Palette.colorPrimaryCyan : Colors.white24,
                ),
                minimumSize: const Size(160, 44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                widget.button.toUpperCase(),
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
              ),
            ),
            8.gapH,
          ],
        ),
      ),
    );
  }
}
