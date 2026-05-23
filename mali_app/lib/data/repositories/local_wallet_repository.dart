import 'package:mali_app/data/local/dao/wallet_dao.dart';
import 'package:mali_app/data/local/mappers/wallet_mapper.dart';
import 'package:mali_app/domain/entities/wallet.dart';
import 'package:mali_app/domain/repositories/wallet_repository.dart';

class LocalWalletRepository implements IWalletRepository {
  const LocalWalletRepository({
    required WalletDao walletDao,
  }) : _walletDao = walletDao;

  final WalletDao _walletDao;

  @override
  Future<void> save(Wallet wallet) {
    return _walletDao.upsertWallet(WalletMapper.toCompanion(wallet));
  }

  @override
  Future<Wallet?> findById(String id) async {
    final row = await _walletDao.getById(id);
    if (row == null) {
      return null;
    }
    return WalletMapper.toDomain(row);
  }

  @override
  Stream<List<Wallet>> watchActive() {
    return _walletDao.watchActiveWallets().map(WalletMapper.toDomainList);
  }

  @override
  Future<void> updateBalance({
    required String walletId,
    required String balance,
  }) {
    return _walletDao.updateBalance(walletId: walletId, balance: balance);
  }
}
