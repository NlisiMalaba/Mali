import 'package:mali_app/domain/entities/wallet.dart';

/// Orders wallets with recently used entries first.
class WalletOrdering {
  const WalletOrdering._();

  static List<Wallet> withRecentFirst({
    required List<Wallet> wallets,
    required List<String> recentWalletIds,
  }) {
    if (recentWalletIds.isEmpty) {
      return List<Wallet>.from(wallets);
    }

    final byId = {for (final wallet in wallets) wallet.id: wallet};
    final recent = recentWalletIds
        .map((id) => byId[id])
        .whereType<Wallet>()
        .toList(growable: false);
    final recentIds = recent.map((wallet) => wallet.id).toSet();
    final remaining = wallets
        .where((wallet) => !recentIds.contains(wallet.id))
        .toList(growable: false);

    return [...recent, ...remaining];
  }
}
