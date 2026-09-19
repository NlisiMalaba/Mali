import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mali_app/application/providers/category_providers.dart';
import 'package:mali_app/domain/usecases/get_analytics_overview_usecase.dart';
import 'package:mali_app/presentation/theme/app_colors.dart';
import 'package:mali_app/presentation/utils/category_icons.dart';
import 'package:mali_app/presentation/utils/money_display.dart';
import 'package:mali_app/presentation/utils/share_fraction.dart';

class TopSpendingCategoriesList extends StatelessWidget {
  const TopSpendingCategoriesList({
    required this.categories,
    super.key,
  });

  static const Key listKey = Key('top-spending-categories');
  static const double barHeight = 8;

  static Key rowKey(String categoryId) =>
      Key('top-spending-category-$categoryId');

  final List<RankedCategorySpend> categories;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (categories.isEmpty) {
      return Text(
        'No spending this month.',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
        ),
      );
    }

    final maxAmount = categories.first.amount;

    return Card(
      key: listKey,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Column(
          children: [
            for (var index = 0; index < categories.length; index++) ...[
              if (index > 0) const Divider(height: 1),
              _CategorySpendRow(
                spend: categories[index],
                rank: index + 1,
                maxAmount: maxAmount,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CategorySpendRow extends ConsumerWidget {
  const _CategorySpendRow({
    required this.spend,
    required this.rank,
    required this.maxAmount,
  });

  final RankedCategorySpend spend;
  final int rank;
  final Decimal maxAmount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final category = ref.watch(categoryByIdProvider(spend.categoryId));
    final name = category?.name ?? 'Other';
    final color = category == null
        ? AppColors.tealPrimary
        : CategoryIcons.colorFromHex(category.colorHex);
    final icon = category == null
        ? Icons.category_outlined
        : CategoryIcons.fromKey(category.iconKey);
    final fraction = ShareFraction.of(amount: spend.amount, total: maxAmount);

    return Padding(
      key: TopSpendingCategoriesList.rowKey(spend.categoryId),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.15),
            child: Icon(icon, color: color, size: 20),
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
                        '$rank. $name',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      MoneyDisplay.withCurrency(
                        amount: spend.amount.toString(),
                        currencyCode: spend.displayCurrency.value,
                      ),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(
                    TopSpendingCategoriesList.barHeight / 2,
                  ),
                  child: LinearProgressIndicator(
                    value: fraction,
                    minHeight: TopSpendingCategoriesList.barHeight,
                    backgroundColor: color.withValues(alpha: 0.15),
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
