import 'package:drift/drift.dart';
import 'package:mali_app/data/local/app_database.dart';
import 'package:mali_app/domain/entities/wallet.dart';

class WalletMapper {
  const WalletMapper._();

  static Wallet toDomain(WalletsTableData row) {
    return Wallet(
      id: row.id,
      userId: row.userId,
      name: row.name,
      currencyCode: row.currencyCode,
      balance: row.balance,
      isArchived: row.isArchived,
      isSynced: row.isSynced,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      deletedAt: row.deletedAt,
    );
  }

  static List<Wallet> toDomainList(List<WalletsTableData> rows) {
    return rows.map(toDomain).toList(growable: false);
  }

  static WalletsTableCompanion toCompanion(Wallet wallet) {
    return WalletsTableCompanion(
      id: Value(wallet.id),
      userId: Value(wallet.userId),
      name: Value(wallet.name),
      currencyCode: Value(wallet.currencyCode),
      balance: Value(wallet.balance),
      isArchived: Value(wallet.isArchived),
      isSynced: Value(wallet.isSynced),
      createdAt: Value(wallet.createdAt),
      updatedAt: Value(wallet.updatedAt),
      deletedAt: Value(wallet.deletedAt),
    );
  }
}
