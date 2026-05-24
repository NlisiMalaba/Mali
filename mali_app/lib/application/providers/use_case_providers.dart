import 'package:mali_app/application/providers/gateway_providers.dart';
import 'package:mali_app/application/providers/repository_providers.dart';
import 'package:mali_app/domain/usecases/allocate_to_goal_usecase.dart';
import 'package:mali_app/domain/usecases/calculate_net_worth_usecase.dart';
import 'package:mali_app/domain/usecases/get_monthly_summary_usecase.dart';
import 'package:mali_app/domain/usecases/log_transaction_usecase.dart';
import 'package:mali_app/domain/usecases/sync_usecase.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'use_case_providers.g.dart';

@Riverpod(keepAlive: true)
LogTransactionUseCase logTransactionUseCase(Ref ref) {
  return LogTransactionUseCase(
    transactionRepository: ref.watch(transactionRepositoryProvider),
    walletRepository: ref.watch(walletRepositoryProvider),
    budgetRepository: ref.watch(budgetRepositoryProvider),
  );
}

@Riverpod(keepAlive: true)
CalculateNetWorthUseCase calculateNetWorthUseCase(Ref ref) {
  return CalculateNetWorthUseCase(
    walletRepository: ref.watch(walletRepositoryProvider),
    exchangeRateRepository: ref.watch(exchangeRateRepositoryProvider),
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
SyncUseCase syncUseCase(Ref ref) {
  return SyncUseCase(
    transactionRepository: ref.watch(transactionRepositoryProvider),
    syncPushGateway: ref.watch(transactionSyncPushGatewayProvider),
    syncPullGateway: ref.watch(syncPullGatewayProvider),
  );
}
