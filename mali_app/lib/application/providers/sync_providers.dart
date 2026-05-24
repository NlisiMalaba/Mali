import 'package:mali_app/application/providers/connectivity_provider.dart';
import 'package:mali_app/application/providers/dao_providers.dart';
import 'package:mali_app/application/providers/database_provider.dart';
import 'package:mali_app/application/providers/gateway_providers.dart';
import 'package:mali_app/application/providers/use_case_providers.dart';
import 'package:mali_app/data/sync/background_sync_service.dart';
import 'package:mali_app/data/sync/last_sync_store.dart';
import 'package:mali_app/data/sync/sync_bootstrap.dart';
import 'package:mali_app/data/sync/sync_queue_manager.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sync_providers.g.dart';

@Riverpod(keepAlive: true)
LastSyncStore lastSyncStore(Ref ref) {
  return const LastSyncStore();
}

@Riverpod(keepAlive: true)
SyncQueueManager syncQueueManager(Ref ref) {
  return SyncQueueManager(
    syncQueueDao: ref.watch(syncQueueDaoProvider),
    syncPushGateway: ref.watch(remoteSyncPushGatewayProvider),
  );
}

@Riverpod(keepAlive: true)
BackgroundSyncService backgroundSyncService(Ref ref) {
  return BackgroundSyncService(
    syncUseCase: ref.watch(syncUseCaseProvider),
    syncQueueManager: ref.watch(syncQueueManagerProvider),
    lastSyncStore: ref.watch(lastSyncStoreProvider),
    connectivity: ref.watch(connectivityClientProvider),
  );
}

@Riverpod(keepAlive: true)
SyncBootstrap syncBootstrap(Ref ref) {
  return SyncBootstrap(
    database: ref.watch(databaseProvider),
    syncUseCase: ref.watch(syncUseCaseProvider),
    syncQueueManager: ref.watch(syncQueueManagerProvider),
    backgroundSyncService: ref.watch(backgroundSyncServiceProvider),
  );
}
