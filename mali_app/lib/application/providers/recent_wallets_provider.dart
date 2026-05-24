import 'package:mali_app/core/storage/recent_wallet_store.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'recent_wallets_provider.g.dart';

@Riverpod(keepAlive: true)
RecentWalletStore recentWalletStore(Ref ref) {
  return RecentWalletStore();
}

@Riverpod(keepAlive: true)
class RecentWallets extends _$RecentWallets {
  @override
  Future<List<String>> build() {
    return ref.read(recentWalletStoreProvider).readAll();
  }

  Future<void> recordUsage(String walletId) async {
    final store = ref.read(recentWalletStoreProvider);
    final current = state.value ?? const [];
    final next = store.recordUsage(current: current, walletId: walletId);

    state = AsyncData(next);
    await store.writeAll(next);
  }
}

@riverpod
List<String> recentWalletIds(Ref ref) {
  final recentAsync = ref.watch(recentWalletsProvider);
  return recentAsync.maybeWhen(
    data: (recent) => recent,
    orElse: () => const [],
  );
}

typedef DefaultWalletKey = ({List<String> walletIds, String? preferredWalletId});

@riverpod
String? defaultWalletId(Ref ref, DefaultWalletKey key) {
  if (key.walletIds.isEmpty) {
    return null;
  }

  if (key.preferredWalletId != null &&
      key.walletIds.contains(key.preferredWalletId)) {
    return key.preferredWalletId;
  }

  final recentIds = ref.watch(recentWalletIdsProvider);
  for (final recentId in recentIds) {
    if (key.walletIds.contains(recentId)) {
      return recentId;
    }
  }

  return key.walletIds.first;
}
