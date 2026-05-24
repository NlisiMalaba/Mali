import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:mali_app/domain/entities/transaction.dart';
import 'package:mali_app/presentation/theme/app_colors.dart';
import 'package:mali_app/presentation/widgets/transaction/transaction_tile.dart';

Transaction _transaction({
  String type = 'expense',
  String amount = '25.50',
  String? notes,
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
    notes: notes,
    transactionDate: timestamp,
    isSynced: false,
    createdAt: timestamp,
    updatedAt: timestamp,
  );
}

void main() {
  group('TransactionTile', () {
    testWidgets('shows expense amount in red and currency code', (tester) async {
      final transaction = _transaction();
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: TransactionTile(transaction: transaction),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Lunch'), findsOneWidget);
      expect(find.text('-25.50'), findsOneWidget);
      expect(find.text('USD'), findsOneWidget);
      expect(
        find.text(DateFormat.jm().format(transaction.transactionDate)),
        findsOneWidget,
      );

      final amountText = tester.widget<Text>(find.text('-25.50'));
      expect(amountText.style?.color, AppColors.error);
    });

    testWidgets('shows income amount in green with plus prefix', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: TransactionTile(
                transaction: _transaction(
                  type: 'income',
                  amount: '100.00',
                  categoryId: 'cat-salary',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('+100.00'), findsOneWidget);

      final amountText = tester.widget<Text>(find.text('+100.00'));
      expect(amountText.style?.color, AppColors.success);
    });

    testWidgets('displays notes when provided', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: TransactionTile(
                transaction: _transaction(notes: 'Team lunch'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Team lunch'), findsOneWidget);
    });

    testWidgets('shows category icon for known category', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: TransactionTile(transaction: _transaction()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.restaurant_outlined), findsOneWidget);
    });
  });
}
