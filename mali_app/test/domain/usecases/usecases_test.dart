import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:mali_app/core/error/failure.dart';
import 'package:mali_app/domain/entities/budget.dart';
import 'package:mali_app/domain/entities/exchange_rate.dart';
import 'package:mali_app/domain/entities/goal_contribution.dart';
import 'package:mali_app/domain/entities/savings_goal.dart';
import 'package:mali_app/domain/entities/transaction.dart';
import 'package:mali_app/domain/entities/wallet.dart';
import 'package:mali_app/domain/repositories/budget_repository.dart';
import 'package:mali_app/domain/repositories/exchange_rate_repository.dart';
import 'package:mali_app/domain/repositories/goal_repository.dart';
import 'package:mali_app/domain/repositories/transaction_repository.dart';
import 'package:mali_app/domain/repositories/wallet_repository.dart';
import 'package:mali_app/domain/usecases/allocate_to_goal_usecase.dart';
import 'package:mali_app/domain/usecases/calculate_net_worth_usecase.dart';
import 'package:mali_app/domain/usecases/get_monthly_summary_usecase.dart';
import 'package:mali_app/domain/usecases/log_transaction_usecase.dart';
import 'package:mali_app/domain/usecases/sync_usecase.dart';
import 'package:mali_app/domain/value_objects/currency_code.dart';

