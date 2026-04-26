import 'package:drift/drift.dart';

class TransactionsTable extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get walletId => text()();
  TextColumn get categoryId => text().nullable()();
  TextColumn get syncId => text().nullable()();

  // Allowed values: expense, income, transfer.
  TextColumn get type =>
      text().check(const CustomExpression<bool>("type IN ('expense', 'income', 'transfer')"))();

  // Use string columns for money values to avoid floating-point precision loss.
  TextColumn get amount => text()();
  TextColumn get currencyCode => text().withLength(min: 3, max: 3)();
  TextColumn get exchangeRate => text().nullable()();

  TextColumn get title => text().withLength(min: 1, max: 120)();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get transactionDate => dateTime()();

  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => const ['UNIQUE(sync_id)'];
}
