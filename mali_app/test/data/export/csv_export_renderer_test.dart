import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mali_app/data/export/csv_export_renderer.dart';
import 'package:mali_app/domain/usecases/build_transaction_export_usecase.dart';
import 'package:mali_app/domain/value_objects/date_range.dart';

ExportTransactionRow _row({
  String id = 't-1',
  String type = 'expense',
  String amount = '25.50',
  String currencyCode = 'USD',
  String categoryName = 'Food',
  String walletName = 'Cash',
  String title = 'Lunch',
  String? notes,
  DateTime? date,
}) {
  return ExportTransactionRow(
    transactionId: id,
    date: date ?? DateTime(2026, 9, 5),
    type: type,
    categoryName: categoryName,
    amount: amount,
    currencyCode: currencyCode,
    walletName: walletName,
    title: title,
    notes: notes,
  );
}

TransactionExport _export({List<ExportTransactionRow>? rows}) {
  return TransactionExport(
    range: DateRange(
      start: DateTime(2026, 9, 1),
      end: DateTime(2026, 9, 30, 23, 59, 59),
    ),
    userName: 'Tendai Moyo',
    generatedAt: DateTime(2026, 10, 1, 8, 30),
    rows: rows ?? [_row()],
    monthlySummaries: const [],
  );
}

/// Decodes rendered bytes back to text, dropping the byte order mark.
Future<String> _renderText(TransactionExport export) async {
  const renderer = CsvExportRenderer();
  final bytes = await renderer.render(export);
  return utf8.decode(bytes.sublist(CsvExportRenderer.utf8ByteOrderMark.length));
}

void main() {
  const renderer = CsvExportRenderer();

  group('CsvExportRenderer', () {
    test('declares the csv format', () {
      expect(renderer.fileExtension, 'csv');
      expect(renderer.mimeType, 'text/csv');
    });

    test('writes the specified header row', () async {
      final text = await _renderText(_export(rows: const []));

      expect(text, 'date,type,category,amount,currency,wallet,notes\r\n');
      expect(
        CsvExportRenderer.headers,
        ['date', 'type', 'category', 'amount', 'currency', 'wallet', 'notes'],
      );
    });

    test('starts with a UTF-8 byte order mark for Excel', () async {
      final bytes = await renderer.render(_export());

      expect(
        bytes.sublist(0, 3),
        CsvExportRenderer.utf8ByteOrderMark,
      );
    });

    test('writes one row per transaction in column order', () async {
      final text = await _renderText(
        _export(
          rows: [
            _row(
              date: DateTime(2026, 9, 5),
              type: 'expense',
              categoryName: 'Food',
              amount: '25.50',
              currencyCode: 'USD',
              walletName: 'Cash',
              notes: 'Team lunch',
            ),
          ],
        ),
      );

      expect(
        text.split('\r\n')[1],
        '2026-09-05,expense,Food,25.50,USD,Cash,Team lunch',
      );
    });

    test('writes amounts unformatted so they parse as numbers', () async {
      final text = await _renderText(
        _export(rows: [_row(amount: '1234.5', currencyCode: 'ZAR')]),
      );

      expect(text, contains(',1234.5,ZAR,'));
    });

    test('leaves the notes column empty when there are no notes', () async {
      final text = await _renderText(_export(rows: [_row()]));

      expect(text.split('\r\n')[1], endsWith(',Cash,'));
    });

    test('escapes commas and quotes in user text', () async {
      final text = await _renderText(
        _export(
          rows: [
            _row(
              categoryName: 'Food, drink',
              walletName: 'The "Main" Wallet',
              notes: 'Split 50/50, paid cash',
            ),
          ],
        ),
      );

      expect(text, contains('"Food, drink"'));
      expect(text, contains('"The ""Main"" Wallet"'));
      expect(text, contains('"Split 50/50, paid cash"'));
    });

    test('keeps a multi-line note inside a single quoted field', () async {
      final text = await _renderText(
        _export(rows: [_row(notes: 'first line\nsecond line')]),
      );

      expect(text, contains('"first line\nsecond line"'));
      // Header, the single data row, and the trailing terminator.
      expect(text.split('\r\n'), hasLength(3));
    });

    test('round-trips non-ASCII text through UTF-8', () async {
      final text = await _renderText(
        _export(rows: [_row(walletName: 'Épargne', notes: 'Café')]),
      );

      expect(text, contains('Épargne'));
      expect(text, contains('Café'));
    });

    test('renders only a header when there are no transactions', () async {
      final text = await _renderText(_export(rows: const []));

      expect(text.split('\r\n').where((line) => line.isNotEmpty), hasLength(1));
    });
  });
}
