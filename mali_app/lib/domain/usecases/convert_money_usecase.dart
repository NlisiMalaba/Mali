import 'package:decimal/decimal.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mali_app/core/error/failure.dart';
import 'package:mali_app/domain/repositories/exchange_rate_repository.dart';
import 'package:mali_app/domain/value_objects/currency_code.dart';
import 'package:mali_app/domain/value_objects/money.dart';

class ConvertMoneyUseCase {
  const ConvertMoneyUseCase({
    required IExchangeRateRepository exchangeRateRepository,
  }) : _exchangeRateRepository = exchangeRateRepository;

  final IExchangeRateRepository _exchangeRateRepository;

  Future<Either<Failure, Money>> call({
    required Money money,
    required CurrencyCode targetCurrency,
  }) async {
    if (money.currency == targetCurrency) {
      return right(money);
    }

    final converted = await _convert(money, targetCurrency);
    if (converted == null) {
      return left(
        NotFoundFailure(
          message:
              'Missing exchange rate from ${money.currency.value} to ${targetCurrency.value}.',
          resource: 'exchange_rate',
        ),
      );
    }

    return right(converted);
  }

  Future<Money?> _convert(Money money, CurrencyCode targetCurrency) async {
    final directRate = await _exchangeRateRepository.getRate(
      baseCurrencyCode: money.currency,
      quoteCurrencyCode: targetCurrency,
    );
    if (directRate == null) {
      return null;
    }

    final parsedRate = _parseDecimal(directRate.rate);
    if (parsedRate == null) {
      return null;
    }

    return Money(
      amount: money.amount * parsedRate,
      currency: targetCurrency,
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
