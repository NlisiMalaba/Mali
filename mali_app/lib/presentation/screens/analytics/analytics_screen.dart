import 'package:flutter/material.dart';
import 'package:mali_app/presentation/models/analytics_tab.dart';
import 'package:mali_app/presentation/theme/app_colors.dart';
import 'package:mali_app/presentation/widgets/analytics/analytics_overview_tab.dart';
import 'package:mali_app/presentation/widgets/analytics/analytics_spending_tab.dart';
import 'package:mali_app/presentation/widgets/analytics/analytics_trends_tab.dart';
import 'package:mali_app/presentation/widgets/sovereign/sovereign_app_bar.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({
    this.initialTab = AnalyticsTab.overview,
    super.key,
  });

  static const Key screenKey = Key('analytics-screen');
  static const Key tabBarKey = Key('analytics-tab-bar');
  static const String path = '/analytics';
  static const String tabQuery = 'tab';

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DefaultTabController(
      key: ValueKey(initialTab),
      initialIndex: initialTab.index,
      length: AnalyticsTab.values.length,
      child: Scaffold(
        key: screenKey,
        appBar: const SovereignAppBar(),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Financial Insights',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    'Tracking your wealth journey',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TabBar(
                key: tabBarKey,
                isScrollable: true,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.onSurfaceVariant,
                indicatorColor: AppColors.primary,
                dividerColor: Colors.transparent,
                labelStyle: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                tabs: [
                  for (final tab in AnalyticsTab.values)
                    Tab(
                      key: tab.tabKey,
                      text: tab.label,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Expanded(
              child: TabBarView(
                children: [
                  AnalyticsOverviewTab(),
                  AnalyticsSpendingTab(),
                  AnalyticsTrendsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
