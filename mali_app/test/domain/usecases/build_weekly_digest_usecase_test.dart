import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mali_app/domain/entities/exchange_rate.dart';
import 'package:mali_app/domain/entities/goal_contribution.dart';
import 'package:mali_app/domain/entities/savings_goal.dart';
import 'package:mali_app/domain/entities/transaction.dart';
import 'package:mali_app/domain/repositories/exchange_rate_repository.dart';
import 'package:mali_app/domain/repositories/goal_repository.dart';
import 'package:mali_app/domain/repositories/transaction_repository.dart';
import 'package:mali_app/domain/usecases/build_weekly_digest_usecase.dart';
import 'package:mali_app/domain/usecases/convert_money_usecase.dart';
import 'package:mali_app/domain/value_objects/currency_code.dart';

class _FakeTransactionRepository implements ITransactionRepository {
  _FakeTransactionRepository(this._transactions);

  final List<Transaction> _transactions;
  TransactionQuery? lastQuery;
  Object? error;

  @override
  Future<List<Transaction>> list({required TransactionQuery query}) async {
    lastQuery = query;
    if (error != null) {
      throw error!;
    }
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
  _FakeExchangeRateRepository([this._rates = const {}]);

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
    final timestamp = DateTime(2026, 9, 20);
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

Transaction _expense({
  required String id,
  required String amount,
  required DateTime date,
  String? categoryId = 'cat-food',
  String currencyCode = 'USD',
}) {
  return Transaction(
    id: id,
    userId: 'u-1',
    walletId: 'w-1',
    categoryId: categoryId,
    type: 'expense',
    amount: amount,
    currencyCode: currencyCode,
    title: 'Expense $id',
    transactionDate: date,
    isSynced: false,
    createdAt: date,
    updatedAt: date,
  );
}

SavingsGoal _goal({
  required String id,
  required String name,
  required int priorityOrder,
  String targetAmount = '1000',
  String currentAmount = '250',
  bool isCompleted = false,
}) {
  final timestamp = DateTime(2026, 9, 1);
  return SavingsGoal(
    id: id,
    userId: 'u-1',
    name: name,
    targetAmount: targetAmount,
    currentAmount: currentAmount,
    currencyCode: 'USD',
    priorityOrder: priorityOrder,
    isCompleted: isCompleted,
    isSynced: false,
    createdAt: timestamp,
    updatedAt: timestamp,
  );
}

BuildWeeklyDigestUseCase _useCase({
  List<Transaction> transactions = const [],
  List<SavingsGoal> goals = const [],
  Map<String, String> rates = const {},
  _FakeTransactionRepository? transactionRepository,
}) {
  return BuildWeeklyDigestUseCase(
    transactionRepository:
        transactionRepository ?? _FakeTransactionRepository(transactions),
    goalRepository: _FakeGoalRepository(goals),
    convertMoney: ConvertMoneyUseCase(
      exchangeRateRepository: _FakeExchangeRateRepository(rates),
    ),
  );
}

void main() {
  // Sunday evening.
  final now = DateTime(2026, 9, 20, 18, 5);

  group('BuildWeeklyDigestUseCase window', () {
    test('covers the seven calendar days ending today', () {
      final window = BuildWeeklyDigestUseCase.windowEndingAt(now);

      expect(window.start, DateTime(2026, 9, 14));
      expect(window.end, DateTime(2026, 9, 20, 23, 59, 59, 999, 999));
    });

    test('spans a month boundary without drifting', () {
      final window = BuildWeeklyDigestUseCase.windowEndingAt(
        DateTime(2026, 10, 4, 18),
      );

      expect(window.start, DateTime(2026, 9, 28));
    });

    test('queries only expenses inside the window', () async {
      final repository = _FakeTransactionRepository(const []);

      await _useCase(transactionRepository: repository)(
        now: now,
        displayCurrency: CurrencyCode.usd,
      );

      final query = repository.lastQuery!;
      expect(query.type, 'expense');
      expect(query.dateFrom, DateTime(2026, 9, 14));
      expect(query.dateTo, DateTime(2026, 9, 20, 23, 59, 59, 999, 999));
    });
  });

  group('BuildWeeklyDigestUseCase aggregation', () {
    test('totals spending and ranks the biggest category', () async {
      final result = await _useCase(
        transactions: [
          _expense(id: 't-1', amount: '20.50', date: DateTime(2026, 9, 15)),
          _expense(id: 't-2', amount: '9.50', date: DateTime(2026, 9, 17)),
          _expense(
            id: 't-3',
            amount: '45.00',
            date: DateTime(2026, 9, 18),
            categoryId: 'cat-rent',
          ),
        ],
      )(now: now, displayCurrency: CurrencyCode.usd);

      final digest = result.getOrElse((_) => throw StateError('expected right'));
      expect(digest.totalSpent.amount, Decimal.parse('75.00'));
      expect(digest.totalSpent.currency, CurrencyCode.usd);
      expect(digest.expenseCount, 3);
      expect(digest.topCategory!.categoryId, 'cat-rent');
      expect(digest.topCategory!.amount.amount, Decimal.parse('45.00'));
    });

    test('converts foreign currency spend into the display currency', () async {
      final result = await _useCase(
        transactions: [
          _expense(id: 't-1', amount: '10', date: DateTime(2026, 9, 15)),
          _expense(
            id: 't-2',
            amount: '100',
            date: DateTime(2026, 9, 16),
            currencyCode: 'ZAR',
            categoryId: 'cat-transport',
          ),
        ],
        rates: const {'ZAR>USD': '0.055'},
      )(now: now, displayCurrency: CurrencyCode.usd);

      final digest = result.getOrElse((_) => throw StateError('expected right'));
      expect(digest.totalSpent.amount, Decimal.parse('15.5'));
      expect(digest.topCategory!.categoryId, 'cat-food');
    });

    test('fails when a required exchange rate is missing', () async {
      final result = await _useCase(
        transactions: [
          _expense(
            id: 't-1',
            amount: '100',
            date: DateTime(2026, 9, 16),
            currencyCode: 'ZAR',
          ),
        ],
      )(now: now, displayCurrency: CurrencyCode.usd);

      expect(result.isLeft(), isTrue);
    });

    test('counts uncategorised spend in the total but not the ranking',
        () async {
      final result = await _useCase(
        transactions: [
          _expense(
            id: 't-1',
            amount: '30',
            date: DateTime(2026, 9, 16),
            categoryId: null,
          ),
        ],
      )(now: now, displayCurrency: CurrencyCode.usd);

      final digest = result.getOrElse((_) => throw StateError('expected right'));
      expect(digest.totalSpent.amount, Decimal.parse('30'));
      expect(digest.topCategory, isNull);
    });

    test('maps repository errors to a failure', () async {
      final repository = _FakeTransactionRepository(const [])
        ..error = StateError('db unavailable');

      final result = await _useCase(transactionRepository: repository)(
        now: now,
        displayCurrency: CurrencyCode.usd,
      );

      expect(result.isLeft(), isTrue);
    });
  });

  group('BuildWeeklyDigestUseCase goals', () {
    test('reports the highest-priority incomplete goal', () async {
      final result = await _useCase(
        goals: [
          _goal(id: 'g-2', name: 'Car', priorityOrder: 2),
          _goal(
            id: 'g-1',
            name: 'Emergency Fund',
            priorityOrder: 1,
            currentAmount: '750',
          ),
        ],
      )(now: now, displayCurrency: CurrencyCode.usd);

      final digest = result.getOrElse((_) => throw StateError('expected right'));
      expect(digest.topGoal!.name, 'Emergency Fund');
      expect(digest.topGoal!.percentFunded, 75);
    });

    test('skips completed goals', () async {
      final result = await _useCase(
        goals: [
          _goal(id: 'g-1', name: 'Done', priorityOrder: 1, isCompleted: true),
          _goal(id: 'g-2', name: 'Car', priorityOrder: 2),
        ],
      )(now: now, displayCurrency: CurrencyCode.usd);

      final digest = result.getOrElse((_) => throw StateError('expected right'));
      expect(digest.topGoal!.name, 'Car');
    });

    test('reports no goal when none are active', () async {
      final result = await _useCase()(
        now: now,
        displayCurrency: CurrencyCode.usd,
      );

      final digest = result.getOrElse((_) => throw StateError('expected right'));
      expect(digest.topGoal, isNull);
      expect(digest.hasNothingToReport, isTrue);
    });
  });
}
