import 'package:drift/drift.dart';

class SyncQueueTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();

  // Allowed values: create, update, delete.
  TextColumn get operation =>
      text().check(const CustomExpression<bool>("operation IN ('create', 'update', 'delete')"))();

  TextColumn get payloadJson => text()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastAttemptAt => dateTime().nullable()();
  DateTimeColumn get syncedAt => dateTime().nullable()();
  TextColumn get lastError => text().nullable()();
}
