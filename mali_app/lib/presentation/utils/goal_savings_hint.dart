import 'package:mali_app/domain/services/goal_required_monthly.dart';
import 'package:mali_app/presentation/utils/money_display.dart';

class GoalSavingsHint {
  const GoalSavingsHint._();

  static String? saveEachMonth({
    required String targetAmount,
    required String? currencyCode,
    required DateTime? deadline,
    required DateTime now,
    String savedAmount = '0',
  }) {
    if (currencyCode == null || deadline == null) {
      return null;
    }

    final monthly = GoalRequiredMonthly.amount(
      targetAmount: targetAmount,
      savedAmount: savedAmount,
      now: now,
      deadline: deadline,
    );
    if (monthly == null) {
      return null;
    }

    return 'Save ${MoneyDisplay.withCurrency(
      amount: monthly.toString(),
      currencyCode: currencyCode,
    )}/month to hit your goal';
  }
}
