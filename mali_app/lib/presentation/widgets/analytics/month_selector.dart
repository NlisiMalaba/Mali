import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mali_app/application/providers/home_providers.dart';
import 'package:mali_app/presentation/theme/app_colors.dart';

enum MonthSelectorVariant {
  plain,
  chip,
}

class MonthSelector extends ConsumerWidget {
  const MonthSelector({
    this.variant = MonthSelectorVariant.plain,
    super.key,
  });

  static const Key titleKey = Key('month-summary-title');
  static const Key previousMonthKey = Key('month-summary-previous');
  static const Key nextMonthKey = Key('month-summary-next');

  final MonthSelectorVariant variant;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final selectedMonth = ref.watch(homeSelectedMonthProvider);
    final monthNotifier = ref.read(homeSelectedMonthProvider.notifier);
    final now = DateTime.now();
    final canGoForward = selectedMonth.year < now.year ||
        (selectedMonth.year == now.year && selectedMonth.month < now.month);
    final label = variant == MonthSelectorVariant.chip
        ? DateFormat('MMM yyyy').format(selectedMonth)
        : DateFormat.yMMMM().format(selectedMonth);

    if (variant == MonthSelectorVariant.chip) {
      return Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              key: previousMonthKey,
              onPressed: monthNotifier.previousMonth,
              icon: const Icon(Icons.chevron_left, size: 18),
              color: AppColors.onSurface,
              tooltip: 'Previous month',
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
            Text(
              label,
              key: titleKey,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: AppColors.onSurface,
              ),
            ),
            IconButton(
              key: nextMonthKey,
              onPressed: canGoForward ? monthNotifier.nextMonth : null,
              icon: const Icon(Icons.chevron_right, size: 18),
              color: AppColors.onSurface,
              tooltip: 'Next month',
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        IconButton(
          key: previousMonthKey,
          onPressed: monthNotifier.previousMonth,
          icon: const Icon(Icons.chevron_left),
          tooltip: 'Previous month',
        ),
        Expanded(
          child: Text(
            label,
            key: titleKey,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        IconButton(
          key: nextMonthKey,
          onPressed: canGoForward ? monthNotifier.nextMonth : null,
          icon: const Icon(Icons.chevron_right),
          tooltip: 'Next month',
        ),
      ],
    );
  }
}
