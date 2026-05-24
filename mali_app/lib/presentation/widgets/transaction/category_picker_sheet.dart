import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mali_app/application/providers/category_providers.dart';
import 'package:mali_app/application/providers/recent_categories_provider.dart';
import 'package:mali_app/domain/entities/category.dart';
import 'package:mali_app/presentation/utils/category_ordering.dart';
import 'package:mali_app/presentation/widgets/transaction/category_grid.dart';
import 'package:mali_app/presentation/widgets/transaction/category_icon_button.dart';

class CategoryPickerSheet extends ConsumerWidget {
  const CategoryPickerSheet({
    required this.transactionType,
    required this.selectedCategoryId,
    required this.onCategorySelected,
    super.key,
  });

  final String transactionType;
  final String? selectedCategoryId;
  final ValueChanged<Category> onCategorySelected;

  static Future<Category?> show(
    BuildContext context, {
    required String transactionType,
    required String? selectedCategoryId,
  }) {
    return showModalBottomSheet<Category>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => CategoryPickerSheet(
        transactionType: transactionType,
        selectedCategoryId: selectedCategoryId,
        onCategorySelected: (category) {
          Navigator.of(context).pop(category);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final categories = ref.watch(categoriesForTypeProvider(transactionType));
    final recentIds = ref.watch(recentCategoryIdsProvider(transactionType));
    final ordered = CategoryOrdering.withRecentFirst(
      categories: categories,
      recentCategoryIds: recentIds,
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottomInset),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.75,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Choose category',
            style: theme.textTheme.titleLarge,
          ),
          if (recentIds.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Recently used',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 84,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: recentIds.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final category = ordered[index];
                  return CategoryIconButton(
                    category: category,
                    isSelected: selectedCategoryId == category.id,
                    compact: true,
                    onTap: () => onCategorySelected(category),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            'All categories',
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Flexible(
            child: SingleChildScrollView(
              child: CategoryGrid(
                categories: ordered,
                selectedCategoryId: selectedCategoryId,
                onCategorySelected: onCategorySelected,
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }
}
