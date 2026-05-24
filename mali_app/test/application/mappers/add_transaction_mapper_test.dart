import 'package:flutter_test/flutter_test.dart';
import 'package:mali_app/application/mappers/add_transaction_mapper.dart';

void main() {
  group('AddTransactionMapper', () {
    test('maps input to offline-first transaction entity', () {
      final transaction = AddTransactionMapper.toTransaction(
        AddTransactionInput(
          userId: 'user-1',
          type: 'expense',
          amount: '12.50',
          currencyCode: 'USD',
          walletId: 'wallet-1',
          categoryId: 'cat-food',
          title: 'Food',
          notes: 'Lunch',
          transactionDate: DateTime.utc(2026, 5, 24, 12),
        ),
      );

      expect(transaction.userId, 'user-1');
      expect(transaction.walletId, 'wallet-1');
      expect(transaction.type, 'expense');
      expect(transaction.amount, '12.50');
      expect(transaction.currencyCode, 'USD');
      expect(transaction.categoryId, 'cat-food');
      expect(transaction.title, 'Food');
      expect(transaction.notes, 'Lunch');
      expect(transaction.isSynced, isFalse);
      expect(transaction.id, startsWith('tx-'));
      expect(transaction.syncId, transaction.id);
    });

    test('includes exchange rate for cross-currency transfers', () {
      final transaction = AddTransactionMapper.toTransaction(
        AddTransactionInput(
          userId: 'user-1',
          type: 'transfer',
          amount: '100',
          currencyCode: 'USD',
          walletId: 'wallet-usd',
          exchangeRate: '26.5',
          title: 'Transfer',
          transactionDate: DateTime.utc(2026, 5, 24),
        ),
      );

      expect(transaction.exchangeRate, '26.5');
      expect(transaction.categoryId, isNull);
    });
  });
}
