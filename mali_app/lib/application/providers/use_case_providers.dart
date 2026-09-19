import 'package:mali_app/application/events/budget_exceeded_event_bus.dart';
import 'package:mali_app/application/providers/gateway_providers.dart';
import 'package:mali_app/application/providers/repository_providers.dart';
import 'package:mali_app/domain/usecases/allocate_to_goal_usecase.dart';
import 'package:mali_app/domain/usecases/calculate_net_worth_usecase.dart';
import 'package:mali_app/domain/usecases/convert_money_usecase.dart';
import 'package:mali_app/domain/usecases/archive_wallet_usecase.dart';
import 'package:mali_app/domain/usecases/create_budget_usecase.dart';
import 'package:mali_app/domain/usecases/create_goal_usecase.dart';
import 'package:mali_app/domain/usecases/create_wallet_usecase.dart';
import 'package:mali_app/domain/usecases/reorder_goals_usecase.dart';
import 'package:mali_app/domain/usecases/update_goal_usecase.dart';
import 'package:mali_app/domain/usecases/get_monthly_summary_usecase.dart';
import 'package:mali_app/domain/usecases/delete_transaction_usecase.dart';
import 'package:mali_app/domain/usecases/log_transaction_usecase.dart';
import 'package:mali_app/application/providers/biometric_providers.dart';
import 'package:mali_app/application/providers/pin_lock_store_providers.dart';
import 'package:mali_app/domain/usecases/authenticate_with_biometric_usecase.dart';
import 'package:mali_app/domain/usecases/disable_pin_lock_usecase.dart';
import 'package:mali_app/domain/usecases/set_biometric_unlock_usecase.dart';
import 'package:mali_app/domain/usecases/refresh_exchange_rates_usecase.dart';
import 'package:mali_app/domain/usecases/set_pin_usecase.dart';
import 'package:mali_app/domain/usecases/verify_pin_usecase.dart';
import 'package:mali_app/domain/usecases/restore_transaction_usecase.dart';
import 'package:mali_app/domain/usecases/set_manual_exchange_rate_usecase.dart';
import 'package:mali_app/domain/usecases/sync_usecase.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'use_case_providers.g.dart';

@Riverpod(keepAlive: true)
ArchiveWalletUseCase archiveWalletUseCase(Ref ref) {
  return ArchiveWalletUseCase(
    walletRepository: ref.watch(walletRepositoryProvider),
  );
}

@Riverpod(keepAlive: true)
CreateWalletUseCase createWalletUseCase(Ref ref) {
  return CreateWalletUseCase(
    walletRepository: ref.watch(walletRepositoryProvider),
  );
}

@Riverpod(keepAlive: true)
CreateBudgetUseCase createBudgetUseCase(Ref ref) {
  return CreateBudgetUseCase(
    budgetRepository: ref.watch(budgetRepositoryProvider),
  );
}

@Riverpod(keepAlive: true)
CreateGoalUseCase createGoalUseCase(Ref ref) {
  return CreateGoalUseCase(
    goalRepository: ref.watch(goalRepositoryProvider),
  );
}

@Riverpod(keepAlive: true)
UpdateGoalUseCase updateGoalUseCase(Ref ref) {
  return UpdateGoalUseCase(
    goalRepository: ref.watch(goalRepositoryProvider),
  );
}

@Riverpod(keepAlive: true)
ReorderGoalsUseCase reorderGoalsUseCase(Ref ref) {
  return ReorderGoalsUseCase(
    goalRepository: ref.watch(goalRepositoryProvider),
  );
}

@Riverpod(keepAlive: true)
BudgetExceededEventBus budgetExceededEventBus(Ref ref) {
  return BudgetExceededEventBus.instance;
}

@Riverpod(keepAlive: true)
LogTransactionUseCase logTransactionUseCase(Ref ref) {
  return LogTransactionUseCase(
    transactionRepository: ref.watch(transactionRepositoryProvider),
    walletRepository: ref.watch(walletRepositoryProvider),
    budgetRepository: ref.watch(budgetRepositoryProvider),
    budgetExceededEventPublisher: ref.watch(budgetExceededEventBusProvider),
  );
}

