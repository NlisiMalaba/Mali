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
import 'package:mali_app/domain/repositories/exchange_rate_fetcher.dart';
import 'package:mali_app/domain/repositories/exchange_rate_repository.dart';
import 'package:mali_app/domain/repositories/biometric_authenticator.dart';
import 'package:mali_app/domain/repositories/pin_lock_repository.dart';
import 'package:mali_app/domain/repositories/goal_repository.dart';
import 'package:mali_app/domain/repositories/transaction_repository.dart';
import 'package:mali_app/domain/repositories/wallet_repository.dart';
import 'package:mali_app/domain/events/budget_exceeded_event.dart';
import 'package:mali_app/domain/services/budget_exceeded_event_publisher.dart';
import 'package:mali_app/domain/usecases/allocate_to_goal_usecase.dart';
import 'package:mali_app/domain/usecases/calculate_net_worth_usecase.dart';
import 'package:mali_app/domain/usecases/convert_money_usecase.dart';
import 'package:mali_app/domain/usecases/archive_wallet_usecase.dart';
import 'package:mali_app/domain/usecases/create_budget_usecase.dart';
import 'package:mali_app/domain/usecases/create_wallet_usecase.dart';
import 'package:mali_app/domain/usecases/get_monthly_summary_usecase.dart';
import 'package:mali_app/domain/usecases/log_transaction_usecase.dart';
import 'package:mali_app/domain/usecases/refresh_exchange_rates_usecase.dart';
import 'package:mali_app/domain/usecases/disable_pin_lock_usecase.dart';
import 'package:mali_app/domain/usecases/set_manual_exchange_rate_usecase.dart';
import 'package:mali_app/domain/usecases/set_biometric_unlock_usecase.dart';
import 'package:mali_app/domain/usecases/set_pin_usecase.dart';
import 'package:mali_app/domain/usecases/verify_pin_usecase.dart';
import 'package:mali_app/domain/usecases/sync_usecase.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mali_app/domain/value_objects/currency_code.dart';
import 'package:mali_app/domain/value_objects/money.dart';

