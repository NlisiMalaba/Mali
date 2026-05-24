import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mali_app/application/mappers/add_transaction_mapper.dart';
import 'package:mali_app/application/providers/add_transaction_provider.dart';
import 'package:mali_app/application/providers/auth_provider.dart';
import 'package:mali_app/application/providers/recent_categories_provider.dart';
import 'package:mali_app/application/providers/recent_wallets_provider.dart';
import 'package:mali_app/application/providers/transfer_exchange_rate_provider.dart';
import 'package:mali_app/application/providers/wallet_providers.dart';
import 'package:mali_app/core/storage/recent_category_store.dart';
import 'package:mali_app/core/storage/recent_wallet_store.dart';
import 'package:mali_app/domain/entities/user.dart';
import 'package:mali_app/domain/entities/wallet.dart';
import 'package:mali_app/presentation/utils/category_icons.dart';
import 'package:mali_app/presentation/widgets/transaction/add_transaction_sheet.dart';

class _TestAuth extends Auth {
  @override
  Future<User?> build() async {
    return User(
      id: 'user-1',
      name: 'Mali User',
      email: 'user@example.com',
      createdAt: DateTime.utc(2026, 1, 1),
    );
  }
}

class _InMemoryRecentCategoryStore extends RecentCategoryStore {
  _InMemoryRecentCategoryStore(this._data);

  Map<String, List<String>> _data;

  @override
  Future<Map<String, List<String>>> readAll() async {
    return Map<String, List<String>>.from(_data);
  }

  @override
  Future<void> writeAll(Map<String, List<String>> data) async {
    _data = Map<String, List<String>>.from(data);
  }
}

class _InMemoryRecentWalletStore extends RecentWalletStore {
  _InMemoryRecentWalletStore(this._data);

  List<String> _data;

  @override
  Future<List<String>> readAll() async {
    return List<String>.from(_data);
  }

  @override
  Future<void> writeAll(List<String> walletIds) async {
    _data = List<String>.from(walletIds);
  }
}

class _SpyAddTransaction extends AddTransaction {
  int submitCount = 0;

  @override
  Future<void> submit(AddTransactionInput input) async {
    submitCount++;
  }
}

Wallet _wallet(String id, String name, {required String currencyCode}) {
  return Wallet(
    id: id,
    userId: 'user-1',
    name: name,
    currencyCode: currencyCode,
    balance: '100',
    isArchived: false,
    isSynced: false,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );
}

final _usdWallet = _wallet('w-usd', 'USD Wallet', currencyCode: 'USD');
final _zwgWallet = _wallet('w-zwg', 'ZWG Wallet', currencyCode: 'ZWG');

Color? _categoryBorderColor(WidgetTester tester, String categoryId) {
  final containerFinder = find.descendant(
    of: find.byKey(Key('category-icon-$categoryId')),
    matching: find.byType(Container),
  );
  if (containerFinder.evaluate().isEmpty) {
    return null;
  }
  final container = tester.widget<Container>(containerFinder.first);
  final decoration = container.decoration;
  if (decoration is! BoxDecoration) {
    return null;
  }
  return decoration.border?.top.color;
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pump();
}

Future<ProviderContainer> _pumpAddTransactionSheet(
  WidgetTester tester, {
  List<Wallet> wallets = const [],
  _SpyAddTransaction? spy,
}) async {
  await tester.binding.setSurfaceSize(const Size(800, 1200));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final addTransaction = spy ?? _SpyAddTransaction();
  final container = ProviderContainer(
    overrides: [
      authProvider.overrideWith(_TestAuth.new),
      activeWalletsProvider.overrideWith((ref) => Stream.value(wallets)),
      recentCategoryStoreProvider.overrideWithValue(
        _InMemoryRecentCategoryStore({}),
      ),
      recentWalletStoreProvider.overrideWithValue(_InMemoryRecentWalletStore([])),
      suggestedTransferExchangeRateProvider(
        (fromCurrency: 'USD', toCurrency: 'ZWG'),
      ).overrideWith((ref) async => '26.5'),
      addTransactionProvider.overrideWith(() => addTransaction),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: AddTransactionSheet(initialWalletId: wallets.firstOrNull?.id),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  return container;
}

void main() {
  group('AddTransactionSheet', () {
    testWidgets('empty amount blocks submit', (tester) async {
      final spy = _SpyAddTransaction();
      await _pumpAddTransactionSheet(
        tester,
        wallets: [_usdWallet],
        spy: spy,
      );

      await _tap(tester, find.byKey(const Key('add-transaction-submit')));

      expect(find.text('Enter an amount greater than zero.'), findsOneWidget);
      expect(spy.submitCount, 0);
    });

    testWidgets('transfer type shows exchange rate field', (tester) async {
      await _pumpAddTransactionSheet(
        tester,
        wallets: [_usdWallet, _zwgWallet],
      );

      await _tap(tester, find.text('Transfer'));

      await _tap(tester, find.byKey(const Key('wallet-selector-from-w-usd')));
      await _tap(tester, find.byKey(const Key('wallet-selector-to-w-zwg')));

      expect(find.byKey(const Key('transfer-exchange-rate')), findsOneWidget);
      expect(find.text('Exchange rate'), findsOneWidget);
    });

    testWidgets('category selection updates icon display', (tester) async {
      await _pumpAddTransactionSheet(
        tester,
        wallets: [_usdWallet],
      );

      expect(
        _categoryBorderColor(tester, 'cat-food'),
        isNot(Colors.transparent),
      );
      expect(
        _categoryBorderColor(tester, 'cat-transport'),
        Colors.transparent,
      );
      expect(find.byIcon(Icons.restaurant_outlined), findsWidgets);
      expect(find.byIcon(Icons.directions_bus_outlined), findsWidgets);

      await _tap(tester, find.byKey(const Key('category-icon-cat-transport')));

      expect(
        _categoryBorderColor(tester, 'cat-transport'),
        CategoryIcons.colorFromHex('#4ECDC4'),
      );
      expect(
        _categoryBorderColor(tester, 'cat-food'),
        Colors.transparent,
      );
    });
  });
}
