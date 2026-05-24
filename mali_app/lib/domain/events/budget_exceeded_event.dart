import 'package:decimal/decimal.dart';
import 'package:mali_app/domain/entities/budget.dart';

/// Fired when spending crosses a budget warning (80%) or exceeded (100%) threshold.
class BudgetExceededEvent {
  const BudgetExceededEvent({
    required this.budget,
    required this.thresholdRatio,
  });

  static final Decimal warningThresholdRatio = Decimal.parse('0.8');
  static final Decimal exceededThresholdRatio = Decimal.one;

  final Budget budget;
  final Decimal thresholdRatio;

  bool get isExceeded => thresholdRatio >= exceededThresholdRatio;

  bool get isWarning =>
      thresholdRatio >= warningThresholdRatio &&
      thresholdRatio < exceededThresholdRatio;
}
