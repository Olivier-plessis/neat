part of 'widgets.dart';

/// Wraps [child] with a desktop drag-and-drop target: dropping a file whose
/// extension matches [allowedExtensions] calls [onFilePicked] with its path —
/// same allow-list shape as `FilePicker.pickFiles(allowedExtensions: ...)`,
/// so drop and click-to-browse never disagree on what's valid. A mismatched
/// extension calls [onRejected] instead of silently doing nothing. Purely
/// additive: this never replaces the existing click-to-browse button inside
/// [child] — it just gives the same drop area a second way in.
///
/// Only takes the first dropped file — every current use (a single image or
/// a single CSV) is single-file by design.
class DropZone extends StatefulWidget {
  const DropZone({
    required this.child,
    required this.allowedExtensions,
    required this.onFilePicked,
    this.onRejected,
    super.key,
  });

  final Widget child;

  /// Lowercase, no leading dot — e.g. `['png']`, `['csv']`.
  final List<String> allowedExtensions;
  final ValueChanged<String> onFilePicked;
  final VoidCallback? onRejected;

  @override
  State<DropZone> createState() => _DropZoneState();
}

class _DropZoneState extends State<DropZone> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return DropTarget(
      onDragEntered: (_) => setState(() => _hovering = true),
      onDragExited: (_) => setState(() => _hovering = false),
      onDragDone: (details) {
        setState(() => _hovering = false);
        if (details.files.isEmpty) return;
        final path = details.files.first.path;
        final ext = path.contains('.') ? path.split('.').last.toLowerCase() : '';
        if (!widget.allowedExtensions.contains(ext)) {
          widget.onRejected?.call();
          return;
        }
        widget.onFilePicked(path);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          borderRadius: .circular(12),
          border: .all(color: _hovering ? Palette.colorPrimaryCyan : Colors.transparent, width: 2),
        ),
        child: widget.child,
      ),
    );
  }
}
