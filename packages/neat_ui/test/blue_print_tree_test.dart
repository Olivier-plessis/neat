import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neat_ui/neat_ui.dart';

void main() {
  testWidgets(
    'BluePrintTree lays out without a RenderFlex unbounded-height error '
    'when used as a plain (non-Expanded) child of a Column inside a '
    'bounded-height ancestor (the real feature_gen_screen.dart usage shape)',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: SizedBox(
              height: 600,
              width: 500,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BluePrintTree(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [Text('lib/features/foo/data/foo.dart')],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Generate Feature'),
                ],
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('lib/features/foo/data/foo.dart'), findsOneWidget);
    },
  );
}
