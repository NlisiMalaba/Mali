import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mali_app/application/providers/display_currency_provider.dart';
import 'package:mali_app/application/providers/wallet_card_providers.dart';
import 'package:mali_app/domain/entities/wallet.dart';
import 'package:mali_app/domain/value_objects/currency_code.dart';
import 'package:mali_app/presentation/utils/currency_display.dart';
import 'package:mali_app/presentation/widgets/wallet/wallet_card.dart';

Wallet _wallet({
  String currencyCode = 'ZAR',
  String balance = '20',
  String name = 'Main',
}) {
  return Wallet(
    id: 'w-1',
    userId: 'u-1',
    name: name,
    currencyCode: currencyCode,
    balance: balance,
    isArchived: false,
    isSynced: false,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );
}

void main() {
  group('WalletCard', () {
    testWidgets('displays wallet name and correct currency flag', (tester) async {
      const currency = CurrencyCode.zar;
      final wallet = _wallet(currencyCode: currency.value, name: 'EcoCash ZAR');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            displayCurrencyProvider.overrideWithValue(CurrencyCode.usd),
            walletEquivalentLabelProvider(
              (balance: wallet.balance, currencyCode: wallet.currencyCode),
            ).overrideWith((ref) async => null),
          ],
          child: MaterialApp(
            home: Scaffold(body: WalletCard(wallet: wallet)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('EcoCash ZAR'), findsOneWidget);
      expect(find.text(CurrencyDisplay.flagEmoji(currency)), findsOneWidget);
      expect(find.text('ZAR 20.00'), findsOneWidget);
    });

    testWidgets('balance rounds to 2 decimal places', (tester) async {
      final wallet = _wallet(currencyCode: 'USD', balance: '10.567');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            displayCurrencyProvider.overrideWithValue(CurrencyCode.usd),
            walletEquivalentLabelProvider(
              (balance: wallet.balance, currencyCode: wallet.currencyCode),
            ).overrideWith((ref) async => null),
          ],
          child: MaterialApp(
            home: Scaffold(body: WalletCard(wallet: wallet)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('USD 10.57'), findsOneWidget);
    });

    testWidgets('hides equivalent when wallet currency matches display currency',
        (tester) async {
      final wallet = _wallet(currencyCode: 'USD', balance: '10.5');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            displayCurrencyProvider.overrideWithValue(CurrencyCode.usd),
            walletEquivalentLabelProvider(
              (balance: wallet.balance, currencyCode: wallet.currencyCode),
            ).overrideWith((ref) async => null),
          ],
          child: MaterialApp(
            home: Scaffold(body: WalletCard(wallet: wallet)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('USD 10.50'), findsOneWidget);
      expect(find.textContaining('≈'), findsNothing);
    });

    testWidgets('equivalent shows ≈ prefix when currencies differ', (tester) async {
      final wallet = _wallet(currencyCode: 'ZAR', balance: '20');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            displayCurrencyProvider.overrideWithValue(CurrencyCode.usd),
            walletEquivalentLabelProvider(
              (balance: wallet.balance, currencyCode: wallet.currencyCode),
            ).overrideWith((ref) async => '≈ USD 1.00'),
          ],
          child: MaterialApp(
            home: Scaffold(body: WalletCard(wallet: wallet)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ZAR 20.00'), findsOneWidget);
      final equivalent = find.text('≈ USD 1.00');
      expect(equivalent, findsOneWidget);
      expect(
        tester.widget<Text>(equivalent).data,
        startsWith('≈'),
      );
    });
  });
}
