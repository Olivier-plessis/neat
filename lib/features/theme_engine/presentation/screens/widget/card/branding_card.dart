import 'dart:io';

import 'package:flutter/material.dart';
import 'package:neat_ui/neat_ui.dart';

class BrandingCard extends StatelessWidget {
  const BrandingCard({
    required this.logoPath,
    required this.onPick,
    required this.onRemove,
    super.key,
  });

  final String logoPath;
  final Future<void> Function() onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final hasLogo = logoPath.isNotEmpty && File(logoPath).existsSync();
    return Container(
      padding: const .all(16),
      decoration: BoxDecoration(
        color: context.neatColors.colorSurfaceCard,
        borderRadius: .circular(12),
        border: .all(color: Colors.white10),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: .circular(10),
            child: hasLogo
                ? Image.file(File(logoPath), width: 52, height: 52, fit: BoxFit.cover)
                : Container(
                    width: 52,
                    height: 52,
                    color: Colors.white10,
                    child: Icon(Icons.image_outlined, color: Colors.grey[600]),
                  ),
          ),
          16.gapW,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'App icon & splash',
                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                ),
                4.gapH,
                Text(
                  hasLogo
                      ? logoPath.split('/').last
                      : 'Upload a square PNG logo → icons + splash generated for you.',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          12.gapW,
          if (hasLogo)
            TextButton(
              onPressed: onRemove,
              style: TextButton.styleFrom(foregroundColor: Colors.white54),
              child: const Text('Remove'),
            ),
          FilledButton.icon(
            onPressed: onPick,
            icon: const Icon(Icons.upload_outlined, size: 16),
            label: Text(hasLogo ? 'Replace' : 'Upload PNG'),
            style: FilledButton.styleFrom(
              backgroundColor: context.neatColors.colorPrimaryCyan,
              foregroundColor: const Color(0xFF0E0E0E),
            ),
          ),
        ],
      ),
    );
  }
}
