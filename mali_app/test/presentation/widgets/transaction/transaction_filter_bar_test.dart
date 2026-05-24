import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mali_app/application/models/transaction_list_filters.dart';
import 'package:mali_app/application/providers/transaction_list_filters_provider.dart';
import 'package:mali_app/application/providers/wallet_providers.dart';
import 'package:mali_app/domain/entities/wallet.dart';
import 'package:mali_app/presentation/widgets/transaction/transaction_filter_bar.dart';

Wallet _wallet({required String id, required String name}) {
  final timestamp = DateTime.utc(2026, 1, 1);
  return Wallet(
    id: id,
    userId: 'user-1',
    name: name,
    currencyCode: 'USD',
    balance: '100',
    isArchived: false,
    isSynced: false,
    createdAt: timestamp,
    updatedAt: timestamp,
  );
}

void main() {
  group('TransactionFilterBar', () {
    testWidgets('shows category, wallet, and date selector chips', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeWalletsProvider.overrideWith(
              (ref) => Stream.value([
                _wallet(id: 'w-1', name: 'Cash'),
              ]),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: TransactionFilterBar(scopedWalletId: null),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('filter-chip-category')), findsOneWidget);
      expect(find.byKey(const Key('filter-chip-wallet')), findsOneWidget);
      expect(find.byKey(const Key('filter-chip-date')), findsOneWidget);
    });

    testWidgets('shows dismissible active filter chips', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            transactionListFiltersProvider(null).overrideWith(
              () => _StubFilters(
                const TransactionListFilters(categoryId: 'cat-food'),
              ),
            ),
            activeWalletsProvider.overrideWith(
              (ref) => Stream.value(const []),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: TransactionFilterBar(scopedWalletId: null),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('active-filter-category-cat-food')),
          findsOneWidget);
      expect(find.text('Food'), findsOneWidget);
    });

    testWidgets('hides wallet filter chip when wallet scope is fixed',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeWalletsProvider.overrideWith(
              (ref) => Stream.value(const []),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: TransactionFilterBar(scopedWalletId: 'w-1'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('filter-chip-wallet')), findsNothing);
      expect(find.byKey(const Key('filter-chip-category')), findsOneWidget);
    });
  });
}

class _StubFilters extends TransactionListFiltersNotifier {
  _StubFilters(this._initial);

  final TransactionListFilters _initial;

  @override
  TransactionListFilters build(String? scopedWalletId) => _initial;
}
