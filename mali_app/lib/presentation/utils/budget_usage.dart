import 'package:decimal/decimal.dart';
import 'package:mali_app/domain/entities/budget.dart';
import 'package:mali_app/presentation/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Display thresholds for budget progress coloring.
const double budgetWarningUsageRatio = 0.8;

class BudgetUsage {
  const BudgetUsage._();

  static double ratio(Budget budget) {
    try {
      final budgetAmount = Decimal.parse(budget.amount);
      if (budgetAmount <= Decimal.zero) {
        return 0;
      }
      final spentAmount = Decimal.parse(budget.spentAmount);
      return (spentAmount / budgetAmount).toDouble();
    } catch (_) {
      return 0;
    }
  }

  static Color progressColor(double usage) {
    if (usage >= 1) {
      return AppColors.error;
    }
    if (usage >= budgetWarningUsageRatio) {
      return AppColors.warning;
    }
    return AppColors.success;
  }

  static Decimal remainingAmount(Budget budget) {
    try {
      final budgetAmount = Decimal.parse(budget.amount);
      final spentAmount = Decimal.parse(budget.spentAmount);
      return budgetAmount - spentAmount;
    } catch (_) {
      return Decimal.zero;
    }
  }

  static bool isOverBudget(Budget budget) => remainingAmount(budget) < Decimal.zero;
}
