import 'package:decimal/decimal.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mali_app/domain/usecases/get_analytics_trends_usecase.dart';
import 'package:mali_app/presentation/theme/app_colors.dart';

class IncomeExpenseTrendsChart extends StatelessWidget {
  const IncomeExpenseTrendsChart({
    required this.trends,
    required this.visibleCurrencies,
    required this.onCurrencyToggled,
    required this.onMonthSelected,
    this.focusedMonth,
    super.key,
  });

  static const Key chartKey = Key('trends-line-chart');
  static const Key currencyTogglesKey = Key('trends-currency-toggles');
  static const double chartHeight = 240;
  static const double lineWidth = 3;
  static const double dotRadius = 3.5;
  static const double focusedDotRadius = 5;
  static const double minimumAxisMax = 1;
  static const double axisHeadroom = 1.1;
  static const double leftTitleReservedSize = 40;
  static const Duration animationDuration = Duration.zero;

  static const List<Color> incomeLineColors = [
    AppColors.success,
    Color(0xFF2563EB),
    Color(0xFF7C3AED),
  ];
  static const List<Color> expenseLineColors = [
    AppColors.error,
    Color(0xFFEA580C),
    Color(0xFFDB2777),
  ];

  static const List<int> expenseDashArray = [6, 4];

  static Key currencyToggleKey(String currencyCode) =>
      Key('trends-currency-toggle-$currencyCode');

  static Key monthPointKey(DateTime month) =>
      Key('trends-month-${month.year}-${month.month}');

  final AnalyticsTrends trends;
  final Set<String> visibleCurrencies;
  final DateTime? focusedMonth;
  final ValueChanged<String> onCurrencyToggled;
  final ValueChanged<DateTime> onMonthSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visibleSeries = [
      for (final series in trends.currencies)
        if (visibleCurrencies.contains(series.currencyCode)) series,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          key: currencyTogglesKey,
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final series in trends.currencies)
              FilterChip(
                key: currencyToggleKey(series.currencyCode),
                label: Text(series.currencyCode),
                selected: visibleCurrencies.contains(series.currencyCode),
                onSelected: (_) => onCurrencyToggled(series.currencyCode),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _LegendSwatch(
              color: AppColors.success,
              label: 'Income',
              dashed: false,
              textStyle: theme.textTheme.labelSmall,
            ),
            const SizedBox(width: 16),
            _LegendSwatch(
              color: AppColors.error,
              label: 'Expense',
              dashed: true,
              textStyle: theme.textTheme.labelSmall,
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (visibleSeries.isEmpty)
          Text(
            'Select a currency to see trends.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
            ),
          )
        else
          SizedBox(
            key: chartKey,
            height: chartHeight,
            child: LineChart(
              _chartData(theme, visibleSeries),
              duration: animationDuration,
            ),
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final month in trends.months)
              Expanded(
                child: InkWell(
                  key: monthPointKey(month),
                  onTap: () => onMonthSelected(month),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      DateFormat.MMM().format(month),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: _isFocused(month)
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  LineChartData _chartData(
    ThemeData theme,
    List<CurrencyTrendSeries> visibleSeries,
  ) {
    final maxAmount = _maxVisibleAmount(visibleSeries);
    final maxY = maxAmount <= Decimal.zero
        ? minimumAxisMax
        : maxAmount.toDouble() * axisHeadroom;
    final focusedIndex = _focusedIndex();

    return LineChartData(
      minX: 0,
      maxX: (trends.months.length - 1).toDouble(),
      minY: 0,
      maxY: maxY,
      gridData: const FlGridData(show: true),
      borderData: FlBorderData(show: false),
      extraLinesData: ExtraLinesData(
        verticalLines: [
          if (focusedIndex != null)
            VerticalLine(
              x: focusedIndex.toDouble(),
              color: theme.colorScheme.outline.withValues(alpha: 0.5),
              strokeWidth: 1,
            ),
        ],
      ),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: leftTitleReservedSize,
            getTitlesWidget: (value, meta) {
              if (value == meta.max || value == meta.min) {
                return const SizedBox.shrink();
              }
              return Text(
                value.toInt().toString(),
                style: theme.textTheme.labelSmall,
              );
            },
          ),
        ),
        bottomTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      ),
      lineTouchData: LineTouchData(
        handleBuiltInTouches: true,
        touchCallback: (event, response) {
          if (event is! FlTapUpEvent) {
            return;
          }
          final spots = response?.lineBarSpots;
          if (spots == null || spots.isEmpty) {
            return;
          }
          final index = spots.first.x.round();
          if (index < 0 || index >= trends.months.length) {
            return;
          }
          onMonthSelected(trends.months[index]);
        },
      ),
      lineBarsData: [
        for (var index = 0; index < visibleSeries.length; index++) ...[
          _barData(
            values: visibleSeries[index].incomeByMonth,
            color: incomeLineColors[index % incomeLineColors.length],
            dashed: false,
            focusedIndex: focusedIndex,
          ),
          _barData(
            values: visibleSeries[index].expensesByMonth,
            color: expenseLineColors[index % expenseLineColors.length],
            dashed: true,
            focusedIndex: focusedIndex,
          ),
        ],
      ],
    );
  }

  LineChartBarData _barData({
    required List<Decimal> values,
    required Color color,
    required bool dashed,
    required int? focusedIndex,
  }) {
    return LineChartBarData(
      isCurved: false,
      color: color,
      barWidth: lineWidth,
      dashArray: dashed ? expenseDashArray : null,
      spots: [
        for (var index = 0; index < values.length; index++)
          // Display-only geometry; persisted money stays on Decimal.
          FlSpot(index.toDouble(), values[index].toDouble()),
      ],
      dotData: FlDotData(
        getDotPainter: (spot, percent, bar, index) {
          final radius =
              index == focusedIndex ? focusedDotRadius : dotRadius;
          return FlDotCirclePainter(
            radius: radius,
            color: color,
            strokeWidth: 0,
          );
        },
      ),
    );
  }

  Decimal _maxVisibleAmount(List<CurrencyTrendSeries> series) {
    var maxAmount = Decimal.zero;
    for (final item in series) {
      for (final amount in [...item.incomeByMonth, ...item.expensesByMonth]) {
        if (amount > maxAmount) {
          maxAmount = amount;
        }
      }
    }
    return maxAmount;
  }

  int? _focusedIndex() {
    final focused = focusedMonth;
    if (focused == null) {
      return null;
    }
    for (var index = 0; index < trends.months.length; index++) {
      final month = trends.months[index];
      if (month.year == focused.year && month.month == focused.month) {
        return index;
      }
    }
    return null;
  }

  bool _isFocused(DateTime month) {
    final focused = focusedMonth;
    return focused != null &&
        focused.year == month.year &&
        focused.month == month.month;
  }
}

class _LegendSwatch extends StatelessWidget {
  const _LegendSwatch({
    required this.color,
    required this.label,
    required this.dashed,
    required this.textStyle,
  });

  final Color color;
  final String label;
  final bool dashed;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18,
          height: 3,
          decoration: BoxDecoration(
            color: dashed ? null : color,
            border: dashed
                ? Border(bottom: BorderSide(color: color, width: 2))
                : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: textStyle),
      ],
    );
  }
}
