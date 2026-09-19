import 'package:decimal/decimal.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mali_app/application/providers/category_providers.dart';
import 'package:mali_app/domain/usecases/get_analytics_overview_usecase.dart';
import 'package:mali_app/presentation/theme/app_colors.dart';
import 'package:mali_app/presentation/utils/category_icons.dart';
import 'package:mali_app/presentation/utils/money_display.dart';
import 'package:mali_app/presentation/utils/share_fraction.dart';

class CategorySpendPieChart extends ConsumerWidget {
  const CategorySpendPieChart({
    required this.categories,
    required this.onCategorySelected,
    super.key,
  });

  static const Key chartKey = Key('spending-pie-chart');
  static const Key legendKey = Key('spending-legend');
  static const double chartHeight = 240;
  static const double sectionRadius = 76;
  static const double centerSpaceRadius = 52;
  static const double sectionsSpace = 2;
  static const double minLabeledSlicePercent = 8;
  static const double titleFontSize = 12;
  static const Duration animationDuration = Duration.zero;

  static Key legendRowKey(String categoryId) =>
      Key('spending-legend-$categoryId');

  final List<RankedCategorySpend> categories;
  final ValueChanged<RankedCategorySpend> onCategorySelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final total = _totalSpend(categories);
    final currencyCode = categories.first.displayCurrency.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          key: chartKey,
          height: chartHeight,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sectionsSpace: sectionsSpace,
                  centerSpaceRadius: centerSpaceRadius,
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
                          index >= categories.length) {
                        return;
                      }
                      onCategorySelected(categories[index]);
                    },
                  ),
                  sections: [
                    for (final spend in categories)
                      _section(
                        spend: spend,
                        total: total,
                        color: _colorFor(ref, spend.categoryId),
                      ),
                  ],
                ),
                duration: animationDuration,
              ),
              IgnorePointer(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Spent',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.65),
                        ),
                      ),
                      Text(
                        MoneyDisplay.withCurrency(
                          amount: total.toString(),
                          currencyCode: currencyCode,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          key: legendKey,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
            child: Column(
              children: [
                for (var index = 0; index < categories.length; index++) ...[
                  if (index > 0) const Divider(height: 1),
                  _LegendRow(
                    spend: categories[index],
                    total: total,
                    onTap: () => onCategorySelected(categories[index]),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  PieChartSectionData _section({
    required RankedCategorySpend spend,
    required Decimal total,
    required Color color,
  }) {
    final percent =
        ShareFraction.of(amount: spend.amount, total: total) * 100;
    final showTitle = percent >= minLabeledSlicePercent;
    return PieChartSectionData(
      // Display-only geometry; persisted money stays on Decimal.
      value: spend.amount.toDouble(),
      color: color,
      radius: sectionRadius,
      showTitle: showTitle,
      title: '${percent.round()}%',
      titleStyle: const TextStyle(
        fontSize: titleFontSize,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    );
  }

  Color _colorFor(WidgetRef ref, String categoryId) {
    final category = ref.watch(categoryByIdProvider(categoryId));
    if (category == null) {
      return AppColors.tealPrimary;
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
    required this.total,
    required this.onTap,
  });

  final RankedCategorySpend spend;
  final Decimal total;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final category = ref.watch(categoryByIdProvider(spend.categoryId));
    final name = category?.name ?? 'Other';
    final color = category == null
        ? AppColors.tealPrimary
        : CategoryIcons.colorFromHex(category.colorHex);
    final percent =
        (ShareFraction.of(amount: spend.amount, total: total) * 100).round();

    return ListTile(
      key: CategorySpendPieChart.legendRowKey(spend.categoryId),
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.15),
        child: CircleAvatar(
          radius: 8,
          backgroundColor: color,
        ),
      ),
      title: Text(
        name,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text('$percent%'),
      trailing: Text(
        MoneyDisplay.withCurrency(
          amount: spend.amount.toString(),
          currencyCode: spend.displayCurrency.value,
        ),
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
