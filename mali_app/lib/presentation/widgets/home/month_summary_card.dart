import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mali_app/application/models/home_monthly_summary_display.dart';
import 'package:mali_app/application/providers/home_providers.dart';
import 'package:mali_app/presentation/theme/app_colors.dart';
import 'package:mali_app/presentation/utils/money_display.dart';

class MonthSummaryCard extends ConsumerWidget {
  const MonthSummaryCard({super.key});

  static const Key monthTitleKey = Key('month-summary-title');
  static const Key previousMonthKey = Key('month-summary-previous');
  static const Key nextMonthKey = Key('month-summary-next');
  static const Key netLabelKey = Key('month-summary-net-label');
  static const Key netAmountKey = Key('month-summary-net-amount');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final summaryAsync = ref.watch(homeMonthlySummaryDisplayProvider);
    final selectedMonth = ref.watch(homeSelectedMonthProvider);
    final monthNotifier = ref.read(homeSelectedMonthProvider.notifier);
    final now = DateTime.now();
    final canGoForward = selectedMonth.year < now.year ||
        (selectedMonth.year == now.year && selectedMonth.month < now.month);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _MonthNavigationHeader(
              selectedMonth: selectedMonth,
              canGoForward: canGoForward,
              onPrevious: monthNotifier.previousMonth,
              onNext: canGoForward ? monthNotifier.nextMonth : null,
            ),
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

class _MonthNavigationHeader extends StatelessWidget {
  const _MonthNavigationHeader({
    required this.selectedMonth,
    required this.canGoForward,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime selectedMonth;
  final bool canGoForward;
  final VoidCallback onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        IconButton(
          key: MonthSummaryCard.previousMonthKey,
          onPressed: onPrevious,
          icon: const Icon(Icons.chevron_left),
          tooltip: 'Previous month',
        ),
        Expanded(
          child: Text(
            DateFormat.yMMMM().format(selectedMonth),
            key: MonthSummaryCard.monthTitleKey,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        IconButton(
          key: MonthSummaryCard.nextMonthKey,
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right),
          tooltip: 'Next month',
        ),
      ],
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
