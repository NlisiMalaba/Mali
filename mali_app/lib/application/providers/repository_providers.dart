import 'package:mali_app/application/providers/api_client_provider.dart';
import 'package:mali_app/application/providers/dao_providers.dart';
import 'package:mali_app/data/repositories/hybrid_transaction_repository.dart';
import 'package:mali_app/data/repositories/local_budget_repository.dart';
import 'package:mali_app/data/repositories/local_exchange_rate_repository.dart';
import 'package:mali_app/data/repositories/local_goal_repository.dart';
import 'package:mali_app/data/repositories/local_transaction_repository.dart';
import 'package:mali_app/data/repositories/local_wallet_repository.dart';
import 'package:mali_app/data/repositories/remote_transaction_repository.dart';
import 'package:mali_app/domain/repositories/budget_repository.dart';
import 'package:mali_app/domain/repositories/exchange_rate_repository.dart';
import 'package:mali_app/domain/repositories/goal_repository.dart';
import 'package:mali_app/domain/repositories/transaction_repository.dart';
import 'package:mali_app/domain/repositories/wallet_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'repository_providers.g.dart';

@Riverpod(keepAlive: true)
LocalTransactionRepository localTransactionRepository(Ref ref) {
  return LocalTransactionRepository(
    transactionDao: ref.watch(transactionDaoProvider),
  );
}

@Riverpod(keepAlive: true)
ITransactionRepository transactionRepository(Ref ref) {
  return HybridTransactionRepository(
    localRepository: ref.watch(localTransactionRepositoryProvider),
    syncQueueDao: ref.watch(syncQueueDaoProvider),
  );
}

@Riverpod(keepAlive: true)
IRemoteTransactionRepository remoteTransactionRepository(Ref ref) {
  return RemoteTransactionRepository(dio: ref.watch(dioProvider));
}

@Riverpod(keepAlive: true)
IWalletRepository walletRepository(Ref ref) {
  return LocalWalletRepository(
    walletDao: ref.watch(walletDaoProvider),
  );
}

@Riverpod(keepAlive: true)
IBudgetRepository budgetRepository(Ref ref) {
  return LocalBudgetRepository(
    budgetDao: ref.watch(budgetDaoProvider),
  );
}

@Riverpod(keepAlive: true)
IGoalRepository goalRepository(Ref ref) {
  return LocalGoalRepository(
    goalDao: ref.watch(goalDaoProvider),
  );
}

@Riverpod(keepAlive: true)
IExchangeRateRepository exchangeRateRepository(Ref ref) {
  return LocalExchangeRateRepository(
    exchangeRateDao: ref.watch(exchangeRateDaoProvider),
  );
}
