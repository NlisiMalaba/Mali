import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mali_app/application/providers/home_providers.dart';

class MonthSelector extends ConsumerWidget {
  const MonthSelector({super.key});

  static const Key titleKey = Key('month-summary-title');
  static const Key previousMonthKey = Key('month-summary-previous');
  static const Key nextMonthKey = Key('month-summary-next');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final selectedMonth = ref.watch(homeSelectedMonthProvider);
    final monthNotifier = ref.read(homeSelectedMonthProvider.notifier);
    final now = DateTime.now();
    final canGoForward = selectedMonth.year < now.year ||
        (selectedMonth.year == now.year && selectedMonth.month < now.month);

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
            DateFormat.yMMMM().format(selectedMonth),
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
