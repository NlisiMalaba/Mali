import 'package:mali_app/domain/entities/exchange_rate.dart';
import 'package:mali_app/domain/value_objects/currency_code.dart';

abstract interface class IExchangeRateRepository {
  Future<void> save(ExchangeRate rate);

  Future<ExchangeRate?> getRate({
    required CurrencyCode baseCurrencyCode,
    required CurrencyCode quoteCurrencyCode,
  });

  Stream<List<ExchangeRate>> watchAllRates();
}
