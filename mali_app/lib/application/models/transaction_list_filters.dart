import 'package:mali_app/core/constants/transaction_list_constants.dart';
import 'package:mali_app/domain/repositories/transaction_repository.dart';

class TransactionListFilters {
  const TransactionListFilters({
    this.categoryId,
    this.walletId,
    this.dateFrom,
    this.dateTo,
    this.type,
    this.searchQuery,
  });

  final String? categoryId;
  final String? walletId;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final String? type;
  final String? searchQuery;

  bool get hasActiveFilters =>
      categoryId != null ||
      walletId != null ||
      dateFrom != null ||
      dateTo != null ||
      type != null ||
      (searchQuery != null && searchQuery!.trim().isNotEmpty);

  String? effectiveWalletId(String? scopedWalletId) {
    return scopedWalletId ?? walletId;
  }

  String? get normalizedSearchQuery {
    final query = searchQuery?.trim();
    if (query == null || query.isEmpty) {
      return null;
    }
    return query;
  }

  TransactionWatchQuery toWatchQuery(String? scopedWalletId) {
    return TransactionWatchQuery(
      walletId: effectiveWalletId(scopedWalletId),
      categoryId: categoryId,
      dateFrom: dateFrom,
      dateTo: dateTo,
      type: type,
      searchQuery: normalizedSearchQuery,
      limit: TransactionListConstants.pageSize,
    );
  }

  TransactionQuery toListQuery({
    required String? scopedWalletId,
    TransactionCursor? cursor,
    required int limit,
  }) {
    return TransactionQuery(
      walletId: effectiveWalletId(scopedWalletId),
      categoryId: categoryId,
      dateFrom: dateFrom,
      dateTo: dateTo,
      type: type,
      searchQuery: normalizedSearchQuery,
      cursor: cursor,
      limit: limit,
    );
  }

  TransactionListFilters copyWith({
    Object? categoryId = _unset,
    Object? walletId = _unset,
    Object? dateFrom = _unset,
    Object? dateTo = _unset,
    Object? type = _unset,
    Object? searchQuery = _unset,
  }) {
    return TransactionListFilters(
      categoryId: identical(categoryId, _unset)
          ? this.categoryId
          : categoryId as String?,
      walletId:
          identical(walletId, _unset) ? this.walletId : walletId as String?,
      dateFrom:
          identical(dateFrom, _unset) ? this.dateFrom : dateFrom as DateTime?,
      dateTo: identical(dateTo, _unset) ? this.dateTo : dateTo as DateTime?,
      type: identical(type, _unset) ? this.type : type as String?,
      searchQuery: identical(searchQuery, _unset)
          ? this.searchQuery
          : searchQuery as String?,
    );
  }

  static const Object _unset = Object();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TransactionListFilters &&
        other.categoryId == categoryId &&
        other.walletId == walletId &&
        other.dateFrom == dateFrom &&
        other.dateTo == dateTo &&
        other.type == type &&
        other.searchQuery == searchQuery;
  }

  @override
  int get hashCode => Object.hash(
        categoryId,
        walletId,
        dateFrom,
        dateTo,
        type,
        searchQuery,
      );
}
