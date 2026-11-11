import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mali_app/application/providers/budget_providers.dart';
import 'package:mali_app/domain/entities/budget.dart';
import 'package:mali_app/presentation/screens/budget/budgets_screen.dart';
import 'package:mali_app/presentation/widgets/budget/budget_list_tile.dart';
import 'package:mali_app/presentation/widgets/budget/budget_overall_gauge.dart';

Budget _budget({
  required String id,
  required String categoryId,
  required String amount,
  required String spentAmount,
}) {
  return Budget(
    id: id,
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

Future<void> _pumpBudgets(
  WidgetTester tester, {
  required List<Budget> budgets,
}) async {
  await tester.binding.setSurfaceSize(const Size(800, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentMonthBudgetsProvider.overrideWith(
          (ref) => Stream.value(budgets),
        ),
      ],
      child: MaterialApp(
        home: BudgetsScreen(now: DateTime(2026, 11, 11)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows header, gauge hero, and New button', (tester) async {
    await _pumpBudgets(tester, budgets: const []);

    expect(find.byKey(BudgetsScreen.screenKey), findsOneWidget);
    expect(find.text('Budgets'), findsOneWidget);
    expect(find.text('November · 20 days left'), findsOneWidget);
    expect(find.byKey(BudgetsScreen.newBudgetButtonKey), findsOneWidget);
    expect(find.byKey(BudgetsScreen.heroKey), findsOneWidget);
    expect(find.byKey(BudgetOverallGauge.gaugeKey), findsOneWidget);
    expect(find.text('No budget envelopes yet'), findsOneWidget);
  });

  testWidgets('lists budgets with status chips and totals', (tester) async {
    await _pumpBudgets(
      tester,
      budgets: [
        _budget(
          id: 'b-1',
          categoryId: 'cat-airtime',
          amount: '40',
          spentAmount: '46',
        ),
        _budget(
          id: 'b-2',
          categoryId: 'cat-transport',
          amount: '150',
          spentAmount: '141',
        ),
        _budget(
          id: 'b-3',
          categoryId: 'cat-groceries',
          amount: '300',
          spentAmount: '216',
        ),
      ],
    );

    expect(find.byType(BudgetListTile), findsNWidgets(3));
    expect(find.textContaining('Over by'), findsOneWidget);
    expect(find.text('Close to limit'), findsOneWidget);
    expect(find.text('On track'), findsOneWidget);
    expect(find.textContaining('of'), findsWidgets);
    expect(find.textContaining('used ·'), findsOneWidget);
  });
}
