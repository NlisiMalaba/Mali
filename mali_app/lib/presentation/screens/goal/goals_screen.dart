import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mali_app/application/providers/goal_providers.dart';
import 'package:mali_app/domain/entities/savings_goal.dart';
import 'package:mali_app/presentation/theme/app_colors.dart';
import 'package:mali_app/presentation/theme/app_decorations.dart';
import 'package:mali_app/presentation/theme/app_typography.dart';
import 'package:mali_app/presentation/utils/money_display.dart';
import 'package:mali_app/presentation/widgets/goal/add_goal_sheet.dart';
import 'package:mali_app/presentation/widgets/goal/goal_card.dart';
import 'package:mali_app/presentation/widgets/sovereign/sovereign_app_bar.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  static const Key screenKey = Key('goals-screen');
  static const Key addGoalFabKey = Key('add-goal-fab');
  static const Key reorderButtonKey = Key('reorder-goals-button');

  Future<void> _openAddGoal(BuildContext context) async {
    final created = await AddGoalSheet.show(context);
    if (created == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Goal added.')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(activeGoalsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      key: screenKey,
      appBar: SovereignAppBar(
        actions: [
          if (goalsAsync.maybeWhen(
            data: (goals) => goals.isNotEmpty,
            orElse: () => false,
          ))
            IconButton(
              key: reorderButtonKey,
              tooltip: 'Reorder goals',
              icon: const Icon(Icons.swap_vert),
              onPressed: () => context.push('/goals/priority'),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        key: addGoalFabKey,
        heroTag: 'add-goal-fab',
        onPressed: () => _openAddGoal(context),
        tooltip: 'Add Goal',
        backgroundColor: AppColors.primaryContainer,
        foregroundColor: AppColors.onPrimaryContainer,
        child: const Icon(Icons.add),
      ),
      body: goalsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Could not load goals: $error'),
          ),
        ),
        data: (goals) {
          if (goals.isEmpty) {
            return _EmptyGoals(onAdd: () => _openAddGoal(context));
          }

          final totals = _computeTotals(goals);

          return ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
            children: [
              Text(
                'TOTAL SAVINGS PROGRESS',
                style: AppTypography.sectionLabel(context),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      MoneyDisplay.withCurrency(
                        amount: totals.saved.toString(),
                        currencyCode: totals.currencyCode,
                      ),
                      style: AppTypography.currencyHero(context).copyWith(
                        fontSize: 40,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryFixed,
                      borderRadius: BorderRadius.circular(
                        AppDecorations.radiusMd,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.trending_up,
                          size: 16,
                          color: AppColors.onPrimaryFixed,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${totals.overallPercent}% Overall',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.onPrimaryFixed,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              ...goals.map(
                (goal) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: GoalCard(goal: goal),
                ),
              ),
              _AddGoalCard(onTap: () => _openAddGoal(context)),
            ],
          );
        },
      ),
    );
  }

  ({Decimal saved, Decimal target, String currencyCode, int overallPercent})
      _computeTotals(List<SavingsGoal> goals) {
    Decimal saved = Decimal.zero;
    Decimal target = Decimal.zero;
    String? currency;

    for (final goal in goals) {
      saved += Decimal.tryParse(goal.currentAmount) ?? Decimal.zero;
      target += Decimal.tryParse(goal.targetAmount) ?? Decimal.zero;
      currency ??= goal.currencyCode;
    }

    final percent = target > Decimal.zero
        ? ((saved / target).toDouble() * 100).round()
        : 0;

    return (
      saved: saved,
      target: target,
      currencyCode: currency ?? 'USD',
      overallPercent: percent,
    );
  }
}

class _AddGoalCard extends StatelessWidget {
  const _AddGoalCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppDecorations.radiusHero),
          border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.3),
            width: 2,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add,
                size: 32,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Add New Goal',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Define your next milestone and start growing your wealth.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyGoals extends StatelessWidget {
  const _EmptyGoals({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'No savings goals yet',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Create a goal to track what you are saving for.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add your first goal'),
            ),
          ],
        ),
      ),
    );
  }
}
