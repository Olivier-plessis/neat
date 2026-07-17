import 'package:flutter/material.dart';
import 'package:neat_ui/neat_ui.dart';

InputDecoration fieldDecoration(String hint, String? error, BuildContext context) =>
    InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[600]),
      errorText: error,
      filled: true,
      fillColor: context.neatColors.colorSurfaceCard,
      enabledBorder: OutlineInputBorder(
        borderRadius: .circular(8),
        borderSide: const BorderSide(color: Colors.white10),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: .circular(8),
        borderSide: BorderSide(color: context.neatColors.colorPrimaryCyan),
      ),
    );
