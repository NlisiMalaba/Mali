import 'package:mali_app/domain/entities/transaction.dart';
import 'package:mali_app/presentation/utils/transaction_date_grouping.dart';
import 'package:mali_app/presentation/utils/transaction_day_summary.dart';

sealed class TransactionListItem {
  const TransactionListItem();
}

class TransactionDateHeaderItem extends TransactionListItem {
  const TransactionDateHeaderItem({
    required this.label,
    required this.summary,
  });

  final String label;
  final String summary;
}

class TransactionEntryItem extends TransactionListItem {
  const TransactionEntryItem(this.transaction);

  final Transaction transaction;
}

List<TransactionListItem> buildGroupedTransactionListItems(
  List<Transaction> transactions,
) {
  if (transactions.isEmpty) {
    return const [];
  }

  final groups = <String, List<Transaction>>{};
  final order = <String>[];

  for (final transaction in transactions) {
    final header = formatTransactionDateGroupHeader(transaction.transactionDate);
    final bucket = groups.putIfAbsent(header, () {
      order.add(header);
      return <Transaction>[];
    });
    bucket.add(transaction);
  }

  final items = <TransactionListItem>[];
  for (final header in order) {
    final dayTransactions = groups[header]!;
    items.add(
      TransactionDateHeaderItem(
        label: header,
        summary: formatTransactionDaySummary(dayTransactions),
      ),
    );
    for (final transaction in dayTransactions) {
      items.add(TransactionEntryItem(transaction));
    }
  }

  return items;
}
