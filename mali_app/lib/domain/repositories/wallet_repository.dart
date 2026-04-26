import 'package:mali_app/domain/entities/wallet.dart';

abstract interface class IWalletRepository {
  Future<void> save(Wallet wallet);

  Future<Wallet?> findById(String id);

  Stream<List<Wallet>> watchActive();

  Future<void> updateBalance({
    required String walletId,
    required String balance,
  });
}
