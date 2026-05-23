import 'package:mali_app/data/local/dao/transaction_dao.dart';
import 'package:mali_app/data/local/mappers/transaction_mapper.dart';
import 'package:mali_app/domain/entities/transaction.dart';
import 'package:mali_app/domain/repositories/transaction_repository.dart';

class LocalTransactionRepository implements ITransactionRepository {
  const LocalTransactionRepository({
    required TransactionDao transactionDao,
  }) : _transactionDao = transactionDao;

  final TransactionDao _transactionDao;

  @override
  Future<void> save(Transaction transaction) {
    return _transactionDao.upsertTransaction(
      TransactionMapper.toCompanion(transaction),
    );
  }

  @override
  Future<Transaction?> findById(String id) async {
    final row = await _transactionDao.getById(id);
    if (row == null) {
      return null;
    }
    return TransactionMapper.toDomain(row);
  }

  @override
  Future<Transaction?> findBySyncId(String syncId) async {
    final row = await _transactionDao.getBySyncId(syncId);
    if (row == null) {
      return null;
    }
    return TransactionMapper.toDomain(row);
  }

  @override
  Future<List<Transaction>> list({
    required TransactionQuery query,
  }) async {
    final rows = await _transactionDao.list(
      walletId: query.walletId,
      categoryId: query.categoryId,
      dateFrom: query.dateFrom,
      dateTo: query.dateTo,
      type: query.type,
      cursorTransactionDate: query.cursor?.transactionDate,
      cursorTransactionId: query.cursor?.transactionId,
      limit: query.limit,
    );
    return TransactionMapper.toDomainList(rows);
  }

  @override
  Stream<List<Transaction>> watchByWallet(String walletId) {
    return _transactionDao.watchByWallet(walletId).map(TransactionMapper.toDomainList);
  }

  @override
  Future<List<Transaction>> listUnsynced() async {
    final rows = await _transactionDao.listUnsynced();
    return TransactionMapper.toDomainList(rows);
  }

  @override
  Future<void> softDelete(String id) async {
    await _transactionDao.softDeleteById(id);
  }
}
