import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mali_app/application/providers/repository_providers.dart';
import 'package:mali_app/domain/repositories/transaction_repository.dart';
import 'package:mali_app/domain/usecases/build_transaction_export_usecase.dart';
import 'package:mali_app/domain/value_objects/date_range.dart';

/// Identifies the export preview count for a date range and filters.
class ExportCountQuery {
  const ExportCountQuery({
    required this.range,
    this.walletId,
    this.categoryId,
  });

  final DateRange range;
  final String? walletId;
  final String? categoryId;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is ExportCountQuery &&
        other.range == range &&
        other.walletId == walletId &&
        other.categoryId == categoryId;
  }

  @override
  int get hashCode => Object.hash(range, walletId, categoryId);
}

/// How many transactions the current export selection would include.
final exportTransactionCountProvider =
    FutureProvider.autoDispose.family<int, ExportCountQuery>((ref, query) async {
  final transactions = await ref.watch(transactionRepositoryProvider).list(
        query: TransactionQuery(
          dateFrom: query.range.start,
          dateTo: query.range.end,
          walletId: query.walletId,
          categoryId: query.categoryId,
          limit: BuildTransactionExportUseCase.transactionLimit,
        ),
      );
  return transactions.length;
});
