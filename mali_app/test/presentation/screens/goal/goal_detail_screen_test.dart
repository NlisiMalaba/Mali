import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mali_app/application/providers/goal_providers.dart';
import 'package:mali_app/domain/entities/goal_contribution.dart';
import 'package:mali_app/domain/entities/savings_goal.dart';
import 'package:mali_app/presentation/screens/goal/goal_detail_screen.dart';
import 'package:mali_app/presentation/widgets/goal/goal_milestones_card.dart';
import 'package:mali_app/presentation/widgets/goal/goal_savings_jar.dart';

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
    note: 'From April surplus',
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
  testWidgets('shows jar hero, amounts, meta cards, and Add money',
      (tester) async {
    await _pumpDetail(tester, goal: _goal(currentAmount: '300'));

    expect(find.byKey(GoalDetailScreen.screenKey), findsOneWidget);
    expect(find.byKey(GoalSavingsJar.jarKey), findsOneWidget);
    expect(find.text('Emergency Fund'), findsOneWidget);
    expect(find.text('33%'), findsOneWidget);
    expect(find.text('\$300 saved'), findsOneWidget);
    expect(find.textContaining('of \$900'), findsOneWidget);
    expect(find.byKey(GoalDetailScreen.neededEachMonthKey), findsOneWidget);
    expect(find.text('Needed each month'), findsOneWidget);
    expect(find.text('Target date'), findsOneWidget);
    expect(find.text('30 Jun 2026'), findsOneWidget);
    expect(find.byKey(GoalMilestonesCard.cardKey), findsOneWidget);
    expect(find.byKey(GoalDetailScreen.addContributionButtonKey), findsOneWidget);
    expect(find.byTooltip('Edit goal'), findsOneWidget);
    expect(find.text('Add money'), findsOneWidget);
  });

  testWidgets('lists contribution history', (tester) async {
    await _pumpDetail(
      tester,
      goal: _goal(currentAmount: '150'),
      contributions: [_contribution()],
    );

    expect(find.text('From April surplus'), findsOneWidget);
    expect(find.textContaining('20 Apr'), findsOneWidget);
    expect(find.text('+\$150.00'), findsOneWidget);
  });

  testWidgets('shows needed each month when behind schedule', (tester) async {
    await _pumpDetail(tester, goal: _goal());

    expect(find.byKey(GoalDetailScreen.neededEachMonthKey), findsOneWidget);
    expect(find.text('Needed each month'), findsOneWidget);
    expect(find.textContaining('Behind for'), findsOneWidget);
  });

  testWidgets('shows empty contribution history copy', (tester) async {
    await _pumpDetail(tester, goal: _goal(currentAmount: '300'));

    expect(find.text('No contributions yet.'), findsOneWidget);
  });
}
