import 'package:decimal/decimal.dart';
import 'package:mali_app/domain/entities/savings_goal.dart';

class RequiredThisMonth {
  const RequiredThisMonth({
    required this.amount,
    required this.originalAmount,
    required this.isBehindSchedule,
  });

  /// Catch-up (or remaining) amount to save this month.
  final Decimal amount;

  /// Originally planned monthly amount from when the goal was created.
  final Decimal originalAmount;

  final bool isBehindSchedule;
}

class GoalRequiredMonthly {
  const GoalRequiredMonthly._();

  static const int minSavingsMonths = 1;

  /// Calendar months used to spread remaining savings, matching the API.
  static int savingsMonths({
    required DateTime fromDate,
    required DateTime toDate,
  }) {
    final from = DateTime(fromDate.year, fromDate.month, fromDate.day);
    final to = DateTime(toDate.year, toDate.month, toDate.day);
    var months = (to.year - from.year) * 12 + (to.month - from.month);
    if (to.day > from.day) {
      months += 1;
    }
    if (months < minSavingsMonths) {
      return minSavingsMonths;
    }
    return months;
  }

  /// Remaining target divided across [savingsMonths]. Null when inputs are incomplete.
  static Decimal? amount({
    required String targetAmount,
    String savedAmount = '0',
    required DateTime now,
    required DateTime deadline,
  }) {
    try {
      final target = Decimal.parse(targetAmount.trim());
      if (target <= Decimal.zero) {
        return null;
      }

      final today = DateTime(now.year, now.month, now.day);
      final due = DateTime(deadline.year, deadline.month, deadline.day);
      if (!due.isAfter(today)) {
        return null;
      }

      var saved = Decimal.zero;
      final trimmedSaved = savedAmount.trim();
      if (trimmedSaved.isNotEmpty) {
        saved = Decimal.parse(trimmedSaved);
      }

      var remaining = target - saved;
      if (remaining < Decimal.zero) {
        remaining = Decimal.zero;
      }

      final months = Decimal.fromInt(
        savingsMonths(fromDate: now, toDate: deadline),
      );
      return (remaining / months).toDecimal(scaleOnInfinitePrecision: 8);
    } catch (_) {
      return null;
    }
  }

  static const int _compareScale = 2;

  /// Required savings this month, raised when the goal is behind the original plan.
  static RequiredThisMonth? forGoal({
    required SavingsGoal goal,
    required DateTime now,
  }) {
    final deadline = goal.targetDate;
    if (deadline == null || goal.isCompleted) {
      return null;
    }

    final current = amount(
      targetAmount: goal.targetAmount,
      savedAmount: goal.currentAmount,
      now: now,
      deadline: deadline,
    );
    if (current == null) {
      return null;
    }

    final original = amount(
          targetAmount: goal.targetAmount,
          savedAmount: '0',
          now: goal.createdAt,
          deadline: deadline,
        ) ??
        current;

    return RequiredThisMonth(
      amount: current,
      originalAmount: original,
      isBehindSchedule: current.round(scale: _compareScale) >
          original.round(scale: _compareScale),
    );
  }
}
