import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mali_app/application/providers/goal_providers.dart';
import 'package:mali_app/domain/entities/goal_contribution.dart';
import 'package:mali_app/domain/entities/savings_goal.dart';
import 'package:mali_app/domain/services/goal_required_monthly.dart';
import 'package:mali_app/presentation/utils/goal_progress.dart';
import 'package:mali_app/presentation/utils/money_display.dart';
import 'package:mali_app/presentation/widgets/goal/add_goal_sheet.dart';
import 'package:mali_app/presentation/widgets/goal/contribute_to_goal_sheet.dart';
import 'package:mali_app/presentation/widgets/goal/goal_contribution_tile.dart';
import 'package:mali_app/presentation/widgets/goal/goal_progress_ring.dart';
import 'package:mali_app/presentation/widgets/goal/required_this_month_card.dart';

class GoalDetailScreen extends ConsumerWidget {
  const GoalDetailScreen({
    required this.goalId,
    this.now,
    super.key,
  });

  static const Key screenKey = Key('goal-detail-screen');
  static const Key addContributionButtonKey = Key('add-contribution-button');
  static const Key editGoalButtonKey = Key('edit-goal-button');

  final String goalId;
  final DateTime? now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(activeGoalsProvider);
    final goal = goalsAsync.maybeWhen(
      data: _goalById,
      orElse: () => null,
    );

    return Scaffold(
      key: screenKey,
      appBar: AppBar(
        title: Text(goal?.name ?? 'Goal'),
        actions: [
          IconButton(
            key: editGoalButtonKey,
            tooltip: 'Edit goal',
            icon: const Icon(Icons.edit_outlined),
            onPressed: goal == null ? null : () => _openEdit(context, goal),
          ),
        ],
      ),
      body: goalsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Could not load goal: $error'),
          ),
        ),
        data: (goals) {
          final goal = _goalById(goals);
          if (goal == null) {
            return const Center(child: Text('Goal not found'));
          }
          return _GoalDetailBody(goal: goal, now: now);
        },
      ),
    );
  }

  SavingsGoal? _goalById(List<SavingsGoal> goals) {
    for (final goal in goals) {
      if (goal.id == goalId) {
        return goal;
      }
    }
    return null;
  }

  Future<void> _openEdit(BuildContext context, SavingsGoal goal) async {
    final updated = await AddGoalSheet.show(context, goal: goal);
    if (updated == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Goal updated.')),
      );
    }
  }
}

class _GoalDetailBody extends ConsumerWidget {
  const _GoalDetailBody({
    required this.goal,
    this.now,
  });

  final SavingsGoal goal;
  final DateTime? now;

  DateTime get _now => now ?? DateTime.now();

  Future<void> _openContribute(BuildContext context) async {
    final result = await ContributeToGoalSheet.show(context, goal: goal);
    if (!context.mounted || result == null) {
      return;
    }
    if (result.reachedMilestones.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contribution added.')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contributionsAsync = ref.watch(goalContributionsProvider(goal.id));
    final theme = Theme.of(context);
    final progress = GoalProgress.ratio(goal);
    final percent = (progress.clamp(0.0, 1.0) * 100).round();
    final emoji = goal.emoji?.trim();
    final hasEmoji = emoji != null && emoji.isNotEmpty;
    final remaining = GoalProgress.remainingLabel(
      targetDate: goal.targetDate,
      now: _now,
    );
    final requiredThisMonth = GoalRequiredMonthly.forGoal(
      goal: goal,
      now: _now,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Center(
          child: Semantics(
            label: '${goal.name} progress',
            value: '$percent%',
            child: GoalProgressRing(
              progress: progress,
              size: GoalProgressRing.detailSize,
              strokeWidth: GoalProgressRing.detailStrokeWidth,
              milestoneSize: GoalProgressRing.detailMilestoneSize,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasEmoji)
                    Text(emoji, style: theme.textTheme.headlineMedium),
                  Text(
                    '$percent%',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          goal.name,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
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
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge,
        ),
        if (remaining != null) ...[
          const SizedBox(height: 4),
          Text(
            remaining,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
            ),
          ),
        ],
        if (requiredThisMonth != null) ...[
          const SizedBox(height: 20),
          RequiredThisMonthCard(
            requiredThisMonth: requiredThisMonth,
            currencyCode: goal.currencyCode,
          ),
        ],
        const SizedBox(height: 20),
        FilledButton.icon(
          key: GoalDetailScreen.addContributionButtonKey,
          onPressed: () => _openContribute(context),
          icon: const Icon(Icons.add),
          label: const Text('Add Contribution'),
        ),
        const SizedBox(height: 28),
        Text(
          'Contribution history',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        contributionsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text('Could not load contributions: $error'),
          ),
          data: (contributions) => _ContributionHistory(
            contributions: contributions,
          ),
        ),
      ],
    );
  }
}

class _ContributionHistory extends StatelessWidget {
  const _ContributionHistory({required this.contributions});

  final List<GoalContribution> contributions;

  @override
  Widget build(BuildContext context) {
    if (contributions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'No contributions yet.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(
                      alpha: 0.65,
                    ),
              ),
        ),
      );
    }

    return Column(
      children: [
        for (var index = 0; index < contributions.length; index++) ...[
          if (index > 0) const Divider(height: 1),
          GoalContributionTile(contribution: contributions[index]),
        ],
      ],
    );
  }
}
