import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mali_app/application/providers/budget_providers.dart';
import 'package:mali_app/domain/entities/budget.dart';
import 'package:mali_app/presentation/theme/app_colors.dart';
import 'package:mali_app/presentation/theme/app_decorations.dart';
import 'package:mali_app/presentation/theme/app_typography.dart';
import 'package:mali_app/presentation/utils/budget_status.dart';
import 'package:mali_app/presentation/utils/budget_usage.dart';
import 'package:mali_app/presentation/utils/money_display.dart';
import 'package:mali_app/presentation/widgets/budget/add_budget_sheet.dart';
import 'package:mali_app/presentation/widgets/budget/budget_list_tile.dart';
import 'package:mali_app/presentation/widgets/budget/budget_overall_gauge.dart';
import 'package:mali_app/presentation/widgets/common/fade_slide_in.dart';

class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({
    this.now,
    super.key,
  });

  static const Key screenKey = Key('budgets-screen');
  static const Key newBudgetButtonKey = Key('new-budget-button');
  static const Key heroKey = Key('budgets-hero');

  final DateTime? now;

  Future<void> _openAddBudget(BuildContext context) async {
    final created = await AddBudgetSheet.show(context);
    if (created == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Budget added.')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetsAsync = ref.watch(currentMonthBudgetsProvider);
    final effectiveNow = now ?? DateTime.now();

    return Scaffold(
      key: screenKey,
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: budgetsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Could not load budgets: $error'),
            ),
          ),
          data: (budgets) {
            final totals = _computeTotals(budgets);
            final ordered = _sortedBudgets(budgets);
            final daysLeft = _daysLeftInMonth(effectiveNow);
            final monthLabel = DateFormat('MMMM').format(effectiveNow);

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                _BudgetsHeader(
                  subtitle: '$monthLabel · $daysLeft days left',
                  onNew: () => _openAddBudget(context),
                ),
                const SizedBox(height: 14),
                FadeSlideIn(
                  index: 0,
                  child: _BudgetsHero(
                    totalAllocated: totals.allocated,
                    totalSpent: totals.spent,
                    currencyCode: totals.currencyCode,
                  ),
                ),
                const SizedBox(height: 14),
                if (ordered.isEmpty)
                  _EmptyBudgets(onAdd: () => _openAddBudget(context))
                else
                  ...ordered.asMap().entries.map(
                    (entry) => Padding(
                      padding: EdgeInsets.only(
                        bottom: entry.key == ordered.length - 1 ? 0 : 10,
                      ),
                      child: FadeSlideIn(
                        index: entry.key + 1,
                        child: BudgetListTile(budget: entry.value),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  static List<Budget> _sortedBudgets(List<Budget> budgets) {
    final sorted = [...budgets]
      ..sort((a, b) {
        final rankCompare = BudgetStatus.fromBudget(a)
            .sortRank
            .compareTo(BudgetStatus.fromBudget(b).sortRank);
        if (rankCompare != 0) {
          return rankCompare;
        }
        return BudgetUsage.ratio(b).compareTo(BudgetUsage.ratio(a));
      });
    return sorted;
  }

  static int _daysLeftInMonth(DateTime now) {
    final lastDay = DateTime(now.year, now.month + 1, 0).day;
    return (lastDay - now.day + 1).clamp(0, lastDay);
  }

  ({Decimal allocated, Decimal spent, String currencyCode}) _computeTotals(
    List<Budget> budgets,
  ) {
    Decimal allocated = Decimal.zero;
    Decimal spent = Decimal.zero;
    String? currency;

    for (final budget in budgets) {
      allocated += Decimal.tryParse(budget.amount) ?? Decimal.zero;
      spent += Decimal.tryParse(budget.spentAmount) ?? Decimal.zero;
      currency ??= budget.currencyCode;
    }

    return (
      allocated: allocated,
      spent: spent,
      currencyCode: currency ?? 'USD',
    );
  }
}

class _BudgetsHeader extends StatelessWidget {
  const _BudgetsHeader({
    required this.subtitle,
    required this.onNew,
  });

  final String subtitle;
  final VoidCallback onNew;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Material(
          color: AppColors.surfaceContainerLowest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0xFFE1E5EE), width: 0.8),
          ),
          child: InkWell(
            onTap: () {
              if (context.canPop()) {
                context.pop();
              }
            },
            borderRadius: BorderRadius.circular(14),
            child: const SizedBox(
              width: 44,
              height: 44,
              child: Icon(
                Icons.chevron_left,
                size: 20,
                color: AppColors.onSurface,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Budgets',
                style: AppTypography.money(
                  fontSize: 28,
                  color: AppColors.onSurface,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        FilledButton.icon(
          key: BudgetsScreen.newBudgetButtonKey,
          onPressed: onNew,
          icon: const Icon(Icons.add, size: 16),
          label: const Text('New'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.navy,
            foregroundColor: AppColors.silver,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _BudgetsHero extends StatelessWidget {
  const _BudgetsHero({
    required this.totalAllocated,
    required this.totalSpent,
    required this.currencyCode,
  });

  final Decimal totalAllocated;
  final Decimal totalSpent;
  final String currencyCode;

  @override
  Widget build(BuildContext context) {
    final progress = totalAllocated <= Decimal.zero
        ? 0.0
        : (totalSpent / totalAllocated).toDouble();
    final remaining = totalAllocated - totalSpent;
    final remainingAbs = remaining < Decimal.zero ? -remaining : remaining;
    final spentLabel = MoneyDisplay.compact(
      amount: totalSpent.toString(),
      currencyCode: currencyCode,
      trimTrailingZeros: true,
    );
    final allocatedLabel = MoneyDisplay.compact(
      amount: totalAllocated.toString(),
      currencyCode: currencyCode,
      trimTrailingZeros: true,
    );
    final remainingLabel = MoneyDisplay.compact(
      amount: remainingAbs.toString(),
      currencyCode: currencyCode,
      trimTrailingZeros: true,
    );
    final remainingCopy = remaining < Decimal.zero
        ? '$remainingLabel over'
        : '$remainingLabel left';

    return Container(
      key: BudgetsScreen.heroKey,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: AppDecorations.heroCard(radius: 26),
      child: Column(
        children: [
          BudgetOverallGauge(progress: progress.clamp(0.0, 1.0)),
          const SizedBox(height: 4),
          Text(
            totalAllocated <= Decimal.zero
                ? 'No budgets set this month'
                : '$spentLabel of $allocatedLabel used · $remainingCopy',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.onNavyMuted,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyBudgets extends StatelessWidget {
  const _EmptyBudgets({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Text(
            'No budget envelopes yet',
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Create envelopes to track spending by category.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Add your first budget'),
          ),
        ],
      ),
    );
  }
}
