import 'package:drift/drift.dart';

class CategoriesTable extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().nullable()();
  TextColumn get name => text().withLength(min: 1, max: 60)();

  // Allowed values: expense, income, transfer.
  TextColumn get type =>
      text().check(const CustomExpression<bool>("type IN ('expense', 'income', 'transfer')"))();

  TextColumn get iconKey => text().withLength(min: 1, max: 80)();
  TextColumn get colorHex => text().withLength(min: 7, max: 9)();
  BoolColumn get isSystem => boolean().withDefault(const Constant(false))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
