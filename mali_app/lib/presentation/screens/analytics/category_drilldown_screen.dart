import 'dart:math' as math;

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mali_app/application/models/category_month_query.dart';
import 'package:mali_app/application/providers/analytics_providers.dart';
import 'package:mali_app/application/providers/budget_providers.dart';
import 'package:mali_app/application/providers/category_providers.dart';
import 'package:mali_app/application/providers/wallet_providers.dart';
import 'package:mali_app/domain/entities/budget.dart';
import 'package:mali_app/domain/entities/transaction.dart';
import 'package:mali_app/domain/value_objects/money.dart';
import 'package:mali_app/presentation/theme/app_colors.dart';
import 'package:mali_app/presentation/theme/app_motion.dart';
import 'package:mali_app/presentation/theme/app_typography.dart';
import 'package:mali_app/presentation/utils/budget_usage.dart';
import 'package:mali_app/presentation/utils/category_icons.dart';
import 'package:mali_app/presentation/utils/money_display.dart';
import 'package:mali_app/presentation/utils/transaction_amount_style.dart';
import 'package:mali_app/presentation/widgets/analytics/analytics_breadcrumb_bar.dart';
import 'package:mali_app/presentation/widgets/common/animated_progress_bar.dart';
import 'package:mali_app/presentation/widgets/common/fade_slide_in.dart';
import 'package:mali_app/presentation/widgets/common/pressable_scale.dart';

class CategoryDrilldownScreen extends ConsumerWidget {
  const CategoryDrilldownScreen({
    required this.categoryId,
    required this.year,
    required this.month,
    super.key,
  });

  static const Key screenKey = Key('category-drilldown-screen');
  static const Key totalKey = Key('category-drilldown-total');
  static const Key dayChartKey = Key('category-drilldown-day-chart');
  static const Key paceTipKey = Key('category-drilldown-pace-tip');

  static String location({
    required String categoryId,
    required DateTime month,
  }) {
    return '/analytics/categories/$categoryId'
        '?year=${month.year}&month=${month.month}';
  }

  final String categoryId;
  final int year;
  final int month;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = CategoryMonthQuery(
      categoryId: categoryId,
      year: year,
      month: month,
    );
    final category = ref.watch(categoryByIdProvider(categoryId));
    final categoryName = category?.name ?? 'Category';
    final categoryColor = category == null
        ? AppColors.warning
        : CategoryIcons.colorFromHex(category.colorHex);
    final categoryIcon = CategoryIcons.fromKey(
      category?.iconKey ?? 'category',
    );
    final transactionsAsync =
        ref.watch(categoryMonthTransactionsProvider(query));
    final totalAsync = ref.watch(categoryMonthDisplayTotalProvider(query));
    final budgetAsync = ref.watch(categoryMonthBudgetProvider(query));
    final monthShort = DateFormat.MMMM().format(DateTime(year, month));
    final daysInMonth = DateTime(year, month + 1, 0).day;

