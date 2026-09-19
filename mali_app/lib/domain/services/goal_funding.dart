import 'package:decimal/decimal.dart';
import 'package:mali_app/domain/entities/savings_goal.dart';

/// Decimal-safe funding progress for savings goals.
class GoalFunding {
  const GoalFunding._();

  static const int minPercent = 0;
  static const int maxPercent = 100;

  static final Decimal _percentMultiplier = Decimal.fromInt(maxPercent);

  /// Scale retained when the saved/target division does not terminate.
  static const int _ratioScale = 8;

  /// Saved amount as a whole percentage of the target, clamped to 0-100 for
  /// display. Returns 0 when the target is missing, zero, or unparseable.
  static int percentFunded(SavingsGoal goal) {
    final target = Decimal.tryParse(goal.targetAmount);
    final current = Decimal.tryParse(goal.currentAmount);
    if (target == null || current == null || target <= Decimal.zero) {
      return minPercent;
    }

    final percent =
        (current / target).toDecimal(scaleOnInfinitePrecision: _ratioScale) *
            _percentMultiplier;

    return percent.round().toBigInt().toInt().clamp(minPercent, maxPercent);
  }
}
