import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mali_app/application/providers/home_providers.dart';
import 'package:mali_app/domain/entities/savings_goal.dart';
import 'package:mali_app/presentation/theme/app_colors.dart';
import 'package:mali_app/presentation/utils/money_display.dart';

class GoalsProgressRow extends ConsumerWidget {
  const GoalsProgressRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(homeTopGoalsProvider);

    return goalsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Text('Could not load goals: $error'),
      data: (goals) {
        if (goals.isEmpty) {
          return const _EmptyGoalsMessage();
        }

        return Column(
          children: [
            for (var index = 0; index < goals.length; index++) ...[
              if (index > 0) const SizedBox(height: 12),
              _GoalProgressTile(goal: goals[index]),
            ],
          ],
        );
      },
    );
  }
}

class _GoalProgressTile extends StatelessWidget {
  const _GoalProgressTile({required this.goal});

  final SavingsGoal goal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = _goalProgress(goal);
    final emoji = goal.emoji?.trim();
    final titlePrefix = (emoji != null && emoji.isNotEmpty) ? '$emoji ' : '';

    return Card(
      key: Key('home-goal-${goal.id}'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$titlePrefix${goal.name}',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress.clamp(0, 1),
                minHeight: 8,
                backgroundColor: AppColors.tealPrimary.withValues(alpha: 0.15),
                color: AppColors.tealPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${MoneyDisplay.withCurrency(
                amount: goal.currentAmount,
                currencyCode: goal.currencyCode,
              )} of '
              '${MoneyDisplay.withCurrency(
                amount: goal.targetAmount,
                currencyCode: goal.currencyCode,
              )}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _goalProgress(SavingsGoal goal) {
    try {
      final target = Decimal.parse(goal.targetAmount);
      if (target <= Decimal.zero) {
        return 0;
      }
      final current = Decimal.parse(goal.currentAmount);
      return (current / target).toDouble();
    } catch (_) {
      return 0;
    }
  }
}

class _EmptyGoalsMessage extends StatelessWidget {
  const _EmptyGoalsMessage();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      'No active savings goals yet.',
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
      ),
    );
  }
}
