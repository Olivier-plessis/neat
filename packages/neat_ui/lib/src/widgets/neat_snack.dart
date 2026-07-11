part of 'widgets.dart';

/// Shows a consistent floating snackbar (cyan = success, red = error).
void neatSnack(BuildContext context, String message, {bool success = true}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: success ? const Color(0xFF0E1A1A) : const Color(0xFF2A1A1A),
        duration: const Duration(seconds: 2),
        content: Row(
          mainAxisSize: .min,
          spacing: 10,
          children: [
            Icon(
              success ? Icons.check_circle_outline : Icons.error_outline,
              color: success ? Palette.colorPrimaryCyan : Colors.redAccent,
              size: 18,
            ),
            Flexible(
              child: Text(message, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
}
