import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mali_app/application/providers/auth_provider.dart';
import 'package:mali_app/domain/entities/user.dart';
import 'package:mali_app/domain/repositories/auth_repository.dart';
import 'package:mali_app/presentation/router/app_router.dart';
import 'package:mali_app/presentation/screens/auth/register_screen.dart';

class _UnauthenticatedAuth extends Auth {
  @override
  Future<User?> build() async => null;
}

class _RegisterSuccessAuth extends Auth {
  @override
  Future<User?> build() async => null;

  @override
  Future<void> register(RegisterInput input) async {
    state = const AsyncLoading();
    state = AsyncData(
      User(
        id: 'user-new',
        name: input.name,
        email: input.email,
        phone: input.phone,
        createdAt: DateTime.utc(2026, 5, 24),
      ),
    );
  }
}

Future<void> _pumpRegisterScreen(
  WidgetTester tester, {
  required Auth Function() authOverride,
  bool useRouter = false,
}) async {
  final container = ProviderContainer(
    overrides: [
      authProvider.overrideWith(authOverride),
    ],
  );
  addTearDown(container.dispose);

  if (useRouter) {
    final router = container.read(appRouterProvider);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    router.go('/auth/register');
    await tester.pumpAndSettle();
    return;
  }

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        home: RegisterScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _fillRegisterForm(
  WidgetTester tester, {
  String name = 'Jane Doe',
  String email = 'jane@example.com',
  String password = 'password123',
  String confirmPassword = 'password123',
}) async {
  final fields = find.byType(TextFormField);
  await tester.enterText(fields.at(0), name);
  await tester.enterText(fields.at(1), email);
  await tester.enterText(fields.at(2), password);
  await tester.enterText(fields.at(3), confirmPassword);
}

void main() {
  group('RegisterScreen', () {
    testWidgets('empty submit shows field errors', (tester) async {
      await _pumpRegisterScreen(
        tester,
        authOverride: _UnauthenticatedAuth.new,
      );

      await tester.tap(find.text('Create account'));
      await tester.pumpAndSettle();

      expect(find.text('Enter your name'), findsOneWidget);
      expect(find.text('Enter your email address'), findsOneWidget);
      expect(find.text('Enter a password'), findsOneWidget);
      expect(find.text('Confirm your password'), findsOneWidget);
    });

    testWidgets('mismatched passwords shows error', (tester) async {
      await _pumpRegisterScreen(
        tester,
        authOverride: _UnauthenticatedAuth.new,
      );

      await _fillRegisterForm(
        tester,
        confirmPassword: 'different-password',
      );

      await tester.tap(find.text('Create account'));
      await tester.pumpAndSettle();

      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('successful register navigates to home', (tester) async {
      await _pumpRegisterScreen(
        tester,
        authOverride: _RegisterSuccessAuth.new,
        useRouter: true,
      );

      await _fillRegisterForm(tester);

      await tester.tap(find.text('Create account'));
      await tester.pumpAndSettle();

      expect(find.text('Home screen'), findsOneWidget);
      expect(find.text('Register'), findsNothing);
    });
  });
}
