import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mali_app/application/models/home_monthly_summary_display.dart';
import 'package:mali_app/application/providers/home_providers.dart';
import 'package:mali_app/presentation/theme/app_colors.dart';
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                  _SummaryBars(summary: summary),
                  const SizedBox(height: 20),
                  _NetResult(summary: summary),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryBars extends StatelessWidget {
  const _SummaryBars({required this.summary});

  final HomeMonthlySummaryDisplay summary;

  static const double barHeight = 12;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxValue = _maxBarValue(summary.income, summary.expenses);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _SummaryBarColumn(
            label: 'Income',
            amount: summary.income,
            currencyCode: summary.displayCurrency.value,
            color: AppColors.success,
            fraction: _barFraction(summary.income, maxValue),
            theme: theme,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _SummaryBarColumn(
            label: 'Expenses',
            amount: summary.expenses,
            currencyCode: summary.displayCurrency.value,
            color: AppColors.tealPrimary,
            fraction: _barFraction(summary.expenses, maxValue),
            theme: theme,
          ),
        ),
      ],
    );
  }

  Decimal _maxBarValue(Decimal income, Decimal expenses) {
    final max = income >= expenses ? income : expenses;
    if (max <= Decimal.zero) {
      return Decimal.one;
    }
    return max;
  }

  double _barFraction(Decimal value, Decimal maxValue) {
    if (maxValue <= Decimal.zero) {
      return 0;
    }
    return (value / maxValue).toDouble().clamp(0, 1);
  }
}

class _SummaryBarColumn extends StatelessWidget {
  const _SummaryBarColumn({
    required this.label,
    required this.amount,
    required this.currencyCode,
    required this.color,
    required this.fraction,
    required this.theme,
  });

  final String label;
  final Decimal amount;
  final String currencyCode;
  final Color color;
  final double fraction;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(_SummaryBars.barHeight / 2),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: _SummaryBars.barHeight,
            backgroundColor: color.withValues(alpha: 0.15),
            color: color,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          MoneyDisplay.withCurrency(
            amount: amount.toString(),
            currencyCode: currencyCode,
          ),
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
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
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
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
