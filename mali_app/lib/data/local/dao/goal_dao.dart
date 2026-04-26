import 'package:drift/drift.dart';
import 'package:mali_app/data/local/app_database.dart';
import 'package:mali_app/data/local/tables/tables.dart';

part 'goal_dao.g.dart';

@DriftAccessor(tables: [SavingsGoalsTable, GoalContributionsTable])
class GoalDao extends DatabaseAccessor<AppDatabase> with _$GoalDaoMixin {
  GoalDao(super.db);

  Future<void> upsertGoal(SavingsGoalsTableCompanion entry) {
    return into(savingsGoalsTable).insertOnConflictUpdate(entry);
  }

  Stream<List<SavingsGoalsTableData>> watchActiveGoals() {
    return (select(savingsGoalsTable)
          ..where((table) => table.deletedAt.isNull())
          ..orderBy([(table) => OrderingTerm.asc(table.priorityOrder)]))
        .watch();
  }

  Future<void> addContribution(GoalContributionsTableCompanion entry) {
    return into(goalContributionsTable).insert(entry);
  }

  Stream<List<GoalContributionsTableData>> watchContributions(String goalId) {
    return (select(goalContributionsTable)
          ..where((table) => table.goalId.equals(goalId))
          ..where((table) => table.deletedAt.isNull())
          ..orderBy([(table) => OrderingTerm.desc(table.contributionDate)]))
        .watch();
  }
}
