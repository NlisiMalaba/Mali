import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mali_app/data/export/pdf_export_renderer.dart';
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
}) {
  return ExportTransactionRow(
    transactionId: id,
    date: DateTime(2026, 9, 5),
    type: type,
    categoryName: categoryName,
    amount: amount,
    currencyCode: currencyCode,
    walletName: walletName,
    title: title,
    notes: null,
  );
}

TransactionExport _export({
  List<ExportTransactionRow>? rows,
  List<ExportMonthlySummary>? summaries,
}) {
  return TransactionExport(
    range: DateRange(
      start: DateTime(2026, 9, 1),
      end: DateTime(2026, 9, 30, 23, 59, 59),
    ),
    userName: 'Tendai Moyo',
    generatedAt: DateTime(2026, 10, 1, 8, 30),
    rows: rows ?? [_row()],
    monthlySummaries: summaries ??
        [
          ExportMonthlySummary(
            month: DateTime(2026, 9),
            currencyCode: 'USD',
            income: Decimal.parse('1000'),
            expenses: Decimal.parse('250.50'),
          ),
        ],
  );
}

/// Counts page objects in the raw PDF. Object dictionaries are written
/// uncompressed, so the `/Type /Page` marker is greppable.
int _pageCount(List<int> bytes) {
  return RegExp(r'/Type\s*/Page[^s]')
      .allMatches(String.fromCharCodes(bytes))
      .length;
}

void main() {
  const renderer = PdfExportRenderer();

  group('PdfExportRenderer', () {
    test('declares the pdf format', () {
      expect(renderer.fileExtension, 'pdf');
      expect(renderer.mimeType, 'application/pdf');
    });

    test('produces a valid PDF document', () async {
      final bytes = await renderer.render(_export());

      expect(bytes, isNotEmpty);
      // Every PDF starts with the %PDF- magic number.
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    });

    test('renders an empty range without throwing', () async {
      final bytes = await renderer.render(
        _export(rows: const [], summaries: const []),
      );

      expect(bytes, isNotEmpty);
    });

    test('splits a long transaction table across pages', () async {
      final many = [
        for (var i = 0; i < 200; i++) _row(id: 't-$i', title: 'Item $i'),
      ];

      final bytes = await renderer.render(_export(rows: many));

      expect(_pageCount(bytes), greaterThan(1));
    });

    test('keeps a short export on a single page', () async {
      final bytes = await renderer.render(_export());

      expect(_pageCount(bytes), 1);
    });

    test('handles multiple currencies in the summary', () async {
      final bytes = await renderer.render(
        _export(
          summaries: [
            ExportMonthlySummary(
              month: DateTime(2026, 9),
              currencyCode: 'USD',
              income: Decimal.parse('1000'),
              expenses: Decimal.parse('250'),
            ),
            ExportMonthlySummary(
              month: DateTime(2026, 9),
              currencyCode: 'ZAR',
              income: Decimal.zero,
              expenses: Decimal.parse('400'),
            ),
          ],
        ),
      );

      expect(bytes, isNotEmpty);
    });
  });
}
