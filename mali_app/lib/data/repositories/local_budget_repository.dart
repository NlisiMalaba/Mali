import 'package:mali_app/data/local/dao/budget_dao.dart';
import 'package:mali_app/data/local/mappers/budget_mapper.dart';
import 'package:mali_app/domain/entities/budget.dart';
import 'package:mali_app/domain/repositories/budget_repository.dart';

class LocalBudgetRepository implements IBudgetRepository {
  const LocalBudgetRepository({
    required BudgetDao budgetDao,
  }) : _budgetDao = budgetDao;

  final BudgetDao _budgetDao;

  @override
  Future<void> save(Budget budget) {
    return _budgetDao.upsertBudget(BudgetMapper.toCompanion(budget));
  }

  @override
  Stream<List<Budget>> watchMonthBudgets({
    required int year,
    required int month,
  }) {
    return _budgetDao
        .watchMonthBudgets(year: year, month: month)
        .map(BudgetMapper.toDomainList);
  }

  @override
  Future<void> updateSpentAmount({
    required String budgetId,
    required String spentAmount,
  }) {
    return _budgetDao.updateSpentAmount(
      budgetId: budgetId,
      spentAmount: spentAmount,
    );
  }
}
