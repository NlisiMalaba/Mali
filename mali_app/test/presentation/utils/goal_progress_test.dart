import 'package:flutter_test/flutter_test.dart';
import 'package:mali_app/domain/entities/savings_goal.dart';
import 'package:mali_app/presentation/utils/goal_progress.dart';

SavingsGoal _goal({
  String targetAmount = '200.00',
  String currentAmount = '50.00',
  DateTime? targetDate,
}) {
  return SavingsGoal(
    id: 'g-1',
    userId: 'u-1',
    name: 'Emergency Fund',
    emoji: '🛟',
    targetAmount: targetAmount,
    currentAmount: currentAmount,
    currencyCode: 'USD',
    targetDate: targetDate,
    priorityOrder: 0,
    isCompleted: false,
    isSynced: false,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );
}

void main() {
  group('GoalProgress.ratio', () {
    test('returns saved fraction of target', () {
      expect(GoalProgress.ratio(_goal()), 0.25);
    });

    test('returns 0 when target is zero', () {
      expect(
        GoalProgress.ratio(_goal(targetAmount: '0', currentAmount: '10')),
        0,
      );
    });

    test('returns 0 when amounts are not decimal-safe numbers', () {
      expect(
        GoalProgress.ratio(_goal(targetAmount: 'abc', currentAmount: '10')),
        0,
      );
    });
  });

  group('GoalProgress.monthsRemaining', () {
    final now = DateTime(2026, 9, 19);

    test('counts whole calendar months until the deadline', () {
      expect(
        GoalProgress.monthsRemaining(
          targetDate: DateTime(2026, 12, 19),
          now: now,
        ),
        3,
      );
    });

    test('drops a month when the deadline day has not been reached', () {
      expect(
        GoalProgress.monthsRemaining(
          targetDate: DateTime(2026, 12, 18),
          now: now,
        ),
        2,
      );
    });

    test('returns negative months when the deadline has passed', () {
      expect(
        GoalProgress.monthsRemaining(
          targetDate: DateTime(2026, 6, 19),
          now: now,
        ),
        -3,
      );
    });
  });

  group('GoalProgress.remainingLabel', () {
    final now = DateTime(2026, 9, 19);

    test('returns null when there is no deadline', () {
      expect(
        GoalProgress.remainingLabel(targetDate: null, now: now),
        isNull,
      );
    });

    test('uses singular month wording', () {
      expect(
        GoalProgress.remainingLabel(
          targetDate: DateTime(2026, 10, 19),
          now: now,
        ),
        '1 month to go',
      );
    });

    test('uses plural months wording', () {
      expect(
        GoalProgress.remainingLabel(
          targetDate: DateTime(2026, 12, 19),
          now: now,
        ),
        '3 months to go',
      );
    });

    test('describes a deadline in the current month', () {
      expect(
        GoalProgress.remainingLabel(
          targetDate: DateTime(2026, 9, 30),
          now: now,
        ),
        'Less than a month to go',
      );
    });

    test('marks past deadlines as overdue', () {
      expect(
        GoalProgress.remainingLabel(
          targetDate: DateTime(2026, 8, 19),
          now: now,
        ),
        'Overdue',
      );
    });
  });
}
