import 'dart:math' as math;

import 'package:decimal/decimal.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mali_app/application/providers/category_providers.dart';
import 'package:mali_app/domain/usecases/get_analytics_overview_usecase.dart';
import 'package:mali_app/presentation/theme/app_colors.dart';
import 'package:mali_app/presentation/theme/app_typography.dart';
import 'package:mali_app/presentation/utils/category_icons.dart';
import 'package:mali_app/presentation/utils/money_display.dart';

class CategorySpendPieChart extends ConsumerWidget {
  const CategorySpendPieChart({
    required this.categories,
    required this.onCategorySelected,
    this.highlightedCategoryId,
    this.maxLegendItems = 5,
    super.key,
  });

  static const Key chartKey = Key('spending-pie-chart');
  static const Key legendKey = Key('spending-legend');
  static const double chartSize = 156;
  static const double sectionRadius = 22;
  static const double centerSpaceRadius = 48;
  static const double sectionsSpace = 0;
  static const Duration animationDuration = Duration.zero;

  static Key legendRowKey(String categoryId) =>
      Key('spending-legend-$categoryId');

  final List<RankedCategorySpend> categories;
  final ValueChanged<RankedCategorySpend> onCategorySelected;
  final String? highlightedCategoryId;
  final int maxLegendItems;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final total = _totalSpend(categories);
    final currencyCode = categories.first.displayCurrency.value;
    final visible = categories.take(maxLegendItems).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            key: chartKey,
            width: chartSize,
            height: chartSize,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: sectionsSpace,
                    centerSpaceRadius: centerSpaceRadius,
                    startDegreeOffset: -90,
                    borderData: FlBorderData(show: false),
                    pieTouchData: PieTouchData(
                      touchCallback: (event, response) {
                        if (event is! FlTapUpEvent) {
                          return;
                        }
                        final index =
                            response?.touchedSection?.touchedSectionIndex;
                        if (index == null ||
                            index < 0 ||
                            index >= visible.length) {
                          return;
                        }
                        onCategorySelected(visible[index]);
                      },
                    ),
                    sections: [
                      for (final spend in visible)
                        PieChartSectionData(
                          value: math.max(
                            spend.amount.toDouble(),
                            0.0001,
                          ),
                          color: _colorFor(ref, spend.categoryId),
                          radius: sectionRadius,
                          showTitle: false,
                        ),
                    ],
                  ),
                  duration: animationDuration,
                ),
                IgnorePointer(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Spent',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        MoneyDisplay.compact(
                          amount: total.toString(),
                          currencyCode: currencyCode,
                          trimTrailingZeros: true,
                        ),
                        style: AppTypography.money(
                          fontSize: 22,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              key: legendKey,
              children: [
                for (final spend in visible)
                  _LegendRow(
                    spend: spend,
                    highlighted: spend.categoryId == highlightedCategoryId,
                    onTap: () => onCategorySelected(spend),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _colorFor(WidgetRef ref, String categoryId) {
    final category = ref.watch(categoryByIdProvider(categoryId));
    if (category == null) {
      return AppColors.link;
    }
    return CategoryIcons.colorFromHex(category.colorHex);
  }

  Decimal _totalSpend(List<RankedCategorySpend> categories) {
    var total = Decimal.zero;
    for (final spend in categories) {
      total += spend.amount;
    }
    return total;
  }
}

class _LegendRow extends ConsumerWidget {
  const _LegendRow({
    required this.spend,
    required this.highlighted,
    required this.onTap,
  });

  final RankedCategorySpend spend;
  final bool highlighted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final category = ref.watch(categoryByIdProvider(spend.categoryId));
    final name = category?.name ?? 'Other';
    final color = category == null
        ? AppColors.link
        : CategoryIcons.colorFromHex(category.colorHex);

    return InkWell(
      key: CategorySpendPieChart.legendRowKey(spend.categoryId),
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 13.5,
                  fontWeight: highlighted ? FontWeight.w600 : FontWeight.w400,
                  color: highlighted ? AppColors.link : AppColors.onSurface,
                  decoration:
                      highlighted ? TextDecoration.underline : null,
                  decorationColor: AppColors.link,
                ),
              ),
            ),
            Text(
              MoneyDisplay.compact(
                amount: spend.amount.toString(),
                currencyCode: spend.displayCurrency.value,
                trimTrailingZeros: true,
              ),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
