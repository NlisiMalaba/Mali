import 'package:fpdart/fpdart.dart';
import 'package:mali_app/core/error/failure.dart';
import 'package:mali_app/domain/entities/wallet.dart';
import 'package:mali_app/domain/repositories/wallet_repository.dart';

class ArchiveWalletUseCase {
  const ArchiveWalletUseCase({
    required IWalletRepository walletRepository,
  }) : _walletRepository = walletRepository;

  final IWalletRepository _walletRepository;

  Future<Either<Failure, Wallet>> call({required String walletId}) async {
    final wallet = await _walletRepository.findById(walletId);
    if (wallet == null) {
      return left(
        const NotFoundFailure(
          message: 'Wallet not found.',
          resource: 'wallet',
        ),
      );
    }

    if (wallet.isArchived) {
      return right(wallet);
    }

    try {
      await _walletRepository.archive(walletId: walletId);
    } catch (error) {
      return left(
        StorageFailure(
          message: 'Failed to archive wallet.',
          cause: error,
        ),
      );
    }

    final updated = wallet.copyWith(
      isArchived: true,
      updatedAt: DateTime.now(),
    );
    return right(updated);
  }
}
