import 'package:flutter/material.dart';
import 'package:mali_app/presentation/theme/app_colors.dart';

enum TransactionType { expense, income, transfer }

extension TransactionTypeX on TransactionType {
  String get value => switch (this) {
        TransactionType.expense => 'expense',
        TransactionType.income => 'income',
        TransactionType.transfer => 'transfer',
      };

  String get label => switch (this) {
        TransactionType.expense => 'Expense',
        TransactionType.income => 'Income',
        TransactionType.transfer => 'Transfer',
      };

  String get saveLabel => switch (this) {
        TransactionType.expense => 'Save expense',
        TransactionType.income => 'Save income',
        TransactionType.transfer => 'Save transfer',
      };

  static TransactionType fromValue(String value) {
    return switch (value) {
      'income' => TransactionType.income,
      'transfer' => TransactionType.transfer,
      _ => TransactionType.expense,
    };
  }
}

/// Pill segmented control matching the Add Expense redesign.
class TransactionTypeToggle extends StatelessWidget {
  const TransactionTypeToggle({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final TransactionType selected;
  final ValueChanged<TransactionType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          for (final type in TransactionType.values)
            Expanded(
              child: _Segment(
                label: type.label,
                selected: selected == type,
                onTap: () => onChanged(type),
              ),
            ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.surfaceContainerLowest : Colors.transparent,
      elevation: selected ? 1.5 : 0,
      shadowColor: AppColors.navy.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: selected
                  ? AppColors.navy
                  : AppColors.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
