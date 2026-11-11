import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mali_app/presentation/screens/analytics/analytics_screen.dart';
import 'package:mali_app/presentation/theme/app_colors.dart';

/// Compact Insights trail used on category drill-down: `Insights › November`.
class AnalyticsBreadcrumbBar extends StatelessWidget {
  const AnalyticsBreadcrumbBar({
    required this.monthLabel,
    this.categoryName,
    super.key,
  });

  static const Key barKey = Key('category-drilldown-breadcrumb');
  static const Key analyticsCrumbKey = Key('breadcrumb-analytics');
  static const Key spendingCrumbKey = Key('breadcrumb-spending');
  static const Key categoryCrumbKey = Key('breadcrumb-category');

  final String monthLabel;

  /// Kept for older call sites / tests that still pass a category label.
  final String? categoryName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: barKey,
      padding: EdgeInsets.zero,
      child: Row(
        children: [
          Flexible(
            child: GestureDetector(
              key: analyticsCrumbKey,
              onTap: () => context.go(AnalyticsScreen.location()),
              behavior: HitTestBehavior.opaque,
              child: Text(
                'Insights',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 12.5,
                    ),
              ),
            ),
          ),
          Text(
            ' › ',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 12.5,
                ),
          ),
          Flexible(
            child: GestureDetector(
              key: spendingCrumbKey,
              onTap: () => context.go(AnalyticsScreen.location()),
              behavior: HitTestBehavior.opaque,
              child: Text(
                monthLabel,
                key: categoryCrumbKey,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 12.5,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
