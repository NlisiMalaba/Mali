import 'package:decimal/decimal.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mali_app/core/error/failure.dart';
import 'package:mali_app/domain/entities/transaction.dart';
import 'package:mali_app/domain/repositories/transaction_repository.dart';
import 'package:mali_app/domain/repositories/wallet_repository.dart';
import 'package:mali_app/domain/value_objects/date_range.dart';
import 'package:mali_app/domain/value_objects/export_filters.dart';

/// Gathers everything an export document needs for a date range.
///
/// Amounts are never converted between currencies: an export is a record of
/// what happened, so each row keeps its original amount and currency and the
/// summary is reported per currency.
class BuildTransactionExportUseCase {
  const BuildTransactionExportUseCase({
    required ITransactionRepository transactionRepository,
    required IWalletRepository walletRepository,
    required ExportCategoryNameLookup categoryNameLookup,
  })  : _transactionRepository = transactionRepository,
        _walletRepository = walletRepository,
        _categoryNameLookup = categoryNameLookup;

  /// Upper bound on rows in a single export.
  static const int transactionLimit = 20000;

  static const String incomeType = 'income';
  static const String expenseType = 'expense';

  /// Shown when a transaction has no category, or an unknown one.
  static const String uncategorisedLabel = 'Uncategorised';

  /// Shown when a wallet has been hard-deleted but its transactions remain.
  static const String unknownWalletLabel = 'Unknown wallet';

  final ITransactionRepository _transactionRepository;
  final IWalletRepository _walletRepository;
  final ExportCategoryNameLookup _categoryNameLookup;

  Future<Either<Failure, TransactionExport>> call({
    required DateRange range,
    required String userName,
    required DateTime generatedAt,
    ExportFilters filters = ExportFilters.none,
  }) async {
    if (userName.trim().isEmpty) {
      return left(
        const ValidationFailure(
          message: 'A user name is required to label the export.',
          field: 'userName',
        ),
      );
    }

    try {
      final transactions = await _transactionRepository.list(
        query: TransactionQuery(
          dateFrom: range.start,
          dateTo: range.end,
          walletId: filters.walletId,
          categoryId: filters.categoryId,
          limit: transactionLimit,
        ),
      );

      final walletNames = await _walletNamesFor(transactions);
      final rows = _buildRows(transactions, walletNames);

      return right(
        TransactionExport(
          range: range,
          userName: userName.trim(),
          generatedAt: generatedAt,
          rows: rows,
          monthlySummaries: _summarise(transactions),
          appliedFilters: await _describeFilters(filters),
        ),
      );
    } catch (error) {
      return left(
        StorageFailure(
          message: 'Failed to collect transactions for export.',
          cause: error,
        ),
      );
    }
  }

  /// Human-readable labels for any active filter, so a reader can tell the
  /// document is a subset rather than a complete record.
  Future<List<String>> _describeFilters(ExportFilters filters) async {
    final walletId = filters.walletId;
    final categoryId = filters.categoryId;

    return [
      if (walletId != null)
        'Wallet: ${(await _walletRepository.findById(walletId))?.name ?? unknownWalletLabel}',
      if (categoryId != null) 'Category: ${_categoryName(categoryId)}',
    ];
  }

  Future<Map<String, String>> _walletNamesFor(
    List<Transaction> transactions,
  ) async {
    final walletIds = {for (final t in transactions) t.walletId};
    final names = <String, String>{};

    for (final walletId in walletIds) {
      final wallet = await _walletRepository.findById(walletId);
      if (wallet != null) {
        names[walletId] = wallet.name;
      }
    }

    return names;
  }

  /// Oldest first, so the document reads chronologically.
  List<ExportTransactionRow> _buildRows(
    List<Transaction> transactions,
    Map<String, String> walletNames,
  ) {
    final ordered = [...transactions]
      ..sort((a, b) {
        final byDate = a.transactionDate.compareTo(b.transactionDate);
        return byDate != 0 ? byDate : a.id.compareTo(b.id);
      });

    return [
      for (final transaction in ordered)
        ExportTransactionRow(
          transactionId: transaction.id,
          date: transaction.transactionDate,
          type: transaction.type,
          categoryName: _categoryName(transaction.categoryId),
          amount: transaction.amount,
          currencyCode: transaction.currencyCode,
          walletName: walletNames[transaction.walletId] ?? unknownWalletLabel,
          title: transaction.title,
          notes: transaction.notes,
        ),
    ];
  }

  String _categoryName(String? categoryId) {
    if (categoryId == null) {
      return uncategorisedLabel;
    }
    return _categoryNameLookup(categoryId) ?? uncategorisedLabel;
  }

  /// One entry per month and currency, oldest month first.
  List<ExportMonthlySummary> _summarise(List<Transaction> transactions) {
    final totals = <String, ExportMonthlySummary>{};

    for (final transaction in transactions) {
      final isIncome = transaction.type == incomeType;
      final isExpense = transaction.type == expenseType;
      if (!isIncome && !isExpense) {
        continue;
      }

      final amount = Decimal.tryParse(transaction.amount);
      if (amount == null) {
        continue;
      }

      final month = DateTime(
        transaction.transactionDate.year,
        transaction.transactionDate.month,
      );
      final key = '${month.toIso8601String()}|${transaction.currencyCode}';
      final current = totals[key] ??
          ExportMonthlySummary(
            month: month,
            currencyCode: transaction.currencyCode,
            income: Decimal.zero,
            expenses: Decimal.zero,
          );

      totals[key] = isIncome
          ? current.copyWith(income: current.income + amount)
          : current.copyWith(expenses: current.expenses + amount);
    }

    return totals.values.toList()
      ..sort((a, b) {
        final byMonth = a.month.compareTo(b.month);
        return byMonth != 0
            ? byMonth
            : a.currencyCode.compareTo(b.currencyCode);
      });
  }
}

/// Resolves a category id to a display name, or null when unknown.
typedef ExportCategoryNameLookup = String? Function(String categoryId);

class TransactionExport {
  const TransactionExport({
    required this.range,
    required this.userName,
    required this.generatedAt,
    required this.rows,
    required this.monthlySummaries,
    this.appliedFilters = const [],
  });

  final DateRange range;
  final String userName;
  final DateTime generatedAt;
  final List<ExportTransactionRow> rows;
  final List<ExportMonthlySummary> monthlySummaries;

  /// Labels describing any filters applied, empty for a full export.
  final List<String> appliedFilters;

  bool get isEmpty => rows.isEmpty;
}

class ExportTransactionRow {
  const ExportTransactionRow({
    required this.transactionId,
    required this.date,
    required this.type,
    required this.categoryName,
    required this.amount,
    required this.currencyCode,
    required this.walletName,
    required this.title,
    required this.notes,
  });

  final String transactionId;
  final DateTime date;
  final String type;
  final String categoryName;

  /// Decimal-safe string, exactly as stored.
  final String amount;
  final String currencyCode;
  final String walletName;
  final String title;
  final String? notes;
}

class ExportMonthlySummary {
  const ExportMonthlySummary({
    required this.month,
    required this.currencyCode,
    required this.income,
    required this.expenses,
  });

  final DateTime month;
  final String currencyCode;
  final Decimal income;
  final Decimal expenses;

  Decimal get net => income - expenses;

  ExportMonthlySummary copyWith({
    Decimal? income,
    Decimal? expenses,
  }) {
    return ExportMonthlySummary(
      month: month,
      currencyCode: currencyCode,
      income: income ?? this.income,
      expenses: expenses ?? this.expenses,
    );
  }
}
