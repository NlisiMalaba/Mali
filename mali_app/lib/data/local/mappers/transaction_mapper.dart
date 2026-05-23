import 'package:drift/drift.dart';
import 'package:mali_app/data/local/app_database.dart';
import 'package:mali_app/domain/entities/transaction.dart';

class TransactionMapper {
  const TransactionMapper._();

  static Transaction toDomain(TransactionsTableData row) {
    return Transaction(
      id: row.id,
      userId: row.userId,
      walletId: row.walletId,
      categoryId: row.categoryId,
      syncId: row.syncId,
      type: row.type,
      amount: row.amount,
      currencyCode: row.currencyCode,
      exchangeRate: row.exchangeRate,
      title: row.title,
      notes: row.notes,
      transactionDate: row.transactionDate,
      isSynced: row.isSynced,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      deletedAt: row.deletedAt,
    );
  }

  static List<Transaction> toDomainList(List<TransactionsTableData> rows) {
    return rows.map(toDomain).toList(growable: false);
  }

  static TransactionsTableCompanion toCompanion(Transaction transaction) {
    return TransactionsTableCompanion(
      id: Value(transaction.id),
      userId: Value(transaction.userId),
      walletId: Value(transaction.walletId),
      categoryId: Value(transaction.categoryId),
      syncId: Value(transaction.syncId),
      type: Value(transaction.type),
      amount: Value(transaction.amount),
      currencyCode: Value(transaction.currencyCode),
      exchangeRate: Value(transaction.exchangeRate),
      title: Value(transaction.title),
      notes: Value(transaction.notes),
      transactionDate: Value(transaction.transactionDate),
      isSynced: Value(transaction.isSynced),
      createdAt: Value(transaction.createdAt),
      updatedAt: Value(transaction.updatedAt),
      deletedAt: Value(transaction.deletedAt),
    );
  }
}
