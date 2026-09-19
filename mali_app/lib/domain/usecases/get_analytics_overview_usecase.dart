import 'package:decimal/decimal.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mali_app/core/error/failure.dart';
import 'package:mali_app/domain/usecases/convert_money_usecase.dart';
import 'package:mali_app/domain/usecases/get_monthly_summary_usecase.dart';
import 'package:mali_app/domain/value_objects/currency_code.dart';
import 'package:mali_app/domain/value_objects/money.dart';

class GetAnalyticsOverviewUseCase {
  const GetAnalyticsOverviewUseCase({
    required GetMonthlySummaryUseCase monthlySummary,
    required ConvertMoneyUseCase convertMoney,
  })  : _monthlySummary = monthlySummary,
        _convertMoney = convertMoney;

  static const int topCategoryLimit = 5;

  final GetMonthlySummaryUseCase _monthlySummary;
  final ConvertMoneyUseCase _convertMoney;

  Future<Either<Failure, AnalyticsOverview>> call({
    required int year,
    required int month,
    required CurrencyCode displayCurrency,
  }) async {
    final summaryResult = await _monthlySummary(year: year, month: month);
    if (summaryResult.isLeft()) {
      return left(
        summaryResult.getLeft().toNullable() ??
            const StorageFailure(message: 'Failed to load monthly summary.'),
      );
    }

    final monthly = summaryResult.getOrElse(
      (_) => throw StateError('expected monthly summary'),
    );
    return _buildOverview(
      monthly: monthly,
      displayCurrency: displayCurrency,
    );
  }

  Future<Either<Failure, AnalyticsOverview>> _buildOverview({
    required MonthlySummary monthly,
    required CurrencyCode displayCurrency,
  }) async {
    try {
      final merged = <String, Decimal>{};
      for (final spend in monthly.categoryBreakdown) {
        final converted = await _convertAmount(
          amount: spend.amount,
          sourceCurrency: CurrencyCode(spend.currencyCode),
          targetCurrency: displayCurrency,
        );
        merged[spend.categoryId] =
            (merged[spend.categoryId] ?? Decimal.zero) + converted;
      }

      final ranked = [
        for (final entry in merged.entries)
          if (entry.value > Decimal.zero)
            RankedCategorySpend(
              categoryId: entry.key,
              amount: entry.value,
              displayCurrency: displayCurrency,
            ),
      ]..sort((a, b) => b.amount.compareTo(a.amount));

      return right(
        AnalyticsOverview(
          totalsByCurrency: monthly.totalsByCurrency,
          categorySpend: ranked,
        ),
      );
    } on Failure catch (failure) {
      return left(failure);
    } catch (error) {
      return left(
        StorageFailure(
          message: 'Failed to build analytics overview.',
          cause: error,
        ),
      );
    }
  }

  Future<Decimal> _convertAmount({
    required Decimal amount,
    required CurrencyCode sourceCurrency,
    required CurrencyCode targetCurrency,
  }) async {
    if (amount <= Decimal.zero) {
      return Decimal.zero;
    }

    final result = await _convertMoney(
      money: Money(amount: amount, currency: sourceCurrency),
      targetCurrency: targetCurrency,
    );

    return result.fold(
      (failure) => throw failure,
      (converted) => converted.amount,
    );
  }
}

class AnalyticsOverview {
  const AnalyticsOverview({
    required this.totalsByCurrency,
    required this.categorySpend,
  });

  final List<CurrencyMonthlyTotals> totalsByCurrency;
  final List<RankedCategorySpend> categorySpend;

  List<RankedCategorySpend> get topCategories =>
      categorySpend.take(GetAnalyticsOverviewUseCase.topCategoryLimit).toList();

  Decimal get totalCategorySpend {
    var total = Decimal.zero;
    for (final spend in categorySpend) {
      total += spend.amount;
    }
    return total;
  }
}

class RankedCategorySpend {
  const RankedCategorySpend({
    required this.categoryId,
    required this.amount,
    required this.displayCurrency,
  });

  final String categoryId;
  final Decimal amount;
  final CurrencyCode displayCurrency;
}
