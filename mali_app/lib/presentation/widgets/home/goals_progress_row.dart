import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mali_app/application/providers/home_providers.dart';
import 'package:mali_app/domain/entities/savings_goal.dart';
import 'package:mali_app/presentation/theme/app_colors.dart';
import 'package:mali_app/presentation/theme/app_decorations.dart';
import 'package:mali_app/presentation/theme/app_typography.dart';
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
              if (index > 0) const SizedBox(height: 16),
              _GoalProgressTile(goal: goals[index], index: index),
            ],
          ],
        );
      },
    );
  }
}

class _GoalProgressTile extends StatelessWidget {
  const _GoalProgressTile({
    required this.goal,
    required this.index,
  });

  final SavingsGoal goal;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = _goalProgress(goal);
    final percent = (progress.clamp(0.0, 1.0) * 100).round();
    final emoji = goal.emoji?.trim();
    final progressColor = index.isEven
        ? AppColors.tertiary
        : AppColors.primaryContainer;
    final iconBg = index.isEven
        ? AppColors.tertiaryFixed
        : AppColors.primaryFixed;

    return Container(
      key: Key('home-goal-${goal.id}'),
      padding: const EdgeInsets.all(20),
      decoration: AppDecorations.ghostBorderCard(),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(AppDecorations.radiusMd),
                ),
                alignment: Alignment.center,
                child: emoji != null && emoji.isNotEmpty
                    ? Text(emoji, style: theme.textTheme.titleMedium)
                    : Icon(
                        Icons.flag_outlined,
                        color: progressColor,
                        size: 22,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'TARGET: ${MoneyDisplay.withCurrency(
                        amount: goal.targetAmount,
                        currencyCode: goal.currencyCode,
                      )}',
                      style: AppTypography.sectionLabel(context).copyWith(
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$percent%',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress.clamp(0, 1),
              minHeight: 8,
              backgroundColor: AppColors.surfaceContainerHigh,
              color: progressColor,
            ),
          ),
        ],
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
        color: AppColors.onSurfaceVariant,
      ),
    );
  }
}