@Riverpod(keepAlive: true)
ConvertMoneyUseCase convertMoneyUseCase(Ref ref) {
  return ConvertMoneyUseCase(
    exchangeRateRepository: ref.watch(exchangeRateRepositoryProvider),
  );
}

@Riverpod(keepAlive: true)
CalculateNetWorthUseCase calculateNetWorthUseCase(Ref ref) {
  return CalculateNetWorthUseCase(
    walletRepository: ref.watch(walletRepositoryProvider),
    convertMoneyUseCase: ref.watch(convertMoneyUseCaseProvider),
  );
}

@Riverpod(keepAlive: true)
GetMonthlySummaryUseCase getMonthlySummaryUseCase(Ref ref) {
  return GetMonthlySummaryUseCase(
    transactionRepository: ref.watch(transactionRepositoryProvider),
  );
}

@Riverpod(keepAlive: true)
AllocateToGoalUseCase allocateToGoalUseCase(Ref ref) {
  return AllocateToGoalUseCase(
    goalRepository: ref.watch(goalRepositoryProvider),
  );
}

@Riverpod(keepAlive: true)
DeleteTransactionUseCase deleteTransactionUseCase(Ref ref) {
  return DeleteTransactionUseCase(
    transactionRepository: ref.watch(transactionRepositoryProvider),
    walletRepository: ref.watch(walletRepositoryProvider),
  );
}

@Riverpod(keepAlive: true)
RestoreTransactionUseCase restoreTransactionUseCase(Ref ref) {
  return RestoreTransactionUseCase(
    transactionRepository: ref.watch(transactionRepositoryProvider),
    walletRepository: ref.watch(walletRepositoryProvider),
  );
}

@Riverpod(keepAlive: true)
SyncUseCase syncUseCase(Ref ref) {
  return SyncUseCase(
    transactionRepository: ref.watch(transactionRepositoryProvider),
    syncPushGateway: ref.watch(transactionSyncPushGatewayProvider),
    syncPullGateway: ref.watch(syncPullGatewayProvider),
  );
}

@Riverpod(keepAlive: true)
SetManualExchangeRateUseCase setManualExchangeRateUseCase(Ref ref) {
  return SetManualExchangeRateUseCase(
    exchangeRateRepository: ref.watch(exchangeRateRepositoryProvider),
  );
}

@Riverpod(keepAlive: true)
RefreshExchangeRatesUseCase refreshExchangeRatesUseCase(Ref ref) {
  return RefreshExchangeRatesUseCase(
    exchangeRateRepository: ref.watch(exchangeRateRepositoryProvider),
    exchangeRateFetcher: ref.watch(exchangeRateFetcherProvider),
  );
}

@Riverpod(keepAlive: true)
SetPinUseCase setPinUseCase(Ref ref) {
  return SetPinUseCase(
    pinLockRepository: ref.watch(pinLockRepositoryProvider),
  );
}

@Riverpod(keepAlive: true)
VerifyPinUseCase verifyPinUseCase(Ref ref) {
  return VerifyPinUseCase(
    pinLockRepository: ref.watch(pinLockRepositoryProvider),
  );
}

@Riverpod(keepAlive: true)
DisablePinLockUseCase disablePinLockUseCase(Ref ref) {
  return DisablePinLockUseCase(
    pinLockRepository: ref.watch(pinLockRepositoryProvider),
    verifyPinUseCase: ref.watch(verifyPinUseCaseProvider),
  );
}

@Riverpod(keepAlive: true)
AuthenticateWithBiometricUseCase authenticateWithBiometricUseCase(Ref ref) {
  return AuthenticateWithBiometricUseCase(
    biometricAuthenticator: ref.watch(biometricAuthenticatorProvider),
  );
}

@Riverpod(keepAlive: true)
SetBiometricUnlockUseCase setBiometricUnlockUseCase(Ref ref) {
  return SetBiometricUnlockUseCase(
    pinLockRepository: ref.watch(pinLockRepositoryProvider),
    biometricAuthenticator: ref.watch(biometricAuthenticatorProvider),
  );
}
