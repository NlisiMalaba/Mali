import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mali_app/application/providers/budget_providers.dart';
import 'package:mali_app/domain/entities/budget.dart';
import 'package:mali_app/presentation/theme/app_colors.dart';
import 'package:mali_app/presentation/theme/app_decorations.dart';
import 'package:mali_app/presentation/theme/app_typography.dart';
import 'package:mali_app/presentation/utils/money_display.dart';
import 'package:mali_app/presentation/widgets/budget/add_budget_sheet.dart';
import 'package:mali_app/presentation/widgets/budget/budget_list_tile.dart';
import 'package:mali_app/presentation/widgets/sovereign/sovereign_app_bar.dart';

class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  static const Key screenKey = Key('budgets-screen');

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
    final theme = Theme.of(context);

    return Scaffold(
      key: screenKey,
      appBar: const SovereignAppBar(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddBudget(context),
        tooltip: 'Add budget',
        backgroundColor: AppColors.primaryContainer,
        foregroundColor: AppColors.onPrimaryContainer,
        child: const Icon(Icons.add),
      ),
      body: budgetsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Could not load budgets: $error'),
          ),
        ),
        data: (budgets) {
          final totals = _computeTotals(budgets);

          return ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            children: [
              _BudgetHeroSummary(
                totalAllocated: totals.allocated,
                totalSpent: totals.spent,
                currencyCode: totals.currencyCode,
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Budget Envelopes',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'MONTHLY VIEW',
                    style: AppTypography.sectionLabel(context).copyWith(
                      color: AppColors.primary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (budgets.isEmpty)
                _EmptyBudgets(onAdd: () => _openAddBudget(context))
              else
                ...budgets.map(
                  (budget) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: BudgetListTile(budget: budget),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  ({Decimal allocated, Decimal spent, String currencyCode}) _computeTotals(
    List<Budget> budgets,
  ) {
    Decimal allocated = Decimal.zero;
    Decimal spent = Decimal.zero;
    String? currency;

    for (final budget in budgets) {
      allocated += Decimal.parse(budget.amount);
      spent += Decimal.parse(budget.spentAmount);
      currency ??= budget.currencyCode;
    }

    return (
      allocated: allocated,
      spent: spent,
      currencyCode: currency ?? 'USD',
    );
  }
}

class _BudgetHeroSummary extends StatelessWidget {
  const _BudgetHeroSummary({
    required this.totalAllocated,
    required this.totalSpent,
    required this.currencyCode,
  });

  final Decimal totalAllocated;
  final Decimal totalSpent;
  final String currencyCode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final remaining = totalAllocated - totalSpent;

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: AppDecorations.heroCard(),
      child: Stack(
        children: [
          Positioned(
            top: -32,
            right: -32,
            child: Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TOTAL ALLOCATED',
                style: AppTypography.sectionLabel(context).copyWith(
                  color: AppColors.onPrimaryContainer.withValues(alpha: 0.8),
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                MoneyDisplay.withCurrency(
                  amount: totalAllocated.toString(),
                  currencyCode: currencyCode,
                ),
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _HeroStat(
                      label: 'Spent',
                      value: MoneyDisplay.withCurrency(
                        amount: totalSpent.toString(),
                        currencyCode: currencyCode,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _HeroStat(
                      label: 'Remaining',
                      value: MoneyDisplay.withCurrency(
                        amount: remaining.toString(),
                        currencyCode: currencyCode,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDecorations.radiusXl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: AppTypography.sectionLabel(context).copyWith(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: Colors.white,
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
