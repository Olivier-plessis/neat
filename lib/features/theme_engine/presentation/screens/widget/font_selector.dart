import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:neat_ui/neat_ui.dart';

const _popularGoogleFonts = <String>[
  'Inter',
  'Poppins',
  'Roboto',
  'Open Sans',
  'Lato',
  'Montserrat',
  'Nunito',
  'Raleway',
  'Work Sans',
  'DM Sans',
  'Plus Jakarta Sans',
  'Outfit',
  'Manrope',
  'Sora',
  'Space Grotesk',
  'Rubik',
  'Mulish',
  'Karla',
  'Quicksand',
  'Josefin Sans',
  'Source Sans 3',
  'PT Sans',
  'Noto Sans',
  'Lexend',
  'Playfair Display',
  'Merriweather',
  'Lora',
  'Bitter',
  'Roboto Slab',
  'Roboto Mono',
  'JetBrains Mono',
  'Fira Code',
];

class FontSelector extends StatelessWidget {
  const FontSelector({required this.value, required this.onChanged, super.key});

  final String value;
  final ValueChanged<String> onChanged;

  void _apply(BuildContext context, String font, {TextEditingController? controller}) {
    final name = font.trim();
    if (name.isEmpty) return;
    try {
      GoogleFonts.getFont(name); // throws if not a known Google Font
      onChanged(name);
    } catch (_) {
      controller?.text = value;
      neatSnack(context, '"$name" not found on Google Fonts', success: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      // Autocomplete only reads initialValue when its internal state is first
      // created — without this key, an external change to [value] (the
      // typography Reset button) would never reach the visible text field.
      key: ValueKey(value),
      initialValue: TextEditingValue(text: value),
      optionsBuilder: (t) {
        final q = t.text.trim().toLowerCase();
        if (q.isEmpty) return _popularGoogleFonts;
        return _popularGoogleFonts.where((f) => f.toLowerCase().contains(q));
      },
      onSelected: (f) => _apply(context, f),
      fieldViewBuilder: (context, controller, focusNode, onSubmit) {
        return Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1E),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            children: [
              const Icon(Icons.search, color: Colors.white24, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    hintText: 'Search a Google Font…',
                    hintStyle: TextStyle(color: Colors.white24, fontSize: 13),
                  ),
                  onSubmitted: (v) => _apply(context, v, controller: controller),
                ),
              ),
            ],
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            color: const Color(0xFF1E1E22),
            elevation: 8,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260, maxWidth: 320),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 4),
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, i) {
                  final f = options.elementAt(i);
                  return InkWell(
                    onTap: () => onSelected(f),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      child: Text(
                        f,
                        style: TextStyle(
                          color: f == value ? Palette.colorPrimaryCyan : Colors.white70,
                          fontSize: 13,
                          fontWeight: f == value ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
