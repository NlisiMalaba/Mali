import 'package:mali_app/domain/entities/category.dart';

abstract interface class ICategoryRepository {
  Future<void> save(Category category);

  Stream<List<Category>> watchByType(String categoryType);

  Future<List<Category>> listAllActive();
}
