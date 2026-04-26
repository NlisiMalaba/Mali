import 'package:drift/drift.dart';

class BudgetsTable extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get categoryId => text()();
  TextColumn get currencyCode => text().withLength(min: 3, max: 3)();

  // Stored as string for decimal-safe money handling.
  TextColumn get amount => text()();
  TextColumn get spentAmount => text().withDefault(const Constant('0'))();

  IntColumn get month =>
      integer().check(const CustomExpression<bool>('month BETWEEN 1 AND 12'))();
  IntColumn get year => integer()();
  BoolColumn get rolloverEnabled => boolean().withDefault(const Constant(false))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
