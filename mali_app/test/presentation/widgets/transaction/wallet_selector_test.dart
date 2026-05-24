import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mali_app/application/providers/recent_wallets_provider.dart';
import 'package:mali_app/core/storage/recent_wallet_store.dart';
import 'package:mali_app/domain/entities/wallet.dart';
import 'package:mali_app/presentation/utils/wallet_ordering.dart';
import 'package:mali_app/presentation/widgets/transaction/transfer_exchange_rate_field.dart';
import 'package:mali_app/presentation/widgets/transaction/wallet_selector.dart';

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

Wallet _wallet(String id, String name, {String currencyCode = 'USD'}) {
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

void main() {
  group('WalletOrdering', () {
    test('places recent wallets first', () {
      final wallets = [
        _wallet('w-1', 'Cash'),
        _wallet('w-2', 'EcoCash'),
        _wallet('w-3', 'Bank'),
      ];

      final ordered = WalletOrdering.withRecentFirst(
        wallets: wallets,
        recentWalletIds: const ['w-3', 'w-1'],
      );

      expect(ordered.map((wallet) => wallet.id).toList(), [
        'w-3',
        'w-1',
        'w-2',
      ]);
    });
  });

  group('RecentWalletStore', () {
    test('moves selected wallet to front and caps list size', () {
      final store = RecentWalletStore(maxRecent: 3);
      var current = ['w-1', 'w-2', 'w-3'];

      final next = store.recordUsage(current: current, walletId: 'w-4');
      expect(next, ['w-4', 'w-1', 'w-2']);

      current = next;
      final promoted = store.recordUsage(current: current, walletId: 'w-2');
      expect(promoted, ['w-2', 'w-4', 'w-1']);
    });
  });

  group('isValidExchangeRate', () {
    test('accepts positive decimal rates only', () {
      expect(isValidExchangeRate('1.25'), isTrue);
      expect(isValidExchangeRate('0'), isFalse);
      expect(isValidExchangeRate('abc'), isFalse);
      expect(isValidExchangeRate(null), isFalse);
    });
  });

  group('WalletSelector', () {
    testWidgets('shows transfer exchange rate when currencies differ',
        (tester) async {
      final store = _InMemoryRecentWalletStore([]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            recentWalletStoreProvider.overrideWithValue(store),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: _WalletSelectorHarness(
                wallets: [
                  _wallet('w-usd', 'USD Wallet', currencyCode: 'USD'),
                  _wallet('w-zwg', 'ZWG Wallet', currencyCode: 'ZWG'),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('wallet-selector-from-w-usd')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('wallet-selector-to-w-zwg')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('transfer-exchange-rate')), findsOneWidget);
      expect(find.text('Exchange rate'), findsOneWidget);
    });

    testWidgets('hides exchange rate for same-currency transfer', (tester) async {
      final store = _InMemoryRecentWalletStore([]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            recentWalletStoreProvider.overrideWithValue(store),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: _WalletSelectorHarness(
                wallets: [
                  _wallet('w-1', 'Cash A'),
                  _wallet('w-2', 'Cash B'),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('wallet-selector-from-w-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('wallet-selector-to-w-2')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('transfer-exchange-rate')), findsNothing);
    });
  });
}

class _WalletSelectorHarness extends StatefulWidget {
  const _WalletSelectorHarness({required this.wallets});

  final List<Wallet> wallets;

  @override
  State<_WalletSelectorHarness> createState() => _WalletSelectorHarnessState();
}

class _WalletSelectorHarnessState extends State<_WalletSelectorHarness> {
  String? _fromWalletId;
  String? _toWalletId;
  final _exchangeRateController = TextEditingController();

  @override
  void dispose() {
    _exchangeRateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WalletSelector(
      wallets: widget.wallets,
      mode: WalletSelectorMode.transfer,
      fromWalletId: _fromWalletId,
      toWalletId: _toWalletId,
      onFromWalletChanged: (wallet) {
        setState(() => _fromWalletId = wallet.id);
      },
      onToWalletChanged: (wallet) {
        setState(() => _toWalletId = wallet.id);
      },
      exchangeRateController: _exchangeRateController,
      suggestedExchangeRate: null,
      onExchangeRateChanged: (_) {},
    );
  }
}
