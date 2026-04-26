import 'package:mali_app/domain/entities/transaction.dart';

abstract interface class ITransactionRepository {
  Future<void> save(Transaction transaction);

  Future<Transaction?> findById(String id);

  Future<Transaction?> findBySyncId(String syncId);

  Future<List<Transaction>> list({
    required TransactionQuery query,
  });

  Stream<List<Transaction>> watchByWallet(String walletId);

  Future<List<Transaction>> listUnsynced();

  Future<void> softDelete(String id);
}

class TransactionQuery {
  const TransactionQuery({
    this.walletId,
    this.categoryId,
    this.dateFrom,
    this.dateTo,
    this.type,
    this.cursor,
    this.limit = 50,
  }) : assert(limit > 0, 'limit must be greater than zero');

  final String? walletId;
  final String? categoryId;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final String? type;
  final TransactionCursor? cursor;
  final int limit;
}

class TransactionCursor {
  const TransactionCursor({
    required this.transactionDate,
    required this.transactionId,
  });

  final DateTime transactionDate;
  final String transactionId;
}
