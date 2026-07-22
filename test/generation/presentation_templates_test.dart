import 'package:flutter_test/flutter_test.dart';
import 'package:neat/features/generation/domain/services/templates/dart/presentation_templates.dart';

void main() {
  group('featurePage (riverpod list page) — Skeletonizer placeholder is '
      'hoisted, not rebuilt inline (real gap found via a wesioo comparison: '
      'doctor_agenda_page.dart computes its skeleton state once, outside '
      'build() — NEAT used to reconstruct 8 full nested entities from '
      'scratch on every rebuild while loading)', () {
    final code = PresentationTemplates.featurePage(
      featureName: 'recipe',
      packageName: 'demo',
      hasRiverpod: true,
      useAnnotations: true,
      hasBloc: false,
      useCubit: false,
      dataList: true,
    );

    test('the placeholder list is a top-level final, computed once', () {
      expect(
        code,
        contains('final _recipeSkeletonItems = List.generate(8, (_) => RecipeEntity('),
      );
    });

    test('build() references the hoisted variable, not an inline List.generate', () {
      expect(code, contains('Skeletonizer(child: _RecipeList(items: _recipeSkeletonItems))'));
      expect(code, isNot(contains('items: List.generate(\n')));
    });

    test('the hoisted variable sits before the class, not inside build()', () {
      final varIdx = code.indexOf('final _recipeSkeletonItems');
      final classIdx = code.indexOf('class RecipePage');
      final buildIdx = code.indexOf('Widget build(BuildContext context, WidgetRef ref)');
      expect(varIdx, greaterThan(-1));
      expect(varIdx, lessThan(classIdx));
      expect(varIdx, lessThan(buildIdx));
    });
  });
}
