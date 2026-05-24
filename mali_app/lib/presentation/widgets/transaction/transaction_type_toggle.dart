import 'package:flutter/material.dart';
import 'package:mali_app/presentation/theme/app_colors.dart';

enum TransactionType { expense, income, transfer }

extension TransactionTypeX on TransactionType {
  String get value => switch (this) {
        TransactionType.expense => 'expense',
        TransactionType.income => 'income',
        TransactionType.transfer => 'transfer',
      };

  static TransactionType fromValue(String value) {
    return switch (value) {
      'income' => TransactionType.income,
      'transfer' => TransactionType.transfer,
      _ => TransactionType.expense,
    };
  }
}

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
    final theme = Theme.of(context);

    return SegmentedButton<TransactionType>(
      segments: const [
        ButtonSegment(
          value: TransactionType.expense,
          label: Text('Expense'),
          icon: Icon(Icons.remove_circle_outline, size: 18),
        ),
        ButtonSegment(
          value: TransactionType.income,
          label: Text('Income'),
          icon: Icon(Icons.add_circle_outline, size: 18),
        ),
        ButtonSegment(
          value: TransactionType.transfer,
          label: Text('Transfer'),
          icon: Icon(Icons.swap_horiz, size: 18),
        ),
      ],
      selected: {selected},
      onSelectionChanged: (selection) {
        if (selection.isNotEmpty) {
          onChanged(selection.first);
        }
      },
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return theme.colorScheme.onPrimary;
          }
          return theme.colorScheme.onSurface;
        }),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return switch (selected) {
              TransactionType.income => AppColors.success,
              TransactionType.expense => AppColors.error,
              TransactionType.transfer => AppColors.tealPrimary,
            };
          }
          return theme.colorScheme.surfaceContainerHighest;
        }),
      ),
    );
  }
}
