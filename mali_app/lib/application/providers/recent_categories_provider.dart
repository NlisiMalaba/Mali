import 'package:mali_app/application/providers/category_providers.dart';
import 'package:mali_app/core/storage/recent_category_store.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'recent_categories_provider.g.dart';

@Riverpod(keepAlive: true)
RecentCategoryStore recentCategoryStore(Ref ref) {
  return RecentCategoryStore();
}

@Riverpod(keepAlive: true)
class RecentCategories extends _$RecentCategories {
  @override
  Future<Map<String, List<String>>> build() {
    return ref.read(recentCategoryStoreProvider).readAll();
  }

  Future<void> recordUsage({
    required String type,
    required String categoryId,
  }) async {
    final store = ref.read(recentCategoryStoreProvider);
    final current = state.value ?? const {};
    final nextIds = store.recordUsage(
      current: current,
      type: type,
      categoryId: categoryId,
    );
    final next = Map<String, List<String>>.from(current)..[type] = nextIds;

    state = AsyncData(next);
    await store.writeAll(next);
  }
}

@riverpod
List<String> recentCategoryIds(Ref ref, String type) {
  final recentAsync = ref.watch(recentCategoriesProvider);
  return recentAsync.maybeWhen(
    data: (recent) => recent[type] ?? const [],
    orElse: () => const [],
  );
}
