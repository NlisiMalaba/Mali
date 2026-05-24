import 'package:decimal/decimal.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mali_app/core/error/failure.dart';
import 'package:mali_app/core/utils/local_id_generator.dart';
import 'package:mali_app/domain/entities/wallet.dart';
import 'package:mali_app/domain/repositories/wallet_repository.dart';
import 'package:mali_app/domain/value_objects/currency_code.dart';

class CreateWalletParams {
  const CreateWalletParams({
    required this.userId,
    required this.name,
    required this.currencyCode,
    required this.openingBalance,
  });

  final String userId;
  final String name;
  final CurrencyCode currencyCode;
  final String openingBalance;
}

class CreateWalletUseCase {
  const CreateWalletUseCase({
    required IWalletRepository walletRepository,
  }) : _walletRepository = walletRepository;

  final IWalletRepository _walletRepository;

  static const int maxNameLength = 80;

  Future<Either<Failure, Wallet>> call(CreateWalletParams params) async {
    final trimmedName = params.name.trim();
    if (trimmedName.isEmpty) {
      return left(
        const ValidationFailure(
          message: 'Wallet name is required.',
          field: 'name',
        ),
      );
    }

    if (trimmedName.length > maxNameLength) {
      return left(
        ValidationFailure(
          message: 'Wallet name must be at most $maxNameLength characters.',
          field: 'name',
        ),
      );
    }

    final balance = _parseNonNegativeDecimal(params.openingBalance);
    if (balance == null) {
      return left(
        const ValidationFailure(
          message: 'Opening balance must be a valid amount (0 or greater).',
          field: 'openingBalance',
        ),
      );
    }

    final now = DateTime.now();
    final wallet = Wallet(
      id: LocalIdGenerator.newId('wallet'),
      userId: params.userId,
      name: trimmedName,
      currencyCode: params.currencyCode.value,
      balance: balance.toString(),
      isArchived: false,
      isSynced: false,
      createdAt: now,
      updatedAt: now,
    );

    try {
      await _walletRepository.save(wallet);
    } catch (error) {
      return left(
        StorageFailure(
          message: 'Failed to save wallet.',
          cause: error,
        ),
      );
    }

    return right(wallet);
  }

  Decimal? _parseNonNegativeDecimal(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return Decimal.zero;
    }

    try {
      final parsed = Decimal.parse(trimmed);
      if (parsed < Decimal.zero) {
        return null;
      }
      return parsed;
    } catch (_) {
      return null;
    }
  }
}