    return Scaffold(
      key: screenKey,
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: transactionsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Could not load transactions: $error'),
            ),
          ),
          data: (transactions) {
            final expenses = transactions
                .where((tx) => tx.type == 'expense')
                .toList(growable: false);
            final daily = _dailySpend(expenses, daysInMonth);
            final budget = budgetAsync.asData?.value;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                  child: FadeSlideIn(
                    index: 0,
                    child: _Header(
                      categoryName: categoryName,
                      monthLabel: monthShort,
                      categoryColor: categoryColor,
                      categoryIcon: categoryIcon,
                      onBack: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/analytics');
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                    children: [
                      FadeSlideIn(
                        index: 1,
                        child: totalAsync.when(
                          loading: () => const _SpentCardSkeleton(),
                          error: (error, _) => Text('Could not load total: $error'),
                          data: (total) => _SpentCard(
                            total: total,
                            budget: budget,
                            accent: categoryColor,
                            year: year,
                            month: month,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      FadeSlideIn(
                        index: 2,
                        child: _DayByDayCard(
                          daily: daily,
                          accent: categoryColor,
                          year: year,
                          month: month,
                          budget: budget,
                          total: totalAsync.asData?.value,
                        ),
                      ),
                      if (totalAsync.asData?.value != null) ...[
                        const SizedBox(height: 14),
                        FadeSlideIn(
                          index: 3,
                          child: _PaceTipCard(
                            total: totalAsync.asData!.value,
                            categoryName: categoryName.toLowerCase(),
                            year: year,
                            month: month,
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      FadeSlideIn(
                        index: 4,
                        child: _TransactionsCard(
                          transactions: expenses,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

List<Decimal> _dailySpend(List<Transaction> expenses, int daysInMonth) {
  final daily = List<Decimal>.filled(daysInMonth, Decimal.zero);
  for (final tx in expenses) {
    final day = tx.transactionDate.day;
    if (day < 1 || day > daysInMonth) {
      continue;
    }
    try {
      daily[day - 1] += Decimal.parse(tx.amount);
    } catch (_) {
      // Skip malformed amounts; display total still comes from converted provider.
    }
  }
  return daily;
}

class _Header extends StatelessWidget {
  const _Header({
    required this.categoryName,
    required this.monthLabel,
    required this.categoryColor,
    required this.categoryIcon,
    required this.onBack,
  });

  final String categoryName;
  final String monthLabel;
  final Color categoryColor;
  final IconData categoryIcon;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        PressableScale(
          onTap: onBack,
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE1E5EE)),
            ),
            child: const Icon(
              Icons.chevron_left,
              size: 22,
              color: AppColors.onSurface,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnalyticsBreadcrumbBar(monthLabel: monthLabel),
              Text(
                categoryName,
                style: AppTypography.money(
                  fontSize: 26,
                  color: AppColors.onSurface,
                ).copyWith(letterSpacing: -0.5),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: categoryColor.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(categoryIcon, size: 20, color: categoryColor),
        ),
      ],
    );
  }
}

class _SpentCardSkeleton extends StatelessWidget {
  const _SpentCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 105,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(22),
      ),
      alignment: Alignment.center,
      child: const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}

class _SpentCard extends StatelessWidget {
  const _SpentCard({
    required this.total,
    required this.budget,
    required this.accent,
    required this.year,
    required this.month,
  });

  final Money total;
  final Budget? budget;
  final Color accent;
  final int year;
  final int month;

  @override
  Widget build(BuildContext context) {
    final currency = total.currency.value;
    final spentLabel = MoneyDisplay.compact(
      amount: total.amount.toString(),
      currencyCode: currency,
    );
    final usage = budget == null ? 0.0 : BudgetUsage.ratio(budget!);
    final remaining = budget == null
        ? null
        : BudgetUsage.remainingAmount(budget!);
    final badge = budget == null
        ? null
        : '${(usage * 100).clamp(0, 999).round()}% · '
            '${remaining! < Decimal.zero ? 'over ' : ''}'
            '${MoneyDisplay.compact(
              amount: remaining.abs().toString(),
              currencyCode: budget!.currencyCode,
              trimTrailingZeros: true,
            )}'
            '${remaining < Decimal.zero ? '' : ' left'}';
    final resetLabel = DateFormat('d MMM').format(DateTime(year, month + 1, 1));
    final budgetLine = budget == null
        ? 'No budget set for this category'
        : 'Budget ${MoneyDisplay.compact(
            amount: budget!.amount,
            currencyCode: budget!.currencyCode,
            trimTrailingZeros: true,
          )} · resets $resetLabel';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Spent so far',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.onSurfaceVariant,
                            fontSize: 13,
                          ),
                    ),
                    Text(
                      spentLabel,
                      key: CategoryDrilldownScreen.totalKey,
                      style: AppTypography.money(
                        fontSize: 34,
                        color: AppColors.onSurface,
                      ).copyWith(letterSpacing: -1),
                    ),
                  ],
                ),
              ),
              if (badge != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      color: _darken(accent),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          if (budget != null) ...[
            const SizedBox(height: 10),
            AnimatedProgressBar(
              value: usage,
              color: BudgetUsage.progressColor(usage),
              backgroundColor: AppColors.surfaceContainer,
              height: 10,
              borderRadius: 5,
            ),
          ],
          const SizedBox(height: 10),
          Text(
            budgetLine,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 13,
                ),
          ),
        ],
      ),
    );
  }
}

