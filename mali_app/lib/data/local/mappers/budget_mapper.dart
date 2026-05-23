import 'package:drift/drift.dart';
import 'package:mali_app/data/local/app_database.dart';
import 'package:mali_app/domain/entities/budget.dart';

class BudgetMapper {
  const BudgetMapper._();

  static Budget toDomain(BudgetsTableData row) {
    return Budget(
      id: row.id,
      userId: row.userId,
      categoryId: row.categoryId,
      currencyCode: row.currencyCode,
      amount: row.amount,
      spentAmount: row.spentAmount,
      month: row.month,
      year: row.year,
      rolloverEnabled: row.rolloverEnabled,
      isSynced: row.isSynced,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      deletedAt: row.deletedAt,
    );
  }

  static List<Budget> toDomainList(List<BudgetsTableData> rows) {
    return rows.map(toDomain).toList(growable: false);
  }

  static BudgetsTableCompanion toCompanion(Budget budget) {
    return BudgetsTableCompanion(
      id: Value(budget.id),
      userId: Value(budget.userId),
      categoryId: Value(budget.categoryId),
      currencyCode: Value(budget.currencyCode),
      amount: Value(budget.amount),
      spentAmount: Value(budget.spentAmount),
      month: Value(budget.month),
      year: Value(budget.year),
      rolloverEnabled: Value(budget.rolloverEnabled),
      isSynced: Value(budget.isSynced),
      createdAt: Value(budget.createdAt),
      updatedAt: Value(budget.updatedAt),
      deletedAt: Value(budget.deletedAt),
    );
  }
}
