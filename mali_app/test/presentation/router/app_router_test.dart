import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mali_app/application/providers/auth_provider.dart';
import 'package:mali_app/domain/entities/user.dart';
import 'package:mali_app/presentation/router/app_router.dart';

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
      await tester.pumpAndSettle();

      expect(find.text('Login'), findsOneWidget);
    });

    testWidgets('navigates between all defined routes when authenticated',
        (tester) async {
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(_AuthenticatedAuth.new),
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

      final routes = <String, String>{
        '/home': 'Home',
        '/add-transaction': 'Add Transaction',
        '/wallets': 'Wallets',
        '/goals': 'Goals',
        '/goals/goal-1': 'Goal goal-1',
        '/analytics': 'Analytics',
        '/settings': 'Settings',
      };

      for (final entry in routes.entries) {
        router.go(entry.key);
        await tester.pumpAndSettle();
        expect(find.text(entry.value), findsOneWidget);
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
  });
}
