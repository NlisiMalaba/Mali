import 'package:mali_app/domain/entities/category.dart';

/// Orders categories with recently used entries first.
class CategoryOrdering {
  const CategoryOrdering._();

  static const defaultStripLimit = 7;

  static List<Category> withRecentFirst({
    required List<Category> categories,
    required List<String> recentCategoryIds,
  }) {
    if (recentCategoryIds.isEmpty) {
      return List<Category>.from(categories);
    }

    final byId = {for (final category in categories) category.id: category};
    final recent = recentCategoryIds
        .map((id) => byId[id])
        .whereType<Category>()
        .toList(growable: false);
    final recentIds = recent.map((category) => category.id).toSet();
    final remaining = categories
        .where((category) => !recentIds.contains(category.id))
        .toList(growable: false);

    return [...recent, ...remaining];
  }
}
