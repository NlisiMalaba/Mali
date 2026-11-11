import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mali_app/domain/entities/budget.dart';
import 'package:mali_app/presentation/utils/insights_coach_tip.dart';

Budget _budget({
  required String categoryId,
  required String amount,
  required String spentAmount,
}) {
  return Budget(
    id: 'b-$categoryId',
    userId: 'u-1',
    categoryId: categoryId,
    currencyCode: 'USD',
    amount: amount,
    spentAmount: spentAmount,
    month: 11,
    year: 2026,
    rolloverEnabled: false,
    isSynced: false,
    createdAt: DateTime(2026, 11, 1),
    updatedAt: DateTime(2026, 11, 1),
  );
}

void main() {
  test('builds tip from stressed and spare budgets', () {
    final tip = InsightsCoachTip.fromBudgets(
      budgets: [
        _budget(
          categoryId: 'cat-transport',
          amount: '150',
          spentAmount: '141',
        ),
        _budget(
          categoryId: 'cat-entertainment',
          amount: '150',
          spentAmount: '98',
        ),
      ],
      now: DateTime(2026, 11, 11),
      categoryName: (id) => switch (id) {
            'cat-transport' => 'Transport',
            'cat-entertainment' => 'Eating out',
            _ => id,
          },
    );

    expect(tip, isNotNull);
    expect(tip!.stressedCategoryName, 'Transport');
    expect(tip.stressedPercent, 94);
    expect(tip.daysRemaining, 20);
    expect(tip.spareCategoryName, 'Eating out');
    expect(tip.spareRemaining, Decimal.parse('52'));
    expect(tip.suggestedMove, Decimal.parse('20'));
    expect(
      tip.message(currencyCode: 'USD'),
      'Transport is at 94% with 20 days to go. Eating out has \$52 spare.',
    );
    expect(tip.ctaLabel(currencyCode: 'USD'), 'Move \$20 to Transport');
  });

  test('returns null when no budget is near its limit', () {
    final tip = InsightsCoachTip.fromBudgets(
      budgets: [
        _budget(
          categoryId: 'cat-transport',
          amount: '150',
          spentAmount: '40',
        ),
      ],
      now: DateTime(2026, 11, 11),
      categoryName: (id) => 'Transport',
    );

    expect(tip, isNull);
  });
}
