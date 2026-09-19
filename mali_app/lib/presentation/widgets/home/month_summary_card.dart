import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mali_app/application/models/home_monthly_summary_display.dart';
import 'package:mali_app/application/providers/home_providers.dart';
import 'package:mali_app/presentation/theme/app_colors.dart';
import 'package:mali_app/presentation/theme/app_decorations.dart';
import 'package:mali_app/presentation/theme/app_typography.dart';
import 'package:mali_app/presentation/utils/money_display.dart';
import 'package:mali_app/presentation/widgets/analytics/month_selector.dart';

class MonthSummaryCard extends ConsumerWidget {
  const MonthSummaryCard({super.key});

  static const Key monthTitleKey = MonthSelector.titleKey;
  static const Key previousMonthKey = MonthSelector.previousMonthKey;
  static const Key nextMonthKey = MonthSelector.nextMonthKey;
  static const Key netLabelKey = Key('month-summary-net-label');
  static const Key netAmountKey = Key('month-summary-net-amount');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(homeMonthlySummaryDisplayProvider);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppDecorations.radiusHero),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final legend = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _LegendDot(color: AppColors.primary, label: 'Income'),
                  const SizedBox(width: 12),
                  _LegendDot(color: AppColors.secondary, label: 'Expenses'),
                ],
              );

              if (constraints.maxWidth < 420) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Monthly Summary',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    legend,
                  ],
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Monthly Summary',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  legend,
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          const MonthSelector(),
          const SizedBox(height: 16),
          summaryAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) =>
                Text('Could not load month summary: $error'),
            data: (summary) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _MiniBarChart(summary: summary),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _StatTile(
                        label: 'Savings Rate',
                        value: _savingsRate(summary),
                        valueColor: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _StatTile(
                        label: 'Burn Rate',
                        value: _burnRate(summary),
                        valueColor: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _NetResult(summary: summary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _savingsRate(HomeMonthlySummaryDisplay summary) {
    if (summary.income <= Decimal.zero) {
      return '0%';
    }
    final rate = ((summary.net / summary.income).toDouble() * 100)
        .clamp(0, 100)
        .round();
    return '$rate%';
  }

  String _burnRate(HomeMonthlySummaryDisplay summary) {
    final daysInMonth = DateTime(
      summary.month.year,
      summary.month.month + 1,
      0,
    ).day;
    final dayOfMonth = DateTime.now().day.clamp(1, daysInMonth);
    if (dayOfMonth == 0 || summary.expenses <= Decimal.zero) {
      return MoneyDisplay.withCurrency(
        amount: '0',
        currencyCode: summary.displayCurrency.value,
      );
    }
    final daily = summary.expenses / Decimal.fromInt(dayOfMonth);
    return '${MoneyDisplay.withCurrency(
      amount: daily.toString(),
      currencyCode: summary.displayCurrency.value,
    )}/day';
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
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _MiniBarChart extends StatelessWidget {
  const _MiniBarChart({required this.summary});

  final HomeMonthlySummaryDisplay summary;

  @override
  Widget build(BuildContext context) {
    final maxValue = summary.income >= summary.expenses
        ? summary.income
        : summary.expenses;
    final incomeFrac = maxValue > Decimal.zero
        ? (summary.income / maxValue).toDouble().clamp(0.1, 1.0)
        : 0.1;
    final expenseFrac = maxValue > Decimal.zero
        ? (summary.expenses / maxValue).toDouble().clamp(0.1, 1.0)
        : 0.1;

    return SizedBox(
      height: 128,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < 10; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      flex: (i.isEven ? incomeFrac * 100 : expenseFrac * 100)
                          .round()
                          .clamp(1, 100),
                      child: Container(
                        decoration: BoxDecoration(
                          color: (i.isEven ? AppColors.primary : AppColors.secondary)
                              .withValues(alpha: i == 8 ? 0.4 : 0.2),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppDecorations.radiusXl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: AppTypography.sectionLabel(context).copyWith(fontSize: 10),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _NetResult extends StatelessWidget {
  const _NetResult({required this.summary});

  final HomeMonthlySummaryDisplay summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final net = summary.net.abs();
    final label = summary.isSurplus ? 'Surplus' : 'Deficit';
    final color = summary.isSurplus ? AppColors.success : AppColors.error;

    return Column(
      children: [
        Text(
          label,
          key: MonthSummaryCard.netLabelKey,
          style: theme.textTheme.labelLarge?.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          MoneyDisplay.withCurrency(
            amount: net.toString(),
            currencyCode: summary.displayCurrency.value,
          ),
          key: MonthSummaryCard.netAmountKey,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
