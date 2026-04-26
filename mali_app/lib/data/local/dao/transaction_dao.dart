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

  Stream<List<TransactionsTableData>> watchByWallet(String walletId) {
    return (select(transactionsTable)
          ..where((table) => table.walletId.equals(walletId))
          ..where((table) => table.deletedAt.isNull())
          ..orderBy([(table) => OrderingTerm.desc(table.transactionDate)]))
        .watch();
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