import 'usecases_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<ITransactionRepository>(),
  MockSpec<IWalletRepository>(),
  MockSpec<IBudgetRepository>(),
  MockSpec<IGoalRepository>(),
  MockSpec<IExchangeRateRepository>(),
  MockSpec<ISyncPushGateway>(),
  MockSpec<ISyncPullGateway>(),
])
void main() {
  group('LogTransactionUseCase', () {
    late MockITransactionRepository transactionRepository;
    late MockIWalletRepository walletRepository;
    late MockIBudgetRepository budgetRepository;
    late LogTransactionUseCase useCase;

    setUp(() {
      transactionRepository = MockITransactionRepository();
      walletRepository = MockIWalletRepository();
      budgetRepository = MockIBudgetRepository();
      useCase = LogTransactionUseCase(
        transactionRepository: transactionRepository,
        walletRepository: walletRepository,
        budgetRepository: budgetRepository,
      );
    });

    test('returns validation failure when amount is not positive', () async {
      final result = await useCase(_transaction(amount: '0'));
      expect(result.isLeft(), isTrue);
    });

    test('returns not found failure when wallet does not exist', () async {
      when(walletRepository.findById('w-1')).thenAnswer((_) async => null);
      final result = await useCase(_transaction());
      expect(result.swap().getOrElse((_) => const StorageFailure(message: 'x')),
          isA<NotFoundFailure>());
    });

    test('updates wallet, saves transaction, and emits 80% budget alert', () async {
      when(walletRepository.findById('w-1')).thenAnswer((_) async => _wallet(balance: '100'));
      when(walletRepository.updateBalance(walletId: 'w-1', balance: '90'))
          .thenAnswer((_) async {});
      when(transactionRepository.save(_transaction(type: 'expense', amount: '10')))
          .thenAnswer((_) async {});
      when(budgetRepository.watchMonthBudgets(year: 2026, month: 4))
          .thenAnswer((_) => Stream.value([_budget(amount: '100', spentAmount: '70')]));
      when(budgetRepository.updateSpentAmount(budgetId: 'b-1', spentAmount: '80'))
          .thenAnswer((_) async {});

      final result = await useCase(_transaction(type: 'expense', amount: '10'));
      expect(result.isRight(), isTrue);
      final value = result.getOrElse((_) => LogTransactionResult(updatedWallet: _wallet()));
      expect(value.updatedWallet.balance, '90');
      expect(value.budgetThresholdAlert, isNotNull);
    });
  });

  group('AllocateToGoalUseCase', () {
    late MockIGoalRepository goalRepository;
    late AllocateToGoalUseCase useCase;

    setUp(() {
      goalRepository = MockIGoalRepository();
      useCase = AllocateToGoalUseCase(goalRepository: goalRepository);
    });

    test('returns validation failure for non-positive contribution', () async {
      final result = await useCase.call(contribution: _contribution(amount: '-1'));
      expect(result.swap().getOrElse((_) => const StorageFailure(message: 'x')),
          isA<ValidationFailure>());
    });

    test('returns not found failure when goal is absent', () async {
      when(goalRepository.watchActiveGoals()).thenAnswer((_) => Stream.value(const []));
      final result = await useCase.call(contribution: _contribution());
      expect(result.swap().getOrElse((_) => const StorageFailure(message: 'x')),
          isA<NotFoundFailure>());
    });

    test('updates goal and returns reached milestones', () async {
      when(goalRepository.watchActiveGoals())
          .thenAnswer((_) => Stream.value([_goal(currentAmount: '20', targetAmount: '100')]));
      when(goalRepository.addContribution(_contribution(amount: '60')))
          .thenAnswer((_) async {});
      when(goalRepository.saveGoal(any)).thenAnswer((_) async {});

      final result = await useCase.call(contribution: _contribution(amount: '60'));
      expect(result.isRight(), isTrue);
      final value = result.getOrElse(
        (_) => AllocateToGoalResult(updatedGoal: _goal(), reachedMilestones: const []),
      );
      expect(value.updatedGoal.currentAmount, '80');
      expect(value.reachedMilestones.length, 3);
    });
  });

  group('CalculateNetWorthUseCase', () {
    late MockIWalletRepository walletRepository;
    late MockIExchangeRateRepository exchangeRateRepository;
    late CalculateNetWorthUseCase useCase;

    setUp(() {
      walletRepository = MockIWalletRepository();
      exchangeRateRepository = MockIExchangeRateRepository();
      useCase = CalculateNetWorthUseCase(
        walletRepository: walletRepository,
        exchangeRateRepository: exchangeRateRepository,
      );
    });

    test('returns total when wallets are already in display currency', () async {
      when(walletRepository.watchActive()).thenAnswer(
        (_) => Stream.value([
          _wallet(id: 'w-1', currencyCode: 'USD', balance: '10'),
          _wallet(id: 'w-2', currencyCode: 'USD', balance: '15'),
        ]),
      );

      final result = await useCase.call(displayCurrency: CurrencyCode.usd);
      expect(result.isRight(), isTrue);
      expect(result.getOrElse((_) => throw StateError('expected right')).total.amount,
          Decimal.parse('25'));
    });

    test('uses direct exchange rate for conversion', () async {
      when(walletRepository.watchActive())
          .thenAnswer((_) => Stream.value([_wallet(currencyCode: 'ZAR', balance: '20')]));
      when(exchangeRateRepository.getRate(
        baseCurrencyCode: CurrencyCode.zar,
        quoteCurrencyCode: CurrencyCode.usd,
      )).thenAnswer((_) async => _rate(base: 'ZAR', quote: 'USD', rate: '0.05'));

      final result = await useCase.call(displayCurrency: CurrencyCode.usd);
      expect(result.getOrElse((_) => throw StateError('expected right')).total.amount,
          Decimal.parse('1'));
    });

    test('returns not found when no usable exchange rate exists', () async {
      when(walletRepository.watchActive())
          .thenAnswer((_) => Stream.value([_wallet(currencyCode: 'BWP', balance: '20')]));
      when(exchangeRateRepository.getRate(
        baseCurrencyCode: CurrencyCode.bwp,
        quoteCurrencyCode: CurrencyCode.usd,
      )).thenAnswer((_) async => null);

      final result = await useCase.call(displayCurrency: CurrencyCode.usd);
      expect(result.swap().getOrElse((_) => const StorageFailure(message: 'x')),
          isA<NotFoundFailure>());
    });
  });

  group('GetMonthlySummaryUseCase', () {
    late MockITransactionRepository transactionRepository;
    late GetMonthlySummaryUseCase useCase;

    setUp(() {
      transactionRepository = MockITransactionRepository();
      useCase = GetMonthlySummaryUseCase(transactionRepository: transactionRepository);
    });

    test('returns validation failure for invalid month', () async {
      final result = await useCase.call(year: 2026, month: 13);
      expect(result.swap().getOrElse((_) => const StorageFailure(message: 'x')),
          isA<ValidationFailure>());
    });

    test('aggregates income and expenses by currency', () async {
      when(transactionRepository.list(query: anyNamed('query'))).thenAnswer(
        (_) async => [
          _transaction(type: 'income', amount: '100', currencyCode: 'USD'),
          _transaction(type: 'expense', amount: '40', currencyCode: 'USD', categoryId: 'cat-food'),
          _transaction(type: 'expense', amount: '20', currencyCode: 'USD', categoryId: 'cat-food'),
        ],
      );

      final result = await useCase.call(year: 2026, month: 4);
      final value = result.getOrElse((_) => throw StateError('expected right'));
      expect(value.transactionsCount, 3);
      expect(value.totalsByCurrency.first.net, Decimal.parse('40'));
      expect(value.categoryBreakdown.first.amount, Decimal.parse('60'));
    });

    test('returns storage failure when amount parsing fails', () async {
      when(transactionRepository.list(query: anyNamed('query')))
          .thenAnswer((_) async => [_transaction(amount: 'invalid')]);

      final result = await useCase.call(year: 2026, month: 4);
      expect(result.swap().getOrElse((_) => const ValidationFailure(message: 'x')),
          isA<StorageFailure>());
    });
  });

  group('SyncUseCase', () {
    late MockITransactionRepository transactionRepository;
    late MockISyncPushGateway syncPushGateway;
    late MockISyncPullGateway syncPullGateway;
    late SyncUseCase useCase;

    setUp(() {
      transactionRepository = MockITransactionRepository();
      syncPushGateway = MockISyncPushGateway();
      syncPullGateway = MockISyncPullGateway();
      useCase = SyncUseCase(
        transactionRepository: transactionRepository,
        syncPushGateway: syncPushGateway,
        syncPullGateway: syncPullGateway,
      );
    });

    test('pushes unsynced transactions and stores pulled changes', () async {
      final unsynced = [_transaction(id: 'tx-local', isSynced: false)];
      final pulled = [_transaction(id: 'tx-remote', isSynced: false)];
      when(transactionRepository.listUnsynced()).thenAnswer((_) async => unsynced);
      when(syncPushGateway.pushTransactions(unsynced))
          .thenAnswer((_) async => PushResult(accepted: unsynced, rejected: const []));
      when(syncPullGateway.pullChanges(since: DateTime(2026, 1, 1)))
          .thenAnswer((_) async => PullResult(transactions: pulled));
      when(transactionRepository.save(any)).thenAnswer((_) async {});

      final result = await useCase.call(since: DateTime(2026, 1, 1));
      final value = result.getOrElse((_) => throw StateError('expected right'));
      expect(value.pushedAcceptedCount, 1);
      expect(value.pulledCount, 1);
    });

    test('reports rejected items count from push response', () async {
      final local = [_transaction(id: 'tx-1', isSynced: false)];
      when(transactionRepository.listUnsynced()).thenAnswer((_) async => local);
      when(syncPushGateway.pushTransactions(local)).thenAnswer(
        (_) async => PushResult(
          accepted: const [],
          rejected: [RejectedSyncItem(transaction: local.first, reason: 'conflict')],
        ),
      );
      when(syncPullGateway.pullChanges(since: DateTime(2026, 1, 1)))
          .thenAnswer((_) async => const PullResult(transactions: []));

      final result = await useCase.call(since: DateTime(2026, 1, 1));
      final value = result.getOrElse((_) => throw StateError('expected right'));
      expect(value.pushedRejectedCount, 1);
    });

    test('returns network failure when sync gateway throws', () async {
      when(transactionRepository.listUnsynced()).thenAnswer((_) async => const []);
      when(syncPushGateway.pushTransactions(const [])).thenThrow(Exception('network down'));

      final result = await useCase.call(since: DateTime(2026, 1, 1));
      expect(result.swap().getOrElse((_) => const StorageFailure(message: 'x')),
          isA<NetworkFailure>());
    });
  });
}

