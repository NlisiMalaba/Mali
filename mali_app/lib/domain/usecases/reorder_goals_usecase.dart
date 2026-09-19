import 'package:fpdart/fpdart.dart';
import 'package:mali_app/core/error/failure.dart';
import 'package:mali_app/domain/entities/savings_goal.dart';
import 'package:mali_app/domain/repositories/goal_repository.dart';

class ReorderGoalsUseCase {
  const ReorderGoalsUseCase({
    required IGoalRepository goalRepository,
  }) : _goalRepository = goalRepository;

  final IGoalRepository _goalRepository;

  Future<Either<Failure, List<SavingsGoal>>> call({
    required List<String> orderedGoalIds,
  }) async {
    if (orderedGoalIds.isEmpty) {
      return left(
        const ValidationFailure(
          message: 'Select at least one goal to reorder.',
          field: 'orderedGoalIds',
        ),
      );
    }

    if (orderedGoalIds.toSet().length != orderedGoalIds.length) {
      return left(
        const ValidationFailure(
          message: 'Goal order contains duplicates.',
          field: 'orderedGoalIds',
        ),
      );
    }

    late final List<SavingsGoal> currentGoals;
    try {
      currentGoals = await _goalRepository.watchActiveGoals().first;
    } catch (error) {
      return left(
        StorageFailure(
          message: 'Could not load goals.',
          cause: error,
        ),
      );
    }

    final currentIds = {for (final goal in currentGoals) goal.id};
    final requestedIds = orderedGoalIds.toSet();
    if (currentIds.length != requestedIds.length ||
        !currentIds.containsAll(requestedIds)) {
      return left(
        const ValidationFailure(
          message: 'Goal list changed. Try again.',
          field: 'orderedGoalIds',
        ),
      );
    }

    final byId = {for (final goal in currentGoals) goal.id: goal};
    final now = DateTime.now();
    final updated = <SavingsGoal>[];

    try {
      for (var index = 0; index < orderedGoalIds.length; index++) {
        final goal = byId[orderedGoalIds[index]]!;
        if (goal.priorityOrder == index) {
          updated.add(goal);
          continue;
        }

        final next = goal.copyWith(
          priorityOrder: index,
          isSynced: false,
          updatedAt: now,
        );
        await _goalRepository.saveGoal(next);
        updated.add(next);
      }
    } catch (error) {
      return left(
        StorageFailure(
          message: 'Failed to save goal order.',
          cause: error,
        ),
      );
    }

    return right(updated);
  }
}
