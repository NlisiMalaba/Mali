import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mali_app/domain/entities/exchange_rate.dart';
import 'package:mali_app/domain/entities/goal_contribution.dart';
import 'package:mali_app/domain/entities/savings_goal.dart';
import 'package:mali_app/domain/entities/transaction.dart';
import 'package:mali_app/domain/repositories/exchange_rate_repository.dart';
import 'package:mali_app/domain/repositories/goal_repository.dart';
import 'package:mali_app/domain/repositories/transaction_repository.dart';
import 'package:mali_app/domain/usecases/build_contribution_reminder_usecase.dart';
import 'package:mali_app/domain/usecases/convert_money_usecase.dart';
import 'package:mali_app/domain/usecases/get_monthly_summary_usecase.dart';
import 'package:mali_app/domain/value_objects/currency_code.dart';

class _FakeTransactionRepository implements ITransactionRepository {
  _FakeTransactionRepository(this._transactions);

  final List<Transaction> _transactions;
  TransactionQuery? lastQuery;

  @override
  Future<List<Transaction>> list({required TransactionQuery query}) async {
    lastQuery = query;
    return _transactions;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeGoalRepository implements IGoalRepository {
  _FakeGoalRepository(this._goals);

  final List<SavingsGoal> _goals;

  @override
  Future<List<SavingsGoal>> listActiveGoals() async => _goals;

  @override
  Future<void> addContribution(GoalContribution contribution) async {}

  @override
  Future<void> saveGoal(SavingsGoal goal) async {}

  @override
  Stream<List<SavingsGoal>> watchActiveGoals() => const Stream.empty();

  @override
  Stream<List<GoalContribution>> watchContributions(String goalId) =>
      const Stream.empty();
}

class _FakeExchangeRateRepository implements IExchangeRateRepository {
  _FakeExchangeRateRepository(this._rates);

  /// Keyed by 'BASE>QUOTE'.
  final Map<String, String> _rates;

  @override
  Future<ExchangeRate?> getRate({
    required CurrencyCode baseCurrencyCode,
    required CurrencyCode quoteCurrencyCode,
  }) async {
    final rate = _rates['${baseCurrencyCode.value}>${quoteCurrencyCode.value}'];
    if (rate == null) {
      return null;
    }
    final timestamp = DateTime(2026, 10, 1);
    return ExchangeRate(
      id: '${baseCurrencyCode.value}-${quoteCurrencyCode.value}',
      baseCurrencyCode: baseCurrencyCode.value,
      quoteCurrencyCode: quoteCurrencyCode.value,
      rate: rate,
      isManual: true,
      rateDate: timestamp,
      isSynced: false,
      createdAt: timestamp,
      updatedAt: timestamp,
    );
  }

  @override
  Future<void> save(ExchangeRate rate) async {}

  @override
  Stream<List<ExchangeRate>> watchAllRates() => const Stream.empty();
}

Transaction _transaction({
  required String id,
  required String type,
  required String amount,
  String currencyCode = 'USD',
  DateTime? date,
}) {
  final transactionDate = date ?? DateTime(2026, 9, 15);
  return Transaction(
    id: id,
    userId: 'u-1',
    walletId: 'w-1',
    categoryId: type == 'income' ? 'cat-salary' : 'cat-food',
    type: type,
    amount: amount,
    currencyCode: currencyCode,
    title: 'Entry $id',
    transactionDate: transactionDate,
    isSynced: false,
    createdAt: transactionDate,
    updatedAt: transactionDate,
  );
}

SavingsGoal _goal({
  required String id,
  required String name,
  required int priorityOrder,
  bool isCompleted = false,
}) {
  final timestamp = DateTime(2026, 9, 1);
  return SavingsGoal(
    id: id,
    userId: 'u-1',
    name: name,
    targetAmount: '1000',
    currentAmount: '250',
    currencyCode: 'USD',
    priorityOrder: priorityOrder,
    isCompleted: isCompleted,
    isSynced: false,
    createdAt: timestamp,
    updatedAt: timestamp,
  );
}

BuildContributionReminderUseCase _useCase({
  List<Transaction> transactions = const [],
  List<SavingsGoal> goals = const [],
  Map<String, String> rates = const {},
  _FakeTransactionRepository? transactionRepository,
}) {
  return BuildContributionReminderUseCase(
    monthlySummary: GetMonthlySummaryUseCase(
      transactionRepository:
          transactionRepository ?? _FakeTransactionRepository(transactions),
    ),
    goalRepository: _FakeGoalRepository(goals),
    convertMoney: ConvertMoneyUseCase(
      exchangeRateRepository: _FakeExchangeRateRepository(rates),
    ),
  );
}

void main() {
  // The 1st of October, so the reminder reports on September.
  final now = DateTime(2026, 10, 1, 9);
  final defaultGoals = [_goal(id: 'g-1', name: 'Emergency Fund', priorityOrder: 1)];

  group('BuildContributionReminderUseCase month selection', () {
    test('reports on the calendar month before now', () {
      expect(
        BuildContributionReminderUseCase.previousMonthOf(now),
        DateTime(2026, 9),
      );
    });

    test('rolls back across a year boundary', () {
      expect(
        BuildContributionReminderUseCase.previousMonthOf(DateTime(2027, 1, 1)),
        DateTime(2026, 12),
      );
    });

    test('queries the previous month date range', () async {
      final repository = _FakeTransactionRepository(const []);

      await _useCase(transactionRepository: repository)(
        now: now,
        displayCurrency: CurrencyCode.usd,
      );

      expect(repository.lastQuery!.dateFrom, DateTime(2026, 9, 1));
      expect(
        repository.lastQuery!.dateTo,
        DateTime(2026, 9, 30, 23, 59, 59, 999, 999),
      );
    });
  });

  group('BuildContributionReminderUseCase surplus', () {
    test('is income minus expenses for the month', () async {
      final result = await _useCase(
        transactions: [
          _transaction(id: 't-1', type: 'income', amount: '2000'),
          _transaction(id: 't-2', type: 'expense', amount: '1250.25'),
        ],
        goals: defaultGoals,
      )(now: now, displayCurrency: CurrencyCode.usd);

      final reminder = result.getOrElse((_) => throw StateError('expected right'));
      expect(reminder.surplus.amount, Decimal.parse('749.75'));
      expect(reminder.month, DateTime(2026, 9));
      expect(reminder.shouldPrompt, isTrue);
    });

    test('converts other currencies into the display currency', () async {
      final result = await _useCase(
        transactions: [
          _transaction(id: 't-1', type: 'income', amount: '100'),
          _transaction(
            id: 't-2',
            type: 'income',
            amount: '1000',
            currencyCode: 'ZAR',
          ),
        ],
        goals: defaultGoals,
        rates: const {'ZAR>USD': '0.055'},
      )(now: now, displayCurrency: CurrencyCode.usd);

      final reminder = result.getOrElse((_) => throw StateError('expected right'));
      expect(reminder.surplus.amount, Decimal.parse('155'));
    });

    test('lets a deficit in one currency offset a surplus in another', () async {
      final result = await _useCase(
        transactions: [
          _transaction(id: 't-1', type: 'income', amount: '100'),
          _transaction(
            id: 't-2',
            type: 'expense',
            amount: '1000',
            currencyCode: 'ZAR',
          ),
        ],
        goals: defaultGoals,
        rates: const {'ZAR>USD': '0.055'},
      )(now: now, displayCurrency: CurrencyCode.usd);

      final reminder = result.getOrElse((_) => throw StateError('expected right'));
      expect(reminder.surplus.amount, Decimal.parse('45'));
      expect(reminder.shouldPrompt, isTrue);
    });

    test('does not prompt when the month ran a deficit', () async {
      final result = await _useCase(
        transactions: [
          _transaction(id: 't-1', type: 'income', amount: '500'),
          _transaction(id: 't-2', type: 'expense', amount: '900'),
        ],
        goals: defaultGoals,
      )(now: now, displayCurrency: CurrencyCode.usd);

      final reminder = result.getOrElse((_) => throw StateError('expected right'));
      expect(reminder.surplus.amount, Decimal.parse('-400'));
      expect(reminder.shouldPrompt, isFalse);
    });

    test('does not prompt when income exactly matches expenses', () async {
      final result = await _useCase(
        transactions: [
          _transaction(id: 't-1', type: 'income', amount: '500'),
          _transaction(id: 't-2', type: 'expense', amount: '500'),
        ],
        goals: defaultGoals,
      )(now: now, displayCurrency: CurrencyCode.usd);

      final reminder = result.getOrElse((_) => throw StateError('expected right'));
      expect(reminder.shouldPrompt, isFalse);
    });

    test('fails when a required exchange rate is missing', () async {
      final result = await _useCase(
        transactions: [
          _transaction(
            id: 't-1',
            type: 'income',
            amount: '1000',
            currencyCode: 'ZAR',
          ),
        ],
        goals: defaultGoals,
      )(now: now, displayCurrency: CurrencyCode.usd);

      expect(result.isLeft(), isTrue);
    });
  });

  group('BuildContributionReminderUseCase goal selection', () {
    test('picks the highest-priority incomplete goal', () async {
      final result = await _useCase(
        transactions: [_transaction(id: 't-1', type: 'income', amount: '100')],
        goals: [
          _goal(id: 'g-2', name: 'Car', priorityOrder: 2),
          _goal(id: 'g-1', name: 'Emergency Fund', priorityOrder: 1),
        ],
      )(now: now, displayCurrency: CurrencyCode.usd);

      final reminder = result.getOrElse((_) => throw StateError('expected right'));
      expect(reminder.topGoal!.name, 'Emergency Fund');
      expect(reminder.topGoal!.percentFunded, 25);
    });

    test('does not prompt when every goal is complete', () async {
      final result = await _useCase(
        transactions: [_transaction(id: 't-1', type: 'income', amount: '100')],
        goals: [
          _goal(id: 'g-1', name: 'Done', priorityOrder: 1, isCompleted: true),
        ],
      )(now: now, displayCurrency: CurrencyCode.usd);

      final reminder = result.getOrElse((_) => throw StateError('expected right'));
      expect(reminder.topGoal, isNull);
      expect(reminder.shouldPrompt, isFalse);
    });
  });
}
