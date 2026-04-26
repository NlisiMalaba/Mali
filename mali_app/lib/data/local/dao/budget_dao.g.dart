// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'budget_dao.dart';

// ignore_for_file: type=lint
mixin _$BudgetDaoMixin on DatabaseAccessor<AppDatabase> {
  $BudgetsTableTable get budgetsTable => attachedDatabase.budgetsTable;
  BudgetDaoManager get managers => BudgetDaoManager(this);
}

class BudgetDaoManager {
  final _$BudgetDaoMixin _db;
  BudgetDaoManager(this._db);
  $$BudgetsTableTableTableManager get budgetsTable =>
      $$BudgetsTableTableTableManager(_db.attachedDatabase, _db.budgetsTable);
}
