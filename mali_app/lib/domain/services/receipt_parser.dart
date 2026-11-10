import 'package:decimal/decimal.dart';
import 'package:mali_app/domain/value_objects/currency_code.dart';
import 'package:mali_app/domain/value_objects/receipt_scan.dart';

/// Turns raw receipt OCR text into a [ReceiptScan] using simple heuristics.
///
/// Dates are read day-first (the convention in Zimbabwe and the region), and
/// amounts must carry two decimals so phone numbers and quantities are ignored.
class ReceiptParser {
  const ReceiptParser({DateTime Function() clock = DateTime.now})
      : _clock = clock;

  final DateTime Function() _clock;

  static const int _merchantSearchLines = 6;
  static const int _merchantMaxLength = 40;
  static const int _maxReceiptAgeDays = 730;

  static final RegExp _money = RegExp(
    r'(?<![\d.,])(\d{1,3}(?:[ ,.]\d{3})+|\d+)[.,](\d{2})(?![\d])',
  );

  static final RegExp _totalKeyword = RegExp(
    r'\b(grand\s*total|total\s*due|amount\s*due|balance\s*due|to\s*pay|'
    r'total|amount)\b',
    caseSensitive: false,
  );

  static final RegExp _notTotalKeyword = RegExp(
    r'\b(sub\s*-?\s*total|tax|vat|change|cash|tendered|discount|savings|'
    r'rounding|tip|points)\b',
    caseSensitive: false,
  );

  static final RegExp _merchantNoise = RegExp(
    r'(receipt|invoice|welcome|thank|\btel\b|phone|fax|\bvat\b|'
    r'\bbp\s*no\b|\btin\b|www|@|\bdate\b|\btime\b|\btill\b|cashier|'
    r'\border\b)',
    caseSensitive: false,
  );

  static const Map<String, int> _months = {
    'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
    'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
  };

  ReceiptScan parse(String text) {
    final lines = text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList(growable: false);

    return ReceiptScan(
      amount: _findTotal(lines),
      currency: _findCurrency(text),
      date: _findDate(text),
      merchant: _findMerchant(lines),
    );
  }

  String? _findTotal(List<String> lines) {
    final candidates = <Decimal>[];

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (!_totalKeyword.hasMatch(line) || _notTotalKeyword.hasMatch(line)) {
        continue;
      }
      var amounts = _amountsIn(line);
      // Some printers put the figure on the row below its label.
      if (amounts.isEmpty && i + 1 < lines.length) {
        amounts = _amountsIn(lines[i + 1]);
      }
      candidates.addAll(amounts);
    }

    if (candidates.isEmpty) {
      for (final line in lines) {
        if (_notTotalKeyword.hasMatch(line)) {
          continue;
        }
        candidates.addAll(_amountsIn(line));
      }
    }

    final positive = candidates.where((value) => value > Decimal.zero);
    if (positive.isEmpty) {
      return null;
    }
    return positive.reduce((a, b) => a > b ? a : b).toString();
  }

  List<Decimal> _amountsIn(String line) {
    final result = <Decimal>[];
    for (final match in _money.allMatches(line)) {
      final whole = match.group(1)!.replaceAll(RegExp(r'[ ,.]'), '');
      final value = Decimal.tryParse('$whole.${match.group(2)}');
      if (value != null) {
        result.add(value);
      }
    }
    return result;
  }

  CurrencyCode? _findCurrency(String text) {
    final upper = text.toUpperCase();
    if (RegExp(r'\b(ZWG|ZIG)\b').hasMatch(upper)) {
      return CurrencyCode.zwg;
    }
    if (RegExp(r'\b(ZAR|RAND)\b').hasMatch(upper)) {
      return CurrencyCode.zar;
    }
    if (RegExp(r'\b(BWP|PULA)\b').hasMatch(upper)) {
      return CurrencyCode.bwp;
    }
    if (RegExp(r'\bUSD\b|US\$|\$').hasMatch(upper)) {
      return CurrencyCode.usd;
    }
    return null;
  }

  DateTime? _findDate(String text) {
    final numeric = RegExp(
      r'\b(\d{1,4})[/\-.](\d{1,2})[/\-.](\d{2,4})\b',
    );
    for (final match in numeric.allMatches(text)) {
      final a = int.parse(match.group(1)!);
      final b = int.parse(match.group(2)!);
      final c = int.parse(match.group(3)!);
      final date = match.group(1)!.length == 4
          ? _validDate(a, b, c)
          : _validDate(_fullYear(c), b, a) ?? _validDate(_fullYear(c), a, b);
      if (date != null) {
        return date;
      }
    }

    final written = RegExp(
      r'\b(\d{1,2})[\s\-]*([A-Za-z]{3})[A-Za-z]*[\s\-,]*(\d{2,4})\b',
    );
    for (final match in written.allMatches(text)) {
      final month = _months[match.group(2)!.toLowerCase()];
      if (month == null) {
        continue;
      }
      final date = _validDate(
        _fullYear(int.parse(match.group(3)!)),
        month,
        int.parse(match.group(1)!),
      );
      if (date != null) {
        return date;
      }
    }
    return null;
  }

  int _fullYear(int year) => year < 100 ? 2000 + year : year;

  /// Rejects impossible dates and anything outside a plausible receipt window.
  DateTime? _validDate(int year, int month, int day) {
    if (month < 1 || month > 12 || day < 1 || day > 31) {
      return null;
    }
    final date = DateTime(year, month, day);
    if (date.month != month || date.day != day) {
      return null;
    }
    final now = _clock();
    final today = DateTime(now.year, now.month, now.day);
    if (date.isAfter(today) ||
        today.difference(date).inDays > _maxReceiptAgeDays) {
      return null;
    }
    return date;
  }

  String? _findMerchant(List<String> lines) {
    for (final line in lines.take(_merchantSearchLines)) {
      final letters = RegExp(r'[A-Za-z]').allMatches(line).length;
      if (letters < 3 || letters < line.length / 2) {
        continue;
      }
      if (_merchantNoise.hasMatch(line) || _money.hasMatch(line)) {
        continue;
      }
      final cleaned = line.replaceAll(RegExp(r'\s+'), ' ').trim();
      return cleaned.length > _merchantMaxLength
          ? cleaned.substring(0, _merchantMaxLength).trim()
          : cleaned;
    }
    return null;
  }
}
