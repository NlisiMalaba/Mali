import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mali_app/application/providers/category_providers.dart';
import 'package:mali_app/domain/entities/budget.dart';
import 'package:mali_app/presentation/theme/app_colors.dart';
import 'package:mali_app/presentation/theme/app_decorations.dart';
import 'package:mali_app/presentation/theme/app_typography.dart';
import 'package:mali_app/presentation/utils/budget_usage.dart';
import 'package:mali_app/presentation/utils/category_icons.dart';
import 'package:mali_app/presentation/utils/money_display.dart';

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
    final percentUsed = (usage * 100).round();

    final status = _BudgetStatus.fromUsage(usage, isOver);
    final categoryIcon = category == null
        ? Icons.account_balance_wallet_outlined
        : CategoryIcons.fromKey(category.iconKey);
    final categoryName = category?.name ?? 'Budget';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppDecorations.surfaceCard(radius: AppDecorations.radiusHero),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: status.iconBackground,
                  borderRadius: BorderRadius.circular(AppDecorations.radiusMd),
                ),
                child: Icon(categoryIcon, color: status.accentColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      categoryName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Monthly envelope',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: MoneyDisplay.withCurrency(
                            amount: budget.spentAmount,
                            currencyCode: budget.currencyCode,
                          ),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextSpan(
                          text:
                              ' / ${MoneyDisplay.withCurrency(
                                amount: budget.amount,
                                currencyCode: budget.currencyCode,
                              )}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    status.label.toUpperCase(),
                    style: AppTypography.sectionLabel(context).copyWith(
                      fontSize: 10,
                      color: status.accentColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: usage.clamp(0, 1),
              minHeight: 12,
              backgroundColor: AppColors.surfaceContainer,
              color: status.progressColor,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$percentUsed% used',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              Text(
                isOver
                    ? '${MoneyDisplay.withCurrency(
                        amount: remaining.abs().toString(),
                        currencyCode: budget.currencyCode,
                      )} over'
                    : '${MoneyDisplay.withCurrency(
                        amount: remaining.toString(),
                        currencyCode: budget.currencyCode,
                      )} left',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: status.accentColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BudgetStatus {
  const _BudgetStatus({
    required this.label,
    required this.accentColor,
    required this.progressColor,
    required this.iconBackground,
  });

  final String label;
  final Color accentColor;
  final Color progressColor;
  final Color iconBackground;

  static _BudgetStatus fromUsage(double usage, bool isOver) {
    if (isOver || usage >= 1) {
      return const _BudgetStatus(
        label: 'Depleted',
        accentColor: AppColors.error,
        progressColor: AppColors.error,
        iconBackground: AppColors.errorContainer,
      );
    }
    if (usage >= 0.8) {
      return _BudgetStatus(
        label: 'Watchful',
        accentColor: AppColors.tertiary,
        progressColor: AppColors.tertiaryFixedDim,
        iconBackground: AppColors.tertiaryFixedDim.withValues(alpha: 0.2),
      );
    }
    if (usage >= 0.5) {
      return _BudgetStatus(
        label: 'Stable',
        accentColor: AppColors.secondary,
        progressColor: AppColors.secondaryContainer,
        iconBackground: AppColors.secondaryFixedDim.withValues(alpha: 0.2),
      );
    }
    return _BudgetStatus(
      label: 'Safe Zone',
      accentColor: AppColors.primary,
      progressColor: AppColors.primaryFixedDim,
      iconBackground: AppColors.primaryFixedDim.withValues(alpha: 0.2),
    );
  }
}
