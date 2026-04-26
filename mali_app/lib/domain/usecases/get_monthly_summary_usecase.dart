import 'package:decimal/decimal.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mali_app/core/error/failure.dart';
import 'package:mali_app/domain/entities/transaction.dart';
import 'package:mali_app/domain/repositories/transaction_repository.dart';
import 'package:mali_app/domain/value_objects/date_range.dart';

class GetMonthlySummaryUseCase {
  const GetMonthlySummaryUseCase({
    required ITransactionRepository transactionRepository,
  }) : _transactionRepository = transactionRepository;

  final ITransactionRepository _transactionRepository;

  Future<Either<Failure, MonthlySummary>> call({
    required int year,
    required int month,
  }) async {
    if (month < 1 || month > 12) {
      return left(
        const ValidationFailure(
          message: 'Month must be between 1 and 12.',
          field: 'month',
        ),
      );
    }

    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0, 23, 59, 59, 999, 999);
    final dateRange = DateRange(start: start, end: end);

    final transactions = await _transactionRepository.list(
      query: TransactionQuery(
        dateFrom: dateRange.start,
        dateTo: dateRange.end,
        limit: 10000,
      ),
    );

    try {
      return right(_aggregate(transactions, dateRange));
    } catch (error) {
      return left(
        StorageFailure(
          message: 'Failed to aggregate monthly summary.',
          cause: error,
        ),
      );
    }
  }

  MonthlySummary _aggregate(List<Transaction> transactions, DateRange dateRange) {
    final totalsByCurrency = <String, CurrencyMonthlyTotals>{};
    final expenseByCategory = <String, Decimal>{};

    for (final transaction in transactions) {
      final amount = Decimal.parse(transaction.amount);
      final currentTotals = totalsByCurrency[transaction.currencyCode] ??
          CurrencyMonthlyTotals(
            currencyCode: transaction.currencyCode,
            income: Decimal.zero,
            expenses: Decimal.zero,
          );

      if (transaction.type == 'income') {
        totalsByCurrency[transaction.currencyCode] = currentTotals.copyWith(
          income: currentTotals.income + amount,
        );
      } else if (transaction.type == 'expense') {
        totalsByCurrency[transaction.currencyCode] = currentTotals.copyWith(
          expenses: currentTotals.expenses + amount,
        );
        if (transaction.categoryId != null) {
          expenseByCategory[transaction.categoryId!] =
              (expenseByCategory[transaction.categoryId!] ?? Decimal.zero) + amount;
        }
      }
    }

    final categoryBreakdown = expenseByCategory.entries
        .map(
          (entry) => CategorySpend(
            categoryId: entry.key,
            amount: entry.value,
          ),
        )
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    return MonthlySummary(
      dateRange: dateRange,
      totalsByCurrency: totalsByCurrency.values.toList()
        ..sort((a, b) => a.currencyCode.compareTo(b.currencyCode)),
      categoryBreakdown: categoryBreakdown,
      transactionsCount: transactions.length,
    );
  }
}

class MonthlySummary {
  const MonthlySummary({
    required this.dateRange,
    required this.totalsByCurrency,
    required this.categoryBreakdown,
    required this.transactionsCount,
  });

  final DateRange dateRange;
  final List<CurrencyMonthlyTotals> totalsByCurrency;
  final List<CategorySpend> categoryBreakdown;
  final int transactionsCount;
}

class CurrencyMonthlyTotals {
  const CurrencyMonthlyTotals({
    required this.currencyCode,
    required this.income,
    required this.expenses,
  });

  final String currencyCode;
  final Decimal income;
  final Decimal expenses;

  Decimal get net => income - expenses;

  CurrencyMonthlyTotals copyWith({
    Decimal? income,
    Decimal? expenses,
  }) {
    return CurrencyMonthlyTotals(
      currencyCode: currencyCode,
      income: income ?? this.income,
      expenses: expenses ?? this.expenses,
    );
  }
}

class CategorySpend {
  const CategorySpend({
    required this.categoryId,
    required this.amount,
  });

  final String categoryId;
  final Decimal amount;
}
