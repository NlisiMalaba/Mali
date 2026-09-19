import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mali_app/application/providers/goal_providers.dart';
import 'package:mali_app/application/providers/use_case_providers.dart';
import 'package:mali_app/domain/entities/savings_goal.dart';

class GoalPriorityScreen extends ConsumerStatefulWidget {
  const GoalPriorityScreen({super.key});

  static const Key screenKey = Key('goal-priority-screen');
  static const Key listKey = Key('goal-priority-list');

  static Key tileKey(String goalId) => Key('goal-priority-tile-$goalId');

  static Key dragHandleKey(String goalId) =>
      Key('goal-priority-handle-$goalId');

  @override
  ConsumerState<GoalPriorityScreen> createState() => _GoalPriorityScreenState();
}

class _GoalPriorityScreenState extends ConsumerState<GoalPriorityScreen> {
  List<SavingsGoal>? _ordered;
  bool _isSaving = false;

  Future<void> _onReorder(
    int oldIndex,
    int newIndex,
    List<SavingsGoal> displayed,
  ) async {
    if (_isSaving) {
      return;
    }

    final current = [...(_ordered ?? displayed)];
    var destination = newIndex;
    if (destination > oldIndex) {
      destination -= 1;
    }
    final moved = current.removeAt(oldIndex);
    current.insert(destination, moved);
    setState(() => _ordered = current);

    setState(() => _isSaving = true);
    final result = await ref.read(reorderGoalsUseCaseProvider)(
      orderedGoalIds: [for (final goal in current) goal.id],
    );
    if (!mounted) {
      return;
    }
    setState(() => _isSaving = false);

    final failure = result.fold((left) => left, (_) => null);
    if (failure == null) {
      return;
    }

    setState(() => _ordered = null);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(failure.message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final goalsAsync = ref.watch(activeGoalsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      key: GoalPriorityScreen.screenKey,
      appBar: AppBar(
        title: const Text('Goal priority'),
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
                child: Text(
                  'Add a goal before setting priority.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                ),
              ),
            );
          }

          final ordered = _ordered ?? goals;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Text(
                  'Drag to change which goals appear first on Home.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ),
              Expanded(
                child: ReorderableListView.builder(
                  key: GoalPriorityScreen.listKey,
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 24),
                  itemCount: ordered.length,
                  buildDefaultDragHandles: false,
                  onReorder: (oldIndex, newIndex) {
                    _onReorder(oldIndex, newIndex, ordered);
                  },
                  itemBuilder: (context, index) {
                    final goal = ordered[index];
                    final emoji = goal.emoji?.trim();
                    return ListTile(
                      key: GoalPriorityScreen.tileKey(goal.id),
                      leading: Text(
                        (emoji != null && emoji.isNotEmpty) ? emoji : '🎯',
                        style: theme.textTheme.titleLarge,
                      ),
                      title: Text(goal.name),
                      trailing: ReorderableDragStartListener(
                        index: index,
                        child: Icon(
                          Icons.drag_handle,
                          key: GoalPriorityScreen.dragHandleKey(goal.id),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
