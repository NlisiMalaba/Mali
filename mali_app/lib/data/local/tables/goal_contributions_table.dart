import 'package:drift/drift.dart';
import 'package:mali_app/data/local/tables/savings_goals_table.dart';

class GoalContributionsTable extends Table {
  TextColumn get id => text()();
  TextColumn get goalId =>
      text().references(SavingsGoalsTable, #id, onDelete: KeyAction.cascade)();
  TextColumn get walletId => text().nullable()();
  TextColumn get transactionId => text().nullable()();

  // Stored as string for decimal-safe money handling.
  TextColumn get amount => text()();
  TextColumn get currencyCode => text().withLength(min: 3, max: 3)();

  TextColumn get note => text().nullable()();
  DateTimeColumn get contributionDate => dateTime()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
