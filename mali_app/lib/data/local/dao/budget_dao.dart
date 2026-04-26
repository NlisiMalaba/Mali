import 'package:drift/drift.dart';
import 'package:mali_app/data/local/app_database.dart';
import 'package:mali_app/data/local/tables/tables.dart';

part 'budget_dao.g.dart';

@DriftAccessor(tables: [BudgetsTable])
class BudgetDao extends DatabaseAccessor<AppDatabase> with _$BudgetDaoMixin {
  BudgetDao(super.db);

  Future<void> upsertBudget(BudgetsTableCompanion entry) {
    return into(budgetsTable).insertOnConflictUpdate(entry);
  }

  Stream<List<BudgetsTableData>> watchMonthBudgets({
    required int year,
    required int month,
  }) {
    return (select(budgetsTable)
          ..where((table) => table.year.equals(year))
          ..where((table) => table.month.equals(month))
          ..where((table) => table.deletedAt.isNull())
          ..orderBy([(table) => OrderingTerm.asc(table.categoryId)]))
        .watch();
  }

  Future<int> updateSpentAmount({
    required String budgetId,
    required String spentAmount,
  }) {
    return (update(budgetsTable)..where((table) => table.id.equals(budgetId)))
        .write(
      BudgetsTableCompanion(
        spentAmount: Value(spentAmount),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}
