import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mali_app/application/models/home_monthly_summary_display.dart';
import 'package:mali_app/application/providers/auth_provider.dart';
import 'package:mali_app/application/providers/display_currency_provider.dart';
import 'package:mali_app/application/providers/home_providers.dart';
import 'package:mali_app/application/providers/wallet_card_providers.dart';
import 'package:mali_app/application/providers/wallet_providers.dart';
import 'package:mali_app/domain/entities/transaction.dart';
import 'package:mali_app/domain/entities/user.dart';
import 'package:mali_app/domain/entities/wallet.dart';
import 'package:mali_app/domain/usecases/calculate_net_worth_usecase.dart';
import 'package:mali_app/domain/value_objects/currency_code.dart';
import 'package:mali_app/domain/value_objects/money.dart';
import 'package:mali_app/presentation/screens/wallet/wallets_screen.dart';

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

Stream<List<Wallet>> _walletsStream() {
  return Stream.value([
    Wallet(
      id: 'w-1',
      userId: 'user-1',
      name: 'EcoCash USD',
      currencyCode: 'USD',
      balance: '120.50',
      isArchived: false,
      isSynced: false,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
    ),
  ]);
}

void main() {
  testWidgets('lists wallets with balance and navigates on tap', (tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const WalletsScreen(),
        ),
        GoRoute(
          path: '/wallets/:walletId',
          builder: (context, state) => Scaffold(
            body: Center(
              child: Text('Transactions ${state.pathParameters['walletId']}'),
            ),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(_TestAuth.new),
          activeWalletsProvider.overrideWith((ref) => _walletsStream()),
          displayCurrencyProvider.overrideWithValue(CurrencyCode.usd),
          walletEquivalentLabelProvider(
            (balance: '120.50', currencyCode: 'USD'),
          ).overrideWith((ref) async => null),
          walletTransactionsProvider('w-1').overrideWith(
            (ref) => Stream.value(const <Transaction>[]),
          ),
          homeMonthlySummaryDisplayProvider.overrideWith(
            (ref) async => HomeMonthlySummaryDisplay(
              month: DateTime(2026, 5),
              income: Decimal.parse('100'),
              expenses: Decimal.parse('40'),
              displayCurrency: CurrencyCode.usd,
            ),
          ),
          homeNetWorthProvider.overrideWith(
            (ref) async => CalculateNetWorthResult(
              totalsByCurrency: [
                Money(
                  amount: Decimal.parse('120.50'),
                  currency: CurrencyCode.usd,
                ),
              ],
              walletBreakdown: const [],
            ),
          ),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: child!,
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Wallets'), findsOneWidget);
    expect(find.text('All wallets in USD'), findsOneWidget);
    expect(find.text('EcoCash USD'), findsWidgets);
    expect(find.text('\$120.50'), findsWidgets);
    expect(find.text('Add wallet'), findsOneWidget);
    expect(find.textContaining('green in, red out'), findsOneWidget);
    expect(find.textContaining('Market Rates'), findsNothing);

    await tester.tap(find.text('EcoCash USD').first);
    await tester.pumpAndSettle();

    expect(find.text('Transactions w-1'), findsOneWidget);
  });
}
