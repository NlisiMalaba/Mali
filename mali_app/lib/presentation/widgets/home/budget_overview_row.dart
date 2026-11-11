import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mali_app/application/providers/category_providers.dart';
import 'package:mali_app/application/providers/home_providers.dart';
import 'package:mali_app/domain/entities/budget.dart';
import 'package:mali_app/presentation/theme/app_colors.dart';
import 'package:mali_app/presentation/utils/budget_usage.dart';
import 'package:mali_app/presentation/utils/money_display.dart';
import 'package:mali_app/presentation/widgets/budget/budget_bar.dart';

class BudgetOverviewRow extends ConsumerWidget {
  const BudgetOverviewRow({super.key});

  static const int _maxVisible = 2;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetsAsync = ref.watch(homeTopBudgetsProvider);

    return budgetsAsync.when(
      loading: () => const SizedBox(
        height: 48,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (error, _) => Text('Could not load budgets: $error'),
      data: (budgets) {
        if (budgets.isEmpty) {
          return Text(
            'No budgets set for this month.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
          );
        }

        final visible = budgets.take(_maxVisible).toList();
        return Column(
          children: [
            for (var index = 0; index < visible.length; index++) ...[
              if (index > 0) const SizedBox(height: 14),
              _BudgetOverviewTile(budget: visible[index]),
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
    final usage = BudgetUsage.ratio(budget);
    final remaining = BudgetUsage.remainingAmount(budget);
    final categoryName = category?.name ?? 'Budget';
    final isWarning = usage >= budgetWarningUsageRatio;

    final trailing = isWarning
        ? Text(
            '${(usage * 100).round()}% · '
            '${MoneyDisplay.compact(
              amount: remaining.abs().toString(),
              currencyCode: budget.currencyCode,
              trimTrailingZeros: true,
            )} left',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.moneyOut,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          )
        : Text(
            '${MoneyDisplay.compact(
              amount: budget.spentAmount,
              currencyCode: budget.currencyCode,
              trimTrailingZeros: true,
            )} of '
            '${MoneyDisplay.compact(
              amount: budget.amount,
              currencyCode: budget.currencyCode,
              trimTrailingZeros: true,
            )}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
              fontSize: 14,
            ),
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                categoryName,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            trailing,
          ],
        ),
        const SizedBox(height: 8),
        BudgetBar(usage: usage),
      ],
    );
  }
}
