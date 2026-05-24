import 'package:decimal/decimal.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mali_app/core/error/failure.dart';
import 'package:mali_app/domain/entities/wallet.dart';
import 'package:mali_app/domain/repositories/wallet_repository.dart';
import 'package:mali_app/domain/usecases/convert_money_usecase.dart';
import 'package:mali_app/domain/value_objects/currency_code.dart';
import 'package:mali_app/domain/value_objects/money.dart';

class CalculateNetWorthUseCase {
  const CalculateNetWorthUseCase({
    required IWalletRepository walletRepository,
    required ConvertMoneyUseCase convertMoneyUseCase,
  })  : _walletRepository = walletRepository,
        _convertMoneyUseCase = convertMoneyUseCase;

  final IWalletRepository _walletRepository;
  final ConvertMoneyUseCase _convertMoneyUseCase;

  Future<Either<Failure, CalculateNetWorthResult>> call({
    required CurrencyCode displayCurrency,
  }) async {
    final wallets = await _walletRepository.watchActive().first;
    var total = Money(amount: Decimal.zero, currency: displayCurrency);
    final convertedWallets = <ConvertedWalletBalance>[];

    for (final wallet in wallets) {
      final sourceCurrency = CurrencyCode(wallet.currencyCode);
      final sourceAmount = _parseDecimal(wallet.balance);
      if (sourceAmount == null) {
        return left(
          StorageFailure(
            message: 'Wallet balance is invalid for wallet ${wallet.id}.',
          ),
        );
      }

      final sourceMoney = Money(amount: sourceAmount, currency: sourceCurrency);
      final convertedResult = await _convertMoneyUseCase(
        money: sourceMoney,
        targetCurrency: displayCurrency,
      );

      if (convertedResult.isLeft()) {
        return left(convertedResult.getLeft().toNullable()!);
      }

      final converted = convertedResult.getOrElse((_) => throw StateError('expected right'));
      total = total + converted;
      convertedWallets.add(
        ConvertedWalletBalance(
          wallet: wallet,
          convertedAmount: converted,
        ),
      );
    }

    return right(
      CalculateNetWorthResult(
        total: total,
        walletBreakdown: convertedWallets,
      ),
    );
  }

  Decimal? _parseDecimal(String value) {
    try {
      return Decimal.parse(value);
    } catch (_) {
      return null;
    }
  }
}

class CalculateNetWorthResult {
  const CalculateNetWorthResult({
    required this.total,
    required this.walletBreakdown,
  });

  final Money total;
  final List<ConvertedWalletBalance> walletBreakdown;
}

class ConvertedWalletBalance {
  const ConvertedWalletBalance({
    required this.wallet,
    required this.convertedAmount,
  });

  final Wallet wallet;
  final Money convertedAmount;
}
