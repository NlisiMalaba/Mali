import 'package:mali_app/core/constants/transaction_list_constants.dart';
import 'package:mali_app/domain/repositories/transaction_repository.dart';

class TransactionListFilters {
  const TransactionListFilters({
    this.categoryId,
    this.walletId,
    this.dateFrom,
    this.dateTo,
  });

  final String? categoryId;
  final String? walletId;
  final DateTime? dateFrom;
  final DateTime? dateTo;

  bool get hasActiveFilters =>
      categoryId != null ||
      walletId != null ||
      dateFrom != null ||
      dateTo != null;

  String? effectiveWalletId(String? scopedWalletId) {
    return scopedWalletId ?? walletId;
  }

  TransactionWatchQuery toWatchQuery(String? scopedWalletId) {
    return TransactionWatchQuery(
      walletId: effectiveWalletId(scopedWalletId),
      categoryId: categoryId,
      dateFrom: dateFrom,
      dateTo: dateTo,
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
      cursor: cursor,
      limit: limit,
    );
  }

  TransactionListFilters copyWith({
    Object? categoryId = _unset,
    Object? walletId = _unset,
    Object? dateFrom = _unset,
    Object? dateTo = _unset,
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
        other.dateTo == dateTo;
  }

  @override
  int get hashCode => Object.hash(categoryId, walletId, dateFrom, dateTo);
}
