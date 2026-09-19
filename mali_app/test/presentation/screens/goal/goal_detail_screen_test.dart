import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mali_app/application/providers/goal_providers.dart';
import 'package:mali_app/domain/entities/goal_contribution.dart';
import 'package:mali_app/domain/entities/savings_goal.dart';
import 'package:mali_app/presentation/screens/goal/goal_detail_screen.dart';
import 'package:mali_app/presentation/widgets/goal/goal_progress_ring.dart';
import 'package:mali_app/presentation/widgets/goal/required_this_month_card.dart';

SavingsGoal _goal({
  String currentAmount = '0',
  bool isCompleted = false,
}) {
  return SavingsGoal(
    id: 'g-1',
    userId: 'u-1',
    name: 'Emergency Fund',
    emoji: '🛟',
    targetAmount: '900',
    currentAmount: currentAmount,
    currencyCode: 'USD',
    targetDate: DateTime(2026, 6, 30),
    priorityOrder: 0,
    isCompleted: isCompleted,
    isSynced: false,
    createdAt: DateTime(2026, 4, 10),
    updatedAt: DateTime(2026, 4, 10),
  );
}

GoalContribution _contribution() {
  return GoalContribution(
    id: 'c-1',
    goalId: 'g-1',
    amount: '150',
    currencyCode: 'USD',
    note: 'April deposit',
    contributionDate: DateTime(2026, 4, 20),
    isSynced: false,
    createdAt: DateTime(2026, 4, 20),
    updatedAt: DateTime(2026, 4, 20),
  );
}

Future<void> _pumpDetail(
  WidgetTester tester, {
  required SavingsGoal goal,
  List<GoalContribution> contributions = const [],
  DateTime? now,
}) async {
  await tester.binding.setSurfaceSize(const Size(800, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        activeGoalsProvider.overrideWith((ref) => Stream.value([goal])),
        goalContributionsProvider(goal.id).overrideWith(
          (ref) => Stream.value(contributions),
        ),
      ],
      child: MaterialApp(
        home: GoalDetailScreen(
          goalId: goal.id,
          now: now ?? DateTime(2026, 5, 10),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows large progress ring, amounts, and action buttons',
      (tester) async {
    await _pumpDetail(tester, goal: _goal(currentAmount: '300'));

    expect(find.byKey(GoalDetailScreen.screenKey), findsOneWidget);
    expect(find.byType(GoalProgressRing), findsOneWidget);
    expect(find.text('Emergency Fund'), findsWidgets);
    expect(find.text('🛟'), findsOneWidget);
    expect(find.text('USD 300.00 of USD 900.00'), findsOneWidget);
    expect(find.byKey(GoalDetailScreen.addContributionButtonKey), findsOneWidget);
    expect(find.byTooltip('Edit goal'), findsOneWidget);
    expect(find.text('Add Contribution'), findsOneWidget);
    expect(find.text('Contribution history'), findsOneWidget);
  });

  testWidgets('lists contribution history', (tester) async {
    await _pumpDetail(
      tester,
      goal: _goal(currentAmount: '150'),
      contributions: [_contribution()],
    );

    expect(find.text('+ USD 150.00'), findsOneWidget);
    expect(find.textContaining('April deposit'), findsOneWidget);
  });

  testWidgets('shows an adjusted required-this-month amount when behind',
      (tester) async {
    await _pumpDetail(tester, goal: _goal());

    expect(find.byKey(RequiredThisMonthCard.cardKey), findsOneWidget);
    expect(find.text('Required this month'), findsOneWidget);
    expect(find.text('USD 450.00'), findsOneWidget);
    expect(find.textContaining('behind schedule'), findsOneWidget);
  });

  testWidgets('shows empty contribution history copy', (tester) async {
    await _pumpDetail(tester, goal: _goal(currentAmount: '300'));

    expect(find.text('No contributions yet.'), findsOneWidget);
  });
}