Color _darken(Color color) {
  final hsl = HSLColor.fromColor(color);
  return hsl.withLightness((hsl.lightness * 0.55).clamp(0.15, 0.45)).toColor();
}

class _DayByDayCard extends StatelessWidget {
  const _DayByDayCard({
    required this.daily,
    required this.accent,
    required this.year,
    required this.month,
    required this.budget,
    required this.total,
  });

  final List<Decimal> daily;
  final Color accent;
  final int year;
  final int month;
  final Budget? budget;
  final Money? total;

  @override
  Widget build(BuildContext context) {
    final daysWithSpend = [
      for (var i = 0; i < daily.length; i++)
        if (daily[i] > Decimal.zero) i + 1,
    ];
    final lastDay = daysWithSpend.isEmpty ? 1 : daysWithSpend.last;
    final firstDay = daysWithSpend.isEmpty ? 1 : daysWithSpend.first;
    final visibleCount = math.min(10, math.max(lastDay, 1));
    final startDay = math.max(1, lastDay - visibleCount + 1);
    final bars = <_DayBarData>[];
    Decimal maxSpend = Decimal.one;
    Decimal totalVisible = Decimal.zero;
    var spendDays = 0;

    for (var day = startDay; day <= startDay + visibleCount - 1; day++) {
      final amount = day <= daily.length ? daily[day - 1] : Decimal.zero;
      if (amount > maxSpend) {
        maxSpend = amount;
      }
      if (amount > Decimal.zero) {
        totalVisible += amount;
        spendDays++;
      }
      bars.add(_DayBarData(day: day, amount: amount));
    }

    final average = spendDays == 0
        ? Decimal.zero
        : (totalVisible / Decimal.fromInt(spendDays))
            .toDecimal(scaleOnInfinitePrecision: 8);
    final averageRatio = maxSpend <= Decimal.zero
        ? 0.0
        : (average / maxSpend).toDouble().clamp(0.0, 1.0);

    final tip = _dailyTip(
      budget: budget,
      total: total,
      year: year,
      month: month,
    );

    final rangeLabel = daysWithSpend.isEmpty
        ? DateFormat.MMM().format(DateTime(year, month))
        : '$firstDay–$lastDay ${DateFormat.MMM().format(DateTime(year, month))}';

    return Container(
      key: CategoryDrilldownScreen.dayChartKey,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'Day by day',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
              ),
              const Spacer(),
              Text(
                rangeLabel,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 12.5,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 15 + (85 * averageRatio),
                  child: CustomPaint(
                    size: const Size(double.infinity, 1),
                    painter: _DashedLinePainter(
                      color: const Color(0xFFA8B1C4),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (var i = 0; i < bars.length; i++) ...[
                        if (i > 0) const SizedBox(width: 6),
                        Expanded(
                          child: _DayBar(
                            data: bars[i],
                            maxSpend: maxSpend,
                            average: average,
                            accent: accent,
                            isToday: _isToday(year, month, bars[i].day),
                            index: i,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              for (var i = 0; i < bars.length; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${bars[i].day}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (tip != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                CustomPaint(
                  size: const Size(16, 1),
                  painter: _DashedLinePainter(
                    color: const Color(0xFFA8B1C4),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tip,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 12.5,
                        ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

String? _dailyTip({
  required Budget? budget,
  required Money? total,
  required int year,
  required int month,
}) {
  if (budget == null || total == null) {
    return null;
  }
  final remaining = BudgetUsage.remainingAmount(budget);
  if (remaining <= Decimal.zero) {
    return 'Already over budget for this month';
  }
  final today = DateTime.now();
  final isCurrentMonth = today.year == year && today.month == month;
  final day = isCurrentMonth ? today.day : DateTime(year, month + 1, 0).day;
  final daysLeft = DateTime(year, month + 1, 0).day - day + 1;
  if (daysLeft <= 0) {
    return null;
  }
  final perDay =
      (remaining / Decimal.fromInt(daysLeft)).toDecimal(scaleOnInfinitePrecision: 2);
  return '${MoneyDisplay.compact(
    amount: perDay.toString(),
    currencyCode: budget.currencyCode,
    trimTrailingZeros: true,
  )}/day keeps you on budget';
}

bool _isToday(int year, int month, int day) {
  final now = DateTime.now();
  return now.year == year && now.month == month && now.day == day;
}

class _DayBarData {
  const _DayBarData({required this.day, required this.amount});

  final int day;
  final Decimal amount;
}

class _DayBar extends StatelessWidget {
  const _DayBar({
    required this.data,
    required this.maxSpend,
    required this.average,
    required this.accent,
    required this.isToday,
    required this.index,
  });

  final _DayBarData data;
  final Decimal maxSpend;
  final Decimal average;
  final Color accent;
  final bool isToday;
  final int index;

  @override
  Widget build(BuildContext context) {
    final ratio = maxSpend <= Decimal.zero
        ? 0.0
        : (data.amount / maxSpend).toDouble().clamp(0.0, 1.0);
    final height = math.max(2.0, 96 * ratio);
    final color = isToday
        ? AppColors.navy
        : data.amount <= average
            ? AppColors.success
            : accent;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: height),
      duration: AppMotion.resolve(
        context,
        Duration(milliseconds: 320 + (index * 35)),
      ),
      curve: AppMotion.standard,
      builder: (context, animatedHeight, _) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            height: animatedHeight,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(5),
                bottom: Radius.circular(2),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  const _DashedLinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    const dash = 4.0;
    const gap = 3.0;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(math.min(x + dash, size.width), 0), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _PaceTipCard extends StatelessWidget {
  const _PaceTipCard({
    required this.total,
    required this.categoryName,
    required this.year,
    required this.month,
  });

  final Money total;
  final String categoryName;
  final int year;
  final int month;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final isCurrentMonth = today.year == year && today.month == month;
    final day = isCurrentMonth ? math.max(today.day, 1) : DateTime(year, month + 1, 0).day;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final projected = day <= 0
        ? total.amount
        : (total.amount *
                (Decimal.fromInt(daysInMonth) / Decimal.fromInt(day))
                    .toDecimal(scaleOnInfinitePrecision: 8))
            .round(scale: 0);
    final projectedLabel = MoneyDisplay.compact(
      amount: projected.toString(),
      currencyCode: total.currency.value,
      trimTrailingZeros: true,
    );

    return Container(
      key: CategoryDrilldownScreen.paceTipKey,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.silver,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: const TextStyle(
                  color: AppColors.onPrimary,
                  fontSize: 14,
                  height: 1.45,
                ),
                children: [
                  const TextSpan(text: "At this pace you'll spend about "),
                  TextSpan(
                    text: projectedLabel,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: ' on $categoryName this month.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionsCard extends StatelessWidget {
  const _TransactionsCard({required this.transactions});

  final List<Transaction> transactions;

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          'No transactions in this category.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
        ),
      );
    }

    final sorted = [...transactions]
      ..sort((a, b) => b.transactionDate.compareTo(a.transactionDate));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          for (var i = 0; i < sorted.length; i++)
            _TransactionRow(
              transaction: sorted[i],
              showDivider: i < sorted.length - 1,
            ),
        ],
      ),
    );
  }
}

class _TransactionRow extends ConsumerWidget {
  const _TransactionRow({
    required this.transaction,
    required this.showDivider,
  });

  final Transaction transaction;
  final bool showDivider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletAsync = ref.watch(walletByIdProvider(transaction.walletId));
    final wallet = walletAsync.asData?.value;
    final dateLabel = _relativeDate(transaction.transactionDate);
    final walletLabel = wallet == null
        ? transaction.currencyCode
        : '${wallet.name} ${wallet.currencyCode}';
    final amountColor = TransactionAmountStyle.colorFor(transaction.type);
    final amountPrefix = TransactionAmountStyle.prefixFor(transaction.type);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(
                bottom: BorderSide(color: Color(0xFFEDF0F6), width: 0.8),
              )
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.title,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$dateLabel · $walletLabel',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            MoneyDisplay.compactSigned(
              amount: transaction.amount,
              currencyCode: transaction.currencyCode,
              prefix: amountPrefix,
            ),
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: amountColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

String _relativeDate(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(date.year, date.month, date.day);
  if (target == today) {
    return 'Today';
  }
  if (target == today.subtract(const Duration(days: 1))) {
    return 'Yesterday';
  }
  return DateFormat('EEE, d MMM').format(date);
}
