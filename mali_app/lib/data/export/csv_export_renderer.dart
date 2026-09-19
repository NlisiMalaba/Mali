import 'dart:convert';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:mali_app/core/csv/csv_writer.dart';
import 'package:mali_app/domain/services/export_renderer.dart';
import 'package:mali_app/domain/usecases/build_transaction_export_usecase.dart';

/// Renders a [TransactionExport] as a spreadsheet-friendly CSV.
///
/// Amounts are written unformatted so they parse as numbers, and the currency
/// travels in its own column rather than being glued to the amount.
class CsvExportRenderer implements IExportRenderer {
  const CsvExportRenderer();

  @override
  String get fileExtension => 'csv';

  @override
  String get mimeType => 'text/csv';

  static const List<String> headers = [
    'date',
    'type',
    'category',
    'amount',
    'currency',
    'wallet',
    'notes',
  ];

  /// Excel assumes the system codepage unless a UTF-8 byte order mark is
  /// present, which mangles accented characters in names and notes.
  static const List<int> utf8ByteOrderMark = [0xEF, 0xBB, 0xBF];

  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  @override
  Future<Uint8List> render(TransactionExport export) async {
    final csv = CsvWriter.encode([
      headers,
      for (final row in export.rows)
        [
          _dateFormat.format(row.date),
          row.type,
          row.categoryName,
          row.amount,
          row.currencyCode,
          row.walletName,
          row.notes ?? '',
        ],
    ]);

    return Uint8List.fromList([
      ...utf8ByteOrderMark,
      ...utf8.encode(csv),
    ]);
  }
}
