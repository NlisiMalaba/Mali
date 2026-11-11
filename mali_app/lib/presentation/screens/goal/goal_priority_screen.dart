import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mali_app/application/providers/goal_providers.dart';
import 'package:mali_app/application/providers/use_case_providers.dart';
import 'package:mali_app/domain/entities/savings_goal.dart';
import 'package:mali_app/presentation/theme/app_colors.dart';
import 'package:mali_app/presentation/theme/app_typography.dart';
import 'package:mali_app/presentation/utils/goal_order_funding_hint.dart';
import 'package:mali_app/presentation/utils/goal_progress.dart';
import 'package:mali_app/presentation/widgets/common/animated_progress_bar.dart';

class GoalPriorityScreen extends ConsumerStatefulWidget {
  const GoalPriorityScreen({
    this.now,
    super.key,
  });

  static const Key screenKey = Key('goal-priority-screen');
  static const Key listKey = Key('goal-priority-list');
  static const Key saveButtonKey = Key('goal-priority-save');

  static Key tileKey(String goalId) => Key('goal-priority-tile-$goalId');

  static Key dragHandleKey(String goalId) =>
      Key('goal-priority-handle-$goalId');

  static Key moveUpKey(String goalId) => Key('goal-priority-up-$goalId');

  static Key moveDownKey(String goalId) => Key('goal-priority-down-$goalId');

  final DateTime? now;

  @override
  ConsumerState<GoalPriorityScreen> createState() => _GoalPriorityScreenState();
}

class _GoalPriorityScreenState extends ConsumerState<GoalPriorityScreen> {
  List<SavingsGoal>? _ordered;
  List<String>? _baselineIds;
  bool _isSaving = false;

  DateTime get _now => widget.now ?? DateTime.now();

  bool _isDirty(List<SavingsGoal> displayed) {
    final baseline = _baselineIds;
    if (baseline == null) {
      return false;
    }
    if (baseline.length != displayed.length) {
      return true;
    }
    for (var i = 0; i < displayed.length; i++) {
      if (baseline[i] != displayed[i].id) {
        return true;
      }
    }
    return false;
  }

  void _move({
    required int index,
    required int delta,
    required List<SavingsGoal> displayed,
  }) {
    final target = index + delta;
    if (target < 0 || target >= displayed.length || _isSaving) {
      return;
    }
    final current = [...(_ordered ?? displayed)];
    final moved = current.removeAt(index);
    current.insert(target, moved);
    setState(() => _ordered = current);
  }

