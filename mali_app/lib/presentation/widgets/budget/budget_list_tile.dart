import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mali_app/application/providers/category_providers.dart';
import 'package:mali_app/domain/entities/budget.dart';
import 'package:mali_app/presentation/theme/app_colors.dart';
import 'package:mali_app/presentation/utils/budget_status.dart';
import 'package:mali_app/presentation/utils/budget_usage.dart';
import 'package:mali_app/presentation/utils/category_icons.dart';
import 'package:mali_app/presentation/utils/money_display.dart';
import 'package:mali_app/presentation/widgets/common/animated_progress_bar.dart';
import 'package:mali_app/presentation/widgets/common/pressable_scale.dart';

class BudgetListTile extends ConsumerWidget {
  const BudgetListTile({
    required this.budget,
    this.onTap,
    super.key,
  });

  final Budget budget;
  final VoidCallback? onTap;

  static Key tileKey(String budgetId) => Key('budget-tile-$budgetId');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final category = ref.watch(categoryByIdProvider(budget.categoryId));
    final usage = BudgetUsage.ratio(budget);
    final percentUsed = (usage * 100).round();
    final status = BudgetStatus.fromBudget(budget);
    final categoryName = category?.name ?? 'Budget';
    final initial = categoryName.isNotEmpty
        ? categoryName.characters.first.toUpperCase()
        : '?';
    final categoryColor = category == null
        ? status.accentColor
        : CategoryIcons.colorFromHex(category.colorHex);
    final avatarInk = status.kind == BudgetStatusKind.onTrack
        ? categoryColor
        : status.accentColor;
    final avatarBg = status.kind == BudgetStatusKind.onTrack
        ? categoryColor.withValues(alpha: 0.16)
        : status.iconBackground;
    final spent = MoneyDisplay.compact(
      amount: budget.spentAmount,
      currencyCode: budget.currencyCode,
      trimTrailingZeros: true,
    );
    final limit = MoneyDisplay.compact(
      amount: budget.amount,
      currencyCode: budget.currencyCode,
      trimTrailingZeros: true,
    );

    return PressableScale(
      key: tileKey(budget.id),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: avatarBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                initial,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: avatarInk,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          categoryName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: status.chipBackground,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          status.chipLabel,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: status.accentColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  AnimatedProgressBar(
                    value: usage.clamp(0.0, 1.0),
                    color: status.progressColor,
                    backgroundColor: AppColors.surfaceContainer,
                    height: 7,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$spent of $limit · $percentUsed%',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 12.5,
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
