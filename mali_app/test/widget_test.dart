import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mali_app/application/providers/auth_provider.dart';
import 'package:mali_app/application/providers/wallet_providers.dart';
import 'package:mali_app/domain/entities/wallet.dart';
import 'package:mali_app/domain/entities/user.dart';
import 'package:mali_app/main.dart';
import 'package:mali_app/presentation/screens/splash_screen.dart';

class _ImmediateUnauthenticatedAuth extends Auth {
  @override
  Future<User?> build() async => null;
}

void main() {
  testWidgets('unauthenticated users are redirected to login',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(_ImmediateUnauthenticatedAuth.new),
          activeWalletsProvider.overrideWith((ref) => Stream.value(const <Wallet>[])),
        ],
        child: const MaliApp(),
      ),
    );
    await tester.pump();
    await tester.pump(SplashScreen.minimumDisplayDuration);
    await tester.pumpAndSettle();

    expect(find.text('Login'), findsOneWidget);
  });
}
