import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:mali_app/domain/entities/savings_goal.dart';
import 'package:mali_app/domain/services/goal_required_monthly.dart';
import 'package:mali_app/presentation/theme/app_colors.dart';
import 'package:mali_app/presentation/utils/goal_progress.dart';
import 'package:mali_app/presentation/utils/money_display.dart';

/// Milestone track (25 / 50 / 75 / 100) with next-target copy.
class GoalMilestonesCard extends StatelessWidget {
  const GoalMilestonesCard({
    required this.goal,
    this.now,
    super.key,
  });

  static const Key cardKey = Key('goal-milestones-card');
  static const List<double> markers = [0.25, 0.50, 0.75, 1.0];

  final SavingsGoal goal;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final progress = GoalProgress.ratio(goal).clamp(0.0, 1.0);
    final next = _nextMilestone(goal: goal, progress: progress, now: now);

    return Container(
      key: cardKey,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Milestones',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppColors.onSurface,
                ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 28,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final trackWidth = constraints.maxWidth - 28;
                return Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Positioned(
                      left: 14,
                      right: 14,
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCE1EC),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 14,
                      child: Container(
                        width: trackWidth * progress,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    for (var i = 0; i < markers.length; i++)
                      Positioned(
                        left: (trackWidth * markers[i]),
                        child: _MilestoneDot(
                          label: (markers[i] * 100).round().toString(),
                          reached: progress + 0.001 >= markers[i],
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          if (next != null) ...[
            const SizedBox(height: 16),
            Text(
              next,
              style: const TextStyle(
                color: AppColors.onSurfaceVariant,
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String? _nextMilestone({
    required SavingsGoal goal,
    required double progress,
    DateTime? now,
  }) {
    double? nextFraction;
    for (final marker in markers) {
      if (progress + 0.001 < marker) {
        nextFraction = marker;
        break;
      }
    }
    if (nextFraction == null) {
      return null;
    }

    try {
      final target = Decimal.parse(goal.targetAmount);
      final milestoneAmount =
          (target * Decimal.parse(nextFraction.toString()))
              .round(scale: 2);
      final percent = (nextFraction * 100).round();
      final amountLabel = MoneyDisplay.compact(
        amount: milestoneAmount.toString(),
        currencyCode: goal.currencyCode,
        trimTrailingZeros: true,
      );

      final monthsAway = _monthsUntilMilestone(
        goal: goal,
        milestoneAmount: milestoneAmount,
        now: now ?? DateTime.now(),
      );
      final timing = switch (monthsAway) {
        null => null,
        <= 0 => 'less than a month away',
        1 => 'about 1 month away',
        _ => 'about $monthsAway months away',
      };

      if (timing == null) {
        return 'Next: $percent% at $amountLabel';
      }
      return 'Next: $percent% at $amountLabel — $timing';
    } catch (_) {
      return null;
    }
  }

  static int? _monthsUntilMilestone({
    required SavingsGoal goal,
    required Decimal milestoneAmount,
    required DateTime now,
  }) {
    try {
      final current = Decimal.parse(goal.currentAmount);
      final remaining = milestoneAmount - current;
      if (remaining <= Decimal.zero) {
        return 0;
      }
      final deadline = goal.targetDate;
      if (deadline == null) {
        return null;
      }
      final monthly = GoalRequiredMonthly.amount(
        targetAmount: goal.targetAmount,
        savedAmount: goal.currentAmount,
        now: now,
        deadline: deadline,
      );
      if (monthly == null || monthly <= Decimal.zero) {
        return null;
      }
      final months = (remaining / monthly).toDouble().ceil();
      return months < 0 ? 0 : months;
    } catch (_) {
      return null;
    }
  }
}

class _MilestoneDot extends StatelessWidget {
  const _MilestoneDot({
    required this.label,
    required this.reached,
  });

  final String label;
  final bool reached;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: reached ? AppColors.success : AppColors.surfaceContainerLowest,
        shape: BoxShape.circle,
        border: reached
            ? null
            : Border.all(color: const Color(0xFFC8CFDD), width: 1.6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: reached ? Colors.white : AppColors.onSurfaceVariant,
        ),
      ),
    );
  }
}
