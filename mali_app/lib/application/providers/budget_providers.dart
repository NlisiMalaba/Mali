import 'package:mali_app/application/models/category_month_query.dart';
import 'package:mali_app/application/providers/repository_providers.dart';
import 'package:mali_app/domain/entities/budget.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'budget_providers.g.dart';

@riverpod
Stream<List<Budget>> currentMonthBudgets(Ref ref) {
  final now = DateTime.now();
  return ref.watch(budgetRepositoryProvider).watchMonthBudgets(
        year: now.year,
        month: now.month,
      );
}

@riverpod
Stream<List<Budget>> budgetsForMonth(Ref ref, CategoryMonthQuery query) {
  return ref.watch(budgetRepositoryProvider).watchMonthBudgets(
        year: query.year,
        month: query.month,
      );
}

@riverpod
Stream<Budget?> categoryMonthBudget(Ref ref, CategoryMonthQuery query) {
  return ref.watch(budgetRepositoryProvider).watchMonthBudgets(
        year: query.year,
        month: query.month,
      ).map((budgets) {
    for (final budget in budgets) {
      if (budget.categoryId == query.categoryId) {
        return budget;
      }
    }
    return null;
  });
}
