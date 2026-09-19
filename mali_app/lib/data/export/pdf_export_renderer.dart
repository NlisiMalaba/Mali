import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:mali_app/domain/services/export_renderer.dart';
import 'package:mali_app/domain/usecases/build_transaction_export_usecase.dart';
import 'package:mali_app/presentation/utils/money_display.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Renders a [TransactionExport] as an A4 PDF statement.
///
/// Uses the built-in Helvetica family and a drawn logo mark so the document
/// needs no bundled font or image assets.
class PdfExportRenderer implements IExportRenderer {
  const PdfExportRenderer();

  @override
  String get fileExtension => 'pdf';

  @override
  String get mimeType => 'application/pdf';

  static final PdfColor _brand = PdfColor.fromInt(0xFF0D9488);
  static final PdfColor _muted = PdfColor.fromInt(0xFF64748B);
  static final PdfColor _headerFill = PdfColor.fromInt(0xFFF1F5F9);

  static const double _logoSize = 30;
  static const double _logoCornerRadius = 7;

  static final DateFormat _rowDateFormat = DateFormat('yyyy-MM-dd');
  static final DateFormat _rangeDateFormat = DateFormat('d MMM yyyy');
  static final DateFormat _monthFormat = DateFormat('MMMM yyyy');
  static final DateFormat _generatedFormat = DateFormat('d MMM yyyy, HH:mm');

  @override
  Future<Uint8List> render(TransactionExport export) async {
    final document = pw.Document(
      title: 'Mali transactions',
      author: export.userName,
    );

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        header: (context) =>
            context.pageNumber == 1 ? _header(export) : pw.SizedBox(),
        footer: _footer,
        // Sections are returned flat rather than wrapped in a Column, because
        // MultiPage can only split top-level widgets across pages.
        build: (context) => [
          ..._transactionsSection(export),
          pw.SizedBox(height: 20),
          ..._summarySection(export),
        ],
      ),
    );

    return document.save();
  }

  pw.Widget _header(TransactionExport export) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 14),
      margin: const pw.EdgeInsets.only(bottom: 14),
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _brand, width: 1.5)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              _logoMark(),
              pw.SizedBox(width: 10),
              pw.Text(
                'Mali',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: _brand,
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                export.userName,
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                '${_rangeDateFormat.format(export.range.start)} - '
                '${_rangeDateFormat.format(export.range.end)}',
                style: const pw.TextStyle(fontSize: 10),
              ),
              if (export.appliedFilters.isNotEmpty) ...[
                pw.SizedBox(height: 2),
                pw.Text(
                  export.appliedFilters.join(' · '),
                  style: const pw.TextStyle(fontSize: 9),
                ),
              ],
              pw.SizedBox(height: 2),
              pw.Text(
                'Generated ${_generatedFormat.format(export.generatedAt)}',
                style: pw.TextStyle(fontSize: 8, color: _muted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Vector stand-in for the in-app [MaliLogo] widget.
  pw.Widget _logoMark() {
    return pw.Container(
      width: _logoSize,
      height: _logoSize,
      alignment: pw.Alignment.center,
      decoration: pw.BoxDecoration(
        color: _brand,
        borderRadius: pw.BorderRadius.all(
          pw.Radius.circular(_logoCornerRadius),
        ),
      ),
      child: pw.Text(
        'M',
        style: pw.TextStyle(
          fontSize: 17,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
      ),
    );
  }

  pw.Widget _footer(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 10),
      child: pw.Text(
        'Page ${context.pageNumber} of ${context.pagesCount}',
        style: pw.TextStyle(fontSize: 8, color: _muted),
      ),
    );
  }

  List<pw.Widget> _transactionsSection(TransactionExport export) {
    if (export.isEmpty) {
      return [
        _sectionTitle('Transactions'),
        pw.SizedBox(height: 8),
        pw.Text(
          'No transactions in this date range.',
          style: pw.TextStyle(fontSize: 10, color: _muted),
        ),
      ];
    }

    return [
      _sectionTitle('Transactions (${export.rows.length})'),
      pw.SizedBox(height: 8),
      pw.TableHelper.fromTextArray(
        headers: const [
          'Date',
          'Type',
          'Category',
          'Description',
          'Wallet',
          'Amount',
        ],
        data: [
          for (final row in export.rows)
            [
              _rowDateFormat.format(row.date),
              _titleCase(row.type),
              row.categoryName,
              row.title,
              row.walletName,
              MoneyDisplay.withCurrency(
                amount: row.amount,
                currencyCode: row.currencyCode,
              ),
            ],
        ],
        headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
        headerDecoration: pw.BoxDecoration(color: _headerFill),
        cellStyle: const pw.TextStyle(fontSize: 9),
        cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
        border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.4),
        cellAlignments: const {5: pw.Alignment.centerRight},
        headerAlignments: const {5: pw.Alignment.centerRight},
        columnWidths: const {
          0: pw.FlexColumnWidth(1.6),
          1: pw.FlexColumnWidth(1.1),
          2: pw.FlexColumnWidth(1.7),
          3: pw.FlexColumnWidth(2.6),
          4: pw.FlexColumnWidth(1.7),
          5: pw.FlexColumnWidth(1.8),
        },
      ),
    ];
  }

  List<pw.Widget> _summarySection(TransactionExport export) {
    if (export.monthlySummaries.isEmpty) {
      return const [];
    }

    return [
      _sectionTitle('Monthly summary'),
      pw.SizedBox(height: 8),
      pw.TableHelper.fromTextArray(
        headers: const ['Month', 'Currency', 'Income', 'Expenses', 'Net'],
        data: [
          for (final summary in export.monthlySummaries)
            [
              _monthFormat.format(summary.month),
              summary.currencyCode,
              MoneyDisplay.formatAmount(summary.income.toString()),
              MoneyDisplay.formatAmount(summary.expenses.toString()),
              MoneyDisplay.formatAmount(summary.net.toString()),
            ],
        ],
        headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
        headerDecoration: pw.BoxDecoration(color: _headerFill),
        cellStyle: const pw.TextStyle(fontSize: 9),
        cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
        border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.4),
        cellAlignments: const {
          2: pw.Alignment.centerRight,
          3: pw.Alignment.centerRight,
          4: pw.Alignment.centerRight,
        },
        headerAlignments: const {
          2: pw.Alignment.centerRight,
          3: pw.Alignment.centerRight,
          4: pw.Alignment.centerRight,
        },
      ),
    ];
  }

  pw.Widget _sectionTitle(String text) {
    return pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: 13,
        fontWeight: pw.FontWeight.bold,
        color: _brand,
      ),
    );
  }

  String _titleCase(String value) {
    if (value.isEmpty) {
      return value;
    }
    return value[0].toUpperCase() + value.substring(1);
  }
}
