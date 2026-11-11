import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:mali_app/application/providers/category_providers.dart';
import 'package:mali_app/application/providers/wallet_providers.dart';
import 'package:mali_app/domain/entities/category.dart';
import 'package:mali_app/domain/entities/transaction.dart';
import 'package:mali_app/domain/entities/wallet.dart';
import 'package:mali_app/presentation/theme/app_colors.dart';
import 'package:mali_app/presentation/widgets/transaction/transaction_tile.dart';

Transaction _transaction({
  String type = 'expense',
  String amount = '25.50',
  String? categoryId = 'cat-food',
}) {
  final timestamp = DateTime(2026, 5, 24, 14, 30);
  return Transaction(
    id: 'tx-1',
    userId: 'user-1',
    walletId: 'wallet-1',
    categoryId: categoryId,
    type: type,
    amount: amount,
    currencyCode: 'USD',
    title: 'Lunch',
    transactionDate: timestamp,
    isSynced: false,
    createdAt: timestamp,
    updatedAt: timestamp,
  );
}

Category _category() {
  return Category(
    id: 'cat-food',
    userId: 'user-1',
    name: 'Groceries',
    iconKey: 'restaurant',
    colorHex: '#0F7A3D',
    type: 'expense',
    isSystem: false,
    isArchived: false,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

Wallet _wallet() {
  return Wallet(
    id: 'wallet-1',
    userId: 'user-1',
    name: 'Cash',
    currencyCode: 'USD',
    balance: '100.00',
    isArchived: false,
    isSynced: true,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

List<Override> _overrides() => [
      categoryByIdProvider('cat-food').overrideWithValue(_category()),
      walletByIdProvider('wallet-1').overrideWith((ref) async => _wallet()),
    ];

void main() {
  group('TransactionTile', () {
    testWidgets('shows compact expense amount and category wallet subtitle',
        (tester) async {
      final transaction = _transaction();
      await tester.pumpWidget(
        ProviderScope(
          overrides: _overrides(),
          child: MaterialApp(
            home: Scaffold(
              body: TransactionTile(transaction: transaction),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Lunch'), findsOneWidget);
      expect(find.text('\u2212\$25.50'), findsOneWidget);
      expect(find.text('Groceries · Cash USD'), findsOneWidget);
      expect(find.text('L'), findsOneWidget);

      final amountText = tester.widget<Text>(find.text('\u2212\$25.50'));
      expect(amountText.style?.color, AppColors.expense);
    });

    testWidgets('shows income amount in green with plus prefix', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: _overrides(),
          child: MaterialApp(
            home: Scaffold(
              body: TransactionTile(
                transaction: _transaction(
                  type: 'income',
                  amount: '100.00',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('+\$100.00'), findsOneWidget);

      final amountText = tester.widget<Text>(find.text('+\$100.00'));
      expect(amountText.style?.color, AppColors.income);
    });

    testWidgets('shows transfer amount in neutral black without prefix',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: _overrides(),
          child: MaterialApp(
            home: Scaffold(
              body: TransactionTile(
                transaction: _transaction(
                  type: 'transfer',
                  amount: '50.00',
                  categoryId: null,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('\$50.00'), findsOneWidget);

      final amountText = tester.widget<Text>(find.text('\$50.00'));
      expect(amountText.style?.color, AppColors.transferAmount);
    });
  });
}
