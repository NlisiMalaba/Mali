import 'package:decimal/decimal.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mali_app/core/error/failure.dart';
import 'package:mali_app/core/utils/local_id_generator.dart';
import 'package:mali_app/domain/entities/budget.dart';
import 'package:mali_app/domain/repositories/budget_repository.dart';
import 'package:mali_app/domain/value_objects/currency_code.dart';

class CreateBudgetParams {
  const CreateBudgetParams({
    required this.userId,
    required this.categoryId,
    required this.currencyCode,
    required this.amount,
    required this.month,
    required this.year,
    required this.rolloverEnabled,
  });

  final String userId;
  final String categoryId;
  final CurrencyCode currencyCode;
  final String amount;
  final int month;
  final int year;
  final bool rolloverEnabled;
}

class CreateBudgetUseCase {
  const CreateBudgetUseCase({
    required IBudgetRepository budgetRepository,
  }) : _budgetRepository = budgetRepository;

  final IBudgetRepository _budgetRepository;

  static const int minMonth = 1;
  static const int maxMonth = 12;

  Future<Either<Failure, Budget>> call(CreateBudgetParams params) async {
    if (params.categoryId.trim().isEmpty) {
      return left(
        const ValidationFailure(
          message: 'Select a category for this budget.',
          field: 'categoryId',
        ),
      );
    }

    if (params.month < minMonth || params.month > maxMonth) {
      return left(
        const ValidationFailure(
          message: 'Select a valid month.',
          field: 'month',
        ),
      );
    }

    if (params.year < 2000 || params.year > 2100) {
      return left(
        const ValidationFailure(
          message: 'Select a valid year.',
          field: 'year',
        ),
      );
    }

    final amount = _parsePositiveDecimal(params.amount);
    if (amount == null) {
      return left(
        const ValidationFailure(
          message: 'Enter a budget amount greater than zero.',
          field: 'amount',
        ),
      );
    }

    try {
      final existing = await _budgetRepository
          .watchMonthBudgets(year: params.year, month: params.month)
          .first;
      final duplicate = existing.any(
        (budget) =>
            budget.categoryId == params.categoryId &&
            budget.currencyCode == params.currencyCode.value,
      );
      if (duplicate) {
        return left(
          const ValidationFailure(
            message:
                'A budget for this category and currency already exists this month.',
            field: 'categoryId',
          ),
        );
      }
    } catch (error) {
      return left(
        StorageFailure(
          message: 'Could not verify existing budgets.',
          cause: error,
        ),
      );
    }

    final now = DateTime.now();
    final budget = Budget(
      id: LocalIdGenerator.newId('budget'),
      userId: params.userId,
      categoryId: params.categoryId,
      currencyCode: params.currencyCode.value,
      amount: amount.toString(),
      spentAmount: '0',
      month: params.month,
      year: params.year,
      rolloverEnabled: params.rolloverEnabled,
      isSynced: false,
      createdAt: now,
      updatedAt: now,
    );

    try {
      await _budgetRepository.save(budget);
    } catch (error) {
      return left(
        StorageFailure(
          message: 'Failed to save budget.',
          cause: error,
        ),
      );
    }

    return right(budget);
  }

  Decimal? _parsePositiveDecimal(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    try {
      final parsed = Decimal.parse(trimmed);
      if (parsed <= Decimal.zero) {
        return null;
      }
      return parsed;
    } catch (_) {
      return null;
    }
  }
}
