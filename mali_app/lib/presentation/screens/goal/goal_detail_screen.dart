import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mali_app/application/providers/goal_providers.dart';
import 'package:mali_app/domain/entities/goal_contribution.dart';
import 'package:mali_app/domain/entities/savings_goal.dart';
import 'package:mali_app/domain/services/goal_required_monthly.dart';
import 'package:mali_app/presentation/theme/app_colors.dart';
import 'package:mali_app/presentation/theme/app_typography.dart';
import 'package:mali_app/presentation/utils/goal_progress.dart';
import 'package:mali_app/presentation/utils/money_display.dart';
import 'package:mali_app/presentation/widgets/goal/add_goal_sheet.dart';
import 'package:mali_app/presentation/widgets/goal/contribute_to_goal_sheet.dart';
import 'package:mali_app/presentation/widgets/goal/goal_contribution_tile.dart';
import 'package:mali_app/presentation/widgets/goal/goal_milestones_card.dart';
import 'package:mali_app/presentation/widgets/goal/goal_savings_jar.dart';

class GoalDetailScreen extends ConsumerWidget {
  const GoalDetailScreen({
    required this.goalId,
    this.now,
    super.key,
  });

  static const Key screenKey = Key('goal-detail-screen');
  static const Key addContributionButtonKey = Key('add-contribution-button');
  static const Key editGoalButtonKey = Key('edit-goal-button');
  static const Key neededEachMonthKey = Key('needed-each-month-card');

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
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: goalsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Could not load goal: $error'),
            ),
          ),
          data: (goals) {
            final matched = _goalById(goals);
            if (matched == null) {
              return const Center(child: Text('Goal not found'));
            }
            return _GoalDetailBody(
              goal: matched,
              now: now,
              onEdit: () => _openEdit(context, matched),
            );
          },
        ),
      ),
      bottomNavigationBar: goal == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: SizedBox(
                  height: 56,
                  child: FilledButton(
                    key: addContributionButtonKey,
                    onPressed: () => _openContribute(context, goal),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.navy,
                      foregroundColor: AppColors.silver,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: const Text('Add money'),
                  ),
                ),
              ),
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

  Future<void> _openContribute(BuildContext context, SavingsGoal goal) async {
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
}

class _GoalDetailBody extends ConsumerWidget {
  const _GoalDetailBody({
    required this.goal,
    required this.onEdit,
    this.now,
  });

  final SavingsGoal goal;
  final VoidCallback onEdit;
  final DateTime? now;

  DateTime get _now => now ?? DateTime.now();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contributionsAsync = ref.watch(goalContributionsProvider(goal.id));
    final progress = GoalProgress.ratio(goal);
    final percent = (progress.clamp(0.0, 1.0) * 100).round();
    final requiredThisMonth = GoalRequiredMonthly.forGoal(
      goal: goal,
      now: _now,
    );
    final remainingAmount = _remainingAmount(goal);
    final savedLabel = MoneyDisplay.compact(
      amount: goal.currentAmount,
      currencyCode: goal.currencyCode,
      trimTrailingZeros: true,
    );
    final targetLabel = MoneyDisplay.compact(
      amount: goal.targetAmount,
      currencyCode: goal.currencyCode,
      trimTrailingZeros: true,
    );
    final remainingLabel = remainingAmount == null
        ? null
        : MoneyDisplay.compact(
            amount: remainingAmount.toString(),
            currencyCode: goal.currencyCode,
            trimTrailingZeros: true,
          );
    final trackChip = _trackChipLabel(
      goal: goal,
      requiredThisMonth: requiredThisMonth,
      now: _now,
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Row(
            children: [
              _HeaderIconButton(
                icon: Icons.chevron_left,
                tooltip: 'Back',
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  }
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  goal.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.money(
                    fontSize: 24,
                    color: AppColors.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _HeaderIconButton(
                key: GoalDetailScreen.editGoalButtonKey,
                icon: Icons.edit_outlined,
                tooltip: 'Edit goal',
                onPressed: onEdit,
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GoalSavingsJar(progress: progress),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$percent%',
                            style: AppTypography.money(
                              fontSize: 44,
                              color: AppColors.onSurface,
                            ),
                          ),
                          Text(
                            '$savedLabel saved',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            remainingLabel == null
                                ? 'of $targetLabel'
                                : 'of $targetLabel · $remainingLabel to go',
                            style: const TextStyle(
                              fontSize: 13.5,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                          if (trackChip != null) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: trackChip.background,
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: Text(
                                trackChip.label,
                                style: TextStyle(
                                  color: trackChip.foreground,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _MetaCard(
                      key: GoalDetailScreen.neededEachMonthKey,
                      label: 'Needed each month',
                      value: requiredThisMonth == null
                          ? '—'
                          : MoneyDisplay.compact(
                              amount: requiredThisMonth.amount.toString(),
                              currencyCode: goal.currencyCode,
                              trimTrailingZeros: true,
                            ),
                      navy: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MetaCard(
                      label: 'Target date',
                      value: goal.targetDate == null
                          ? '—'
                          : DateFormat('d MMM yyyy').format(goal.targetDate!),
                      navy: false,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              GoalMilestonesCard(goal: goal, now: _now),
              const SizedBox(height: 14),
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
          ),
        ),
      ],
    );
  }

  static Decimal? _remainingAmount(SavingsGoal goal) {
    try {
      final target = Decimal.parse(goal.targetAmount);
      final current = Decimal.parse(goal.currentAmount);
      final remaining = target - current;
      return remaining < Decimal.zero ? Decimal.zero : remaining;
    } catch (_) {
      return null;
    }
  }

  static ({String label, Color background, Color foreground})? _trackChipLabel({
    required SavingsGoal goal,
    required RequiredThisMonth? requiredThisMonth,
    required DateTime now,
  }) {
    if (goal.isCompleted) {
      return (
        label: 'Goal achieved',
        background: AppColors.successContainer,
        foreground: AppColors.success,
      );
    }
    final deadline = goal.targetDate;
    if (deadline == null) {
      return null;
    }
    final monthLabel = DateFormat('MMMM yyyy').format(deadline);
    if (requiredThisMonth?.isBehindSchedule == true) {
      return (
        label: 'Behind for $monthLabel',
        background: AppColors.warningContainer,
        foreground: AppColors.warningText,
      );
    }
    return (
      label: 'On track for $monthLabel',
      background: AppColors.successContainer,
      foreground: AppColors.success,
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFFE1E5EE), width: 0.8),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, size: 20, color: AppColors.onSurface),
          ),
        ),
      ),
    );
  }
}

class _MetaCard extends StatelessWidget {
  const _MetaCard({
    required this.label,
    required this.value,
    required this.navy,
    super.key,
  });

  final String label;
  final String value;
  final bool navy;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 72),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: navy ? AppColors.navy : AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.2,
              color: navy ? AppColors.onNavyMuted : AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.money(
              fontSize: 20,
              color: navy ? AppColors.silver : AppColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContributionHistory extends StatelessWidget {
  const _ContributionHistory({required this.contributions});

  final List<GoalContribution> contributions;

  @override
  Widget build(BuildContext context) {
    if (contributions.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          'No contributions yet.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          for (var index = 0; index < contributions.length; index++)
            GoalContributionTile(
              contribution: contributions[index],
              showDivider: index > 0,
            ),
        ],
      ),
    );
  }
}
