import 'package:flutter/material.dart';
import 'package:neat_ui/neat_ui.dart';

class ApproachCard extends StatefulWidget {
  const ApproachCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String description;
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
              : const Color(0xFF111316),
          borderRadius: .circular(16),
          border: .all(
            color: _hovered
                ? context.neatColors.colorPrimaryCyan.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.08),
            width: _hovered ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 8),
            Icon(
              widget.icon,
              size: 40,
              color: _hovered ? Palette.colorPrimaryCyan : Colors.white38,
            ),
            const SizedBox(height: 20),
            Text(
              widget.title,
              style: TextStyle(
                color: _hovered ? Colors.white : Colors.white70,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              widget.description,
              style: const TextStyle(color: Colors.white38, fontSize: 13, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: widget.onTap,
              style: OutlinedButton.styleFrom(
                foregroundColor: _hovered ? Palette.colorPrimaryCyan : Colors.white54,
                side: BorderSide(color: _hovered ? Palette.colorPrimaryCyan : Colors.white24),
                minimumSize: const Size(140, 42),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text(
                'STARTED',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
