import 'package:decimal/decimal.dart';
import 'package:mali_app/domain/entities/savings_goal.dart';
import 'package:mali_app/domain/services/goal_required_monthly.dart';
import 'package:mali_app/presentation/utils/money_display.dart';

/// Copy for how surplus flows into each goal in priority order.
class GoalOrderFundingHint {
  const GoalOrderFundingHint._();

  static String forIndex({
    required int index,
    required SavingsGoal goal,
    required DateTime now,
  }) {
    if (index <= 0) {
      final monthly = _monthlyNeeded(goal: goal, now: now);
      if (monthly == null) {
        return 'Gets the first surplus';
      }
      return 'Gets the first $monthly of surplus';
    }

    if (index == 1) {
      final monthly = _monthlyNeeded(goal: goal, now: now);
      if (monthly == null) {
        return "Gets what's left";
      }
      return "Gets what's left, up to $monthly";
    }

    return 'Gets anything after that';
  }

  static String? _monthlyNeeded({
    required SavingsGoal goal,
    required DateTime now,
  }) {
    final deadline = goal.targetDate;
    if (deadline == null || goal.isCompleted) {
      return null;
    }
    final amount = GoalRequiredMonthly.amount(
      targetAmount: goal.targetAmount,
      savedAmount: goal.currentAmount,
      now: now,
      deadline: deadline,
    );
    if (amount == null || amount <= Decimal.zero) {
      return null;
    }
    return MoneyDisplay.compact(
      amount: amount.toString(),
      currencyCode: goal.currencyCode,
      trimTrailingZeros: true,
    );
  }
}
