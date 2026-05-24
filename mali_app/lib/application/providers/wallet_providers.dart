import 'package:mali_app/application/providers/repository_providers.dart';
import 'package:mali_app/domain/entities/transaction.dart';
import 'package:mali_app/domain/entities/wallet.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'wallet_providers.g.dart';

@Riverpod(keepAlive: true)
Stream<List<Wallet>> activeWallets(Ref ref) {
  return ref.watch(walletRepositoryProvider).watchActive();
}

@riverpod
Future<Wallet?> walletById(Ref ref, String walletId) {
  return ref.watch(walletRepositoryProvider).findById(walletId);
}

@riverpod
Stream<List<Transaction>> walletTransactions(Ref ref, String walletId) {
  return ref.watch(transactionRepositoryProvider).watchByWallet(walletId);
}

@Riverpod(keepAlive: true)
bool needsWalletSetup(Ref ref) {
  final wallets = ref.watch(activeWalletsProvider);
  return wallets.when(
    data: (list) => list.isEmpty,
    loading: () => false,
    error: (_, __) => false,
  );
}
