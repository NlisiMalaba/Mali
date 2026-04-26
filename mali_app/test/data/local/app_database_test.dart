import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mali_app/data/local/app_database.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  test(
    'insert transaction updates wallet balance',
    () async {
      await database.walletDao.upsertWallet(
        WalletsTableCompanion.insert(
          id: 'wallet-1',
          userId: 'user-1',
          name: 'Main Wallet',
          currencyCode: 'USD',
          balance: '100.00',
        ),
      );

      await database.transactionDao.insertTransactionAndUpdateWalletBalance(
        entry: TransactionsTableCompanion.insert(
          id: 'tx-1',
          userId: 'user-1',
          walletId: 'wallet-1',
          type: 'expense',
          amount: '30.00',
          currencyCode: 'USD',
          title: 'Groceries',
          transactionDate: DateTime(2026, 4, 26),
        ),
        walletId: 'wallet-1',
        newBalance: '70.00',
      );

      final wallet = await database.walletDao.getById('wallet-1');
      expect(wallet, isNotNull);
      expect(wallet!.balance, '70.00');
    },
  );

  test(
    'cascade delete removes contributions when goal deleted',
    () async {
      await database.goalDao.upsertGoal(
        SavingsGoalsTableCompanion.insert(
          id: 'goal-1',
          userId: 'user-1',
          name: 'Emergency Fund',
          targetAmount: '1000.00',
          currencyCode: 'USD',
        ),
      );

      await database.goalDao.addContribution(
        GoalContributionsTableCompanion.insert(
          id: 'contribution-1',
          goalId: 'goal-1',
          amount: '100.00',
          currencyCode: 'USD',
          contributionDate: DateTime(2026, 4, 26),
        ),
      );

      final beforeDelete = await (database.select(database.goalContributionsTable)
            ..where((table) => table.goalId.equals('goal-1')))
          .get();
      expect(beforeDelete.length, 1);

      await (database.delete(database.savingsGoalsTable)
            ..where((table) => table.id.equals('goal-1')))
          .go();

      final afterDelete = await (database.select(database.goalContributionsTable)
            ..where((table) => table.goalId.equals('goal-1')))
          .get();
      expect(afterDelete, isEmpty);
    },
  );

  test(
    'duplicate sync_id insert is ignored',
    () async {
      final firstInsert = await database.transactionDao.insertIgnoringDuplicateSyncId(
        TransactionsTableCompanion.insert(
          id: 'tx-sync-1',
          userId: 'user-1',
          walletId: 'wallet-1',
          syncId: const Value('sync-abc'),
          type: 'income',
          amount: '50.00',
          currencyCode: 'USD',
          title: 'Salary',
          transactionDate: DateTime(2026, 4, 26),
        ),
      );

      final secondInsert = await database.transactionDao.insertIgnoringDuplicateSyncId(
        TransactionsTableCompanion.insert(
          id: 'tx-sync-2',
          userId: 'user-1',
          walletId: 'wallet-1',
          syncId: const Value('sync-abc'),
          type: 'income',
          amount: '50.00',
          currencyCode: 'USD',
          title: 'Salary duplicate',
          transactionDate: DateTime(2026, 4, 26),
        ),
      );

      final rows = await database.select(database.transactionsTable).get();

      expect(firstInsert, greaterThan(0));
      expect(secondInsert, 0);
      expect(rows.length, 1);
      expect(rows.first.syncId, 'sync-abc');
    },
  );
}
