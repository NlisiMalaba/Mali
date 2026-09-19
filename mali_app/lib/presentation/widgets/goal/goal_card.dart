import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mali_app/domain/entities/savings_goal.dart';
import 'package:mali_app/presentation/theme/app_colors.dart';
import 'package:mali_app/presentation/theme/app_decorations.dart';
import 'package:mali_app/presentation/theme/app_typography.dart';
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

    return GestureDetector(
      key: GoalCard.cardKey(goal.id),
      onTap: () => _openDetail(context),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: AppDecorations.surfaceCard(
          radius: AppDecorations.radiusHero,
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Securing your future',
                        style: AppTypography.sectionLabel(context).copyWith(
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: hasEmoji
                      ? Center(
                          child: Text(emoji, style: theme.textTheme.titleMedium),
                        )
                      : const Icon(
                          Icons.shield,
                          color: AppColors.primary,
                          size: 22,
                        ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Semantics(
              label: '${goal.name} progress',
              value: '$percent%',
              child: GoalProgressRing(
                progress: progress,
                size: 128,
                strokeWidth: 8,
                child: Text(
                  '$percent%',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SAVED',
                        style: AppTypography.sectionLabel(context).copyWith(
                          fontSize: 10,
                        ),
                      ),
                      Text(
                        MoneyDisplay.withCurrency(
                          amount: goal.currentAmount,
                          currencyCode: goal.currencyCode,
                        ),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'TARGET',
                      style: AppTypography.sectionLabel(context).copyWith(
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      MoneyDisplay.withCurrency(
                        amount: goal.targetAmount,
                        currencyCode: goal.currencyCode,
                      ),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (goal.isCompleted) ...[
              const SizedBox(height: 12),
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
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.only(top: 16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: AppColors.outlineVariant.withValues(alpha: 0.4),
                      style: BorderStyle.solid,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      remaining,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: AppColors.surfaceContainerHigh,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
