import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mali_app/application/providers/analytics_providers.dart';
import 'package:mali_app/application/providers/home_providers.dart';
import 'package:mali_app/domain/usecases/get_analytics_overview_usecase.dart';
import 'package:mali_app/presentation/models/analytics_tab.dart';
import 'package:mali_app/presentation/screens/analytics/category_drilldown_screen.dart';
import 'package:mali_app/presentation/widgets/analytics/category_spend_pie_chart.dart';
import 'package:mali_app/presentation/widgets/analytics/month_selector.dart';

class AnalyticsSpendingTab extends ConsumerWidget {
  const AnalyticsSpendingTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overviewAsync = ref.watch(analyticsOverviewProvider);
    final selectedMonth = ref.watch(homeSelectedMonthProvider);

    return ListView(
      key: AnalyticsTab.spending.panelKey,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        const MonthSelector(),
        const SizedBox(height: 16),
        overviewAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => Text('Could not load spending: $error'),
          data: (overview) {
            if (overview.categorySpend.isEmpty) {
              return Text(
                'No spending this month.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.65),
                    ),
              );
            }

            return CategorySpendPieChart(
              categories: overview.categorySpend,
              onCategorySelected: (spend) =>
                  _openCategory(context, spend, selectedMonth),
            );
          },
        ),
      ],
    );
  }

  void _openCategory(
    BuildContext context,
    RankedCategorySpend spend,
    DateTime month,
  ) {
    context.push(
      CategoryDrilldownScreen.location(
        categoryId: spend.categoryId,
        month: month,
      ),
    );
  }
}
