part of 'widgets.dart';

/// A labeled on/off switch row used across NEAT's wizard screens (a title +
/// description on the left, a pill switch on the right). Shared between
/// Architecture and Infrastructure so opt-in toggles can move between screens
/// without duplicating the widget.
class ToggleTile extends StatelessWidget {
  const ToggleTile({
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
    this.disabled = false,
    super.key,
  });

  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  /// Locked: shown but not toggleable (feature pinned / not yet validated).
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: disabled ? 0.55 : 1,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF18181C),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(description, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(width: 16),
            GestureDetector(
              onTap: disabled ? null : () => onChanged(!value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 48,
                height: 28,
                decoration: BoxDecoration(
                  color: value ? Palette.colorPrimaryCyan.withValues(alpha: 0.15) : Colors.white10,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: value ? Palette.colorPrimaryCyan : Colors.white12,
                    width: 1.5,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedAlign(
                      duration: const Duration(milliseconds: 200),
                      alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.all(3),
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: value ? Palette.colorPrimaryCyan : Colors.grey[700],
                            shape: BoxShape.circle,
                          ),
                          child: value
                              ? const Icon(Icons.check, size: 11, color: Color(0xFF0E0E0E))
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
