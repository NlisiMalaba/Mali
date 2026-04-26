import 'package:drift/drift.dart';
import 'package:mali_app/data/local/app_database.dart';
import 'package:mali_app/data/local/tables/tables.dart';

part 'category_dao.g.dart';

@DriftAccessor(tables: [CategoriesTable])
class CategoryDao extends DatabaseAccessor<AppDatabase> with _$CategoryDaoMixin {
  CategoryDao(super.db);

  Future<void> upsertCategory(CategoriesTableCompanion entry) {
    return into(categoriesTable).insertOnConflictUpdate(entry);
  }

  Stream<List<CategoriesTableData>> watchByType(String categoryType) {
    return (select(categoriesTable)
          ..where((table) => table.type.equals(categoryType))
          ..where((table) => table.isArchived.equals(false))
          ..where((table) => table.deletedAt.isNull())
          ..orderBy([(table) => OrderingTerm.asc(table.name)]))
        .watch();
  }

  Future<List<CategoriesTableData>> listAllActive() {
    return (select(categoriesTable)
          ..where((table) => table.isArchived.equals(false))
          ..where((table) => table.deletedAt.isNull())
          ..orderBy([(table) => OrderingTerm.asc(table.name)]))
        .get();
  }
}
