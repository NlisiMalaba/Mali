import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mali_app/application/providers/category_providers.dart';
import 'package:mali_app/application/providers/recent_categories_provider.dart';
import 'package:mali_app/domain/entities/category.dart';
import 'package:mali_app/presentation/utils/category_ordering.dart';
import 'package:mali_app/presentation/widgets/transaction/category_icon_button.dart';
import 'package:mali_app/presentation/widgets/transaction/category_picker_sheet.dart';

class CategorySelector extends ConsumerWidget {
  const CategorySelector({
    required this.transactionType,
    required this.selectedCategory,
    required this.onCategorySelected,
    super.key,
  });

  final String transactionType;
  final Category? selectedCategory;
  final ValueChanged<Category> onCategorySelected;

  Future<void> _openPicker(BuildContext context, WidgetRef ref) async {
    final picked = await CategoryPickerSheet.show(
      context,
      transactionType: transactionType,
      selectedCategoryId: selectedCategory?.id,
    );
    if (picked != null) {
      await _selectCategory(ref, picked);
    }
  }

  Future<void> _selectCategory(WidgetRef ref, Category category) async {
    await ref.read(recentCategoriesProvider.notifier).recordUsage(
          type: transactionType,
          categoryId: category.id,
        );
    onCategorySelected(category);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesForTypeProvider(transactionType));
    final recentIds = ref.watch(recentCategoryIdsProvider(transactionType));
    final ordered = CategoryOrdering.withRecentFirst(
      categories: categories,
      recentCategoryIds: recentIds,
    );
    final stripCategories =
        ordered.take(CategoryOrdering.defaultStripLimit).toList(growable: false);

    return SizedBox(
      height: 84,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: stripCategories.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == stripCategories.length) {
            return CategoryMoreButton(
              onTap: () => _openPicker(context, ref),
            );
          }

          final category = stripCategories[index];
          return CategoryIconButton(
            category: category,
            isSelected: selectedCategory?.id == category.id,
            compact: true,
            onTap: () => _selectCategory(ref, category),
          );
        },
      ),
    );
  }
}
