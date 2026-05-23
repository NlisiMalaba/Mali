import 'dart:convert';

import 'package:mali_app/data/local/app_database.dart';
import 'package:mali_app/data/local/dao/sync_queue_dao.dart';
import 'package:mali_app/data/remote/dto/sync_dto.dart';
import 'package:mali_app/data/remote/sync_push_gateway.dart';

class SyncQueueManager {
  const SyncQueueManager({
    required SyncQueueDao syncQueueDao,
    required ISyncPushGateway syncPushGateway,
    this.batchSize = 100,
  })  : _syncQueueDao = syncQueueDao,
        _syncPushGateway = syncPushGateway;

  static const int maxBatchSize = 100;

  final SyncQueueDao _syncQueueDao;
  final ISyncPushGateway _syncPushGateway;
  final int batchSize;

  Future<SyncQueueProcessResult> processPending() async {
    if (batchSize <= 0 || batchSize > maxBatchSize) {
      throw ArgumentError.value(batchSize, 'batchSize', 'Must be between 1 and $maxBatchSize.');
    }

    var batchesProcessed = 0;
    var acceptedCount = 0;
    var conflictCount = 0;

    while (true) {
      final batch = await _syncQueueDao.getPendingBatch(batchSize);
      if (batch.isEmpty) {
        break;
      }

      final changes = batch.map(_toSyncChange).toList(growable: false);
      final response = await _syncPushGateway.pushChanges(changes);
      batchesProcessed++;

      final acceptedSyncIds = response.acceptedIds.toSet();
      final conflictsBySyncId = {
        for (final conflict in response.conflicts) conflict.syncId: conflict,
      };

      for (final item in batch) {
        final syncId = _resolveSyncId(item);
        if (acceptedSyncIds.contains(syncId)) {
          await _syncQueueDao.markSynced(item.id);
          acceptedCount++;
          continue;
        }

        final conflict = conflictsBySyncId[syncId];
        if (conflict != null) {
          await _syncQueueDao.markFailed(
            id: item.id,
            errorMessage: conflict.reason,
          );
          conflictCount++;
          continue;
        }

        await _syncQueueDao.markFailed(
          id: item.id,
          errorMessage: 'Change was not accepted by sync push response.',
        );
        conflictCount++;
      }

      if (batch.length < batchSize) {
        break;
      }
    }

    final pendingRemaining = await _syncQueueDao.countPending();

    return SyncQueueProcessResult(
      batchesProcessed: batchesProcessed,
      acceptedCount: acceptedCount,
      conflictCount: conflictCount,
      pendingRemaining: pendingRemaining,
    );
  }

  SyncChangeRequestDto _toSyncChange(SyncQueueTableData item) {
    final payload = jsonDecode(item.payloadJson);
    if (payload is! Map<String, dynamic>) {
      throw FormatException('Sync queue payload must be a JSON object for item ${item.id}.');
    }

    return SyncChangeRequestDto(
      syncId: _resolveSyncId(item),
      entity: item.entityType,
      operation: item.operation,
      payload: payload,
    );
  }

  String _resolveSyncId(SyncQueueTableData item) {
    if (item.operation == 'create') {
      final payload = jsonDecode(item.payloadJson);
      if (payload is Map<String, dynamic>) {
        final syncId = payload['sync_id'];
        if (syncId is String && syncId.isNotEmpty) {
          return syncId;
        }
      }
    }

    return item.entityId;
  }
}

class SyncQueueProcessResult {
  const SyncQueueProcessResult({
    required this.batchesProcessed,
    required this.acceptedCount,
    required this.conflictCount,
    required this.pendingRemaining,
  });

  final int batchesProcessed;
  final int acceptedCount;
  final int conflictCount;
  final int pendingRemaining;
}
