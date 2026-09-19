import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mali_app/application/providers/analytics_providers.dart';
import 'package:mali_app/application/providers/home_providers.dart';
import 'package:mali_app/presentation/models/analytics_tab.dart';
import 'package:mali_app/presentation/widgets/analytics/income_expense_trends_chart.dart';
import 'package:mali_app/presentation/widgets/home/month_summary_card.dart';

class AnalyticsTrendsTab extends ConsumerStatefulWidget {
  const AnalyticsTrendsTab({super.key});

  @override
  ConsumerState<AnalyticsTrendsTab> createState() => _AnalyticsTrendsTabState();
}

class _AnalyticsTrendsTabState extends ConsumerState<AnalyticsTrendsTab> {
  DateTime? _focusedMonth;

  @override
  Widget build(BuildContext context) {
    final trendsAsync = ref.watch(analyticsTrendsProvider);
    final disabledCurrencies = ref.watch(trendsDisabledCurrenciesProvider);
    ref.watch(homeSelectedMonthProvider);
    final theme = Theme.of(context);

    return ListView(
      key: AnalyticsTab.trends.panelKey,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Text(
          'Last 6 months',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        trendsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => Text('Could not load trends: $error'),
          data: (trends) {
            if (trends.currencies.isEmpty) {
              return Text(
                'No income or expenses in the last 6 months.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                ),
              );
            }

            final visibleCurrencies = {
              for (final series in trends.currencies)
                if (!disabledCurrencies.contains(series.currencyCode))
                  series.currencyCode,
            };

            return IncomeExpenseTrendsChart(
              trends: trends,
              visibleCurrencies: visibleCurrencies,
              focusedMonth: _focusedMonth,
              onCurrencyToggled: (currencyCode) {
                ref
                    .read(trendsDisabledCurrenciesProvider.notifier)
                    .toggle(currencyCode);
              },
              onMonthSelected: _onMonthSelected,
            );
          },
        ),
        if (_focusedMonth != null) ...[
          const SizedBox(height: 24),
          const MonthSummaryCard(),
        ],
      ],
    );
  }

  void _onMonthSelected(DateTime month) {
    ref.read(homeSelectedMonthProvider.notifier).selectMonth(month);
    setState(() {
      _focusedMonth = DateTime(month.year, month.month);
    });
  }
}
