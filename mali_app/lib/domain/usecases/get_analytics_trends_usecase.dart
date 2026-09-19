import 'package:decimal/decimal.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mali_app/core/error/failure.dart';
import 'package:mali_app/domain/entities/transaction.dart';
import 'package:mali_app/domain/repositories/transaction_repository.dart';
import 'package:mali_app/domain/value_objects/date_range.dart';

class GetAnalyticsTrendsUseCase {
  const GetAnalyticsTrendsUseCase({
    required ITransactionRepository transactionRepository,
  }) : _transactionRepository = transactionRepository;

  static const int monthCount = 6;
  static const int transactionLimit = monthCount * 10000;

  final ITransactionRepository _transactionRepository;

  Future<Either<Failure, AnalyticsTrends>> call({
    required DateTime endMonth,
  }) async {
    final months = monthsEndingAt(endMonth);
    final start = DateTime(months.first.year, months.first.month, 1);
    final end = DateTime(
      months.last.year,
      months.last.month + 1,
      0,
      23,
      59,
      59,
      999,
      999,
    );
    final dateRange = DateRange(start: start, end: end);

    try {
      final transactions = await _transactionRepository.list(
        query: TransactionQuery(
          dateFrom: dateRange.start,
          dateTo: dateRange.end,
          limit: transactionLimit,
        ),
      );
      return right(_aggregate(transactions, months));
    } catch (error) {
      return left(
        StorageFailure(
          message: 'Failed to load analytics trends.',
          cause: error,
        ),
      );
    }
  }

  static List<DateTime> monthsEndingAt(DateTime endMonth) {
    final end = DateTime(endMonth.year, endMonth.month);
    return [
      for (var offset = monthCount - 1; offset >= 0; offset--)
        DateTime(end.year, end.month - offset),
    ];
  }

  AnalyticsTrends _aggregate(
    List<Transaction> transactions,
    List<DateTime> months,
  ) {
    final currencyCodes = <String>{};
    for (final transaction in transactions) {
      if (transaction.type == 'income' || transaction.type == 'expense') {
        currencyCodes.add(transaction.currencyCode);
      }
    }

    final sortedCodes = currencyCodes.toList()..sort();
    final incomeByCurrency = {
      for (final code in sortedCodes)
        code: List<Decimal>.filled(months.length, Decimal.zero),
    };
    final expensesByCurrency = {
      for (final code in sortedCodes)
        code: List<Decimal>.filled(months.length, Decimal.zero),
    };

    for (final transaction in transactions) {
      final monthIndex = _monthIndex(transaction.transactionDate, months);
      if (monthIndex < 0) {
        continue;
      }

      final amount = Decimal.parse(transaction.amount);
      if (transaction.type == 'income') {
        incomeByCurrency[transaction.currencyCode]![monthIndex] += amount;
      } else if (transaction.type == 'expense') {
        expensesByCurrency[transaction.currencyCode]![monthIndex] += amount;
      }
    }

    return AnalyticsTrends(
      months: months,
      currencies: [
        for (final code in sortedCodes)
          CurrencyTrendSeries(
            currencyCode: code,
            incomeByMonth: incomeByCurrency[code]!,
            expensesByMonth: expensesByCurrency[code]!,
          ),
      ],
    );
  }

  int _monthIndex(DateTime date, List<DateTime> months) {
    for (var index = 0; index < months.length; index++) {
      final month = months[index];
      if (month.year == date.year && month.month == date.month) {
        return index;
      }
    }
    return -1;
  }
}

class AnalyticsTrends {
  const AnalyticsTrends({
    required this.months,
    required this.currencies,
  });

  final List<DateTime> months;
  final List<CurrencyTrendSeries> currencies;
}

class CurrencyTrendSeries {
  const CurrencyTrendSeries({
    required this.currencyCode,
    required this.incomeByMonth,
    required this.expensesByMonth,
  });

  final String currencyCode;
  final List<Decimal> incomeByMonth;
  final List<Decimal> expensesByMonth;
}
