import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mali_app/application/providers/category_providers.dart';
import 'package:mali_app/domain/entities/budget.dart';
import 'package:mali_app/presentation/theme/app_colors.dart';
import 'package:mali_app/presentation/utils/budget_usage.dart';
import 'package:mali_app/presentation/utils/category_icons.dart';
import 'package:mali_app/presentation/utils/money_display.dart';
import 'package:mali_app/presentation/widgets/budget/budget_bar.dart';

class BudgetListTile extends ConsumerWidget {
  const BudgetListTile({
    required this.budget,
    super.key,
  });

  final Budget budget;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final category = ref.watch(categoryByIdProvider(budget.categoryId));
    final usage = BudgetUsage.ratio(budget);
    final remaining = BudgetUsage.remainingAmount(budget);
    final isOver = BudgetUsage.isOverBudget(budget);

    final categoryColor = category == null
        ? theme.colorScheme.primary
        : CategoryIcons.colorFromHex(category.colorHex);
    final categoryIcon = category == null
        ? Icons.account_balance_wallet_outlined
        : CategoryIcons.fromKey(category.iconKey);
    final categoryName = category?.name ?? 'Budget';

    final remainingLabel = isOver
        ? '${MoneyDisplay.withCurrency(
            amount: remaining.abs().toString(),
            currencyCode: budget.currencyCode,
          )} over'
        : '${MoneyDisplay.withCurrency(
            amount: remaining.toString(),
            currencyCode: budget.currencyCode,
          )} remaining';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: categoryColor.withValues(alpha: 0.15),
              child: Icon(categoryIcon, color: categoryColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    categoryName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  BudgetBar(usage: usage),
                  const SizedBox(height: 10),
                  Text(
                    '${MoneyDisplay.withCurrency(
                      amount: budget.spentAmount,
                      currencyCode: budget.currencyCode,
                    )} spent · '
                    '${MoneyDisplay.withCurrency(
                      amount: budget.amount,
                      currencyCode: budget.currencyCode,
                    )} budget',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    remainingLabel,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isOver ? AppColors.error : AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
