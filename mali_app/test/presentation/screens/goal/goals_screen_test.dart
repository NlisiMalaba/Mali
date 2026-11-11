import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mali_app/application/providers/goal_providers.dart';
import 'package:mali_app/domain/entities/savings_goal.dart';
import 'package:mali_app/presentation/screens/goal/goal_detail_screen.dart';
import 'package:mali_app/presentation/screens/goal/goals_screen.dart';
import 'package:mali_app/presentation/widgets/goal/goal_list_tile.dart';
import 'package:mali_app/presentation/widgets/goal/goal_priority_hero.dart';

SavingsGoal _goal({
  String id = 'g-1',
  String name = 'School Fees',
  String emoji = '🎓',
  int priorityOrder = 0,
  String currentAmount = '500.00',
  String targetAmount = '2000.00',
}) {
  return SavingsGoal(
    id: id,
    userId: 'u-1',
    name: name,
    emoji: emoji,
    targetAmount: targetAmount,
    currentAmount: currentAmount,
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
      child: MaterialApp(
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          );
        },
        home: const GoalsScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows empty state when there are no goals', (tester) async {
    await _pumpGoalsScreen(tester, goals: const []);

    expect(find.byKey(GoalsScreen.screenKey), findsOneWidget);
    expect(find.text('Goals'), findsOneWidget);
    expect(find.text('New goal'), findsOneWidget);
    expect(find.text('No savings goals yet'), findsOneWidget);
    expect(find.text('Add your first goal'), findsOneWidget);
  });

  testWidgets('shows top priority hero and also-saving list tiles',
      (tester) async {
    await _pumpGoalsScreen(
      tester,
      goals: [
        _goal(
          currentAmount: '2040.00',
          targetAmount: '3000.00',
          name: 'Emergency fund',
          emoji: '🛟',
        ),
        _goal(
          id: 'g-2',
          name: 'New laptop',
          emoji: '💻',
          priorityOrder: 1,
          currentAmount: '420.00',
          targetAmount: '1200.00',
        ),
      ],
    );

    expect(find.byType(GoalPriorityHero), findsOneWidget);
    expect(find.text('TOP PRIORITY'), findsOneWidget);
    expect(find.text('Emergency fund ›'), findsOneWidget);
    expect(find.text('Add money to this goal'), findsOneWidget);
    expect(find.text('Also saving for'), findsOneWidget);
    expect(find.text('Change order'), findsOneWidget);
    expect(find.byType(GoalListTile), findsOneWidget);
    expect(find.text('New laptop'), findsOneWidget);
    expect(find.text('\$420 / \$1,200'), findsOneWidget);
    expect(find.text('New goal'), findsOneWidget);
  });

  testWidgets('tapping top priority title opens GoalDetailScreen',
      (tester) async {
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
        child: MaterialApp.router(
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: child!,
            );
          },
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('School Fees ›'));
    await tester.pumpAndSettle();

    expect(find.byKey(GoalDetailScreen.screenKey), findsOneWidget);
    expect(find.text('School Fees'), findsWidgets);
  });
}
