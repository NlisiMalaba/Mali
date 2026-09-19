import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mali_app/domain/entities/savings_goal.dart';
import 'package:mali_app/domain/services/goal_required_monthly.dart';

void main() {
  group('GoalRequiredMonthly.savingsMonths', () {
    test('counts month span and rounds up a partial month', () {
      expect(
        GoalRequiredMonthly.savingsMonths(
          fromDate: DateTime(2026, 4, 10),
          toDate: DateTime(2026, 6, 30),
        ),
        3,
      );
    });

    test('does not add a month when the day of month is not later', () {
      expect(
        GoalRequiredMonthly.savingsMonths(
          fromDate: DateTime(2026, 4, 10),
          toDate: DateTime(2026, 6, 10),
        ),
        2,
      );
    });

    test('returns at least one month', () {
      expect(
        GoalRequiredMonthly.savingsMonths(
          fromDate: DateTime(2026, 4, 10),
          toDate: DateTime(2026, 4, 20),
        ),
        1,
      );
    });
  });

  group('GoalRequiredMonthly.amount', () {
    test('divides remaining target across savings months', () {
      expect(
        GoalRequiredMonthly.amount(
          targetAmount: '1000',
          savedAmount: '100',
          now: DateTime(2026, 4, 10),
          deadline: DateTime(2026, 6, 30),
        ),
        Decimal.parse('300'),
      );
    });

    test('returns null when the deadline is not in the future', () {
      expect(
        GoalRequiredMonthly.amount(
          targetAmount: '1000',
          now: DateTime(2026, 4, 10),
          deadline: DateTime(2026, 4, 10),
        ),
        isNull,
      );
    });

    test('returns null for a non-positive target', () {
      expect(
        GoalRequiredMonthly.amount(
          targetAmount: '0',
          now: DateTime(2026, 4, 10),
          deadline: DateTime(2026, 6, 30),
        ),
        isNull,
      );
    });
  });

  group('GoalRequiredMonthly.forGoal', () {
    SavingsGoal goal({
      String currentAmount = '0',
      bool isCompleted = false,
    }) {
      return SavingsGoal(
        id: 'g-1',
        userId: 'u-1',
        name: 'Emergency Fund',
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

    test('raises the monthly amount when savings are behind schedule', () {
      final required = GoalRequiredMonthly.forGoal(
        goal: goal(),
        now: DateTime(2026, 5, 10),
      );

      expect(required, isNotNull);
      expect(required!.isBehindSchedule, isTrue);
      expect(required.originalAmount, Decimal.parse('300'));
      expect(required.amount, Decimal.parse('450'));
    });

    test('keeps the original amount when savings are on track', () {
      final required = GoalRequiredMonthly.forGoal(
        goal: goal(currentAmount: '300'),
        now: DateTime(2026, 5, 10),
      );

      expect(required, isNotNull);
      expect(required!.isBehindSchedule, isFalse);
      expect(required.amount, Decimal.parse('300'));
    });

    test('returns null when the goal is already completed', () {
      expect(
        GoalRequiredMonthly.forGoal(
          goal: goal(currentAmount: '900', isCompleted: true),
          now: DateTime(2026, 5, 10),
        ),
        isNull,
      );
    });
  });
}
