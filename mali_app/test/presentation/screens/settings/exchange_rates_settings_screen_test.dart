import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mali_app/application/providers/exchange_rate_settings_providers.dart';
import 'package:mali_app/application/providers/home_providers.dart';
import 'package:mali_app/domain/entities/exchange_rate.dart';
import 'package:mali_app/domain/exchange_rates/exchange_rate_catalog.dart';
import 'package:mali_app/domain/usecases/calculate_net_worth_usecase.dart';
import 'package:mali_app/domain/value_objects/currency_code.dart';
import 'package:mali_app/domain/value_objects/money.dart';
import 'package:mali_app/presentation/screens/settings/exchange_rates_settings_screen.dart';

ExchangeRate _rate({
  required String quote,
  required String rate,
  bool isManual = false,
  DateTime? updatedAt,
}) {
  final stamp = updatedAt ?? DateTime(2026, 11, 11, 7);
  return ExchangeRate(
    id: 'rate-$quote',
    baseCurrencyCode: 'USD',
    quoteCurrencyCode: quote,
    rate: rate,
    isManual: isManual,
    rateDate: stamp,
    isSynced: !isManual,
    createdAt: stamp,
    updatedAt: stamp,
  );
}

Future<void> _pumpScreen(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(800, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final items = [
    for (final pair in ExchangeRateCatalog.allPairs)
      ExchangeRateSettingsItem(
        pair: pair,
        rate: pair.base == CurrencyCode.usd && pair.quote == CurrencyCode.zwg
            ? _rate(quote: 'ZWG', rate: '26.80')
            : pair.base == CurrencyCode.usd && pair.quote == CurrencyCode.zar
                ? _rate(quote: 'ZAR', rate: '18.20')
                : pair.base == CurrencyCode.usd && pair.quote == CurrencyCode.bwp
                    ? _rate(
                        quote: 'BWP',
                        rate: '13.60',
                        isManual: true,
                        updatedAt: DateTime(2026, 11, 2),
                      )
                    : null,
      ),
  ];

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        exchangeRateSettingsItemsProvider.overrideWith(
          (ref) => Stream.value(items),
        ),
        homeNetWorthProvider.overrideWith(
          (ref) async => CalculateNetWorthResult(
            total: Money(
              amount: Decimal.parse('100'),
              currency: CurrencyCode.usd,
            ),
            walletBreakdown: const [],
          ),
        ),
        exchangeRateRefreshProvider.overrideWith(_FakeRefresh.new),
      ],
      child: const MaterialApp(home: ExchangeRatesSettingsScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

class _FakeRefresh extends ExchangeRateRefresh {
  @override
  FutureOr<void> build() {}
}

void main() {
  testWidgets('shows converter, USD rate list, and info note', (tester) async {
    await _pumpScreen(tester);

    expect(
      find.byKey(ExchangeRatesSettingsScreen.screenKey),
      findsOneWidget,
    );
    expect(find.text('Exchange rates'), findsOneWidget);
    expect(find.byKey(ExchangeRatesSettingsScreen.converterKey), findsOneWidget);
    expect(find.text('You have'), findsOneWidget);
    expect(find.text('\$100.00'), findsOneWidget);
    expect(find.text('Worth about'), findsOneWidget);
    expect(find.text('ZiG 2,680.00'), findsOneWidget);
    expect(find.text('1 USD EQUALS'), findsOneWidget);
    expect(find.text('ZiG 26.80'), findsOneWidget);
    expect(find.text('R 18.20'), findsOneWidget);
    expect(find.text('P 13.60'), findsOneWidget);
    expect(find.text('Auto'), findsNWidgets(2));
    expect(find.text('Manual'), findsOneWidget);
    expect(
      find.textContaining('Rates only change how totals are shown'),
      findsOneWidget,
    );
  });

  testWidgets('switching target updates worth about', (tester) async {
    await _pumpScreen(tester);

    await tester.tap(
      find.descendant(
        of: find.byKey(ExchangeRatesSettingsScreen.converterKey),
        matching: find.text('ZAR'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('R 1,820.00'), findsOneWidget);
  });
}
