import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mali_app/application/providers/auth_provider.dart';
import 'package:mali_app/application/providers/display_currency_provider.dart';
import 'package:mali_app/application/providers/exchange_rate_settings_providers.dart';
import 'package:mali_app/application/providers/home_providers.dart';
import 'package:mali_app/application/providers/wallet_card_providers.dart';
import 'package:mali_app/application/providers/wallet_providers.dart';
import 'package:mali_app/domain/value_objects/currency_code.dart';
import 'package:mali_app/domain/entities/user.dart';
import 'package:mali_app/domain/entities/wallet.dart';
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
          exchangeRateSettingsItemsProvider.overrideWith(
            (ref) => Stream.value(const []),
          ),
          exchangeRatesLastUpdatedProvider.overrideWith(
            (ref) => Stream.value(null),
          ),
          walletEquivalentLabelProvider(
            (balance: '120.50', currencyCode: 'USD'),
          ).overrideWith((ref) async => null),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('EcoCash USD'), findsOneWidget);
    expect(find.text('USD 120.50'), findsOneWidget);

    await tester.tap(find.text('EcoCash USD'));
    await tester.pumpAndSettle();

    expect(find.text('Transactions w-1'), findsOneWidget);
  });
}
