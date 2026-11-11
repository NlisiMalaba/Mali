import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mali_app/core/constants/app_info.dart';
import 'package:mali_app/presentation/screens/welcome/welcome_screen.dart';
import 'package:mali_app/presentation/theme/app_theme.dart';

void main() {
  testWidgets('welcome screen shows brand, hero copy, and CTAs', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final router = GoRouter(
      initialLocation: '/welcome',
      routes: [
        GoRoute(
          path: '/welcome',
          builder: (_, _) => const WelcomeScreen(),
        ),
        GoRoute(
          path: '/auth/register',
          builder: (_, _) => const Scaffold(body: Text('register')),
        ),
        GoRoute(
          path: '/auth/login',
          builder: (_, _) => const Scaffold(body: Text('login')),
        ),
      ],
    );

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(390, 844),
          disableAnimations: true,
        ),
        child: MaterialApp.router(
          theme: AppTheme.lightTheme,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(WelcomeScreen.screenKey), findsOneWidget);
    expect(find.text(AppInfo.name), findsOneWidget);
    expect(find.textContaining('Every currency.'), findsOneWidget);
    expect(find.textContaining('One calm ledger.'), findsOneWidget);
    expect(find.text('USD'), findsOneWidget);
    expect(find.text('ZWG'), findsOneWidget);
    expect(find.text('ZAR'), findsOneWidget);
    expect(find.text('Create my ledger'), findsOneWidget);
    expect(find.text('I already have an account'), findsOneWidget);

    await tester.tap(find.byKey(WelcomeScreen.createLedgerButtonKey));
    await tester.pumpAndSettle();
    expect(find.text('register'), findsOneWidget);
  });
}
