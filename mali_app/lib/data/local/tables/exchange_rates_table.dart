import 'package:drift/drift.dart';

class ExchangeRatesTable extends Table {
  TextColumn get id => text()();
  TextColumn get baseCurrencyCode => text().withLength(min: 3, max: 3)();
  TextColumn get quoteCurrencyCode => text().withLength(min: 3, max: 3)();

  // Stored as string for decimal-safe money handling.
  TextColumn get rate => text()();

  BoolColumn get isManual => boolean().withDefault(const Constant(false))();
  DateTimeColumn get rateDate => dateTime()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        {baseCurrencyCode, quoteCurrencyCode},
      ];
}
