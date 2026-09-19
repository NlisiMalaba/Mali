import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mali_app/domain/entities/savings_goal.dart';
import 'package:mali_app/presentation/theme/app_colors.dart';
import 'package:mali_app/presentation/utils/goal_progress.dart';
import 'package:mali_app/presentation/utils/money_display.dart';
import 'package:mali_app/presentation/widgets/goal/goal_progress_ring.dart';

class GoalCard extends StatelessWidget {
  const GoalCard({
    required this.goal,
    this.onTap,
    this.now,
    super.key,
  });

  final SavingsGoal goal;
  final VoidCallback? onTap;

  /// Clock used for the countdown label. Defaults to the current time.
  final DateTime? now;

  static Key cardKey(String goalId) => Key('goal-card-$goalId');
  static const Key completedCheckKey = Key('goal-card-completed-check');
  static const double completedCheckSize = 18;

  void _openDetail(BuildContext context) {
    if (onTap != null) {
      onTap!();
      return;
    }
    context.push('/goals/${goal.id}');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = GoalProgress.ratio(goal);
    final percent = (progress.clamp(0.0, 1.0) * 100).round();
    final emoji = goal.emoji?.trim();
    final hasEmoji = emoji != null && emoji.isNotEmpty;
    final remaining = GoalProgress.remainingLabel(
      targetDate: goal.targetDate,
      now: now ?? DateTime.now(),
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openDetail(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Semantics(
                label: '${goal.name} progress',
                value: '$percent%',
                child: GoalProgressRing(
                  progress: progress,
                  child: hasEmoji
                      ? Text(
                          emoji,
                          style: theme.textTheme.titleLarge,
                        )
                      : Text(
                          '$percent%',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${MoneyDisplay.withCurrency(
                        amount: goal.currentAmount,
                        currencyCode: goal.currencyCode,
                      )} of '
                      '${MoneyDisplay.withCurrency(
                        amount: goal.targetAmount,
                        currencyCode: goal.currencyCode,
                      )}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.75,
                        ),
                      ),
                    ),
                    if (goal.isCompleted) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            key: GoalCard.completedCheckKey,
                            color: AppColors.success,
                            size: GoalCard.completedCheckSize,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Completed',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ] else if (remaining != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        remaining,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.65,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
