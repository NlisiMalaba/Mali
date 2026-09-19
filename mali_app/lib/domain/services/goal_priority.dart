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

  /// Highest-priority goal that still needs funding, or null when every goal
  /// is completed or deleted.
  static SavingsGoal? topFundable(List<SavingsGoal> goals) {
    final fundable = [
      for (final goal in goals)
        if (!goal.isCompleted && goal.deletedAt == null) goal,
    ];
    if (fundable.isEmpty) {
      return null;
    }
    return sorted(fundable).first;
  }
}
