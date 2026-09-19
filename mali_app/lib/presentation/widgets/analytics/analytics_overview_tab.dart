import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mali_app/application/providers/analytics_providers.dart';
import 'package:mali_app/presentation/models/analytics_tab.dart';
import 'package:mali_app/presentation/widgets/analytics/currency_net_table.dart';
import 'package:mali_app/presentation/widgets/analytics/top_spending_categories_list.dart';
import 'package:mali_app/presentation/widgets/home/month_summary_card.dart';

class AnalyticsOverviewTab extends ConsumerWidget {
  const AnalyticsOverviewTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overviewAsync = ref.watch(analyticsOverviewProvider);
    final theme = Theme.of(context);

    return ListView(
      key: AnalyticsTab.overview.panelKey,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        const MonthSummaryCard(),
        const SizedBox(height: 24),
        Text(
          'By currency',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        overviewAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => Text('Could not load overview: $error'),
          data: (overview) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CurrencyNetTable(totals: overview.totalsByCurrency),
              const SizedBox(height: 24),
              Text(
                'Top spending',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TopSpendingCategoriesList(categories: overview.topCategories),
            ],
          ),
        ),
      ],
    );
  }
}
