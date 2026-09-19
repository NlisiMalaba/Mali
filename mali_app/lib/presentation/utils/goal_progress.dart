import 'package:decimal/decimal.dart';
import 'package:mali_app/domain/entities/savings_goal.dart';

class GoalProgress {
  const GoalProgress._();

  static const List<double> milestoneFractions = [0.25, 0.50, 0.75];

  /// Saved amount as a fraction of the target. Display-only; may exceed 1.
  static double ratio(SavingsGoal goal) {
    try {
      final target = Decimal.parse(goal.targetAmount);
      if (target <= Decimal.zero) {
        return 0;
      }
      final current = Decimal.parse(goal.currentAmount);
      return (current / target).toDouble();
    } catch (_) {
      return 0;
    }
  }

  /// Whole months from [now] until [targetDate], using calendar dates.
  /// Negative when the deadline has already passed by a full month or more.
  static int monthsRemaining({
    required DateTime targetDate,
    required DateTime now,
  }) {
    final target = DateTime(targetDate.year, targetDate.month, targetDate.day);
    final today = DateTime(now.year, now.month, now.day);
    var months = (target.year - today.year) * 12 + (target.month - today.month);
    if (target.day < today.day) {
      months -= 1;
    }
    return months;
  }

  /// Human-readable countdown, or null when the goal has no deadline.
  static String? remainingLabel({
    required DateTime? targetDate,
    required DateTime now,
  }) {
    if (targetDate == null) {
      return null;
    }

    final months = monthsRemaining(targetDate: targetDate, now: now);
    if (months < 0) {
      return 'Overdue';
    }
    if (months == 0) {
      return 'Less than a month to go';
    }
    if (months == 1) {
      return '1 month to go';
    }
    return '$months months to go';
  }
}
