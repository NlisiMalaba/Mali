import 'package:mali_app/domain/entities/category.dart';
import 'package:mali_app/presentation/constants/system_categories.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'category_providers.g.dart';

@riverpod
List<Category> categoriesForType(Ref ref, String type) {
  return SystemCategories.forType(type);
}

@riverpod
Category? categoryById(Ref ref, String categoryId) {
  for (final category in SystemCategories.expense) {
    if (category.id == categoryId) {
      return category;
    }
  }
  for (final category in SystemCategories.income) {
    if (category.id == categoryId) {
      return category;
    }
  }
  return null;
}
