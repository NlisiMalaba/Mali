import 'package:decimal/decimal.dart';
import 'package:mali_app/application/models/home_monthly_summary_display.dart';
import 'package:mali_app/application/providers/display_currency_provider.dart';
import 'package:mali_app/application/providers/repository_providers.dart';
import 'package:mali_app/application/providers/use_case_providers.dart';
import 'package:mali_app/domain/entities/budget.dart';
import 'package:mali_app/domain/entities/savings_goal.dart';
import 'package:mali_app/domain/entities/transaction.dart';
import 'package:mali_app/domain/repositories/transaction_repository.dart';
import 'package:mali_app/domain/usecases/calculate_net_worth_usecase.dart';
import 'package:mali_app/domain/usecases/convert_money_usecase.dart';
import 'package:mali_app/domain/value_objects/currency_code.dart';
import 'package:mali_app/domain/value_objects/money.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'home_providers.g.dart';

const homeRecentTransactionLimit = 5;
const homeTopBudgetLimit = 3;
const homeTopGoalLimit = 2;

@riverpod
Future<CalculateNetWorthResult> homeNetWorth(Ref ref) async {
  final displayCurrency = ref.watch(displayCurrencyProvider);
  final result = await ref.read(calculateNetWorthUseCaseProvider)(
    displayCurrency: displayCurrency,
  );

  return result.fold(
    (failure) => throw failure,
    (netWorth) => netWorth,
  );
}

@riverpod
class HomeSelectedMonth extends _$HomeSelectedMonth {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  void previousMonth() {
    state = DateTime(state.year, state.month - 1);
  }

  void nextMonth() {
    state = DateTime(state.year, state.month + 1);
  }
}

@riverpod
Future<HomeMonthlySummaryDisplay> homeMonthlySummaryDisplay(Ref ref) async {
  final selectedMonth = ref.watch(homeSelectedMonthProvider);
  final displayCurrency = ref.watch(displayCurrencyProvider);
  final convertMoney = ref.read(convertMoneyUseCaseProvider);

  final result = await ref.read(getMonthlySummaryUseCaseProvider)(
    year: selectedMonth.year,
    month: selectedMonth.month,
  );

  final summary = result.fold(
    (failure) => throw failure,
    (value) => value,
  );

  var income = Decimal.zero;
  var expenses = Decimal.zero;

  for (final totals in summary.totalsByCurrency) {
    final currency = CurrencyCode(totals.currencyCode);

    if (totals.income > Decimal.zero) {
      final converted = await _convertAmount(
        convertMoney: convertMoney,
        amount: totals.income,
        sourceCurrency: currency,
        targetCurrency: displayCurrency,
      );
      income += converted;
    }

    if (totals.expenses > Decimal.zero) {
      final converted = await _convertAmount(
        convertMoney: convertMoney,
        amount: totals.expenses,
        sourceCurrency: currency,
        targetCurrency: displayCurrency,
      );
      expenses += converted;
    }
  }

  return HomeMonthlySummaryDisplay(
    month: selectedMonth,
    income: income,
    expenses: expenses,
    displayCurrency: displayCurrency,
  );
}

Future<Decimal> _convertAmount({
  required ConvertMoneyUseCase convertMoney,
  required Decimal amount,
  required CurrencyCode sourceCurrency,
  required CurrencyCode targetCurrency,
}) async {
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

@riverpod
Stream<List<Transaction>> homeRecentTransactions(Ref ref) {
  return ref.watch(transactionRepositoryProvider).watchList(
        query: const TransactionWatchQuery(limit: homeRecentTransactionLimit),
      );
}

@riverpod
Stream<List<Budget>> homeTopBudgets(Ref ref) {
  final selectedMonth = ref.watch(homeSelectedMonthProvider);
  return ref
      .watch(budgetRepositoryProvider)
      .watchMonthBudgets(
        year: selectedMonth.year,
        month: selectedMonth.month,
      )
      .map(
        (budgets) => _topBudgetsByUsage(budgets, homeTopBudgetLimit),
      );
}

List<Budget> _topBudgetsByUsage(List<Budget> budgets, int limit) {
  final sorted = [...budgets]
    ..sort((a, b) {
      final usageCompare =
          _budgetUsageRatio(b).compareTo(_budgetUsageRatio(a));
      if (usageCompare != 0) {
        return usageCompare;
      }
      return b.spentAmount.compareTo(a.spentAmount);
    });
  return sorted.take(limit).toList();
}

Decimal _budgetUsageRatio(Budget budget) {
  try {
    final budgetAmount = Decimal.parse(budget.amount);
    if (budgetAmount <= Decimal.zero) {
      return Decimal.zero;
    }
    final spentAmount = Decimal.parse(budget.spentAmount);
    return (spentAmount / budgetAmount).toDecimal();
  } catch (_) {
    return Decimal.zero;
  }
}

@riverpod
Stream<List<SavingsGoal>> homeTopGoals(Ref ref) {
  return ref.watch(goalRepositoryProvider).watchActiveGoals().map(
        (goals) {
          final sorted = [...goals]
            ..sort((a, b) => a.priorityOrder.compareTo(b.priorityOrder));
          return sorted.take(homeTopGoalLimit).toList();
        },
      );
}

@riverpod
Stream<DateTime?> exchangeRatesLastUpdated(Ref ref) {
  return ref.watch(exchangeRateRepositoryProvider).watchAllRates().map(
        (rates) {
          if (rates.isEmpty) {
            return null;
          }
          return rates
              .map((rate) => rate.updatedAt)
              .reduce(
                (latest, current) =>
                    current.isAfter(latest) ? current : latest,
              );
        },
      );
}
