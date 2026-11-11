import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mali_app/domain/entities/savings_goal.dart';
import 'package:mali_app/domain/services/goal_required_monthly.dart';
import 'package:mali_app/presentation/theme/app_colors.dart';
import 'package:mali_app/presentation/theme/app_decorations.dart';
import 'package:mali_app/presentation/theme/app_typography.dart';
import 'package:mali_app/presentation/utils/goal_progress.dart';
import 'package:mali_app/presentation/utils/money_display.dart';
import 'package:mali_app/presentation/widgets/common/pressable_scale.dart';
import 'package:mali_app/presentation/widgets/goal/contribute_to_goal_sheet.dart';
import 'package:mali_app/presentation/widgets/goal/goal_progress_ring.dart';

/// Navy “TOP PRIORITY” hero for the first savings goal on the Goals tab.
class GoalPriorityHero extends StatelessWidget {
  const GoalPriorityHero({
    required this.goal,
    this.now,
    this.onAddMoney,
    super.key,
  });

  static const Key heroKey = Key('goal-priority-hero');
  static const Key addMoneyKey = Key('goal-priority-add-money');
  static const Color _orbitDot = Color(0xFF5A73B0);

  final SavingsGoal goal;
  final DateTime? now;
  final VoidCallback? onAddMoney;

  Future<void> _openContribute(BuildContext context) async {
    if (onAddMoney != null) {
      onAddMoney!();
      return;
    }
    await ContributeToGoalSheet.show(context, goal: goal);
  }

  void _openDetail(BuildContext context) {
    context.push('/goals/${goal.id}');
  }

  @override
  Widget build(BuildContext context) {
    final effectiveNow = now ?? DateTime.now();
    final progress = GoalProgress.ratio(goal);
    final percent = (progress.clamp(0.0, 1.0) * 100).round();
    final milestoneBadge = _passedMilestoneLabel(progress);
    final tip = _monthlyTip(goal: goal, now: effectiveNow);
    final saved = MoneyDisplay.compact(
      amount: goal.currentAmount,
      currencyCode: goal.currencyCode,
      trimTrailingZeros: true,
    );
    final target = MoneyDisplay.compact(
      amount: goal.targetAmount,
      currencyCode: goal.currencyCode,
      trimTrailingZeros: true,
    );

    return Container(
      key: heroKey,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: AppDecorations.heroCard(),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'TOP PRIORITY',
                style: AppTypography.sectionLabel(context).copyWith(
                  color: AppColors.onNavyMuted,
                  letterSpacing: 0.6,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (milestoneBadge != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.silver,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star_border_rounded,
                        size: 12,
                        color: AppColors.navy,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        milestoneBadge,
                        style: const TextStyle(
                          color: AppColors.navy,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: GoalProgressRing.heroSize,
            height: GoalProgressRing.heroSize,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Positioned(
                  top: 2,
                  child: _OrbitDot(size: 8, color: AppColors.silver),
                ),
                const Positioned(
                  right: 2,
                  child: _OrbitDot(size: 5, color: _orbitDot),
                ),
                const Positioned(
                  left: 22,
                  bottom: 18,
                  child: _OrbitDot(size: 6, color: _orbitDot),
                ),
                GoalProgressRing(
                  progress: progress,
                  size: GoalProgressRing.heroSize,
                  strokeWidth: GoalProgressRing.heroStrokeWidth,
                  showMilestones: false,
                  progressColor: AppColors.silver,
                  trackColor: AppColors.navyRaised,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$percent%',
                        style: AppTypography.money(
                          fontSize: 46,
                          color: AppColors.onPrimary,
                        ),
                      ),
                      Text(
                        '$saved of $target',
                        style: const TextStyle(
                          color: AppColors.onNavyMuted,
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          PressableScale(
            onTap: () => _openDetail(context),
            child: Text(
              '${goal.name} ›',
              textAlign: TextAlign.center,
              style: AppTypography.money(
                fontSize: 22,
                color: AppColors.onPrimary,
              ),
            ),
          ),
          if (tip != null) ...[
            const SizedBox(height: 8),
            Text.rich(
              TextSpan(
                style: const TextStyle(
                  color: AppColors.onNavyMuted,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                children: [
                  const TextSpan(text: 'Put away '),
                  TextSpan(
                    text: tip.monthlyLabel,
                    style: const TextStyle(
                      color: AppColors.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(text: ' to finish by ${tip.deadlineLabel}'),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              key: addMoneyKey,
              onPressed: goal.isCompleted
                  ? null
                  : () => _openContribute(context),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.silver,
                foregroundColor: AppColors.navy,
                disabledBackgroundColor:
                    AppColors.silver.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: const Text('Add money to this goal'),
            ),
          ),
        ],
      ),
    );
  }

  static String? _passedMilestoneLabel(double progress) {
    final clamped = progress.clamp(0.0, 1.0);
    String? label;
    for (final fraction in GoalProgress.milestoneFractions) {
      if (clamped >= fraction) {
        label = 'Passed ${(fraction * 100).round()}%';
      }
    }
    return label;
  }

  static ({String monthlyLabel, String deadlineLabel})? _monthlyTip({
    required SavingsGoal goal,
    required DateTime now,
  }) {
    final deadline = goal.targetDate;
    if (deadline == null || goal.isCompleted) {
      return null;
    }

    final monthly = GoalRequiredMonthly.amount(
      targetAmount: goal.targetAmount,
      savedAmount: goal.currentAmount,
      now: now,
      deadline: deadline,
    );
    if (monthly == null) {
      return null;
    }

    final amount = MoneyDisplay.compact(
      amount: monthly.toString(),
      currencyCode: goal.currencyCode,
      trimTrailingZeros: true,
    );
    return (
      monthlyLabel: '$amount a month',
      deadlineLabel: DateFormat('MMMM yyyy').format(deadline),
    );
  }
}

class _OrbitDot extends StatelessWidget {
  const _OrbitDot({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
