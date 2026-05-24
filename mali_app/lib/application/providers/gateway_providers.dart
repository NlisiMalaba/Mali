import 'package:mali_app/application/providers/api_client_provider.dart';
import 'package:mali_app/application/providers/repository_providers.dart';
import 'package:mali_app/data/remote/frankfurter_exchange_rate_fetcher.dart';
import 'package:mali_app/data/remote/sync_pull_gateway.dart';
import 'package:mali_app/domain/repositories/exchange_rate_fetcher.dart';
import 'package:mali_app/data/remote/sync_push_gateway.dart' as remote_sync;
import 'package:mali_app/data/remote/transaction_list_sync_push_gateway.dart';
import 'package:mali_app/domain/usecases/sync_usecase.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'gateway_providers.g.dart';

@Riverpod(keepAlive: true)
IExchangeRateFetcher exchangeRateFetcher(Ref ref) {
  return FrankfurterExchangeRateFetcher();
}

@Riverpod(keepAlive: true)
remote_sync.ISyncPushGateway remoteSyncPushGateway(Ref ref) {
  return remote_sync.SyncPushGateway(dio: ref.watch(dioProvider));
}

@Riverpod(keepAlive: true)
ISyncPullGateway syncPullGateway(Ref ref) {
  return SyncPullGateway(dio: ref.watch(dioProvider));
}

@Riverpod(keepAlive: true)
ISyncPushGateway transactionSyncPushGateway(Ref ref) {
  return TransactionListSyncPushGateway(
    remoteTransactionRepository: ref.watch(remoteTransactionRepositoryProvider),
  );
}
