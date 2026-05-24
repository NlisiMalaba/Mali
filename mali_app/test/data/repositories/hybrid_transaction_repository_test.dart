import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mali_app/data/local/app_database.dart';
import 'package:mali_app/data/remote/dto/sync_dto.dart';
import 'package:mali_app/data/remote/sync_push_gateway.dart';
import 'package:mali_app/data/repositories/hybrid_transaction_repository.dart';
import 'package:mali_app/data/repositories/local_transaction_repository.dart';
import 'package:mali_app/data/sync/sync_queue_manager.dart';
import 'package:mali_app/domain/entities/transaction.dart';

void main() {
  late AppDatabase database;
  late HybridTransactionRepository hybridRepository;
  late FakeSyncPushGateway fakeSyncPushGateway;
  late SyncQueueManager syncQueueManager;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    fakeSyncPushGateway = FakeSyncPushGateway();
    hybridRepository = HybridTransactionRepository(
      localRepository: LocalTransactionRepository(
        transactionDao: database.transactionDao,
      ),
      syncQueueDao: database.syncQueueDao,
    );
    syncQueueManager = SyncQueueManager(
      syncQueueDao: database.syncQueueDao,
      syncPushGateway: fakeSyncPushGateway,
    );
  });

  tearDown(() async {
    await database.close();
  });

  test(
    'offline save stores transaction locally and enqueues sync item',
    () async {
      await _seedWallet(database);

      await hybridRepository.save(_offlineTransaction());

      final stored = await hybridRepository.findById('tx-offline-1');
      expect(stored, isNotNull);
      expect(stored!.isSynced, isFalse);
      expect(stored.syncId, 'tx-offline-1');

      expect(await database.syncQueueDao.countPending(), 1);

      final pendingItems = await database.syncQueueDao.getPendingBatch(10);
      expect(pendingItems, hasLength(1));
      expect(pendingItems.first.entityType, 'transaction');
      expect(pendingItems.first.entityId, 'tx-offline-1');
      expect(pendingItems.first.operation, 'create');
      expect(fakeSyncPushGateway.pushCallCount, 0);
    },
  );

  test(
    'sync trigger pushes queued transaction to mock remote gateway',
    () async {
      await _seedWallet(database);
      await hybridRepository.save(_offlineTransaction());

      final syncResult = await syncQueueManager.processPending();

      expect(syncResult.acceptedCount, 1);
      expect(syncResult.pendingRemaining, 0);
      expect(fakeSyncPushGateway.pushCallCount, 1);
      expect(fakeSyncPushGateway.lastChanges, hasLength(1));

      final change = fakeSyncPushGateway.lastChanges!.single;
      expect(change.syncId, 'tx-offline-1');
      expect(change.entity, 'transaction');
      expect(change.operation, 'create');
      expect(change.payload['wallet_id'], 'wallet-1');
      expect(change.payload['amount'], '25.00');
    },
  );

  test(
    'conflicted sync push keeps item pending in queue',
    () async {
      await _seedWallet(database);
      await hybridRepository.save(_offlineTransaction());

      fakeSyncPushGateway.shouldRejectAll = true;
      final syncResult = await syncQueueManager.processPending();

      expect(syncResult.acceptedCount, 0);
      expect(syncResult.conflictCount, 1);
      expect(syncResult.pendingRemaining, 1);
      expect(fakeSyncPushGateway.pushCallCount, 1);

      final pendingItems = await database.syncQueueDao.getPendingBatch(10);
      expect(pendingItems, hasLength(1));
      expect(pendingItems.first.lastError, isNotEmpty);
    },
  );
}

Future<void> _seedWallet(AppDatabase database) {
  return database.walletDao.upsertWallet(
    WalletsTableCompanion.insert(
      id: 'wallet-1',
      userId: 'user-1',
      name: 'Main Wallet',
      currencyCode: 'USD',
      balance: '100.00',
    ),
  );
}

Transaction _offlineTransaction() {
  final now = DateTime(2026, 4, 26, 12);
  return Transaction(
    id: 'tx-offline-1',
    userId: 'user-1',
    walletId: 'wallet-1',
    categoryId: 'cat-food',
    type: 'expense',
    amount: '25.00',
    currencyCode: 'USD',
    title: 'Offline groceries',
    notes: 'Queued while offline',
    transactionDate: now,
    isSynced: false,
    createdAt: now,
    updatedAt: now,
  );
}

class FakeSyncPushGateway implements ISyncPushGateway {
  int pushCallCount = 0;
  bool shouldRejectAll = false;
  List<SyncChangeRequestDto>? lastChanges;

  @override
  Future<SyncPushResponseDto> pushChanges(List<SyncChangeRequestDto> changes) async {
    pushCallCount++;
    lastChanges = changes;

    if (shouldRejectAll) {
      return SyncPushResponseDto(
        acceptedIds: const [],
        conflicts: changes
            .map(
              (change) => SyncConflictDto(
                syncId: change.syncId,
                entity: change.entity,
                operation: change.operation,
                reason: 'mock conflict',
              ),
            )
            .toList(growable: false),
      );
    }

    return SyncPushResponseDto(
      acceptedIds: changes.map((change) => change.syncId).toList(growable: false),
      conflicts: const [],
    );
  }
}
