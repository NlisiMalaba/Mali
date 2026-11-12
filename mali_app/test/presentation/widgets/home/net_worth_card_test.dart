import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:mali_app/application/models/home_monthly_summary_display.dart';
import 'package:mali_app/application/providers/home_providers.dart';
import 'package:mali_app/domain/entities/wallet.dart';
import 'package:mali_app/domain/usecases/calculate_net_worth_usecase.dart';
import 'package:mali_app/domain/value_objects/currency_code.dart';
import 'package:mali_app/domain/value_objects/money.dart';
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
  required List<Money> totalsByCurrency,
  required List<WalletBalanceBreakdown> breakdown,
}) {
  return CalculateNetWorthResult(
    totalsByCurrency: totalsByCurrency,
    walletBreakdown: breakdown,
  );
}

HomeMonthlySummaryDisplay _summary({
  String income = '100',
  String expenses = '40',
}) {
  return HomeMonthlySummaryDisplay(
    month: DateTime.utc(2026, 5, 1),
    income: Decimal.parse(income),
    expenses: Decimal.parse(expenses),
    displayCurrency: CurrencyCode.usd,
  );
}

List<Override> _overrides({
  required CalculateNetWorthResult netWorth,
  HomeMonthlySummaryDisplay? summary,
}) {
  return [
    homeNetWorthProvider.overrideWith((ref) async => netWorth),
    homeMonthlySummaryDisplayProvider.overrideWith(
      (ref) async => summary ?? _summary(),
    ),
  ];
}

void main() {
  group('NetWorthCard', () {
    testWidgets('shows net worth label and single-currency total', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: _overrides(
            netWorth: _netWorthResult(
              totalsByCurrency: [
                Money(
                  amount: Decimal.parse('1500'),
                  currency: CurrencyCode.usd,
                ),
              ],
              breakdown: [
                WalletBalanceBreakdown(
                  wallet: _wallet(
                    id: 'w-1',
                    name: 'Cash',
                    currencyCode: 'USD',
                    balance: '1500',
                  ),
                ),
              ],
            ),
          ),
          child: const MaterialApp(
            home: Scaffold(body: NetWorthCard()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Net worth'), findsOneWidget);
      expect(find.byKey(const Key('net-worth-total')), findsOneWidget);
    });

    testWidgets('shows per-currency totals without mixing FX', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: _overrides(
            netWorth: _netWorthResult(
              totalsByCurrency: [
                Money(
                  amount: Decimal.parse('500'),
                  currency: CurrencyCode.usd,
                ),
                Money(
                  amount: Decimal.parse('2000'),
                  currency: CurrencyCode.zar,
                ),
              ],
              breakdown: [
                WalletBalanceBreakdown(
                  wallet: _wallet(
                    id: 'w-1',
                    name: 'EcoCash USD',
                    currencyCode: 'USD',
                    balance: '500',
                  ),
                ),
                WalletBalanceBreakdown(
                  wallet: _wallet(
                    id: 'w-2',
                    name: 'Rand Wallet',
                    currencyCode: 'ZAR',
                    balance: '2000',
                  ),
                ),
              ],
            ),
          ),
          child: const MaterialApp(
            home: Scaffold(body: NetWorthCard()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final currencyLabel = tester.widget<Text>(
        find.byKey(const Key('net-worth-currency')),
      );
      expect(currencyLabel.data, 'Net worth ›');
      expect(find.byKey(const Key('net-worth-total')), findsOneWidget);
      expect(find.text('USD'), findsWidgets);
      expect(find.text('ZAR'), findsWidgets);
      expect(find.textContaining('this month'), findsOneWidget);
    });

    testWidgets('shows currency chips for multi-currency wallets', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: _overrides(
            netWorth: _netWorthResult(
              totalsByCurrency: [
                Money(
                  amount: Decimal.parse('100'),
                  currency: CurrencyCode.usd,
                ),
                Money(
                  amount: Decimal.parse('200'),
                  currency: CurrencyCode.zar,
                ),
              ],
              breakdown: [
                WalletBalanceBreakdown(
                  wallet: _wallet(
                    id: 'w-1',
                    name: 'USD',
                    currencyCode: 'USD',
                    balance: '100',
                  ),
                ),
                WalletBalanceBreakdown(
                  wallet: _wallet(
                    id: 'w-2',
                    name: 'ZAR',
                    currencyCode: 'ZAR',
                    balance: '200',
                  ),
                ),
              ],
            ),
          ),
          child: const MaterialApp(
            home: Scaffold(body: NetWorthCard()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('USD'), findsWidgets);
      expect(find.text('ZAR'), findsWidgets);
    });
  });
}
