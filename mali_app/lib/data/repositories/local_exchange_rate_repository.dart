import 'package:mali_app/data/local/dao/exchange_rate_dao.dart';
import 'package:mali_app/data/local/mappers/exchange_rate_mapper.dart';
import 'package:mali_app/domain/entities/exchange_rate.dart';
import 'package:mali_app/domain/repositories/exchange_rate_repository.dart';
import 'package:mali_app/domain/value_objects/currency_code.dart';

class LocalExchangeRateRepository implements IExchangeRateRepository {
  const LocalExchangeRateRepository({
    required ExchangeRateDao exchangeRateDao,
  }) : _exchangeRateDao = exchangeRateDao;

  final ExchangeRateDao _exchangeRateDao;

  @override
  Future<void> save(ExchangeRate rate) {
    return _exchangeRateDao.upsertRate(ExchangeRateMapper.toCompanion(rate));
  }

  @override
  Future<ExchangeRate?> getRate({
    required CurrencyCode baseCurrencyCode,
    required CurrencyCode quoteCurrencyCode,
  }) async {
    final row = await _exchangeRateDao.getRate(
      baseCurrencyCode: baseCurrencyCode.value,
      quoteCurrencyCode: quoteCurrencyCode.value,
    );
    if (row == null) {
      return null;
    }
    return ExchangeRateMapper.toDomain(row);
  }

  @override
  Stream<List<ExchangeRate>> watchAllRates() {
    return _exchangeRateDao.watchAllRates().map(ExchangeRateMapper.toDomainList);
  }
}
