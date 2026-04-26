import 'package:decimal/decimal.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mali_app/core/error/failure.dart';
import 'package:mali_app/domain/entities/wallet.dart';
import 'package:mali_app/domain/repositories/exchange_rate_repository.dart';
import 'package:mali_app/domain/repositories/wallet_repository.dart';
import 'package:mali_app/domain/value_objects/currency_code.dart';
import 'package:mali_app/domain/value_objects/money.dart';

class CalculateNetWorthUseCase {
  const CalculateNetWorthUseCase({
    required IWalletRepository walletRepository,
    required IExchangeRateRepository exchangeRateRepository,
  })  : _walletRepository = walletRepository,
        _exchangeRateRepository = exchangeRateRepository;

  final IWalletRepository _walletRepository;
  final IExchangeRateRepository _exchangeRateRepository;

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
      final converted = await _convert(sourceMoney, displayCurrency);
      if (converted == null) {
        return left(
          NotFoundFailure(
            message:
                'Missing exchange rate from ${sourceCurrency.value} to ${displayCurrency.value}.',
            resource: 'exchange_rate',
          ),
        );
      }
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

  Future<Money?> _convert(Money money, CurrencyCode targetCurrency) async {
    if (money.currency == targetCurrency) {
      return money;
    }

    final directRate = await _exchangeRateRepository.getRate(
      baseCurrencyCode: money.currency,
      quoteCurrencyCode: targetCurrency,
    );
    if (directRate != null) {
      final parsedRate = _parseDecimal(directRate.rate);
      if (parsedRate != null) {
        return Money(
          amount: money.amount * parsedRate,
          currency: targetCurrency,
        );
      }
      return null;
    }

    return null;
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
