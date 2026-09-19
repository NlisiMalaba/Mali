import 'package:decimal/decimal.dart';
import 'package:mali_app/application/models/category_month_query.dart';
import 'package:mali_app/application/providers/display_currency_provider.dart';
import 'package:mali_app/application/providers/home_providers.dart';
import 'package:mali_app/application/providers/repository_providers.dart';
import 'package:mali_app/application/providers/use_case_providers.dart';
import 'package:mali_app/domain/entities/transaction.dart';
import 'package:mali_app/domain/repositories/transaction_repository.dart';
import 'package:mali_app/domain/usecases/convert_money_usecase.dart';
import 'package:mali_app/domain/usecases/get_analytics_overview_usecase.dart';
import 'package:mali_app/domain/usecases/get_analytics_trends_usecase.dart';
import 'package:mali_app/domain/value_objects/currency_code.dart';
import 'package:mali_app/domain/value_objects/money.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'analytics_providers.g.dart';

const categoryMonthTransactionLimit = 10000;

@riverpod
Future<AnalyticsOverview> analyticsOverview(Ref ref) async {
  final selectedMonth = ref.watch(homeSelectedMonthProvider);
  final displayCurrency = ref.watch(displayCurrencyProvider);
  final result = await ref.read(getAnalyticsOverviewUseCaseProvider)(
    year: selectedMonth.year,
    month: selectedMonth.month,
    displayCurrency: displayCurrency,
  );

  return result.fold(
    (failure) => throw failure,
    (overview) => overview,
  );
}

@riverpod
Stream<List<Transaction>> categoryMonthTransactions(
  Ref ref,
  CategoryMonthQuery query,
) {
  return ref.watch(transactionRepositoryProvider).watchList(
        query: TransactionWatchQuery(
          categoryId: query.categoryId,
          dateFrom: query.start,
          dateTo: query.end,
          limit: categoryMonthTransactionLimit,
        ),
      );
}

@riverpod
Future<Money> categoryMonthDisplayTotal(
  Ref ref,
  CategoryMonthQuery query,
) async {
  final transactions =
      await ref.watch(categoryMonthTransactionsProvider(query).future);
  final displayCurrency = ref.watch(displayCurrencyProvider);
  final convertMoney = ref.read(convertMoneyUseCaseProvider);

  var total = Decimal.zero;
  for (final transaction in transactions) {
    if (transaction.type != 'expense') {
      continue;
    }
    total += await _convertAmount(
      convertMoney: convertMoney,
      amount: Decimal.parse(transaction.amount),
      sourceCurrency: CurrencyCode(transaction.currencyCode),
      targetCurrency: displayCurrency,
    );
  }

  return Money(amount: total, currency: displayCurrency);
}

@riverpod
Future<AnalyticsTrends> analyticsTrends(Ref ref) async {
  final now = DateTime.now();
  final result = await ref.read(getAnalyticsTrendsUseCaseProvider)(
    endMonth: DateTime(now.year, now.month),
  );

  return result.fold(
    (failure) => throw failure,
    (trends) => trends,
  );
}

@riverpod
class TrendsDisabledCurrencies extends _$TrendsDisabledCurrencies {
  @override
  List<String> build() => const [];

  void toggle(String currencyCode) {
    if (state.contains(currencyCode)) {
      state = [
        for (final code in state)
          if (code != currencyCode) code,
      ];
      return;
    }
    state = [...state, currencyCode];
  }
}

Future<Decimal> _convertAmount({
  required ConvertMoneyUseCase convertMoney,
  required Decimal amount,
  required CurrencyCode sourceCurrency,
  required CurrencyCode targetCurrency,
}) async {
  if (amount <= Decimal.zero) {
    return Decimal.zero;
  }
  if (sourceCurrency == targetCurrency) {
    return amount;
  }

  final result = await convertMoney(
    money: Money(amount: amount, currency: sourceCurrency),
    targetCurrency: targetCurrency,
  );

  return result.fold(
    (failure) => throw failure,
    (converted) => converted.amount,
  );
}