Transaction _transaction({
  String id = 'tx-1',
  String userId = 'u-1',
  String walletId = 'w-1',
  String? categoryId = 'cat-1',
  String? syncId = 'sync-1',
  String type = 'expense',
  String amount = '10',
  String currencyCode = 'USD',
  String? exchangeRate,
  String title = 'title',
  String? notes = 'note',
  DateTime? transactionDate,
  bool isSynced = false,
}) {
  final now = DateTime(2026, 4, 10);
  return Transaction(
    id: id,
    userId: userId,
    walletId: walletId,
    categoryId: categoryId,
    syncId: syncId,
    type: type,
    amount: amount,
    currencyCode: currencyCode,
    exchangeRate: exchangeRate,
    title: title,
    notes: notes,
    transactionDate: transactionDate ?? now,
    isSynced: isSynced,
    createdAt: now,
    updatedAt: now,
  );
}

Wallet _wallet({
  String id = 'w-1',
  String userId = 'u-1',
  String name = 'main',
  String currencyCode = 'USD',
  String balance = '100',
}) {
  final now = DateTime(2026, 4, 1);
  return Wallet(
    id: id,
    userId: userId,
    name: name,
    currencyCode: currencyCode,
    balance: balance,
    isArchived: false,
    isSynced: false,
    createdAt: now,
    updatedAt: now,
  );
}

