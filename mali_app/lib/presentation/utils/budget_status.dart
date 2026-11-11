import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:mali_app/domain/entities/budget.dart';
import 'package:mali_app/presentation/theme/app_colors.dart';
import 'package:mali_app/presentation/utils/budget_usage.dart';
import 'package:mali_app/presentation/utils/money_display.dart';

/// Presentation status for a budget envelope (on track / close / over).
class BudgetStatus {
  const BudgetStatus({
    required this.kind,
    required this.chipLabel,
    required this.accentColor,
    required this.progressColor,
    required this.chipBackground,
    required this.iconBackground,
  });

  final BudgetStatusKind kind;
  final String chipLabel;
  final Color accentColor;
  final Color progressColor;
  final Color chipBackground;
  final Color iconBackground;

  static BudgetStatus fromBudget(Budget budget) {
    final usage = BudgetUsage.ratio(budget);
    final remaining = BudgetUsage.remainingAmount(budget);
    final isOver = remaining < Decimal.zero;

    if (isOver || usage > 1) {
      final overLabel = MoneyDisplay.compact(
        amount: remaining.abs().toString(),
        currencyCode: budget.currencyCode,
        trimTrailingZeros: true,
      );
      return BudgetStatus(
        kind: BudgetStatusKind.over,
        chipLabel: 'Over by $overLabel',
        accentColor: AppColors.error,
        progressColor: AppColors.error,
        chipBackground: AppColors.errorContainer,
        iconBackground: AppColors.surfaceContainer,
      );
    }

    if (usage >= budgetWarningUsageRatio) {
      return const BudgetStatus(
        kind: BudgetStatusKind.close,
        chipLabel: 'Close to limit',
        accentColor: AppColors.warningText,
        progressColor: Color(0xFFC96F00),
        chipBackground: AppColors.warningContainer,
        iconBackground: AppColors.warningContainer,
      );
    }

    return const BudgetStatus(
      kind: BudgetStatusKind.onTrack,
      chipLabel: 'On track',
      accentColor: AppColors.success,
      progressColor: AppColors.success,
      chipBackground: AppColors.successContainer,
      iconBackground: AppColors.successContainer,
    );
  }

  /// Sort key: over first, then close to limit, then on track.
  int get sortRank => switch (kind) {
        BudgetStatusKind.over => 0,
        BudgetStatusKind.close => 1,
        BudgetStatusKind.onTrack => 2,
      };
}

enum BudgetStatusKind { over, close, onTrack }
