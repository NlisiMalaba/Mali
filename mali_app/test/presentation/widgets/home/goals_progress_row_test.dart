import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mali_app/application/providers/home_providers.dart';
import 'package:mali_app/domain/entities/savings_goal.dart';
import 'package:mali_app/presentation/widgets/home/goals_progress_row.dart';

SavingsGoal _goal({
  required String id,
  required String name,
  required int priorityOrder,
}) {
  return SavingsGoal(
    id: id,
    userId: 'u-1',
    name: name,
    emoji: '🎯',
    targetAmount: '1000',
    currentAmount: '250',
    currencyCode: 'USD',
    targetDate: DateTime(2026, 12, 31),
    priorityOrder: priorityOrder,
    isCompleted: false,
    isSynced: false,
    createdAt: DateTime(2026, 4, 1),
    updatedAt: DateTime(2026, 4, 1),
  );
}

void main() {
  testWidgets('renders home goal rows in priority order', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          homeTopGoalsProvider.overrideWith(
            (ref) => Stream.value([
              _goal(id: 'g-2', name: 'Car', priorityOrder: 0),
              _goal(id: 'g-1', name: 'Emergency Fund', priorityOrder: 1),
            ]),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: GoalsProgressRow())),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester.getTopLeft(find.textContaining('Car')).dy <
          tester.getTopLeft(find.textContaining('Emergency Fund')).dy,
      isTrue,
    );
    expect(find.byKey(const Key('home-goal-g-2')), findsOneWidget);
    expect(find.byKey(const Key('home-goal-g-1')), findsOneWidget);
  });
}
