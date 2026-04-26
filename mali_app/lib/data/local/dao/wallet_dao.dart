import 'package:drift/drift.dart';
import 'package:mali_app/data/local/app_database.dart';
import 'package:mali_app/data/local/tables/tables.dart';

part 'wallet_dao.g.dart';

@DriftAccessor(tables: [WalletsTable])
class WalletDao extends DatabaseAccessor<AppDatabase> with _$WalletDaoMixin {
  WalletDao(super.db);

  Future<void> upsertWallet(WalletsTableCompanion entry) {
    return into(walletsTable).insertOnConflictUpdate(entry);
  }

  Stream<List<WalletsTableData>> watchActiveWallets() {
    return (select(walletsTable)
          ..where((table) => table.isArchived.equals(false))
          ..where((table) => table.deletedAt.isNull())
          ..orderBy([(table) => OrderingTerm.asc(table.name)]))
        .watch();
  }

  Future<WalletsTableData?> getById(String id) {
    return (select(walletsTable)..where((table) => table.id.equals(id)))
        .getSingleOrNull();
  }

  Future<int> updateBalance({
    required String walletId,
    required String balance,
  }) {
    return (update(walletsTable)..where((table) => table.id.equals(walletId)))
        .write(
      WalletsTableCompanion(
        balance: Value(balance),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}
