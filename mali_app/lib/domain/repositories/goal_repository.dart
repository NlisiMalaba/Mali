import 'package:mali_app/domain/entities/goal_contribution.dart';
import 'package:mali_app/domain/entities/savings_goal.dart';

abstract interface class IGoalRepository {
  Future<void> saveGoal(SavingsGoal goal);

  Stream<List<SavingsGoal>> watchActiveGoals();

  Future<void> addContribution(GoalContribution contribution);

  Stream<List<GoalContribution>> watchContributions(String goalId);
}
