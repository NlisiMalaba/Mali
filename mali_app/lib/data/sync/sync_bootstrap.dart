import 'package:dio/dio.dart';
import 'package:mali_app/core/config/api_config.dart';
import 'package:mali_app/data/local/app_database.dart';
import 'package:mali_app/data/remote/sync_pull_gateway.dart';
import 'package:mali_app/data/remote/sync_push_gateway.dart' as remote_sync;
import 'package:mali_app/data/remote/transaction_list_sync_push_gateway.dart';
import 'package:mali_app/data/repositories/hybrid_transaction_repository.dart';
import 'package:mali_app/data/repositories/local_transaction_repository.dart';
import 'package:mali_app/data/repositories/remote_transaction_repository.dart';
import 'package:mali_app/data/sync/background_sync_service.dart';
import 'package:mali_app/data/sync/last_sync_store.dart';
import 'package:mali_app/data/sync/sync_queue_manager.dart';
import 'package:mali_app/domain/usecases/sync_usecase.dart';

class SyncBootstrap {
  SyncBootstrap._({
    required this.database,
    required this.syncUseCase,
    required this.syncQueueManager,
    required this.backgroundSyncService,
  });

  final AppDatabase database;
  final SyncUseCase syncUseCase;
  final SyncQueueManager syncQueueManager;
  final BackgroundSyncService backgroundSyncService;

  static Future<SyncBootstrap> create() async {
    final database = AppDatabase();
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );

    final localTransactionRepository = LocalTransactionRepository(
      transactionDao: database.transactionDao,
    );
    final hybridTransactionRepository = HybridTransactionRepository(
      localRepository: localTransactionRepository,
      syncQueueDao: database.syncQueueDao,
    );
    final remoteTransactionRepository = RemoteTransactionRepository(dio: dio);
    final syncQueueManager = SyncQueueManager(
      syncQueueDao: database.syncQueueDao,
      syncPushGateway: remote_sync.SyncPushGateway(dio: dio),
    );
    final syncUseCase = SyncUseCase(
      transactionRepository: hybridTransactionRepository,
      syncPushGateway: TransactionListSyncPushGateway(
        remoteTransactionRepository: remoteTransactionRepository,
      ),
      syncPullGateway: SyncPullGateway(dio: dio),
    );
    final backgroundSyncService = BackgroundSyncService(
      syncUseCase: syncUseCase,
      syncQueueManager: syncQueueManager,
      lastSyncStore: const LastSyncStore(),
    );

    return SyncBootstrap._(
      database: database,
      syncUseCase: syncUseCase,
      syncQueueManager: syncQueueManager,
      backgroundSyncService: backgroundSyncService,
    );
  }
}
