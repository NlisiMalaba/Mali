import 'package:drift/drift.dart';

class WalletsTable extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get name => text().withLength(min: 1, max: 80)();
  TextColumn get currencyCode => text().withLength(min: 3, max: 3)();

  // Stored as string for decimal-safe money handling.
  TextColumn get balance => text()();

  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
