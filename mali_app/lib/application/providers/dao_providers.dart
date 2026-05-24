import 'package:mali_app/application/providers/database_provider.dart';
import 'package:mali_app/data/local/dao/budget_dao.dart';
import 'package:mali_app/data/local/dao/category_dao.dart';
import 'package:mali_app/data/local/dao/exchange_rate_dao.dart';
import 'package:mali_app/data/local/dao/goal_dao.dart';
import 'package:mali_app/data/local/dao/sync_queue_dao.dart';
import 'package:mali_app/data/local/dao/transaction_dao.dart';
import 'package:mali_app/data/local/dao/wallet_dao.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dao_providers.g.dart';

@Riverpod(keepAlive: true)
TransactionDao transactionDao(Ref ref) {
  return ref.watch(databaseProvider).transactionDao;
}

@Riverpod(keepAlive: true)
WalletDao walletDao(Ref ref) {
  return ref.watch(databaseProvider).walletDao;
}

@Riverpod(keepAlive: true)
CategoryDao categoryDao(Ref ref) {
  return ref.watch(databaseProvider).categoryDao;
}

@Riverpod(keepAlive: true)
GoalDao goalDao(Ref ref) {
  return ref.watch(databaseProvider).goalDao;
}

@Riverpod(keepAlive: true)
BudgetDao budgetDao(Ref ref) {
  return ref.watch(databaseProvider).budgetDao;
}

@Riverpod(keepAlive: true)
ExchangeRateDao exchangeRateDao(Ref ref) {
  return ref.watch(databaseProvider).exchangeRateDao;
}

@Riverpod(keepAlive: true)
SyncQueueDao syncQueueDao(Ref ref) {
  return ref.watch(databaseProvider).syncQueueDao;
}
