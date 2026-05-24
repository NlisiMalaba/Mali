import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mali_app/application/providers/auth_provider.dart';
import 'package:mali_app/application/providers/wallet_providers.dart';
import 'package:mali_app/domain/entities/user.dart';
import 'package:mali_app/domain/entities/wallet.dart';
import 'package:mali_app/presentation/router/app_router.dart';
import 'package:mali_app/presentation/screens/budget/budgets_screen.dart';
import 'package:mali_app/presentation/screens/splash_screen.dart';

import '../home/home_test_overrides.dart';

class _AuthenticatedAuth extends Auth {
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

class _ImmediateUnauthenticatedAuth extends Auth {
  @override
  Future<User?> build() async => null;
}

Stream<List<Wallet>> _walletsWithOne() {
  return Stream.value([
    Wallet(
      id: 'w-1',
      userId: 'user-1',
      name: 'Cash',
      currencyCode: 'USD',
      balance: '0',
      isArchived: false,
      isSynced: false,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
    ),
  ]);
}

Stream<List<Wallet>> _emptyWallets() => Stream.value(const <Wallet>[]);

void main() {
  group('GoRouter', () {
    testWidgets('redirects unauthenticated users to login', (tester) async {
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(_ImmediateUnauthenticatedAuth.new),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(appRouterProvider);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pump();
      await tester.pump(SplashScreen.minimumDisplayDuration);
      await tester.pumpAndSettle();

      expect(find.text('Login'), findsOneWidget);
    });

    testWidgets('navigates between all defined routes when authenticated',
        (tester) async {
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(_AuthenticatedAuth.new),
          activeWalletsProvider.overrideWith((ref) => _walletsWithOne()),
          ...homeScreenTestOverrides(),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(appRouterProvider);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pump();
      await tester.pump(SplashScreen.minimumDisplayDuration);
      await tester.pumpAndSettle();

      final routes = <String, Finder>{
        '/home': find.byKey(const Key('home-screen')),
        '/transactions': find.text('No transactions yet.'),
        '/add-transaction': find.text('Add Transaction'),
        '/budgets': find.byKey(BudgetsScreen.screenKey),
        '/wallets': find.text('Wallets'),
        '/goals': find.text('Goals'),
        '/goals/goal-1': find.text('Goal goal-1'),
        '/analytics': find.text('Analytics'),
        '/settings': find.text('Settings'),
      };

      for (final entry in routes.entries) {
        router.go(entry.key);
        await tester.pumpAndSettle();
        expect(entry.value, findsOneWidget);
      }
    });

    testWidgets('navigates to auth routes when unauthenticated', (tester) async {
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(_ImmediateUnauthenticatedAuth.new),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(appRouterProvider);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      for (final route in ['/auth/login', '/auth/register']) {
        router.go(route);
        await tester.pumpAndSettle();
      }

      expect(find.text('Register'), findsOneWidget);
    });

    testWidgets('redirects authenticated users without wallets to wallet setup',
        (tester) async {
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(_AuthenticatedAuth.new),
          activeWalletsProvider.overrideWith((ref) => _emptyWallets()),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(appRouterProvider);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pump();
      await tester.pump(SplashScreen.minimumDisplayDuration);
      await tester.pumpAndSettle();

      expect(find.text('Set up wallets'), findsOneWidget);
    });
  });
}
