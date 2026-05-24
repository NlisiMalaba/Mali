import 'dart:convert';

import 'package:mali_app/data/local/app_database.dart';
import 'package:mali_app/data/local/dao/sync_queue_dao.dart';
import 'package:mali_app/data/remote/mappers/remote_transaction_mapper.dart';
import 'package:mali_app/domain/entities/transaction.dart';
import 'package:mali_app/domain/repositories/transaction_repository.dart';

class HybridTransactionRepository implements ITransactionRepository {
  const HybridTransactionRepository({
    required ITransactionRepository localRepository,
    required SyncQueueDao syncQueueDao,
  })  : _localRepository = localRepository,
        _syncQueueDao = syncQueueDao;

  static const String _entityType = 'transaction';

  final ITransactionRepository _localRepository;
  final SyncQueueDao _syncQueueDao;

  @override
  Future<void> save(Transaction transaction) async {
    final pendingTransaction = transaction.copyWith(
      syncId: transaction.syncId ?? transaction.id,
      isSynced: false,
      updatedAt: DateTime.now(),
    );

    await _localRepository.save(pendingTransaction);
    await _syncQueueDao.enqueue(
      SyncQueueTableCompanion.insert(
        entityType: _entityType,
        entityId: pendingTransaction.id,
        operation: 'create',
        payloadJson: _encodeCreatePayload(pendingTransaction),
      ),
    );
  }

  @override
  Future<Transaction?> findById(String id) {
    return _localRepository.findById(id);
  }

  @override
  Future<Transaction?> findBySyncId(String syncId) {
    return _localRepository.findBySyncId(syncId);
  }

  @override
  Future<List<Transaction>> list({
    required TransactionQuery query,
  }) {
    return _localRepository.list(query: query);
  }

  @override
  Stream<List<Transaction>> watchByWallet(String walletId) {
    return _localRepository.watchByWallet(walletId);
  }

  @override
  Stream<List<Transaction>> watchList({
    required TransactionWatchQuery query,
  }) {
    return _localRepository.watchList(query: query);
  }

  @override
  Future<List<Transaction>> listUnsynced() {
    return _localRepository.listUnsynced();
  }

  @override
  Future<void> softDelete(String id) async {
    await _localRepository.softDelete(id);
    await _syncQueueDao.enqueue(
      SyncQueueTableCompanion.insert(
        entityType: _entityType,
        entityId: id,
        operation: 'delete',
        payloadJson: jsonEncode({'transaction_id': id}),
      ),
    );
  }

  String _encodeCreatePayload(Transaction transaction) {
    return jsonEncode(
      RemoteTransactionMapper.toCreateRequest(transaction).toJson(),
    );
  }
}
