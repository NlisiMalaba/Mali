import 'package:drift/drift.dart';
import 'package:mali_app/data/local/app_database.dart';
import 'package:mali_app/domain/entities/exchange_rate.dart';

class ExchangeRateMapper {
  const ExchangeRateMapper._();

  static ExchangeRate toDomain(ExchangeRatesTableData row) {
    return ExchangeRate(
      id: row.id,
      baseCurrencyCode: row.baseCurrencyCode,
      quoteCurrencyCode: row.quoteCurrencyCode,
      rate: row.rate,
      isManual: row.isManual,
      rateDate: row.rateDate,
      isSynced: row.isSynced,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  static List<ExchangeRate> toDomainList(List<ExchangeRatesTableData> rows) {
    return rows.map(toDomain).toList(growable: false);
  }

  static ExchangeRatesTableCompanion toCompanion(ExchangeRate rate) {
    return ExchangeRatesTableCompanion(
      id: Value(rate.id),
      baseCurrencyCode: Value(rate.baseCurrencyCode),
      quoteCurrencyCode: Value(rate.quoteCurrencyCode),
      rate: Value(rate.rate),
      isManual: Value(rate.isManual),
      rateDate: Value(rate.rateDate),
      isSynced: Value(rate.isSynced),
      createdAt: Value(rate.createdAt),
      updatedAt: Value(rate.updatedAt),
    );
  }
}
