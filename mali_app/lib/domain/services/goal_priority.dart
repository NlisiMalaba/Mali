import 'package:mali_app/domain/entities/savings_goal.dart';

class GoalPriority {
  const GoalPriority._();

  static List<SavingsGoal> sorted(List<SavingsGoal> goals) {
    final ordered = [...goals]
      ..sort((a, b) => a.priorityOrder.compareTo(b.priorityOrder));
    return ordered;
  }

  static List<SavingsGoal> top({
    required List<SavingsGoal> goals,
    required int limit,
  }) {
    return sorted(goals).take(limit).toList();
  }
}
