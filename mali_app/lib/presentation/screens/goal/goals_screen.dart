import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mali_app/application/providers/goal_providers.dart';
import 'package:mali_app/presentation/theme/app_colors.dart';
import 'package:mali_app/presentation/theme/app_typography.dart';
import 'package:mali_app/presentation/widgets/common/fade_slide_in.dart';
import 'package:mali_app/presentation/widgets/goal/add_goal_sheet.dart';
import 'package:mali_app/presentation/widgets/goal/goal_list_tile.dart';
import 'package:mali_app/presentation/widgets/goal/goal_priority_hero.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  static const Key screenKey = Key('goals-screen');
  static const Key reorderButtonKey = Key('reorder-goals-button');
  static const Key newGoalButtonKey = Key('new-goal-button');

  Future<void> _openAddGoal(BuildContext context) async {
    final created = await AddGoalSheet.show(context);
    if (created == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Goal added.')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(activeGoalsProvider);

    return Scaffold(
      key: screenKey,
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
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
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: _GoalsHeader(
                      onNewGoal: () => _openAddGoal(context),
                    ),
                  ),
                  Expanded(
                    child: _EmptyGoals(onAdd: () => _openAddGoal(context)),
                  ),
                ],
              );
            }

            final topGoal = goals.first;
            final otherGoals = goals.skip(1).toList();

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                _GoalsHeader(onNewGoal: () => _openAddGoal(context)),
                const SizedBox(height: 18),
                FadeSlideIn(
                  index: 0,
                  child: GoalPriorityHero(goal: topGoal),
                ),
                if (otherGoals.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Also saving for',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: AppColors.onSurface,
                              ),
                        ),
                      ),
                      TextButton(
                        key: reorderButtonKey,
                        onPressed: () => context.push('/goals/priority'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.link,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 8,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Change order',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...otherGoals.asMap().entries.map(
                    (entry) => Padding(
                      padding: EdgeInsets.only(
                        bottom: entry.key == otherGoals.length - 1 ? 0 : 16,
                      ),
                      child: FadeSlideIn(
                        index: entry.key + 1,
                        child: GoalListTile(
                          goal: entry.value,
                          index: entry.key,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _GoalsHeader extends StatelessWidget {
  const _GoalsHeader({required this.onNewGoal});

  final VoidCallback onNewGoal;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Goals',
            style: AppTypography.money(
              fontSize: 30,
              color: AppColors.onSurface,
            ),
          ),
        ),
        FilledButton.icon(
          key: GoalsScreen.newGoalButtonKey,
          onPressed: onNewGoal,
          icon: const Icon(Icons.add, size: 16),
          label: const Text('New goal'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.navy,
            foregroundColor: AppColors.silver,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyGoals extends StatelessWidget {
  const _EmptyGoals({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'No savings goals yet',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Create a goal to track what you are saving for.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add your first goal'),
            ),
          ],
        ),
      ),
    );
  }
}
