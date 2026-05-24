import 'package:intl/intl.dart';
import 'package:mali_app/application/models/transaction_list_filters.dart';
import 'package:mali_app/domain/entities/category.dart';
import 'package:mali_app/domain/entities/wallet.dart';

class TransactionFilterLabels {
  const TransactionFilterLabels._();

  static String categoryLabel(Category category) => category.name;

  static String walletLabel(Wallet wallet) => wallet.name;

  static String dateRangeLabel(TransactionListFilters filters) {
    final from = filters.dateFrom;
    final to = filters.dateTo;
    if (from == null && to == null) {
      return 'Date';
    }
    final format = DateFormat('d MMM yyyy');
    if (from != null && to != null) {
      return '${format.format(from)} – ${format.format(to)}';
    }
    if (from != null) {
      return 'From ${format.format(from)}';
    }
    return 'Until ${format.format(to!)}';
  }
}