Budget _budget({
  String id = 'b-1',
  String categoryId = 'cat-1',
  String currencyCode = 'USD',
  String amount = '100',
  String spentAmount = '70',
}) {
  final now = DateTime(2026, 4, 1);
  return Budget(
    id: id,
    userId: 'u-1',
    categoryId: categoryId,
    currencyCode: currencyCode,
    amount: amount,
    spentAmount: spentAmount,
    month: 4,
    year: 2026,
    rolloverEnabled: false,
    isSynced: false,
    createdAt: now,
    updatedAt: now,
  );
}

SavingsGoal _goal({
  String id = 'g-1',
  String currentAmount = '20',
  String targetAmount = '100',
}) {
  final now = DateTime(2026, 4, 1);
  return SavingsGoal(
    id: id,
    userId: 'u-1',
    name: 'Emergency',
    targetAmount: targetAmount,
    currentAmount: currentAmount,
    currencyCode: 'USD',
    priorityOrder: 0,
    isCompleted: false,
    isSynced: false,
    createdAt: now,
    updatedAt: now,
  );
}

GoalContribution _contribution({
  String id = 'gc-1',
  String goalId = 'g-1',
  String amount = '10',
  String currencyCode = 'USD',
}) {
  final now = DateTime(2026, 4, 10);
  return GoalContribution(
    id: id,
    goalId: goalId,
    amount: amount,
    currencyCode: currencyCode,
    contributionDate: now,
    isSynced: false,
    createdAt: now,
    updatedAt: now,
  );
}

ExchangeRate _rate({
  required String base,
  required String quote,
  required String rate,
}) {
  final now = DateTime(2026, 4, 1);
  return ExchangeRate(
    id: '$base-$quote',
    baseCurrencyCode: base,
    quoteCurrencyCode: quote,
    rate: rate,
    isManual: false,
    rateDate: now,
    isSynced: true,
    createdAt: now,
    updatedAt: now,
  );
}
