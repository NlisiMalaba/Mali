import 'package:drift/drift.dart';

class SavingsGoalsTable extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get name => text().withLength(min: 1, max: 120)();
  TextColumn get emoji => text().nullable()();

  // Stored as string for decimal-safe money handling.
  TextColumn get targetAmount => text()();
  TextColumn get currentAmount => text().withDefault(const Constant('0'))();
  TextColumn get currencyCode => text().withLength(min: 3, max: 3)();

  DateTimeColumn get targetDate => dateTime().nullable()();
  IntColumn get priorityOrder => integer().withDefault(const Constant(0))();

  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
