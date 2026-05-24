import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mali_app/application/providers/category_providers.dart';
import 'package:mali_app/application/providers/home_providers.dart';
import 'package:mali_app/domain/entities/budget.dart';
import 'package:mali_app/presentation/theme/app_colors.dart';
import 'package:mali_app/presentation/utils/category_icons.dart';
import 'package:mali_app/presentation/utils/money_display.dart';

class BudgetOverviewRow extends ConsumerWidget {
  const BudgetOverviewRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetsAsync = ref.watch(homeTopBudgetsProvider);

    return budgetsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Text('Could not load budgets: $error'),
      data: (budgets) {
        if (budgets.isEmpty) {
          return const _EmptySectionMessage(
            message: 'No budgets set for this month.',
          );
        }

        return Column(
          children: [
            for (var index = 0; index < budgets.length; index++) ...[
              if (index > 0) const SizedBox(height: 12),
              _BudgetOverviewTile(budget: budgets[index]),
            ],
          ],
        );
      },
    );
  }
}

class _BudgetOverviewTile extends ConsumerWidget {
  const _BudgetOverviewTile({required this.budget});

  final Budget budget;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final category = ref.watch(categoryByIdProvider(budget.categoryId));
    final usage = _budgetUsage(budget);
    final progressColor = _progressColor(usage);

    final categoryColor = category == null
        ? theme.colorScheme.primary
        : CategoryIcons.colorFromHex(category.colorHex);
    final categoryIcon = category == null
        ? Icons.account_balance_wallet_outlined
        : CategoryIcons.fromKey(category.iconKey);
    final categoryName = category?.name ?? 'Budget';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: categoryColor.withValues(alpha: 0.15),
              child: Icon(categoryIcon, color: categoryColor, size: 20),
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
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: usage.toDouble().clamp(0, 1),
                      minHeight: 8,
                      backgroundColor: progressColor.withValues(alpha: 0.15),
                      color: progressColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${MoneyDisplay.withCurrency(
                      amount: budget.spentAmount,
                      currencyCode: budget.currencyCode,
                    )} of '
                    '${MoneyDisplay.withCurrency(
                      amount: budget.amount,
                      currencyCode: budget.currencyCode,
                    )}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
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

  double _budgetUsage(Budget budget) {
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

  Color _progressColor(double usage) {
    if (usage >= 1) {
      return AppColors.error;
    }
    if (usage >= 0.8) {
      return AppColors.warning;
    }
    return AppColors.success;
  }
}

class _EmptySectionMessage extends StatelessWidget {
  const _EmptySectionMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      message,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
      ),
    );
  }
}
