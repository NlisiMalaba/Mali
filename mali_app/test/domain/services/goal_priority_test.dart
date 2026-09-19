import 'package:flutter_test/flutter_test.dart';
import 'package:mali_app/domain/entities/savings_goal.dart';
import 'package:mali_app/domain/services/goal_priority.dart';

SavingsGoal _goal({
  required String id,
  required String name,
  required int priorityOrder,
}) {
  return SavingsGoal(
    id: id,
    userId: 'u-1',
    name: name,
    targetAmount: '100',
    currentAmount: '10',
    currencyCode: 'USD',
    priorityOrder: priorityOrder,
    isCompleted: false,
    isSynced: false,
    createdAt: DateTime(2026, 4, 1),
    updatedAt: DateTime(2026, 4, 1),
  );
}

void main() {
  test('sorts goals by priorityOrder', () {
    final goals = [
      _goal(id: 'g-2', name: 'Car', priorityOrder: 2),
      _goal(id: 'g-0', name: 'Emergency', priorityOrder: 0),
      _goal(id: 'g-1', name: 'School', priorityOrder: 1),
    ];

    expect(
      GoalPriority.sorted(goals).map((goal) => goal.id),
      ['g-0', 'g-1', 'g-2'],
    );
  });

  test('home rows take the lowest priorityOrder first', () {
    final goals = [
      _goal(id: 'g-2', name: 'Car', priorityOrder: 2),
      _goal(id: 'g-0', name: 'Emergency', priorityOrder: 0),
      _goal(id: 'g-1', name: 'School', priorityOrder: 1),
    ];

    final top = GoalPriority.top(goals: goals, limit: 2);

    expect(top.map((goal) => goal.name), ['Emergency', 'School']);
  });
}
