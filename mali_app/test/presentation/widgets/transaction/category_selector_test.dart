import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mali_app/application/providers/recent_categories_provider.dart';
import 'package:mali_app/core/storage/recent_category_store.dart';
import 'package:mali_app/domain/entities/category.dart';
import 'package:mali_app/presentation/constants/system_categories.dart';
import 'package:mali_app/presentation/utils/category_ordering.dart';
import 'package:mali_app/presentation/widgets/transaction/category_selector.dart';

class _InMemoryRecentCategoryStore extends RecentCategoryStore {
  _InMemoryRecentCategoryStore(this._data);

  Map<String, List<String>> _data;

  @override
  Future<Map<String, List<String>>> readAll() async {
    return Map<String, List<String>>.from(_data);
  }

  @override
  Future<void> writeAll(Map<String, List<String>> data) async {
    _data = Map<String, List<String>>.from(data);
  }
}

Category _category(String id, String name) {
  final template = SystemCategories.expense.first;
  return template.copyWith(id: id, name: name);
}

void main() {
  group('CategoryOrdering', () {
    test('places recent categories first', () {
      final categories = [
        _category('cat-food', 'Food'),
        _category('cat-transport', 'Transport'),
        _category('cat-medical', 'Medical'),
      ];

      final ordered = CategoryOrdering.withRecentFirst(
        categories: categories,
        recentCategoryIds: const ['cat-medical', 'cat-food'],
      );

      expect(ordered.map((c) => c.id).toList(), [
        'cat-medical',
        'cat-food',
        'cat-transport',
      ]);
    });
  });

  group('RecentCategoryStore', () {
    test('moves selected category to front and caps list size', () {
      final store = RecentCategoryStore(maxRecentPerType: 3);
      var current = <String, List<String>>{
        'expense': ['cat-a', 'cat-b', 'cat-c'],
      };

      final next = store.recordUsage(
        current: current,
        type: 'expense',
        categoryId: 'cat-d',
      );

      expect(next, ['cat-d', 'cat-a', 'cat-b']);

      current = {'expense': next};
      final promoted = store.recordUsage(
        current: current,
        type: 'expense',
        categoryId: 'cat-b',
      );

      expect(promoted, ['cat-b', 'cat-d', 'cat-a']);
    });
  });

  group('CategorySelector', () {
    testWidgets('shows horizontal categories with more button', (tester) async {
      final store = _InMemoryRecentCategoryStore({
        'expense': ['cat-transport', 'cat-food'],
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            recentCategoryStoreProvider.overrideWithValue(store),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: CategorySelector(
                transactionType: 'expense',
                selectedCategory: SystemCategories.expense.first,
                onCategorySelected: (_) {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byKey(const Key('category-more-button')), findsOneWidget);
      expect(find.byKey(const Key('category-icon-cat-transport')), findsOneWidget);
      expect(find.byKey(const Key('category-icon-cat-food')), findsOneWidget);
    });

    testWidgets('opens picker sheet when more is tapped', (tester) async {
      final store = _InMemoryRecentCategoryStore({});

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            recentCategoryStoreProvider.overrideWithValue(store),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: CategorySelector(
                transactionType: 'expense',
                selectedCategory: null,
                onCategorySelected: (_) {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('category-more-button')));
      await tester.pumpAndSettle();

      expect(find.text('Choose category'), findsOneWidget);
      expect(find.text('All categories'), findsOneWidget);
    });
  });
}
