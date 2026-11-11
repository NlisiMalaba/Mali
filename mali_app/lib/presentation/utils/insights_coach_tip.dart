import 'package:decimal/decimal.dart';
import 'package:mali_app/domain/entities/budget.dart';
import 'package:mali_app/presentation/utils/budget_usage.dart';
import 'package:mali_app/presentation/utils/money_display.dart';

/// Presentation helper that turns monthly budgets into an Insights coach tip.
class InsightsCoachTip {
  const InsightsCoachTip({
    required this.stressedCategoryId,
    required this.stressedCategoryName,
    required this.stressedPercent,
    required this.daysRemaining,
    this.spareCategoryId,
    this.spareCategoryName,
    this.spareRemaining,
    this.suggestedMove,
  });

  final String stressedCategoryId;
  final String stressedCategoryName;
  final int stressedPercent;
  final int daysRemaining;
  final String? spareCategoryId;
  final String? spareCategoryName;
  final Decimal? spareRemaining;
  final Decimal? suggestedMove;

  static final Decimal _defaultMoveCap = Decimal.parse('20');
  static const double _stressedUsageFloor = 0.8;

  /// Builds a tip when one budget is under pressure and another has spare room.
  static InsightsCoachTip? fromBudgets({
    required List<Budget> budgets,
    required DateTime now,
    required String Function(String categoryId) categoryName,
  }) {
    if (budgets.isEmpty) {
      return null;
    }

    Budget? stressed;
    var stressedUsage = 0.0;
    Budget? spare;
    var spareRemaining = Decimal.zero;

    for (final budget in budgets) {
      final usage = BudgetUsage.ratio(budget);
      final remaining = BudgetUsage.remainingAmount(budget);

      if (usage >= stressedUsage) {
        stressed = budget;
        stressedUsage = usage;
      }
      if (remaining > spareRemaining && usage < _stressedUsageFloor) {
        spare = budget;
        spareRemaining = remaining;
      }
    }

    if (stressed == null || stressedUsage < _stressedUsageFloor) {
      return null;
    }

    // Don't suggest moving money from a budget into itself.
    if (spare != null && spare.categoryId == stressed.categoryId) {
      spare = null;
      spareRemaining = Decimal.zero;
    }

    Decimal? suggested;
    if (spare != null && spareRemaining > Decimal.zero) {
      suggested = spareRemaining < _defaultMoveCap
          ? spareRemaining.round(scale: 0)
          : _defaultMoveCap;
      if (suggested <= Decimal.zero) {
        suggested = null;
      }
    }

    final lastDay = DateTime(now.year, now.month + 1, 0).day;
    final daysRemaining = (lastDay - now.day + 1).clamp(0, lastDay);

    return InsightsCoachTip(
      stressedCategoryId: stressed.categoryId,
      stressedCategoryName: categoryName(stressed.categoryId),
      stressedPercent: (stressedUsage.clamp(0.0, 1.0) * 100).round(),
      daysRemaining: daysRemaining,
      spareCategoryId: spare?.categoryId,
      spareCategoryName:
          spare == null ? null : categoryName(spare.categoryId),
      spareRemaining: spare == null ? null : spareRemaining,
      suggestedMove: suggested,
    );
  }

  String message({required String currencyCode}) {
    final buffer = StringBuffer(
      '$stressedCategoryName is at $stressedPercent% with $daysRemaining '
      'days to go.',
    );
    if (spareCategoryName != null && spareRemaining != null) {
      final spareLabel = MoneyDisplay.compact(
        amount: spareRemaining!.toString(),
        currencyCode: currencyCode,
        trimTrailingZeros: true,
      );
      buffer.write(' $spareCategoryName has $spareLabel spare.');
    }
    return buffer.toString();
  }

  String? ctaLabel({required String currencyCode}) {
    final move = suggestedMove;
    if (move == null) {
      return null;
    }
    final amount = MoneyDisplay.compact(
      amount: move.toString(),
      currencyCode: currencyCode,
      trimTrailingZeros: true,
    );
    return 'Move $amount to $stressedCategoryName';
  }
}
