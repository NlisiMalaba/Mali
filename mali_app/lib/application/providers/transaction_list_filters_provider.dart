import 'package:mali_app/application/models/transaction_list_filters.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'transaction_list_filters_provider.g.dart';

@riverpod
class TransactionListFiltersNotifier extends _$TransactionListFiltersNotifier {
  @override
  TransactionListFilters build(String? scopedWalletId) {
    return const TransactionListFilters();
  }

  void setCategory(String? categoryId) {
    state = state.copyWith(categoryId: categoryId);
  }

  void setWallet(String? walletId) {
    if (scopedWalletId != null) {
      return;
    }
    state = state.copyWith(walletId: walletId);
  }

  void setDateRange({DateTime? from, DateTime? to}) {
    state = state.copyWith(
      dateFrom: from == null
          ? null
          : DateTime(from.year, from.month, from.day),
      dateTo: to == null
          ? null
          : DateTime(to.year, to.month, to.day, 23, 59, 59, 999),
    );
  }

  void clearCategory() => setCategory(null);

  void clearWallet() => setWallet(null);

  void clearDateRange() => setDateRange(from: null, to: null);

  void clearAll() {
    state = const TransactionListFilters();
  }
}
