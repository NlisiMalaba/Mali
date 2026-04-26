import 'package:mali_app/domain/entities/budget.dart';

abstract interface class IBudgetRepository {
  Future<void> save(Budget budget);

  Stream<List<Budget>> watchMonthBudgets({
    required int year,
    required int month,
  });

  Future<void> updateSpentAmount({
    required String budgetId,
    required String spentAmount,
  });
}
