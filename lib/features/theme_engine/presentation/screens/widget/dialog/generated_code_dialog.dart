// ── Generated code preview dialog ───────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:neat_ui/neat_ui.dart';

class GeneratedCodeDialog extends StatelessWidget {
  const GeneratedCodeDialog({required this.code, super.key});

  final String code;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: context.neatColors.colorNeutralBg,
      shape: RoundedRectangleBorder(borderRadius: .circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760, maxHeight: 640),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title bar
            Container(
              padding: const .symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: context.neatColors.colorSurfaceCard,
                borderRadius: .vertical(top: .circular(14)),
              ),
              child: Row(
                spacing: 8,
                children: [
                  const Icon(Icons.code, size: 16, color: Palette.colorPrimaryCyan),
                  Text(
                    'app_theme.dart',
                    style: context.textTheme.bodyMedium!.copyWith(color: Colors.white),
                  ),
                  Text(
                    '· preview of generated code',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 11),
                  ),
                  const Spacer(),
                  Clickable(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: code));
                      neatSnack(context, 'Copied to clipboard');
                    },
                    child: Container(
                      padding: const .symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        borderRadius: .circular(6),
                        border: .all(
                          color: context.neatColors.colorPrimaryCyan.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: .min,
                        children: [
                          Icon(
                            Icons.copy_outlined,
                            size: 13,
                            color: context.neatColors.colorPrimaryCyan,
                          ),
                          6.gapW,
                          Text(
                            'Copy',
                            style: TextStyle(
                              color: context.neatColors.colorPrimaryCyan,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Clickable(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.close, size: 18, color: Colors.white38),
                  ),
                ],
              ),
            ),
            // Code body
            Flexible(
              child: SingleChildScrollView(
                padding: const .all(16),
                child: SingleChildScrollView(
                  scrollDirection: .horizontal,
                  child: SelectableText(
                    code,
                    style: TextStyle(
                      color: context.neatColors.colorGreen,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
