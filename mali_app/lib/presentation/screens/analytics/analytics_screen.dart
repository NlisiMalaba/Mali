import 'package:flutter/material.dart';
import 'package:mali_app/presentation/models/analytics_tab.dart';
import 'package:mali_app/presentation/widgets/analytics/analytics_overview_tab.dart';
import 'package:mali_app/presentation/widgets/analytics/analytics_spending_tab.dart';
import 'package:mali_app/presentation/widgets/analytics/analytics_trends_tab.dart';

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
    return DefaultTabController(
      key: ValueKey(initialTab),
      initialIndex: initialTab.index,
      length: AnalyticsTab.values.length,
      child: Scaffold(
        key: screenKey,
        appBar: AppBar(
          title: const Text('Analytics'),
          bottom: TabBar(
            key: tabBarKey,
            tabs: [
              for (final tab in AnalyticsTab.values)
                Tab(
                  key: tab.tabKey,
                  text: tab.label,
                ),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            AnalyticsOverviewTab(),
            AnalyticsSpendingTab(),
            AnalyticsTrendsTab(),
          ],
        ),
      ),
    );
  }
}
