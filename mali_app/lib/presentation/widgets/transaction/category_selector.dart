import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mali_app/application/providers/category_providers.dart';
import 'package:mali_app/application/providers/recent_categories_provider.dart';
import 'package:mali_app/domain/entities/category.dart';
import 'package:mali_app/presentation/theme/app_colors.dart';
import 'package:mali_app/presentation/utils/category_ordering.dart';
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

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < stripCategories.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            _CategoryChip(
              chipKey: Key('category-icon-${stripCategories[i].id}'),
              label: stripCategories[i].name,
              selected: selectedCategory?.id == stripCategories[i].id,
              onTap: () => _selectCategory(ref, stripCategories[i]),
            ),
          ],
          if (stripCategories.isNotEmpty) const SizedBox(width: 8),
          _CategoryChip(
            chipKey: const Key('category-chip-more'),
            label: 'More',
            selected: false,
            onTap: () => _openPicker(context, ref),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.chipKey,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final Key chipKey;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: chipKey,
      color: selected ? AppColors.navy : AppColors.surfaceContainerLowest,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? AppColors.navy : const Color(0xFFE1E5EE),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: selected ? AppColors.silver : AppColors.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
