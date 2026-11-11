import 'package:flutter/material.dart';
import 'package:mali_app/presentation/theme/app_colors.dart';

/// Shared finance coloring for signed transaction amounts.
///
/// Expense → red, income → green, transfer → neutral black.
abstract final class TransactionAmountStyle {
  static Color colorFor(String type) {
    return switch (type) {
      'income' => AppColors.income,
      'expense' => AppColors.expense,
      _ => AppColors.transferAmount,
    };
  }

  /// True minus (U+2212) for expenses; empty for transfers.
  static String prefixFor(String type) {
    return switch (type) {
      'income' => '+',
      'expense' => '\u2212',
      _ => '',
    };
  }
}
