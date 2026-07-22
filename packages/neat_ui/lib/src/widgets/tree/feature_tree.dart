part of '../widgets.dart';

class FeatureTree extends StatelessWidget {
  const FeatureTree({
    required this.isGenerating,
    required this.scrollController,
    required this.logs,
    super.key,
  });

  final bool isGenerating;
  final ScrollController scrollController;
  final List<String> logs;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: context.neatColors.colorSurfaceCard,
        borderRadius: .circular(10),
        border: .all(color: context.neatColors.surface10),
      ),
      child: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF141416),
              borderRadius: .vertical(top: Radius.circular(10)),
            ),
            child: Row(
              spacing: 6,
              children: [
                Dot(color: Palette.errorColor),
                Dot(color: Palette.colorYellow),
                Dot(color: Palette.colorGreen),
                4.gapW,

                const Text(
                  'System Output',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (isGenerating)
                  const SizedBox(
                    width: 10,
                    height: 10,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: Palette.colorPrimaryCyan,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              padding: const .all(14),
              itemCount: logs.length,
              itemBuilder: (_, i) {
                final line = logs[i];
                return Text(
                  line,
                  style: TextStyle(
                    color: _lineColor(line),
                    fontSize: 12,
                    height: 1.6,
                    fontWeight: line.startsWith('[✓✓]') ? FontWeight.bold : FontWeight.normal,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Mirrors LaunchGenerationUsecase/GenerateFeatureUsecase's own onLog
  // prefixes: [▶] in progress, [✓]/[✓✓] done, [ℹ] informational note, [⚠]
  // recoverable warning, [!]/[✗] failure — plus launch_screen's own synthetic
  // pre-generation lines ([OK]/[WARN]/neat@...).
  Color _lineColor(String line) {
    if (line.startsWith('[✗') || line.startsWith('[!]')) return Colors.redAccent;
    if (line.startsWith('[⚠') || line.startsWith('[WARN]')) return Colors.orangeAccent;
    if (line.startsWith('[ℹ')) return Colors.lightBlueAccent[100]!;
    if (line.startsWith('[✓') || line.startsWith('[OK]')) return const Color(0xFF4CAF50);
    if (line.startsWith('[▶')) return Palette.colorPrimaryCyan;
    if (line.startsWith('neat@')) return Colors.grey;
    return const Color(0xFF9ECE6A);
  }
}
