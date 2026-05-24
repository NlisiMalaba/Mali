import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mali_app/application/providers/auth_provider.dart';
import 'package:mali_app/application/providers/repository_providers.dart';
import 'package:mali_app/domain/entities/user.dart';
import 'package:mali_app/domain/entities/wallet.dart';
import 'package:mali_app/domain/repositories/wallet_repository.dart';
import 'package:mali_app/presentation/screens/wallet/wallet_setup_screen.dart';

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

class _RecordingWalletRepository implements IWalletRepository {
  final savedWallets = <Wallet>[];

  @override
  Future<void> save(Wallet wallet) async {
    savedWallets.add(wallet);
  }

  @override
  Future<Wallet?> findById(String id) async => null;

  @override
  Stream<List<Wallet>> watchActive() => const Stream.empty();

  @override
  Future<void> updateBalance({
    required String walletId,
    required String balance,
  }) async {}

  @override
  Future<void> archive({required String walletId}) async {}
}

Future<void> _pumpWalletSetupScreen(
  WidgetTester tester,
  _RecordingWalletRepository repository,
) async {
  final container = ProviderContainer(
    overrides: [
      authProvider.overrideWith(_TestAuth.new),
      walletRepositoryProvider.overrideWithValue(repository),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: WalletSetupScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('submit without currency shows snackbar', (tester) async {
    final repository = _RecordingWalletRepository();
    await _pumpWalletSetupScreen(tester, repository);

    await tester.tap(find.text('Continue'));
    await tester.pump();

    expect(
      find.text('Select at least one currency to create a wallet.'),
      findsOneWidget,
    );
    expect(repository.savedWallets, isEmpty);
  });

  testWidgets('selecting currency shows wallet detail fields', (tester) async {
    final repository = _RecordingWalletRepository();
    await _pumpWalletSetupScreen(tester, repository);

    expect(find.text('Wallet details'), findsNothing);

    await tester.tap(find.byKey(const Key('currency-USD')));
    await tester.pumpAndSettle();

    expect(find.text('Wallet details'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
  });
}
