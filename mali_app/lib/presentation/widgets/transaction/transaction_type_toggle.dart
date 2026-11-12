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

  /// Expense red, income green, transfer navy — the same colours used for
  /// amounts, so the type can be told apart without reading the label.
  Color get color => switch (this) {
        TransactionType.expense => AppColors.expense,
        TransactionType.income => AppColors.income,
        TransactionType.transfer => AppColors.navy,
      };

  IconData get icon => switch (this) {
        TransactionType.expense => Icons.south_east_rounded,
        TransactionType.income => Icons.north_east_rounded,
        TransactionType.transfer => Icons.swap_horiz_rounded,
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
                icon: type.icon,
                color: type.color,
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
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ink = selected ? Colors.white : color;
    return Semantics(
      selected: selected,
      button: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: selected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(11),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: ink),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
