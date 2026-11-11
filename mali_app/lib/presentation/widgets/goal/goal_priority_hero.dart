import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mali_app/domain/entities/savings_goal.dart';
import 'package:mali_app/domain/services/goal_required_monthly.dart';
import 'package:mali_app/presentation/theme/app_colors.dart';
import 'package:mali_app/presentation/theme/app_decorations.dart';
import 'package:mali_app/presentation/theme/app_motion.dart';
import 'package:mali_app/presentation/theme/app_typography.dart';
import 'package:mali_app/presentation/utils/goal_progress.dart';
import 'package:mali_app/presentation/utils/money_display.dart';
import 'package:mali_app/presentation/widgets/common/pressable_scale.dart';
import 'package:mali_app/presentation/widgets/goal/contribute_to_goal_sheet.dart';
import 'package:mali_app/presentation/widgets/goal/goal_progress_ring.dart';

/// Navy “TOP PRIORITY” hero for the first savings goal on the Goals tab.
class GoalPriorityHero extends StatefulWidget {
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

  @override
  State<GoalPriorityHero> createState() => _GoalPriorityHeroState();
}

class _GoalPriorityHeroState extends State<GoalPriorityHero>
    with TickerProviderStateMixin {
  late final AnimationController _entrance;
  late final AnimationController _ambient;
  late final Animation<double> _entranceCurve;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4800),
    );
    _entranceCurve = CurvedAnimation(
      parent: _entrance,
      curve: AppMotion.standard,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion) {
      _entrance.value = 1;
      if (_ambient.isAnimating) {
        _ambient.stop();
      }
      _ambient.value = 0;
      return;
    }

    if (_entrance.status == AnimationStatus.dismissed) {
      _entrance.forward();
    }
    if (!_ambient.isAnimating) {
      _ambient.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _entrance.dispose();
    _ambient.dispose();
    super.dispose();
  }

  Future<void> _openContribute(BuildContext context) async {
    if (widget.onAddMoney != null) {
      widget.onAddMoney!();
      return;
    }
    await ContributeToGoalSheet.show(context, goal: widget.goal);
  }

  void _openDetail(BuildContext context) {
    context.push('/goals/${widget.goal.id}');
  }

  @override
  Widget build(BuildContext context) {
    final goal = widget.goal;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final effectiveNow = widget.now ?? DateTime.now();
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

    return AnimatedBuilder(
      animation: Listenable.merge([_entranceCurve, _ambient]),
      builder: (context, _) {
        final enter = _entranceCurve.value;
        final float = reduceMotion
            ? 0.0
            : math.sin(_ambient.value * math.pi) * 5;
        final glow = reduceMotion
            ? 0.35
            : 0.22 + (math.sin(_ambient.value * math.pi) * 0.18);

        return Opacity(
          opacity: enter.clamp(0.0, 1.0),
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0012)
              ..translateByDouble(0, (1 - enter) * 28 + float * 0.35, 0, 1)
              ..rotateX(-0.06 + (1 - enter) * 0.2)
              ..scaleByDouble(
                0.94 + 0.06 * enter,
                0.94 + 0.06 * enter,
                1,
                1,
              ),
            child: Container(
              key: GoalPriorityHero.heroKey,
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
                        _MilestoneBadge(
                          label: milestoneBadge,
                          enter: enter,
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: GoalProgressRing.heroSize,
                    height: GoalProgressRing.heroSize,
                    child: Transform.translate(
                      offset: Offset(0, float),
                      child: Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: [
                          _RingGlow(intensity: glow),
                          _OrbitDots(
                            ambient: reduceMotion ? 0 : _ambient.value,
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
                  PressableScale(
                    key: GoalPriorityHero.addMoneyKey,
                    onTap: goal.isCompleted
                        ? null
                        : () => _openContribute(context),
                    child: AnimatedOpacity(
                      duration: AppMotion.fast,
                      opacity: goal.isCompleted ? 0.5 : 1,
                      child: Container(
                        width: double.infinity,
                        height: 52,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.silver,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text(
                          'Add money to this goal',
                          style: TextStyle(
                            color: AppColors.navy,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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

class _MilestoneBadge extends StatelessWidget {
  const _MilestoneBadge({
    required this.label,
    required this.enter,
  });

  final String label;
  final double enter;

  @override
  Widget build(BuildContext context) {
    final scale = 0.85 + 0.15 * Curves.easeOutBack.transform(enter);
    return Transform.scale(
      scale: scale,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.silver,
          borderRadius: BorderRadius.circular(99),
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
              label,
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RingGlow extends StatelessWidget {
  const _RingGlow({required this.intensity});

  final double intensity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.silver.withValues(alpha: intensity * 0.45),
              blurRadius: 42,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }
}

class _OrbitDots extends StatelessWidget {
  const _OrbitDots({required this.ambient});

  final double ambient;

  @override
  Widget build(BuildContext context) {
    final phase = ambient * math.pi * 2;
    final topBob = math.sin(phase) * 3;
    final rightBob = math.cos(phase) * 4;
    final leftBob = math.sin(phase + 1.2) * 3.5;

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          top: 2 + topBob,
          left: 0,
          right: 0,
          child: const Center(
            child: _OrbitDot(size: 8, color: AppColors.silver),
          ),
        ),
        Positioned(
          right: 2 + rightBob.abs() * 0.2,
          top: 96 + rightBob,
          child: const _OrbitDot(
            size: 5,
            color: GoalPriorityHero._orbitDot,
          ),
        ),
        Positioned(
          left: 22 + leftBob.abs() * 0.15,
          bottom: 18 + leftBob,
          child: const _OrbitDot(
            size: 6,
            color: GoalPriorityHero._orbitDot,
          ),
        ),
      ],
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
