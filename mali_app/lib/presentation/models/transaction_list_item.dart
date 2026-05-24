import 'package:mali_app/domain/entities/transaction.dart';
import 'package:mali_app/presentation/utils/transaction_date_grouping.dart';

sealed class TransactionListItem {
  const TransactionListItem();
}

class TransactionDateHeaderItem extends TransactionListItem {
  const TransactionDateHeaderItem(this.label);

  final String label;
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

  final items = <TransactionListItem>[];
  String? currentHeader;

  for (final transaction in transactions) {
    final header = formatTransactionDateGroupHeader(transaction.transactionDate);
    if (header != currentHeader) {
      currentHeader = header;
      items.add(TransactionDateHeaderItem(header));
    }
    items.add(TransactionEntryItem(transaction));
  }

  return items;
}