  Future<void> _save(List<SavingsGoal> displayed) async {
    if (_isSaving || !_isDirty(displayed)) {
      return;
    }

    setState(() => _isSaving = true);
    final result = await ref.read(reorderGoalsUseCaseProvider)(
      orderedGoalIds: [for (final goal in displayed) goal.id],
    );
    if (!mounted) {
      return;
    }
    setState(() => _isSaving = false);

    final failure = result.fold((left) => left, (_) => null);
    if (failure != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure.message)),
      );
      return;
    }

    setState(() {
      _baselineIds = [for (final goal in displayed) goal.id];
      _ordered = displayed;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Goal order saved.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final goalsAsync = ref.watch(activeGoalsProvider);

    return Scaffold(
      key: GoalPriorityScreen.screenKey,
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: goalsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Could not load goals: $error'),
            ),
          ),
          data: (goals) {
            if (goals.isEmpty) {
              return Column(
                children: [
                  const _Header(),
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Add a goal before setting priority.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }

            _baselineIds ??= [for (final goal in goals) goal.id];
            final ordered = _ordered ?? goals;
            final dirty = _isDirty(ordered);

            return Column(
              children: [
                const _Header(),
                Expanded(
                  child: ListView(
                    key: GoalPriorityScreen.listKey,
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                    children: [
                      const _ExplainerCard(),
                      const SizedBox(height: 16),
                      for (var index = 0; index < ordered.length; index++) ...[
                        if (index > 0) const SizedBox(height: 12),
                        _PriorityTile(
                          goal: ordered[index],
                          index: index,
                          total: ordered.length,
                          now: _now,
                          onMoveUp: () => _move(
                            index: index,
                            delta: -1,
                            displayed: ordered,
                          ),
                          onMoveDown: () => _move(
                            index: index,
                            delta: 1,
                            displayed: ordered,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: FilledButton(
                        key: GoalPriorityScreen.saveButtonKey,
                        onPressed: (!dirty || _isSaving)
                            ? null
                            : () => _save(ordered),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.navy,
                          foregroundColor: AppColors.silver,
                          disabledBackgroundColor:
                              AppColors.navy.withValues(alpha: 0.45),
                          disabledForegroundColor:
                              AppColors.silver.withValues(alpha: 0.7),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        child: Text(_isSaving ? 'Saving…' : 'Save order'),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Row(
        children: [
          Material(
            color: AppColors.surfaceContainerLowest,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: Color(0xFFE1E5EE), width: 0.8),
            ),
            child: InkWell(
              onTap: () {
                if (context.canPop()) {
                  context.pop();
                }
              },
              borderRadius: BorderRadius.circular(14),
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Icon(
                  Icons.chevron_left,
                  size: 20,
                  color: AppColors.onSurface,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Goal order',
            style: AppTypography.money(
              fontSize: 26,
              color: AppColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExplainerCard extends StatelessWidget {
  const _ExplainerCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.silver,
              borderRadius: BorderRadius.circular(11),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.south_rounded,
              size: 22,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: const TextStyle(
                  color: AppColors.onPrimary,
                  fontSize: 14,
                  height: 1.45,
                  fontWeight: FontWeight.w400,
                ),
                children: const [
                  TextSpan(
                    text: "Each month's leftover money fills ",
                  ),
                  TextSpan(
                    text: '#1 first',
                    style: TextStyle(
                      color: AppColors.silver,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(
                    text:
                        ', then flows down the list. Move goals to change what gets funded first.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PriorityTile extends StatelessWidget {
  const _PriorityTile({
    required this.goal,
    required this.index,
    required this.total,
    required this.now,
    required this.onMoveUp,
    required this.onMoveDown,
  });

  final SavingsGoal goal;
  final int index;
  final int total;
  final DateTime now;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;

  @override
  Widget build(BuildContext context) {
    final progress = GoalProgress.ratio(goal).clamp(0.0, 1.0);
    final percent = (progress * 100).round();
    final isFirst = index == 0;
    final barColor = switch (index) {
      0 => AppColors.success,
      1 => AppColors.info,
      _ => const Color(0xFFC96F00),
    };
    final hint = GoalOrderFundingHint.forIndex(
      index: index,
      goal: goal,
      now: now,
    );

    return Container(
      key: GoalPriorityScreen.tileKey(goal.id),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 16, 10, 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: isFirst ? 0.18 : 0.05),
            blurRadius: isFirst ? 26 : 6,
            offset: Offset(0, isFirst ? 14 : 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isFirst ? AppColors.navy : AppColors.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${index + 1}',
              style: AppTypography.money(
                fontSize: 17,
                color: isFirst
                    ? AppColors.silver
                    : const Color(0xFF3A4560),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        goal.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ),
                    Text(
                      '$percent%',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                AnimatedProgressBar(
                  value: progress,
                  color: barColor,
                  backgroundColor: AppColors.surfaceContainer,
                  height: 6,
                ),
                const SizedBox(height: 8),
                Text(
                  hint,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Column(
            key: GoalPriorityScreen.dragHandleKey(goal.id),
            children: [
              _MoveButton(
                key: GoalPriorityScreen.moveUpKey(goal.id),
                icon: Icons.keyboard_arrow_up_rounded,
                enabled: index > 0,
                onPressed: onMoveUp,
              ),
              const SizedBox(height: 8),
              _MoveButton(
                key: GoalPriorityScreen.moveDownKey(goal.id),
                icon: Icons.keyboard_arrow_down_rounded,
                enabled: index < total - 1,
                onPressed: onMoveDown,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MoveButton extends StatelessWidget {
  const _MoveButton({
    required this.icon,
    required this.enabled,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: enabled ? onPressed : null,
      icon: Icon(icon, size: 20),
      color: AppColors.onSurface,
      disabledColor: AppColors.onSurface.withValues(alpha: 0.3),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
      tooltip: enabled ? 'Move' : null,
    );
  }
}