import 'usecases_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<ITransactionRepository>(),
  MockSpec<IWalletRepository>(),
  MockSpec<IBudgetRepository>(),
  MockSpec<IGoalRepository>(),
  MockSpec<IExchangeRateRepository>(),
  MockSpec<IExchangeRateFetcher>(),
  MockSpec<IPinLockRepository>(),
  MockSpec<IBiometricAuthenticator>(),
  MockSpec<ISyncPushGateway>(),
  MockSpec<ISyncPullGateway>(),
])
void main() {
  provideDummy<Either<Failure, List<FetchedExchangeRate>>>(
    right(const <FetchedExchangeRate>[]),
  );

  group('LogTransactionUseCase', () {
    late MockITransactionRepository transactionRepository;
    late MockIWalletRepository walletRepository;
    late MockIBudgetRepository budgetRepository;
    late _RecordingBudgetExceededEventPublisher eventPublisher;
    late LogTransactionUseCase useCase;

    setUp(() {
      transactionRepository = MockITransactionRepository();
      walletRepository = MockIWalletRepository();
      budgetRepository = MockIBudgetRepository();
      eventPublisher = _RecordingBudgetExceededEventPublisher();
      useCase = LogTransactionUseCase(
        transactionRepository: transactionRepository,
        walletRepository: walletRepository,
        budgetRepository: budgetRepository,
        budgetExceededEventPublisher: eventPublisher,
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

    test('updates wallet, saves transaction, and fires 80% budget event', () async {
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
      expect(value.budgetExceededEvent, isNotNull);
      expect(value.budgetExceededEvent!.isWarning, isTrue);
      expect(eventPublisher.published, hasLength(1));
      expect(
        eventPublisher.published.single.thresholdRatio,
        BudgetExceededEvent.warningThresholdRatio,
      );
    });

    test('fires 100% budget event when spending reaches budget limit', () async {
      when(walletRepository.findById('w-1')).thenAnswer((_) async => _wallet(balance: '100'));
      when(walletRepository.updateBalance(walletId: 'w-1', balance: '85'))
          .thenAnswer((_) async {});
      when(transactionRepository.save(_transaction(type: 'expense', amount: '15')))
          .thenAnswer((_) async {});
      when(budgetRepository.watchMonthBudgets(year: 2026, month: 4))
          .thenAnswer((_) => Stream.value([_budget(amount: '100', spentAmount: '85')]));
      when(budgetRepository.updateSpentAmount(budgetId: 'b-1', spentAmount: '100'))
          .thenAnswer((_) async {});

      final result = await useCase(_transaction(type: 'expense', amount: '15'));
      expect(result.isRight(), isTrue);
      final value = result.getOrElse((_) => LogTransactionResult(updatedWallet: _wallet()));
      expect(value.budgetExceededEvent, isNotNull);
      expect(value.budgetExceededEvent!.isExceeded, isTrue);
      expect(eventPublisher.published, hasLength(1));
      expect(
        eventPublisher.published.single.thresholdRatio,
        BudgetExceededEvent.exceededThresholdRatio,
      );
    });

    test('does not fire budget event when threshold was already crossed', () async {
      when(walletRepository.findById('w-1')).thenAnswer((_) async => _wallet(balance: '100'));
      when(walletRepository.updateBalance(walletId: 'w-1', balance: '90'))
          .thenAnswer((_) async {});
      when(transactionRepository.save(_transaction(type: 'expense', amount: '10')))
          .thenAnswer((_) async {});
      when(budgetRepository.watchMonthBudgets(year: 2026, month: 4))
          .thenAnswer((_) => Stream.value([_budget(amount: '100', spentAmount: '85')]));
      when(budgetRepository.updateSpentAmount(budgetId: 'b-1', spentAmount: '95'))
          .thenAnswer((_) async {});

      final result = await useCase(_transaction(type: 'expense', amount: '10'));
      expect(result.isRight(), isTrue);
      final value = result.getOrElse((_) => LogTransactionResult(updatedWallet: _wallet()));
      expect(value.budgetExceededEvent, isNull);
      expect(eventPublisher.published, isEmpty);
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

  group('CreateWalletUseCase', () {
    late MockIWalletRepository walletRepository;
    late CreateWalletUseCase useCase;

    setUp(() {
      walletRepository = MockIWalletRepository();
      useCase = CreateWalletUseCase(walletRepository: walletRepository);
    });

    test('returns validation failure when name is empty', () async {
      final result = await useCase(
        const CreateWalletParams(
          userId: 'u-1',
          name: '   ',
          currencyCode: CurrencyCode.usd,
          openingBalance: '10',
        ),
      );

      expect(result.isLeft(), isTrue);
      expect(
        result.getLeft().toNullable(),
        isA<ValidationFailure>().having((f) => f.field, 'field', 'name'),
      );
    });

    test('returns validation failure for invalid opening balance', () async {
      final result = await useCase(
        const CreateWalletParams(
          userId: 'u-1',
          name: 'EcoCash USD',
          currencyCode: CurrencyCode.usd,
          openingBalance: 'not-a-number',
        ),
      );

      expect(result.isLeft(), isTrue);
      expect(
        result.getLeft().toNullable(),
        isA<ValidationFailure>().having((f) => f.field, 'field', 'openingBalance'),
      );
    });

    test('saves wallet with parsed balance', () async {
      when(walletRepository.save(any)).thenAnswer((_) async {});

      final result = await useCase(
        const CreateWalletParams(
          userId: 'u-1',
          name: 'EcoCash USD',
          currencyCode: CurrencyCode.usd,
          openingBalance: '25.50',
        ),
      );

      expect(result.isRight(), isTrue);
      final wallet = result.getOrElse((_) => throw StateError('expected right'));
      expect(wallet.name, 'EcoCash USD');
      expect(wallet.currencyCode, 'USD');
      expect(wallet.balance, '25.5');
      expect(wallet.userId, 'u-1');
      verify(walletRepository.save(any)).called(1);
    });

    test('treats empty opening balance as zero', () async {
      when(walletRepository.save(any)).thenAnswer((_) async {});

      final result = await useCase(
        const CreateWalletParams(
          userId: 'u-1',
          name: 'Cash',
          currencyCode: CurrencyCode.zar,
          openingBalance: '',
        ),
      );

      expect(result.getOrElse((_) => throw StateError('expected right')).balance, '0');
    });
  });

  group('CreateBudgetUseCase', () {
    late MockIBudgetRepository budgetRepository;
    late CreateBudgetUseCase useCase;

    setUp(() {
      budgetRepository = MockIBudgetRepository();
      useCase = CreateBudgetUseCase(budgetRepository: budgetRepository);
    });

    test('returns validation failure when amount is not positive', () async {
      when(
        budgetRepository.watchMonthBudgets(year: 2026, month: 5),
      ).thenAnswer((_) => Stream.value(const []));

      final result = await useCase(
        const CreateBudgetParams(
          userId: 'u-1',
          categoryId: 'cat-food',
          currencyCode: CurrencyCode.usd,
          amount: '0',
          month: 5,
          year: 2026,
          rolloverEnabled: false,
        ),
      );

      expect(result.isLeft(), isTrue);
      expect(
        result.getLeft().toNullable(),
        isA<ValidationFailure>().having((f) => f.field, 'field', 'amount'),
      );
    });

    test('returns validation failure when duplicate category and currency exists',
        () async {
      when(
        budgetRepository.watchMonthBudgets(year: 2026, month: 5),
      ).thenAnswer(
        (_) => Stream.value([
          _budget(
            categoryId: 'cat-food',
            currencyCode: 'USD',
            month: 5,
            year: 2026,
          ),
        ]),
      );

      final result = await useCase(
        const CreateBudgetParams(
          userId: 'u-1',
          categoryId: 'cat-food',
          currencyCode: CurrencyCode.usd,
          amount: '100',
          month: 5,
          year: 2026,
          rolloverEnabled: true,
        ),
      );

      expect(result.isLeft(), isTrue);
      expect(
        result.getLeft().toNullable(),
        isA<ValidationFailure>().having((f) => f.field, 'field', 'categoryId'),
      );
    });

    test('saves budget with rollover flag', () async {
      when(
        budgetRepository.watchMonthBudgets(year: 2026, month: 5),
      ).thenAnswer((_) => Stream.value(const []));
      when(budgetRepository.save(any)).thenAnswer((_) async {});

      final result = await useCase(
        const CreateBudgetParams(
          userId: 'u-1',
          categoryId: 'cat-food',
          currencyCode: CurrencyCode.usd,
          amount: '250',
          month: 5,
          year: 2026,
          rolloverEnabled: true,
        ),
      );

      expect(result.isRight(), isTrue);
      final budget = result.getOrElse((_) => throw StateError('expected right'));
      expect(budget.amount, '250');
      expect(budget.spentAmount, '0');
      expect(budget.rolloverEnabled, isTrue);
      expect(budget.month, 5);
      expect(budget.year, 2026);
      verify(budgetRepository.save(any)).called(1);
    });
  });

  group('ArchiveWalletUseCase', () {
    late MockIWalletRepository walletRepository;
    late ArchiveWalletUseCase useCase;

    setUp(() {
      walletRepository = MockIWalletRepository();
      useCase = ArchiveWalletUseCase(walletRepository: walletRepository);
    });

    test('returns not found when wallet is missing', () async {
      when(walletRepository.findById('missing')).thenAnswer((_) async => null);

      final result = await useCase.call(walletId: 'missing');
      expect(result.isLeft(), isTrue);
      verifyNever(walletRepository.archive(walletId: anyNamed('walletId')));
    });

    test('archives wallet when found', () async {
      when(walletRepository.findById('w-1')).thenAnswer((_) async => _wallet());
      when(walletRepository.archive(walletId: 'w-1')).thenAnswer((_) async {});

      final result = await useCase.call(walletId: 'w-1');

      expect(result.isRight(), isTrue);
      expect(
        result.getOrElse((_) => throw StateError('expected right')).isArchived,
        isTrue,
      );
      verify(walletRepository.archive(walletId: 'w-1')).called(1);
    });
  });

  group('ConvertMoneyUseCase', () {
    late MockIExchangeRateRepository exchangeRateRepository;
    late ConvertMoneyUseCase useCase;

    setUp(() {
      exchangeRateRepository = MockIExchangeRateRepository();
      useCase = ConvertMoneyUseCase(
        exchangeRateRepository: exchangeRateRepository,
      );
    });

    test('returns same money when currencies match', () async {
      final money = Money(amount: Decimal.parse('10'), currency: CurrencyCode.usd);

      final result = await useCase(
        money: money,
        targetCurrency: CurrencyCode.usd,
      );

      expect(result.getOrElse((_) => throw StateError('expected right')), money);
    });

    test('converts using direct exchange rate', () async {
      when(exchangeRateRepository.getRate(
        baseCurrencyCode: CurrencyCode.zar,
        quoteCurrencyCode: CurrencyCode.usd,
      )).thenAnswer((_) async => _rate(base: 'ZAR', quote: 'USD', rate: '0.05'));

      final result = await useCase(
        money: Money(amount: Decimal.parse('20'), currency: CurrencyCode.zar),
        targetCurrency: CurrencyCode.usd,
      );

      expect(
        result.getOrElse((_) => throw StateError('expected right')).amount,
        Decimal.parse('1'),
      );
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
        convertMoneyUseCase: ConvertMoneyUseCase(
          exchangeRateRepository: exchangeRateRepository,
        ),
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

  group('SetBiometricUnlockUseCase', () {
    late MockIPinLockRepository pinLockRepository;
    late MockIBiometricAuthenticator biometricAuthenticator;
    late SetBiometricUnlockUseCase useCase;

    setUp(() {
      pinLockRepository = MockIPinLockRepository();
      biometricAuthenticator = MockIBiometricAuthenticator();
      useCase = SetBiometricUnlockUseCase(
        pinLockRepository: pinLockRepository,
        biometricAuthenticator: biometricAuthenticator,
      );
    });

    test('requires pin lock before enabling biometrics', () async {
      when(pinLockRepository.isEnabled()).thenAnswer((_) async => false);

      final result = await useCase(const SetBiometricUnlockParams(enabled: true));

      expect(result.isLeft(), isTrue);
      verifyNever(biometricAuthenticator.authenticate(localizedReason: anyNamed('localizedReason')));
    });

    test('enables biometrics after successful confirmation', () async {
      when(pinLockRepository.isEnabled()).thenAnswer((_) async => true);
      when(biometricAuthenticator.getCapability()).thenAnswer(
        (_) async => const BiometricCapability(
          isAvailable: true,
          hasFace: false,
          hasFingerprint: true,
          hasIris: false,
        ),
      );
      when(
        biometricAuthenticator.authenticate(
          localizedReason: anyNamed('localizedReason'),
        ),
      ).thenAnswer(
        (_) async => const BiometricAuthResult(outcome: BiometricAuthOutcome.success),
      );
      when(pinLockRepository.setBiometricEnabled(true)).thenAnswer((_) async {});

      final result = await useCase(const SetBiometricUnlockParams(enabled: true));

      expect(result.isRight(), isTrue);
      verify(pinLockRepository.setBiometricEnabled(true)).called(1);
    });

    test('disables biometrics without authentication', () async {
      when(pinLockRepository.isEnabled()).thenAnswer((_) async => true);
      when(pinLockRepository.setBiometricEnabled(false)).thenAnswer((_) async {});

      final result = await useCase(const SetBiometricUnlockParams(enabled: false));

      expect(result.isRight(), isTrue);
      verifyNever(biometricAuthenticator.authenticate(localizedReason: anyNamed('localizedReason')));
    });
  });

  group('SetPinUseCase', () {
    late MockIPinLockRepository pinLockRepository;
    late SetPinUseCase useCase;

    setUp(() {
      pinLockRepository = MockIPinLockRepository();
      useCase = SetPinUseCase(pinLockRepository: pinLockRepository);
    });

    test('rejects mismatched confirmation', () async {
      final result = await useCase(
        const SetPinParams(pin: '1234', confirmPin: '4321'),
      );

      expect(result.isLeft(), isTrue);
      verifyNever(pinLockRepository.savePin(any));
    });

    test('saves valid pin', () async {
      when(pinLockRepository.savePin('1234')).thenAnswer((_) async {});

      final result = await useCase(
        const SetPinParams(pin: '1234', confirmPin: '1234'),
      );

      expect(result.isRight(), isTrue);
      verify(pinLockRepository.savePin('1234')).called(1);
    });
  });

  group('VerifyPinUseCase', () {
    late MockIPinLockRepository pinLockRepository;
    late VerifyPinUseCase useCase;

    setUp(() {
      pinLockRepository = MockIPinLockRepository();
      useCase = VerifyPinUseCase(pinLockRepository: pinLockRepository);
    });

    test('returns auth failure when pin is wrong', () async {
      when(pinLockRepository.verifyPin('1234')).thenAnswer((_) async => false);

      final result = await useCase('1234');

      expect(result.isLeft(), isTrue);
      expect(result.getLeft().toNullable(), isA<AuthFailure>());
    });
  });

  group('DisablePinLockUseCase', () {
    late MockIPinLockRepository pinLockRepository;
    late DisablePinLockUseCase useCase;

    setUp(() {
      pinLockRepository = MockIPinLockRepository();
      useCase = DisablePinLockUseCase(
        pinLockRepository: pinLockRepository,
        verifyPinUseCase: VerifyPinUseCase(
          pinLockRepository: pinLockRepository,
        ),
      );
    });

    test('disables after successful verification', () async {
      when(pinLockRepository.verifyPin('1234')).thenAnswer((_) async => true);
      when(pinLockRepository.disable()).thenAnswer((_) async {});

      final result = await useCase('1234');

      expect(result.isRight(), isTrue);
      verify(pinLockRepository.disable()).called(1);
    });
  });

  group('SetManualExchangeRateUseCase', () {
    late MockIExchangeRateRepository exchangeRateRepository;
    late SetManualExchangeRateUseCase useCase;

    setUp(() {
      exchangeRateRepository = MockIExchangeRateRepository();
      useCase = SetManualExchangeRateUseCase(
        exchangeRateRepository: exchangeRateRepository,
      );
    });

    test('rejects invalid rate', () async {
      final result = await useCase(
        const SetManualExchangeRateParams(
          baseCurrency: CurrencyCode.usd,
          quoteCurrency: CurrencyCode.zwg,
          rate: '0',
        ),
      );

      expect(result.isLeft(), isTrue);
      expect(
        result.getLeft().toNullable(),
        isA<ValidationFailure>(),
      );
    });

    test('saves manual rate', () async {
      when(
        exchangeRateRepository.getRate(
          baseCurrencyCode: CurrencyCode.usd,
          quoteCurrencyCode: CurrencyCode.zwg,
        ),
      ).thenAnswer((_) async => null);

      final result = await useCase(
        const SetManualExchangeRateParams(
          baseCurrency: CurrencyCode.usd,
          quoteCurrency: CurrencyCode.zwg,
          rate: '25.5',
        ),
      );

      expect(result.isRight(), isTrue);
      final saved = result.getOrElse((_) => throw StateError('expected right'));
      expect(saved.isManual, isTrue);
      expect(saved.rate, '25.5');
      verify(exchangeRateRepository.save(any)).called(1);
    });
  });

  group('RefreshExchangeRatesUseCase', () {
    late MockIExchangeRateRepository exchangeRateRepository;
    late MockIExchangeRateFetcher exchangeRateFetcher;
    late RefreshExchangeRatesUseCase useCase;

    setUp(() {
      exchangeRateRepository = MockIExchangeRateRepository();
      exchangeRateFetcher = MockIExchangeRateFetcher();
      useCase = RefreshExchangeRatesUseCase(
        exchangeRateRepository: exchangeRateRepository,
        exchangeRateFetcher: exchangeRateFetcher,
      );
    });

    test('returns failure when fetch fails', () async {
      when(exchangeRateFetcher.fetchLatestRates()).thenAnswer(
        (_) async => left(
          const NetworkFailure(message: 'offline'),
        ),
      );

      final result = await useCase();

      expect(result.isLeft(), isTrue);
    });

    test('saves fetched and inverse rates', () async {
      when(exchangeRateFetcher.fetchLatestRates()).thenAnswer(
        (_) async => right([
          const FetchedExchangeRate(
            base: CurrencyCode.usd,
            quote: CurrencyCode.zar,
            rate: '18.5',
          ),
        ]),
      );
      when(
        exchangeRateRepository.getRate(
          baseCurrencyCode: anyNamed('baseCurrencyCode'),
          quoteCurrencyCode: anyNamed('quoteCurrencyCode'),
        ),
      ).thenAnswer((_) async => null);

      final result = await useCase();

      expect(result.isRight(), isTrue);
      expect(
        result.getOrElse((_) => throw StateError('expected right')).updatedPairCount,
        2,
      );
      verify(exchangeRateRepository.save(any)).called(2);
    });

    test('skips manual rates', () async {
      when(exchangeRateFetcher.fetchLatestRates()).thenAnswer(
        (_) async => right([
          const FetchedExchangeRate(
            base: CurrencyCode.usd,
            quote: CurrencyCode.zar,
            rate: '18.5',
          ),
        ]),
      );
      when(
        exchangeRateRepository.getRate(
          baseCurrencyCode: CurrencyCode.usd,
          quoteCurrencyCode: CurrencyCode.zar,
        ),
      ).thenAnswer(
        (_) async => _rate(base: 'USD', quote: 'ZAR', rate: '20', isManual: true),
      );
      when(
        exchangeRateRepository.getRate(
          baseCurrencyCode: CurrencyCode.zar,
          quoteCurrencyCode: CurrencyCode.usd,
        ),
      ).thenAnswer((_) async => null);

      final result = await useCase();

      expect(result.isRight(), isTrue);
      expect(
        result.getOrElse((_) => throw StateError('expected right')).skippedManualPairCount,
        1,
      );
      verify(exchangeRateRepository.save(any)).called(1);
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
  int month = 4,
  int year = 2026,
}) {
  final now = DateTime(2026, 4, 1);
  return Budget(
    id: id,
    userId: 'u-1',
    categoryId: categoryId,
    currencyCode: currencyCode,
    amount: amount,
    spentAmount: spentAmount,
    month: month,
    year: year,
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
  bool isManual = false,
}) {
  final now = DateTime(2026, 4, 1);
  return ExchangeRate(
    id: '$base-$quote',
    baseCurrencyCode: base,
    quoteCurrencyCode: quote,
    rate: rate,
    isManual: isManual,
    rateDate: now,
    isSynced: true,
    createdAt: now,
    updatedAt: now,
  );
}

class _RecordingBudgetExceededEventPublisher
    implements IBudgetExceededEventPublisher {
  final published = <BudgetExceededEvent>[];

  @override
  void publish(BudgetExceededEvent event) {
    published.add(event);
  }
}
