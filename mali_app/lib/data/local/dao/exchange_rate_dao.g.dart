// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exchange_rate_dao.dart';

// ignore_for_file: type=lint
mixin _$ExchangeRateDaoMixin on DatabaseAccessor<AppDatabase> {
  $ExchangeRatesTableTable get exchangeRatesTable =>
      attachedDatabase.exchangeRatesTable;
  ExchangeRateDaoManager get managers => ExchangeRateDaoManager(this);
}

class ExchangeRateDaoManager {
  final _$ExchangeRateDaoMixin _db;
  ExchangeRateDaoManager(this._db);
  $$ExchangeRatesTableTableTableManager get exchangeRatesTable =>
      $$ExchangeRatesTableTableTableManager(
        _db.attachedDatabase,
        _db.exchangeRatesTable,
      );
}
