import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mali_app/application/providers/category_providers.dart';
import 'package:mali_app/application/providers/wallet_providers.dart';
import 'package:mali_app/domain/entities/transaction.dart';
import 'package:mali_app/presentation/theme/app_colors.dart';
import 'package:mali_app/presentation/theme/app_decorations.dart';
import 'package:mali_app/presentation/utils/category_icons.dart';
import 'package:mali_app/presentation/utils/money_display.dart';

class TransactionTile extends ConsumerWidget {
  const TransactionTile({
    required this.transaction,
    this.compact = false,
    super.key,
  });

  final Transaction transaction;
  final bool compact;

  Color _amountColor(String type) {
    return switch (type) {
      'income' => AppColors.success,
      'expense' => AppColors.onSurface,
      _ => AppColors.onSurface,
    };
  }

  String _amountPrefix(String type) {
    return switch (type) {
      'income' => '+',
      'expense' => '-',
      _ => '',
    };
  }

  Color _avatarColor(Color categoryColor) {
    return categoryColor.withValues(alpha: 0.18);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final category = transaction.categoryId == null
        ? null
        : ref.watch(categoryByIdProvider(transaction.categoryId!));
    final walletAsync = ref.watch(walletByIdProvider(transaction.walletId));
    final wallet = walletAsync.value;

    final categoryColor = category == null
        ? AppColors.onSurfaceVariant
        : CategoryIcons.colorFromHex(category.colorHex);
    final initial = transaction.title.trim().isEmpty
        ? '?'
        : transaction.title.trim().characters.first.toUpperCase();

    final subtitleParts = <String>[];
    if (transaction.type == 'transfer') {
      if (transaction.exchangeRate != null &&
          transaction.exchangeRate!.trim().isNotEmpty) {
        subtitleParts.add('rate ${transaction.exchangeRate}');
      } else {
        subtitleParts.add('Transfer');
      }
    } else if (category != null) {
      subtitleParts.add(category.name);
    }
    if (wallet != null) {
      subtitleParts.add('${wallet.name} ${wallet.currencyCode}');
    }
    final subtitle = subtitleParts.join(' · ');

    return ListTile(
      key: Key('transaction-tile-${transaction.id}'),
      contentPadding: EdgeInsets.symmetric(
        horizontal: compact ? 14 : 16,
        vertical: 2,
      ),
      leading: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _avatarColor(categoryColor),
          borderRadius: BorderRadius.circular(AppDecorations.radiusSm),
        ),
        child: Text(
          initial,
          style: theme.textTheme.titleSmall?.copyWith(
            color: categoryColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      title: Text(
        transaction.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.onSurface,
        ),
      ),
      subtitle: subtitle.isEmpty
          ? null
          : Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
      trailing: Text(
        MoneyDisplay.compactSigned(
          amount: transaction.amount,
          currencyCode: transaction.currencyCode,
          prefix: _amountPrefix(transaction.type),
        ),
        style: theme.textTheme.titleSmall?.copyWith(
          color: _amountColor(transaction.type),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
