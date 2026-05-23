import 'package:drift/drift.dart';
import 'package:mali_app/data/local/app_database.dart';
import 'package:mali_app/domain/entities/goal_contribution.dart';
import 'package:mali_app/domain/entities/savings_goal.dart';

class GoalMapper {
  const GoalMapper._();

  static SavingsGoal toDomain(SavingsGoalsTableData row) {
    return SavingsGoal(
      id: row.id,
      userId: row.userId,
      name: row.name,
      emoji: row.emoji,
      targetAmount: row.targetAmount,
      currentAmount: row.currentAmount,
      currencyCode: row.currencyCode,
      targetDate: row.targetDate,
      priorityOrder: row.priorityOrder,
      isCompleted: row.isCompleted,
      isSynced: row.isSynced,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      deletedAt: row.deletedAt,
    );
  }

  static List<SavingsGoal> toDomainList(List<SavingsGoalsTableData> rows) {
    return rows.map(toDomain).toList(growable: false);
  }

  static SavingsGoalsTableCompanion toGoalCompanion(SavingsGoal goal) {
    return SavingsGoalsTableCompanion(
      id: Value(goal.id),
      userId: Value(goal.userId),
      name: Value(goal.name),
      emoji: Value(goal.emoji),
      targetAmount: Value(goal.targetAmount),
      currentAmount: Value(goal.currentAmount),
      currencyCode: Value(goal.currencyCode),
      targetDate: Value(goal.targetDate),
      priorityOrder: Value(goal.priorityOrder),
      isCompleted: Value(goal.isCompleted),
      isSynced: Value(goal.isSynced),
      createdAt: Value(goal.createdAt),
      updatedAt: Value(goal.updatedAt),
      deletedAt: Value(goal.deletedAt),
    );
  }

  static GoalContribution toContributionDomain(GoalContributionsTableData row) {
    return GoalContribution(
      id: row.id,
      goalId: row.goalId,
      walletId: row.walletId,
      transactionId: row.transactionId,
      amount: row.amount,
      currencyCode: row.currencyCode,
      note: row.note,
      contributionDate: row.contributionDate,
      isSynced: row.isSynced,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      deletedAt: row.deletedAt,
    );
  }

  static List<GoalContribution> toContributionDomainList(
    List<GoalContributionsTableData> rows,
  ) {
    return rows.map(toContributionDomain).toList(growable: false);
  }

  static GoalContributionsTableCompanion toContributionCompanion(
    GoalContribution contribution,
  ) {
    return GoalContributionsTableCompanion(
      id: Value(contribution.id),
      goalId: Value(contribution.goalId),
      walletId: Value(contribution.walletId),
      transactionId: Value(contribution.transactionId),
      amount: Value(contribution.amount),
      currencyCode: Value(contribution.currencyCode),
      note: Value(contribution.note),
      contributionDate: Value(contribution.contributionDate),
      isSynced: Value(contribution.isSynced),
      createdAt: Value(contribution.createdAt),
      updatedAt: Value(contribution.updatedAt),
      deletedAt: Value(contribution.deletedAt),
    );
  }
}
