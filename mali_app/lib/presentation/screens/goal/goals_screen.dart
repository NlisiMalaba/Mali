import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mali_app/application/providers/goal_providers.dart';
import 'package:mali_app/presentation/widgets/goal/add_goal_sheet.dart';
import 'package:mali_app/presentation/widgets/goal/goal_card.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  static const Key screenKey = Key('goals-screen');
  static const Key addGoalFabKey = Key('add-goal-fab');
  static const Key reorderButtonKey = Key('reorder-goals-button');

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
    final theme = Theme.of(context);

    return Scaffold(
      key: screenKey,
      appBar: AppBar(
        title: const Text('Goals'),
        actions: [
          if (goalsAsync.maybeWhen(
            data: (goals) => goals.isNotEmpty,
            orElse: () => false,
          ))
            IconButton(
              key: reorderButtonKey,
              tooltip: 'Reorder goals',
              icon: const Icon(Icons.swap_vert),
              onPressed: () => context.push('/goals/priority'),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        key: addGoalFabKey,
        heroTag: 'add-goal-fab',
        onPressed: () => _openAddGoal(context),
        tooltip: 'Add Goal',
        child: const Icon(Icons.add),
      ),
      body: goalsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Could not load goals: $error'),
          ),
        ),
        data: (goals) {
          if (goals.isEmpty) {
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
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: () => _openAddGoal(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Add your first goal'),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
            itemCount: goals.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final goal = goals[index];
              return GoalCard(
                key: GoalCard.cardKey(goal.id),
                goal: goal,
              );
            },
          );
        },
      ),
    );
  }
}
