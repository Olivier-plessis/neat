import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neat/features/feature_gen/presentation/widgets/entity_fields_editor.dart';
import 'package:neat/features/generation/domain/models/field_spec.dart';

void main() {
  // FieldSpec.fakeStoreProduct already has a real nested object field
  // (`rating` → {rate, count}) — NEAT's own worked-example fixture, reused
  // here instead of inventing a parallel one.
  Widget harness({
    required List<FieldSpec> fields,
    required void Function(int, List<FieldSpec>) onChildrenChanged,
  }) {
    // Scrollable, matching the real usage context (EntityFieldsStep's own
    // step content is a SingleChildScrollView) — without it, the fixed
    // 800x600 test viewport overflows on this many rows.
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: EntityFieldsEditor(
            fields: fields,
            onAddField: () {},
            onName: (_, _) {},
            onType: (_, _) {},
            onNullable: (_, _) {},
            onRemove: (_) {},
            onChildrenChanged: onChildrenChanged,
          ),
        ),
      ),
    );
  }

  testWidgets('a nested object field is collapsed by default — no child rows visible', (
    tester,
  ) async {
    await tester.pumpWidget(harness(fields: FieldSpec.fakeStoreProduct, onChildrenChanged: (_, _) {}));

    expect(find.text('rating'), findsOneWidget);
    expect(find.text('List<Rating>'), findsNothing); // it's an object, not a list
    expect(find.text('Rating'), findsOneWidget); // the type label
    expect(find.text('rate'), findsNothing);
    expect(find.text('count'), findsNothing);
  });

  testWidgets('expanding the nested object row reveals its own children', (tester) async {
    await tester.pumpWidget(harness(fields: FieldSpec.fakeStoreProduct, onChildrenChanged: (_, _) {}));

    // Tap the non-editable type label ("Rating"), not the editable name
    // field ("rating") — a tap on the TextField just places a cursor there
    // instead of toggling the tile, exactly like Custom Endpoints' own
    // EndpointRow (name/method/path are all interactive too).
    await tester.ensureVisible(find.text('Rating'));
    await tester.tap(find.text('Rating'));
    await tester.pumpAndSettle();

    expect(find.text('rate'), findsOneWidget);
    expect(find.text('count'), findsOneWidget);
  });

  testWidgets(
    'toggling a nested field\'s nullable checkbox reports the updated children '
    'for the parent field\'s own index',
    (tester) async {
      int? reportedIndex;
      List<FieldSpec>? reportedChildren;

      await tester.pumpWidget(
        harness(
          fields: FieldSpec.fakeStoreProduct,
          onChildrenChanged: (i, children) {
            reportedIndex = i;
            reportedChildren = children;
          },
        ),
      );

      await tester.ensureVisible(find.text('Rating'));
      await tester.tap(find.text('Rating'));
      await tester.pumpAndSettle();

      // Every field row (top-level and nested) has its own "null?"
      // checkbox, so find.byType(Checkbox).first would hit the locked `id`
      // row (disabled — tapping it is a no-op), not `rate`'s. Scope to the
      // Checkbox living in the same title Row as the "rate" text instead.
      final rateCheckbox = find.descendant(
        of: find.ancestor(of: find.text('rate'), matching: find.byType(Row)).first,
        matching: find.byType(Checkbox),
      );
      await tester.ensureVisible(rateCheckbox);
      await tester.tap(rateCheckbox);
      await tester.pumpAndSettle();

      final ratingIndex = FieldSpec.fakeStoreProduct.indexWhere((f) => f.dartName == 'rating');
      expect(reportedIndex, ratingIndex);
      expect(reportedChildren, isNotNull);
      expect(reportedChildren!.firstWhere((f) => f.dartName == 'rate').nullable, isTrue);
      // The sibling child is untouched.
      expect(reportedChildren!.firstWhere((f) => f.dartName == 'count').nullable, isFalse);
    },
  );

  testWidgets('a plain scalar field never shows an expand affordance', (tester) async {
    await tester.pumpWidget(harness(fields: FieldSpec.idName, onChildrenChanged: (_, _) {}));

    expect(find.byType(ExpansionTile), findsNothing);
  });
}
