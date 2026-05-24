import 'package:decimal/decimal.dart';
import 'package:mali_app/application/models/home_monthly_summary_display.dart';
import 'package:mali_app/application/providers/budget_providers.dart';
import 'package:mali_app/application/providers/home_providers.dart';
import 'package:mali_app/domain/usecases/calculate_net_worth_usecase.dart';
import 'package:mali_app/domain/value_objects/currency_code.dart';
import 'package:mali_app/domain/value_objects/money.dart';

List<dynamic> homeScreenTestOverrides() {
  final now = DateTime.now();
  final selectedMonth = DateTime(now.year, now.month);

  return [
    homeNetWorthProvider.overrideWith(
      (ref) async => CalculateNetWorthResult(
        total: Money(amount: Decimal.zero, currency: CurrencyCode.usd),
        walletBreakdown: const [],
      ),
    ),
    homeMonthlySummaryDisplayProvider.overrideWith(
      (ref) async => HomeMonthlySummaryDisplay(
        month: selectedMonth,
        income: Decimal.zero,
        expenses: Decimal.zero,
        displayCurrency: CurrencyCode.usd,
      ),
    ),
    homeRecentTransactionsProvider.overrideWith(
      (ref) => Stream.value(const []),
    ),
    homeTopBudgetsProvider.overrideWith(
      (ref) => Stream.value(const []),
    ),
    currentMonthBudgetsProvider.overrideWith(
      (ref) => Stream.value(const []),
    ),
    homeTopGoalsProvider.overrideWith(
      (ref) => Stream.value(const []),
    ),
    exchangeRatesLastUpdatedProvider.overrideWith(
      (ref) => Stream.value(null),
    ),
  ];
}
