import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mali_app/application/providers/analytics_providers.dart';
import 'package:mali_app/application/providers/display_currency_provider.dart';
import 'package:mali_app/application/providers/home_providers.dart';
import 'package:mali_app/domain/usecases/get_analytics_overview_usecase.dart';
import 'package:mali_app/presentation/models/analytics_tab.dart';
import 'package:mali_app/presentation/screens/analytics/category_drilldown_screen.dart';
import 'package:mali_app/presentation/theme/app_colors.dart';
import 'package:mali_app/presentation/theme/app_typography.dart';
import 'package:mali_app/presentation/widgets/analytics/category_spend_pie_chart.dart';
import 'package:mali_app/presentation/widgets/analytics/in_vs_out_bar_chart.dart';
import 'package:mali_app/presentation/widgets/analytics/insights_coach_card.dart';
import 'package:mali_app/presentation/widgets/analytics/month_selector.dart';
import 'package:mali_app/presentation/widgets/common/fade_slide_in.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({
    this.initialTab = AnalyticsTab.overview,
    super.key,
  });

  static const Key screenKey = Key('analytics-screen');
  static const Key tabBarKey = Key('analytics-tab-bar');
  static const String path = '/analytics';
  static const String tabQuery = 'tab';

  /// Kept for deep-link / breadcrumb compatibility; Insights is a single page.
  final AnalyticsTab initialTab;

  static String location({AnalyticsTab tab = AnalyticsTab.overview}) {
    if (tab == AnalyticsTab.overview) {
      return path;
    }
    return '$path?$tabQuery=${tab.name}';
  }

  static AnalyticsTab tabFromQuery(String? value) {
    for (final tab in AnalyticsTab.values) {
      if (tab.name == value) {
        return tab;
      }
    }
    return AnalyticsTab.overview;
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overviewAsync = ref.watch(analyticsOverviewProvider);
    final trendsAsync = ref.watch(analyticsTrendsProvider);
    final selectedMonth = ref.watch(homeSelectedMonthProvider);
    final displayCurrency = ref.watch(displayCurrencyProvider).value;

    return Scaffold(
      key: screenKey,
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            FadeSlideIn(
              index: 0,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Insights',
                      style: AppTypography.money(
                        fontSize: 30,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ),
                  const MonthSelector(variant: MonthSelectorVariant.chip),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const FadeSlideIn(
              index: 1,
              child: InsightsCoachCard(),
            ),
            const SizedBox(height: 14),
            FadeSlideIn(
              index: 2,
              child: overviewAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => Text('Could not load spending: $error'),
                data: (overview) {
                  if (overview.categorySpend.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Text(
                        'No spending this month.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
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
            ),
            const SizedBox(height: 14),
            FadeSlideIn(
              index: 3,
              child: trendsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => Text('Could not load trends: $error'),
                data: (trends) => InVsOutBarChart(
                  trends: trends,
                  currencyCode: displayCurrency,
                  focusedMonth: selectedMonth,
                  onMonthSelected: (month) {
                    ref
                        .read(homeSelectedMonthProvider.notifier)
                        .selectMonth(month);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
