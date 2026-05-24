import 'package:decimal/decimal.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mali_app/core/error/failure.dart';
import 'package:mali_app/domain/entities/transaction.dart';
import 'package:mali_app/domain/repositories/transaction_repository.dart';
import 'package:mali_app/domain/repositories/wallet_repository.dart';

class RestoreTransactionUseCase {
  const RestoreTransactionUseCase({
    required ITransactionRepository transactionRepository,
    required IWalletRepository walletRepository,
  })  : _transactionRepository = transactionRepository,
        _walletRepository = walletRepository;

  final ITransactionRepository _transactionRepository;
  final IWalletRepository _walletRepository;

  Future<Either<Failure, Transaction>> call(Transaction transaction) async {
    final existing = await _transactionRepository.findById(transaction.id);
    if (existing == null) {
      return left(
        const NotFoundFailure(
          message: 'Transaction not found.',
          resource: 'transaction',
        ),
      );
    }

    if (existing.deletedAt == null) {
      return right(existing);
    }

    final amount = _parseMoney(transaction.amount);
    if (amount == null) {
      return left(
        const StorageFailure(message: 'Transaction amount is invalid.'),
      );
    }

    final wallet = await _walletRepository.findById(transaction.walletId);
    if (wallet == null) {
      return left(
        const NotFoundFailure(
          message: 'Wallet not found.',
          resource: 'wallet',
        ),
      );
    }

    final walletBalance = _parseMoney(wallet.balance);
    if (walletBalance == null) {
      return left(
        const StorageFailure(message: 'Wallet balance is invalid.'),
      );
    }

    try {
      final updatedBalance = _applyWalletBalanceEffect(
        currentBalance: walletBalance,
        amount: amount,
        transactionType: transaction.type,
      );

      await _walletRepository.updateBalance(
        walletId: wallet.id,
        balance: updatedBalance.toString(),
      );

      final restored = transaction.copyWith(
        deletedAt: null,
        updatedAt: DateTime.now(),
      );
      await _transactionRepository.save(restored);

      return right(restored);
    } catch (error) {
      return left(
        StorageFailure(
          message: 'Failed to restore transaction.',
          cause: error,
        ),
      );
    }
  }

  Decimal _applyWalletBalanceEffect({
    required Decimal currentBalance,
    required Decimal amount,
    required String transactionType,
  }) {
    switch (transactionType) {
      case 'income':
        return currentBalance + amount;
      case 'expense':
      case 'transfer':
        return currentBalance - amount;
      default:
        throw const ValidationFailure(
          message: 'Unsupported transaction type.',
          field: 'type',
        );
    }
  }

  Decimal? _parseMoney(String value) {
    try {
      return Decimal.parse(value);
    } catch (_) {
      return null;
    }
  }
}
