import 'package:drift/drift.dart';
import 'package:mali_app/data/local/app_database.dart';
import 'package:mali_app/data/local/tables/tables.dart';

part 'exchange_rate_dao.g.dart';

@DriftAccessor(tables: [ExchangeRatesTable])
class ExchangeRateDao extends DatabaseAccessor<AppDatabase>
    with _$ExchangeRateDaoMixin {
  ExchangeRateDao(super.db);

  Future<void> upsertRate(ExchangeRatesTableCompanion entry) {
    return into(exchangeRatesTable).insertOnConflictUpdate(entry);
  }

  Future<ExchangeRatesTableData?> getRate({
    required String baseCurrencyCode,
    required String quoteCurrencyCode,
  }) {
    return (select(exchangeRatesTable)
          ..where((table) => table.baseCurrencyCode.equals(baseCurrencyCode))
          ..where((table) => table.quoteCurrencyCode.equals(quoteCurrencyCode)))
        .getSingleOrNull();
  }

  Stream<List<ExchangeRatesTableData>> watchAllRates() {
    return (select(exchangeRatesTable)
          ..orderBy([(table) => OrderingTerm.asc(table.baseCurrencyCode)]))
        .watch();
  }
}
