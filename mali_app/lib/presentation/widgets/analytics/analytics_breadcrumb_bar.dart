import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mali_app/presentation/models/analytics_tab.dart';
import 'package:mali_app/presentation/screens/analytics/analytics_screen.dart';

class AnalyticsBreadcrumbBar extends StatelessWidget {
  const AnalyticsBreadcrumbBar({
    required this.categoryName,
    super.key,
  });

  static const Key barKey = Key('category-drilldown-breadcrumb');
  static const Key analyticsCrumbKey = Key('breadcrumb-analytics');
  static const Key spendingCrumbKey = Key('breadcrumb-spending');
  static const Key categoryCrumbKey = Key('breadcrumb-category');

  final String categoryName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.65);

    return Padding(
      key: barKey,
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _Crumb(
            key: analyticsCrumbKey,
            label: 'Analytics',
            onTap: () => context.go(AnalyticsScreen.location()),
          ),
          _Separator(color: muted),
          _Crumb(
            key: spendingCrumbKey,
            label: AnalyticsTab.spending.label,
            onTap: () => context.go(
              AnalyticsScreen.location(tab: AnalyticsTab.spending),
            ),
          ),
          _Separator(color: muted),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Text(
              categoryName,
              key: categoryCrumbKey,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Crumb extends StatelessWidget {
  const _Crumb({
    required this.label,
    required this.onTap,
    super.key,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(label),
    );
  }
}

class _Separator extends StatelessWidget {
  const _Separator({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.chevron_right,
      size: 16,
      color: color,
    );
  }
}
