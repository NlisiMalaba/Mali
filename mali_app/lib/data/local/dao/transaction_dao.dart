import 'package:drift/drift.dart';
import 'package:mali_app/data/local/app_database.dart';
import 'package:mali_app/data/local/tables/tables.dart';

part 'transaction_dao.g.dart';

@DriftAccessor(tables: [TransactionsTable, WalletsTable])
class TransactionDao extends DatabaseAccessor<AppDatabase>
    with _$TransactionDaoMixin {
  TransactionDao(super.db);

  Future<void> upsertTransaction(TransactionsTableCompanion entry) {
    return into(transactionsTable).insertOnConflictUpdate(entry);
  }

  Future<int> insertIgnoringDuplicateSyncId(TransactionsTableCompanion entry) {
    final syncIdValue = entry.syncId;
    if (syncIdValue.present && syncIdValue.value != null) {
      return _insertWithSyncIdGuard(entry, syncIdValue.value!);
    }

    return into(transactionsTable).insert(entry);
  }

  Future<int> _insertWithSyncIdGuard(
    TransactionsTableCompanion entry,
    String syncId,
  ) async {
    final existing = await (select(transactionsTable)
          ..where((table) => table.syncId.equals(syncId)))
        .getSingleOrNull();
    if (existing != null) {
      return 0;
    }

    return into(transactionsTable).insert(entry);
  }

  Future<void> insertTransactionAndUpdateWalletBalance({
    required TransactionsTableCompanion entry,
    required String walletId,
    required String newBalance,
  }) {
    return transaction(() async {
      await into(transactionsTable).insert(entry);
      await (update(walletsTable)..where((table) => table.id.equals(walletId)))
          .write(
        WalletsTableCompanion(
          balance: Value(newBalance),
          updatedAt: Value(DateTime.now()),
        ),
      );
    });
  }

  Future<TransactionsTableData?> getById(String id) {
    return (select(
      transactionsTable,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
  }

  Future<TransactionsTableData?> getBySyncId(String syncId) {
    return (select(transactionsTable)
          ..where((table) => table.syncId.equals(syncId)))
        .getSingleOrNull();
  }

  Future<List<TransactionsTableData>> list({
    String? walletId,
    String? categoryId,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? type,
    DateTime? cursorTransactionDate,
    String? cursorTransactionId,
    required int limit,
  }) {
    return (select(transactionsTable)
          ..where(
            (table) => _activeTransactionPredicate(
              table: table,
              walletId: walletId,
              categoryId: categoryId,
              dateFrom: dateFrom,
              dateTo: dateTo,
              type: type,
              cursorTransactionDate: cursorTransactionDate,
              cursorTransactionId: cursorTransactionId,
            ),
          )
          ..orderBy([
            (table) => OrderingTerm.desc(table.transactionDate),
            (table) => OrderingTerm.desc(table.id),
          ])
          ..limit(limit))
        .get();
  }

  Stream<List<TransactionsTableData>> watchByWallet(String walletId) {
    return watchList(walletId: walletId, limit: 1000);
  }

  Stream<List<TransactionsTableData>> watchList({
    String? walletId,
    String? categoryId,
    DateTime? dateFrom,
    DateTime? dateTo,
    required int limit,
  }) {
    return (select(transactionsTable)
          ..where((table) => _activeTransactionPredicate(
                table: table,
                walletId: walletId,
                categoryId: categoryId,
                dateFrom: dateFrom,
                dateTo: dateTo,
              ))
          ..orderBy([
            (table) => OrderingTerm.desc(table.transactionDate),
            (table) => OrderingTerm.desc(table.id),
          ])
          ..limit(limit))
        .watch();
  }

  Expression<bool> _activeTransactionPredicate({
    required $TransactionsTableTable table,
    String? walletId,
    String? categoryId,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? type,
    DateTime? cursorTransactionDate,
    String? cursorTransactionId,
  }) {
    var predicate = table.deletedAt.isNull();

    if (walletId != null) {
      predicate = predicate & table.walletId.equals(walletId);
    }
    if (categoryId != null) {
      predicate = predicate & table.categoryId.equals(categoryId);
    }
    if (dateFrom != null) {
      predicate =
          predicate & table.transactionDate.isBiggerOrEqualValue(dateFrom);
    }
    if (dateTo != null) {
      predicate =
          predicate & table.transactionDate.isSmallerOrEqualValue(dateTo);
    }
    if (type != null) {
      predicate = predicate & table.type.equals(type);
    }
    if (cursorTransactionDate != null && cursorTransactionId != null) {
      predicate = predicate &
          (table.transactionDate.isSmallerThanValue(cursorTransactionDate) |
              (table.transactionDate.equals(cursorTransactionDate) &
                  table.id.isSmallerThanValue(cursorTransactionId)));
    }

    return predicate;
  }

  Future<int> softDeleteById(String id) {
    return (update(transactionsTable)..where((table) => table.id.equals(id)))
        .write(
      TransactionsTableCompanion(
        deletedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<List<TransactionsTableData>> listUnsynced() {
    return (select(transactionsTable)
          ..where((table) => table.isSynced.equals(false))
          ..where((table) => table.deletedAt.isNull())
          ..orderBy([(table) => OrderingTerm.asc(table.createdAt)]))
        .get();
  }
}
