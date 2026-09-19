import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mali_app/application/providers/goal_providers.dart';
import 'package:mali_app/domain/entities/savings_goal.dart';
import 'package:mali_app/presentation/screens/goal/goal_detail_screen.dart';
import 'package:mali_app/presentation/screens/goal/goals_screen.dart';
import 'package:mali_app/presentation/widgets/goal/goal_card.dart';

SavingsGoal _goal({
  String id = 'g-1',
  String name = 'School Fees',
  String emoji = '🎓',
  int priorityOrder = 0,
}) {
  return SavingsGoal(
    id: id,
    userId: 'u-1',
    name: name,
    emoji: emoji,
    targetAmount: '2000.00',
    currentAmount: '500.00',
    currencyCode: 'USD',
    targetDate: DateTime(2026, 12, 19),
    priorityOrder: priorityOrder,
    isCompleted: false,
    isSynced: false,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );
}

Future<void> _pumpGoalsScreen(
  WidgetTester tester, {
  required List<SavingsGoal> goals,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        activeGoalsProvider.overrideWith((ref) => Stream.value(goals)),
      ],
      child: const MaterialApp(home: GoalsScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows empty state and Add Goal FAB when there are no goals',
      (tester) async {
    await _pumpGoalsScreen(tester, goals: const []);

    expect(find.byKey(GoalsScreen.screenKey), findsOneWidget);
    expect(find.text('No savings goals yet'), findsOneWidget);
    expect(find.text('Add your first goal'), findsOneWidget);
    expect(find.byTooltip('Add Goal'), findsOneWidget);
  });

  testWidgets('lists goals in GoalCards with name, emoji, and amounts',
      (tester) async {
    await _pumpGoalsScreen(
      tester,
      goals: [
        _goal(),
        _goal(id: 'g-2', name: 'Emergency Fund', emoji: '🛟', priorityOrder: 1),
      ],
    );

    expect(find.byType(GoalCard), findsNWidgets(2));
    expect(find.text('School Fees'), findsOneWidget);
    expect(find.text('🎓'), findsOneWidget);
    expect(find.text('Emergency Fund'), findsOneWidget);
    expect(find.text('🛟'), findsOneWidget);
    expect(find.text('USD 500.00 of USD 2000.00'), findsNWidgets(2));
    expect(find.byTooltip('Add Goal'), findsOneWidget);
  });

  testWidgets('tapping a GoalCard opens GoalDetailScreen', (tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const GoalsScreen(),
        ),
        GoRoute(
          path: '/goals/:id',
          builder: (context, state) => GoalDetailScreen(
            goalId: state.pathParameters['id'] ?? '',
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeGoalsProvider.overrideWith(
            (ref) => Stream.value([_goal()]),
          ),
          goalContributionsProvider('g-1').overrideWith(
            (ref) => Stream.value(const []),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(GoalCard.cardKey('g-1')));
    await tester.pumpAndSettle();

    expect(find.byKey(GoalDetailScreen.screenKey), findsOneWidget);
    expect(find.text('School Fees'), findsWidgets);
  });
}
