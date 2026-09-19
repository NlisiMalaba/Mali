import 'package:flutter_test/flutter_test.dart';
import 'package:mali_app/domain/entities/savings_goal.dart';
import 'package:mali_app/domain/services/goal_funding.dart';

SavingsGoal _goal({
  required String targetAmount,
  required String currentAmount,
}) {
  final timestamp = DateTime(2026, 9, 1);
  return SavingsGoal(
    id: 'g-1',
    userId: 'u-1',
    name: 'Emergency Fund',
    targetAmount: targetAmount,
    currentAmount: currentAmount,
    currencyCode: 'USD',
    priorityOrder: 1,
    isCompleted: false,
    isSynced: false,
    createdAt: timestamp,
    updatedAt: timestamp,
  );
}

void main() {
  group('GoalFunding.percentFunded', () {
    test('returns a whole percentage of the target', () {
      expect(
        GoalFunding.percentFunded(
          _goal(targetAmount: '1000', currentAmount: '250'),
        ),
        25,
      );
    });

    test('rounds recurring ratios to the nearest percent', () {
      expect(
        GoalFunding.percentFunded(
          _goal(targetAmount: '3', currentAmount: '1'),
        ),
        33,
      );
    });

    test('clamps overfunded goals to 100', () {
      expect(
        GoalFunding.percentFunded(
          _goal(targetAmount: '100', currentAmount: '250'),
        ),
        GoalFunding.maxPercent,
      );
    });

    test('returns zero for a non-positive target', () {
      expect(
        GoalFunding.percentFunded(
          _goal(targetAmount: '0', currentAmount: '50'),
        ),
        GoalFunding.minPercent,
      );
    });

    test('returns zero for unparseable amounts rather than throwing', () {
      expect(
        GoalFunding.percentFunded(
          _goal(targetAmount: 'not-a-number', currentAmount: '50'),
        ),
        GoalFunding.minPercent,
      );
    });
  });
}
