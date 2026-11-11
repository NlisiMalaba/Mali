import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mali_app/domain/usecases/get_analytics_trends_usecase.dart';
import 'package:mali_app/presentation/theme/app_colors.dart';

/// Six-month paired “In vs out” bars for Insights.
class InVsOutBarChart extends StatelessWidget {
  const InVsOutBarChart({
    required this.trends,
    required this.currencyCode,
    this.focusedMonth,
    this.onMonthSelected,
    super.key,
  });

  static const Key chartKey = Key('in-vs-out-bar-chart');
  static const double barMaxHeight = 96;
  static const double barWidth = 11;
  static const Color inColor = AppColors.income;
  static const Color outColor = AppColors.expense;

  final AnalyticsTrends trends;
  final String currencyCode;
  final DateTime? focusedMonth;
  final ValueChanged<DateTime>? onMonthSelected;

  @override
  Widget build(BuildContext context) {
    final series = _seriesFor(trends, currencyCode);
    if (series == null) {
      return Text(
        'No income or expenses in the last 6 months.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
      );
    }

    final maxAmount = _maxAmount(series);
    final monthFormat = DateFormat.MMM();

    return Container(
      key: chartKey,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'In vs out',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppColors.onSurface,
                    ),
              ),
              const Spacer(),
              const _LegendDot(color: inColor, label: 'In'),
              const SizedBox(width: 12),
              const _LegendDot(color: outColor, label: 'Out'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: barMaxHeight + 28,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var index = 0; index < trends.months.length; index++) ...[
                  if (index > 0) const Spacer(),
                  Expanded(
                    child: _MonthBars(
                      month: trends.months[index],
                      income: series.incomeByMonth[index],
                      expense: series.expensesByMonth[index],
                      maxAmount: maxAmount,
                      label: monthFormat.format(trends.months[index]),
                      focused: _isSameMonth(
                        trends.months[index],
                        focusedMonth,
                      ),
                      onTap: onMonthSelected == null
                          ? null
                          : () => onMonthSelected!(trends.months[index]),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static CurrencyTrendSeries? _seriesFor(
    AnalyticsTrends trends,
    String currencyCode,
  ) {
    if (trends.currencies.isEmpty) {
      return null;
    }
    for (final series in trends.currencies) {
      if (series.currencyCode == currencyCode) {
        return series;
      }
    }
    return trends.currencies.first;
  }

  static Decimal _maxAmount(CurrencyTrendSeries series) {
    var max = Decimal.zero;
    for (final amount in [...series.incomeByMonth, ...series.expensesByMonth]) {
      if (amount > max) {
        max = amount;
      }
    }
    return max <= Decimal.zero ? Decimal.one : max;
  }

  static bool _isSameMonth(DateTime a, DateTime? b) {
    if (b == null) {
      return false;
    }
    return a.year == b.year && a.month == b.month;
  }
}

class _MonthBars extends StatelessWidget {
  const _MonthBars({
    required this.month,
    required this.income,
    required this.expense,
    required this.maxAmount,
    required this.label,
    required this.focused,
    this.onTap,
  });

  final DateTime month;
  final Decimal income;
  final Decimal expense;
  final Decimal maxAmount;
  final String label;
  final bool focused;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: Key('in-vs-out-month-${month.year}-${month.month}'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SizedBox(
            height: InVsOutBarChart.barMaxHeight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _Bar(
                  value: income,
                  max: maxAmount,
                  color: InVsOutBarChart.inColor,
                ),
                const SizedBox(width: 3),
                _Bar(
                  value: expense,
                  max: maxAmount,
                  color: InVsOutBarChart.outColor,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: focused ? FontWeight.w700 : FontWeight.w400,
              color: focused
                  ? AppColors.onSurface
                  : AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.value,
    required this.max,
    required this.color,
  });

  final Decimal value;
  final Decimal max;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ratio = max <= Decimal.zero
        ? 0.0
        : (value / max).toDouble().clamp(0.0, 1.0);
    final height = (InVsOutBarChart.barMaxHeight * ratio)
        .clamp(4.0, InVsOutBarChart.barMaxHeight);

    return Container(
      width: InVsOutBarChart.barWidth,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.onSurfaceVariant,
            fontSize: 12.5,
          ),
        ),
      ],
    );
  }
}
