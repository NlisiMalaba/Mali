import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mali_app/application/providers/category_providers.dart';
import 'package:mali_app/domain/entities/transaction.dart';
import 'package:mali_app/presentation/theme/app_colors.dart';
import 'package:mali_app/presentation/utils/category_icons.dart';
import 'package:mali_app/presentation/utils/money_display.dart';

class TransactionTile extends ConsumerWidget {
  const TransactionTile({
    required this.transaction,
    super.key,
  });

  final Transaction transaction;

  Color _amountColor(String type) {
    return switch (type) {
      'income' => AppColors.success,
      'expense' => AppColors.error,
      _ => AppColors.tealPrimary,
    };
  }

  String _amountPrefix(String type) {
    return switch (type) {
      'income' => '+',
      'expense' => '-',
      _ => '',
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final timeFormat = DateFormat.jm();
    final category = transaction.categoryId == null
        ? null
        : ref.watch(categoryByIdProvider(transaction.categoryId!));

    final categoryColor = category == null
        ? theme.colorScheme.primary
        : CategoryIcons.colorFromHex(category.colorHex);
    final categoryIcon = category == null
        ? Icons.swap_horiz
        : CategoryIcons.fromKey(category.iconKey);

    final notes = transaction.notes?.trim();
    final secondaryLine = (notes != null && notes.isNotEmpty) ? notes : null;

    return ListTile(
      key: Key('transaction-tile-${transaction.id}'),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: CircleAvatar(
        backgroundColor: categoryColor.withValues(alpha: 0.15),
        child: Icon(
          categoryIcon,
          color: categoryColor,
          size: 22,
        ),
      ),
      title: Text(
        transaction.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: secondaryLine == null
          ? null
          : Text(
              secondaryLine,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${_amountPrefix(transaction.type)}'
            '${MoneyDisplay.formatAmount(transaction.amount)}',
            style: theme.textTheme.titleSmall?.copyWith(
              color: _amountColor(transaction.type),
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            transaction.currencyCode,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
            ),
          ),
          Text(
            timeFormat.format(transaction.transactionDate),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
            ),
          ),
        ],
      ),
    );
  }
}
