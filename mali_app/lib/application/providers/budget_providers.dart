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
