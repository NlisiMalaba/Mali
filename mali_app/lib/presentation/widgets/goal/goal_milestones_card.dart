import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:mali_app/domain/entities/savings_goal.dart';
import 'package:mali_app/domain/services/goal_required_monthly.dart';
import 'package:mali_app/presentation/theme/app_colors.dart';
import 'package:mali_app/presentation/theme/app_motion.dart';
import 'package:mali_app/presentation/utils/goal_progress.dart';
import 'package:mali_app/presentation/utils/money_display.dart';

/// Milestone track (25 / 50 / 75 / 100) with next-target copy.
class GoalMilestonesCard extends StatefulWidget {
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
  State<GoalMilestonesCard> createState() => _GoalMilestonesCardState();
}

class _GoalMilestonesCardState extends State<GoalMilestonesCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progress;
  late final Animation<double> _progressCurve;

  @override
  void initState() {
    super.initState();
    _progress = AnimationController(
      vsync: this,
      duration: AppMotion.progress,
    );
    _progressCurve = CurvedAnimation(
      parent: _progress,
      curve: AppMotion.standard,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _progress.value = 1;
      return;
    }
    if (_progress.status == AnimationStatus.dismissed) {
      _progress.forward();
    }
  }

  @override
  void didUpdateWidget(covariant GoalMilestonesCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.goal.currentAmount != widget.goal.currentAmount &&
        !MediaQuery.disableAnimationsOf(context)) {
      _progress
        ..value = 0
        ..forward();
    }
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = GoalProgress.ratio(widget.goal).clamp(0.0, 1.0);
    final next = _nextMilestone(
      goal: widget.goal,
      progress: progress,
      now: widget.now,
    );

    return Container(
      key: GoalMilestonesCard.cardKey,
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
            child: AnimatedBuilder(
              animation: _progressCurve,
              builder: (context, _) {
                final animated = progress * _progressCurve.value;
                return LayoutBuilder(
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
                            width: trackWidth * animated,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.success,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        for (var i = 0; i < GoalMilestonesCard.markers.length; i++)
                          Positioned(
                            left: trackWidth * GoalMilestonesCard.markers[i],
                            child: _MilestoneDot(
                              label: (GoalMilestonesCard.markers[i] * 100)
                                  .round()
                                  .toString(),
                              reached: animated + 0.001 >=
                                  GoalMilestonesCard.markers[i],
                              highlight: progress + 0.001 >=
                                      GoalMilestonesCard.markers[i] &&
                                  _progressCurve.value > 0.85,
                            ),
                          ),
                      ],
                    );
                  },
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
    for (final marker in GoalMilestonesCard.markers) {
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
          (target * Decimal.parse(nextFraction.toString())).round(scale: 2);
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
    required this.highlight,
  });

  final String label;
  final bool reached;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: reached && highlight ? 1.08 : 1,
      duration: AppMotion.fast,
      curve: AppMotion.standard,
      child: AnimatedContainer(
        duration: AppMotion.normal,
        curve: AppMotion.standard,
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: reached ? AppColors.success : AppColors.surfaceContainerLowest,
          shape: BoxShape.circle,
          border: reached
              ? null
              : Border.all(color: const Color(0xFFC8CFDD), width: 1.6),
          boxShadow: reached && highlight
              ? [
                  BoxShadow(
                    color: AppColors.success.withValues(alpha: 0.35),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: reached ? Colors.white : AppColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
