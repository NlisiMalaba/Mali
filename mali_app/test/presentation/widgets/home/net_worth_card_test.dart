import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mali_app/application/providers/home_providers.dart';
import 'package:mali_app/domain/entities/wallet.dart';
import 'package:mali_app/domain/usecases/calculate_net_worth_usecase.dart';
import 'package:mali_app/domain/value_objects/currency_code.dart';
import 'package:mali_app/domain/value_objects/money.dart';
import 'package:mali_app/presentation/utils/currency_display.dart';
import 'package:mali_app/presentation/widgets/home/net_worth_card.dart';

Wallet _wallet({
  required String id,
  required String name,
  required String currencyCode,
  required String balance,
}) {
  return Wallet(
    id: id,
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

CalculateNetWorthResult _netWorthResult({
  required List<ConvertedWalletBalance> breakdown,
}) {
  return CalculateNetWorthResult(
    total: Money(amount: Decimal.parse('1500'), currency: CurrencyCode.usd),
    walletBreakdown: breakdown,
  );
}

void main() {
  group('NetWorthCard', () {
    testWidgets('shows net worth label and USD-equivalent total', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            homeNetWorthProvider.overrideWith(
              (ref) async => _netWorthResult(
                breakdown: [
                  ConvertedWalletBalance(
                    wallet: _wallet(
                      id: 'w-1',
                      name: 'Cash',
                      currencyCode: 'USD',
                      balance: '1500',
                    ),
                    convertedAmount: Money(
                      amount: Decimal.parse('1500'),
                      currency: CurrencyCode.usd,
                    ),
                  ),
                ],
              ),
            ),
            exchangeRatesLastUpdatedProvider.overrideWith(
              (ref) => Stream.value(null),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: NetWorthCard()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Net worth'), findsOneWidget);
      expect(find.byKey(const Key('net-worth-total')), findsOneWidget);
    });

    testWidgets('shows row of individual wallet balances', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            homeNetWorthProvider.overrideWith(
              (ref) async => _netWorthResult(
                breakdown: [
                  ConvertedWalletBalance(
                    wallet: _wallet(
                      id: 'w-1',
                      name: 'EcoCash USD',
                      currencyCode: 'USD',
                      balance: '500',
                    ),
                    convertedAmount: Money(
                      amount: Decimal.parse('500'),
                      currency: CurrencyCode.usd,
                    ),
                  ),
                  ConvertedWalletBalance(
                    wallet: _wallet(
                      id: 'w-2',
                      name: 'Rand Wallet',
                      currencyCode: 'ZAR',
                      balance: '2000',
                    ),
                    convertedAmount: Money(
                      amount: Decimal.parse('100'),
                      currency: CurrencyCode.usd,
                    ),
                  ),
                ],
              ),
            ),
            exchangeRatesLastUpdatedProvider.overrideWith(
              (ref) => Stream.value(DateTime.utc(2026, 5, 24, 10)),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: NetWorthCard()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(CurrencyDisplay.flagEmoji(CurrencyCode.usd)),
        findsOneWidget,
      );
      expect(
        find.text(CurrencyDisplay.flagEmoji(CurrencyCode.zar)),
        findsOneWidget,
      );
      expect(find.text('USD 500.00'), findsOneWidget);
      expect(find.text('ZAR 2000.00'), findsOneWidget);
      expect(find.text('EcoCash USD'), findsOneWidget);
      expect(find.text('Rand Wallet'), findsOneWidget);
    });

    testWidgets('shows exchange rates footer when multi-currency', (tester) async {
      final updatedAt = DateTime.now().subtract(const Duration(hours: 2));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            homeNetWorthProvider.overrideWith(
              (ref) async => _netWorthResult(
                breakdown: [
                  ConvertedWalletBalance(
                    wallet: _wallet(
                      id: 'w-1',
                      name: 'USD',
                      currencyCode: 'USD',
                      balance: '100',
                    ),
                    convertedAmount: Money(
                      amount: Decimal.parse('100'),
                      currency: CurrencyCode.usd,
                    ),
                  ),
                  ConvertedWalletBalance(
                    wallet: _wallet(
                      id: 'w-2',
                      name: 'ZAR',
                      currencyCode: 'ZAR',
                      balance: '200',
                    ),
                    convertedAmount: Money(
                      amount: Decimal.parse('10'),
                      currency: CurrencyCode.usd,
                    ),
                  ),
                ],
              ),
            ),
            exchangeRatesLastUpdatedProvider.overrideWith(
              (ref) => Stream.value(updatedAt),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: NetWorthCard()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Exchange rates last updated: 2 hours ago'),
        findsOneWidget,
      );
    });

    testWidgets('hides exchange rates footer for single-currency wallets',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            homeNetWorthProvider.overrideWith(
              (ref) async => _netWorthResult(
                breakdown: [
                  ConvertedWalletBalance(
                    wallet: _wallet(
                      id: 'w-1',
                      name: 'Cash',
                      currencyCode: 'USD',
                      balance: '100',
                    ),
                    convertedAmount: Money(
                      amount: Decimal.parse('100'),
                      currency: CurrencyCode.usd,
                    ),
                  ),
                ],
              ),
            ),
            exchangeRatesLastUpdatedProvider.overrideWith(
              (ref) => Stream.value(DateTime.now()),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: NetWorthCard()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Exchange rates last updated'), findsNothing);
    });
  });
}
