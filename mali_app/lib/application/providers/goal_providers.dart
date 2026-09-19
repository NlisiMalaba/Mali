import 'package:mali_app/application/providers/repository_providers.dart';
import 'package:mali_app/domain/entities/goal_contribution.dart';
import 'package:mali_app/domain/entities/savings_goal.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'goal_providers.g.dart';

@riverpod
Stream<List<SavingsGoal>> activeGoals(Ref ref) {
  return ref.watch(goalRepositoryProvider).watchActiveGoals();
}

@riverpod
Stream<List<GoalContribution>> goalContributions(Ref ref, String goalId) {
  return ref.watch(goalRepositoryProvider).watchContributions(goalId);
}
