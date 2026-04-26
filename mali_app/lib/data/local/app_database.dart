import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:mali_app/data/local/dao/budget_dao.dart';
import 'package:mali_app/data/local/dao/category_dao.dart';
import 'package:mali_app/data/local/dao/exchange_rate_dao.dart';
import 'package:mali_app/data/local/dao/goal_dao.dart';
import 'package:mali_app/data/local/dao/sync_queue_dao.dart';
import 'package:mali_app/data/local/dao/transaction_dao.dart';
import 'package:mali_app/data/local/dao/wallet_dao.dart';
import 'package:mali_app/data/local/tables/tables.dart';
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final dbFile = File('${documentsDirectory.path}/mali.sqlite');

    return NativeDatabase.createInBackground(dbFile);
  });
}

@DriftDatabase(tables: [
  TransactionsTable,
  WalletsTable,
  CategoriesTable,
  SavingsGoalsTable,
  GoalContributionsTable,
  BudgetsTable,
  ExchangeRatesTable,
  SyncQueueTable,
], daos: [
  TransactionDao,
  WalletDao,
  CategoryDao,
  GoalDao,
  BudgetDao,
  ExchangeRateDao,
  SyncQueueDao,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.executor);

  // Schema stays on v1 until the first migration is introduced.
  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (migrator) async {
          await migrator.createAll();
        },
        onUpgrade: (migrator, from, to) async {
          // Planned migration flow for v2+.
          // Keep this switch exhaustive as new schema versions are added.
          for (var version = from + 1; version <= to; version++) {
            switch (version) {
              case 2:
                await _migrateToV2(migrator);
              default:
                break;
            }
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON;');
          await customStatement('PRAGMA journal_mode = WAL;');
        },
      );

  Future<void> _migrateToV2(Migrator migrator) async {
    // TODO(task-19.3): Implement concrete v2 schema changes when introduced.
  }
}
